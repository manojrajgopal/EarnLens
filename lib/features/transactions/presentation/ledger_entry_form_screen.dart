import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/income_source.dart';
import '../../../domain/models/records.dart';
import '../../../domain/money/currency.dart';
import '../../../domain/money/money_parser.dart';
import '../../../domain/services/validators.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../income_sources/presentation/widgets/income_common.dart';

/// Records or corrects a ledger entry: payment received, income earned,
/// adjustment, deduction or reversal.
class LedgerEntryFormScreen extends ConsumerStatefulWidget {
  const LedgerEntryFormScreen({super.key, required this.sourceId, this.entryId, this.type, this.period, this.itemId});

  final String sourceId;
  final String? entryId;
  final LedgerType? type;
  final YearMonth? period;
  final String? itemId;

  @override
  ConsumerState<LedgerEntryFormScreen> createState() => _LedgerEntryFormScreenState();
}

class _LedgerEntryFormScreenState extends ConsumerState<LedgerEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  bool _ready = false;
  LedgerEntry? _existing;
  LedgerType _type = LedgerType.received;
  late YearMonth _period;
  late LocalDate _date;
  LedgerStatus _status = LedgerStatus.completed;
  String? _itemId;
  int? _prefilledOutstanding;

  bool get _isEdit => widget.entryId != null;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  static bool _allowsEarned(IncomeSource s) => s.kind == IncomeKind.variable || s.kind == IncomeKind.oneTime;

  List<LedgerType> _typeChoices(IncomeSource s) => [
    for (final t in LedgerType.values)
      if (t != LedgerType.earned || _allowsEarned(s) || _existing?.type == LedgerType.earned) t,
  ];

  bool _init(IncomeSource s, Currency currency) {
    final today = currentDate(ref);
    if (_isEdit) {
      final e = ref.read(snapshotProvider).ledger.where((x) => x.id == widget.entryId).firstOrNull;
      if (e == null) return false;
      _existing = e;
      _type = e.type;
      _period = e.periodMonth;
      _date = e.date;
      _status = e.status;
      _itemId = e.itemId;
      _amount.text = MoneyParser.toInput(e.amountMinor, currency);
      _notes.text = e.notes ?? '';
    } else {
      var t = widget.type ?? (s.kind == IncomeKind.variable ? LedgerType.earned : LedgerType.received);
      if (t == LedgerType.earned && !_allowsEarned(s)) t = LedgerType.received;
      _type = t;
      _itemId = widget.itemId;
      _period = widget.period ?? today.yearMonth;
      // Earned entries are counted by their date, so keep it inside the month.
      _date = t != LedgerType.earned || _period.contains(today)
          ? today
          : (_period.isBefore(today.yearMonth) ? _period.lastDay : _period.firstDay);
      if (t == LedgerType.received && (widget.period != null || widget.itemId != null)) {
        final match = ref.read(expectedPaymentsProvider).where((p) {
          if (p.sourceId != s.id) return false;
          if (widget.itemId != null) return p.itemId == widget.itemId;
          return p.itemId == null && p.periodMonth == widget.period;
        }).firstOrNull;
        if (match != null && match.outstandingMinor > 0) {
          _prefilledOutstanding = match.outstandingMinor;
          _amount.text = MoneyParser.toInput(match.outstandingMinor, currency);
        }
      }
    }
    _ready = true;
    return true;
  }

  LedgerEntry _build(IncomeSource s, Currency currency) {
    final now = ref.read(clockProvider).now();
    final amount = parseMoney(_amount, currency, allowNegative: _type == LedgerType.adjustment)!;
    final e = _existing;
    return LedgerEntry(
      id: e?.id ?? ref.read(idProvider).newId(),
      sourceId: s.id,
      itemId: _itemId,
      type: _type,
      amountMinor: amount,
      currencyCode: e?.currencyCode ?? s.currencyCode,
      periodMonth: _period,
      date: _date,
      status: _status,
      dedupeKey: e?.dedupeKey,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<void> _save(IncomeSource s, Currency currency) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final entry = _build(s, currency);
    try {
      Validators.ledger(entry);
    } on ValidationException catch (e) {
      showMessage(context, e.message);
      return;
    }
    final repo = ref.read(recordsRepositoryProvider);
    if (_isEdit) {
      final ok = await runGuarded(context, () => repo.updateLedgerEntry(entry), success: 'Entry updated');
      if (ok && mounted) context.pop();
      return;
    }
    try {
      await repo.addLedgerEntry(entry);
      if (!mounted) return;
      showMessage(context, '${_type.label} recorded');
      context.pop();
    } on DuplicateEntryException catch (e) {
      if (!mounted) return;
      final again = await confirmDialog(
        context,
        title: 'Looks like a duplicate',
        message: e.message,
        confirm: 'Add anyway',
      );
      if (!again || !mounted) return;
      final ok = await runGuarded(
        context,
        () => repo.addLedgerEntry(entry, allowDuplicate: true),
        success: '${_type.label} recorded',
      );
      if (ok && mounted) context.pop();
    } on AppException catch (e) {
      if (mounted) showMessage(context, e.message);
    } on Object {
      if (mounted) showMessage(context, 'Could not save. Your data was not changed.');
    }
  }

  String _typeHelp(LedgerType t) => switch (t) {
    LedgerType.received => 'Money that reached you. It does not change what you earned — only what has been paid.',
    LedgerType.earned => 'An invoice, sale or job you completed. It adds to this month\'s earnings.',
    LedgerType.adjustment =>
      'Corrects earnings for a month, e.g. arrears after a backdated hike (positive) or a recovery (negative).',
    LedgerType.deduction => 'Money withheld from your pay, like tax or provident fund. It counts as settled.',
    LedgerType.reversal => 'Money you received that was refunded or taken back.',
  };

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(sourceProvider(widget.sourceId));
    if (source == null) return const MissingSourceScaffold(title: 'Transaction');
    final s = source;
    final currency = Currency.byCode(_existing?.currencyCode ?? s.currencyCode);
    if (!_ready && !_init(s, currency)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction')),
        body: const Center(
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Not found',
            message: 'This entry no longer exists.',
          ),
        ),
      );
    }

    final c = context.colors;
    final snap = ref.watch(snapshotProvider);
    final fmt = moneyFormatterFor(ref, s.currencyCode);
    final item = _itemId == null ? null : snap.items.where((i) => i.id == _itemId).firstOrNull;
    final monthRecord = s.kind == IncomeKind.variable ? snap.record(s.id, _period) : null;
    final isReceipt = _type == LedgerType.received || _type == LedgerType.reversal || _type == LedgerType.deduction;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit ${_type.label.toLowerCase()}' : 'Record transaction')),
      body: Form(
        key: _formKey,
        child: PageList(
          children: [
            SourceContextChip(source: s, detail: item?.title),
            if (_existing != null &&
                _existing!.status != LedgerStatus.completed &&
                _existing!.status != LedgerStatus.pending) ...[
              vGap,
              InfoBanner(
                'This entry is ${_existing!.status.label.toLowerCase()} and does not count in totals.',
                tone: BannerTone.warning,
                icon: Icons.info_outline_rounded,
              ),
            ],
            FormSection(
              title: 'Type',
              subtitle: 'What kind of money movement is this?',
              icon: Icons.swap_vert_rounded,
              children: [
                ChoicePills<LedgerType>(
                  values: _typeChoices(s),
                  selected: _type,
                  label: (t) => t.label,
                  onSelected: (t) => setState(() {
                    _type = t;
                    if (t != LedgerType.adjustment && _amount.text.trim().startsWith('-')) {
                      _amount.text = _amount.text.trim().substring(1);
                    }
                  }),
                ),
                vGapSmall,
                Text(_typeHelp(_type), style: AppType.bodySmall.copyWith(color: c.inkMuted)),
              ],
            ),
            FormSection(
              title: 'Details',
              subtitle: 'Amount and dates',
              icon: Icons.payments_outlined,
              color: AppColors.mint,
              children: [
                MoneyField(
                  key: ValueKey('amount-${_type == LedgerType.adjustment}'),
                  controller: _amount,
                  currency: currency,
                  label: 'Amount',
                  allowNegative: _type == LedgerType.adjustment,
                  helper: _type == LedgerType.adjustment
                      ? 'Use a minus sign to reduce earnings, e.g. -1500.'
                      : _prefilledOutstanding != null
                      ? 'Prefilled with the amount still due. Change it if you received a different amount.'
                      : null,
                ),
                if (_prefilledOutstanding != null) ...[
                  vGapSmall,
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.accentSoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: AmountText(
                        'Still due: ${fmt.minor(_prefilledOutstanding!)}',
                        style: AppType.caption.copyWith(color: c.accentText, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
                vGap,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: MonthPickerField(
                        label: 'Earning month',
                        value: _period,
                        helper: 'Which month\'s earnings this belongs to. October salary paid in November belongs to October.',
                        onChanged: (m) => setState(() => _period = m),
                      ),
                    ),
                    const InfoTip(
                      title: 'Earning month',
                      message:
                          'Pay is counted in the month it was earned, not the month the money arrived. '
                          'If your October salary is paid on 1 November, choose October here and 1 November as the date.',
                    ),
                  ],
                ),
                vGap,
                DateField(
                  key: ValueKey('date-$isReceipt'),
                  label: isReceipt ? 'Payment date' : 'Earned date',
                  initial: _date,
                  helper: isReceipt ? 'The day the money arrived or was withheld.' : 'The day this was earned.',
                  onChanged: (d) => setState(() => _date = d ?? _date),
                  validator: (d) => _type == LedgerType.earned && d != null && !_period.contains(d)
                      ? 'Income earned is counted by its date — pick a day in ${formatMonth(_period)}'
                      : null,
                ),
              ],
            ),
            FormSection(
              title: 'Status',
              icon: Icons.task_alt_rounded,
              color: AppColors.sky,
              children: [
                ChoicePills<LedgerStatus>(
                  values: [
                    LedgerStatus.completed,
                    LedgerStatus.pending,
                    if (_existing != null &&
                        !(_existing!.status == LedgerStatus.completed || _existing!.status == LedgerStatus.pending))
                      _existing!.status,
                  ],
                  selected: _status,
                  label: (st) => st.label,
                  onSelected: (st) => setState(() => _status = st),
                ),
                vGapSmall,
                Text(
                  _status == LedgerStatus.pending
                      ? 'Pending entries are a note to yourself and are not counted until marked completed.'
                      : 'Completed entries count in your totals.',
                  style: AppType.bodySmall.copyWith(color: c.inkMuted),
                ),
                if (_type == LedgerType.earned && monthRecord?.actualMinor != null) ...[
                  vGap,
                  InfoBanner(
                    '${formatMonth(_period)} already has a recorded monthly total. The total replaces detailed entries, '
                    'so this entry will be kept for reference but not added on top.',
                    tone: BannerTone.warning,
                    icon: Icons.info_outline_rounded,
                  ),
                ],
              ],
            ),
            ExpandableCard(
              title: 'Notes',
              subtitle: 'Optional — invoice number, bank reference…',
              icon: Icons.sticky_note_2_outlined,
              color: AppColors.peach,
              initiallyExpanded: _notes.text.isNotEmpty,
              children: [
                TextFormField(
                  controller: _notes,
                  maxLines: 3,
                  minLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'e.g. Invoice #42, bank reference',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            BusyButton(label: _isEdit ? 'Save changes' : 'Save', accent: true, onPressed: () => _save(s, currency)),
          ],
        ),
      ),
    );
  }
}
