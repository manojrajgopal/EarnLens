import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/errors/app_exception.dart';
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

/// Create or edit a bonus, benefit, allowance, reimbursement or one-time
/// payment linked to an income source.
class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({super.key, required this.sourceId, this.itemId});

  final String sourceId;
  final String? itemId;

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _expected = TextEditingController();
  final _actual = TextEditingController();
  final _taxNote = TextEditingController();
  final _notes = TextEditingController();

  bool _ready = false;
  CompensationItem? _existing;
  CompensationType _type = CompensationType.annualBonus;
  LocalDate? _expectedDate;
  LocalDate? _earnedDate;
  Recurrence _recurrence = Recurrence.none;
  bool _nonCash = false;
  bool _countsAsEarnings = true;
  bool _includeInForecast = true;

  bool get _isEdit => widget.itemId != null;

  @override
  void dispose() {
    for (final c in [_title, _expected, _actual, _taxNote, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Returns false when the item id does not resolve.
  bool _init(IncomeSource s, Currency currency) {
    if (_isEdit) {
      final item = ref.read(snapshotProvider).items.where((i) => i.id == widget.itemId).firstOrNull;
      if (item == null) return false;
      _existing = item;
      _type = item.type;
      _title.text = item.title;
      if (item.expectedMinor != null) _expected.text = MoneyParser.toInput(item.expectedMinor!, currency);
      if (item.actualMinor != null) _actual.text = MoneyParser.toInput(item.actualMinor!, currency);
      _expectedDate = item.expectedDate;
      _earnedDate = item.earnedDate;
      _recurrence = item.recurrence;
      _nonCash = item.nonCash;
      _countsAsEarnings = item.countsAsEarnings;
      _includeInForecast = item.includeInForecast;
      _taxNote.text = item.taxNote ?? '';
      _notes.text = item.notes ?? '';
    } else {
      _type = s.kind == IncomeKind.oneTime ? CompensationType.oneTimeIncome : CompensationType.annualBonus;
    }
    _ready = true;
    return true;
  }

  void _onTypeChanged(CompensationType t) {
    setState(() {
      _type = t;
      if (_isEdit) return;
      // Sensible defaults: benefits are usually non-cash, reimbursements are not earnings.
      _nonCash = t == CompensationType.benefit;
      _countsAsEarnings = t != CompensationType.reimbursement;
      if (t == CompensationType.recurringBonus || t == CompensationType.allowance) {
        if (_recurrence == Recurrence.none) _recurrence = Recurrence.monthly;
      }
    });
  }

  Future<void> _save(IncomeSource s, Currency currency) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = ref.read(clockProvider).now();
    final item = CompensationItem(
      id: _existing?.id ?? ref.read(idProvider).newId(),
      sourceId: s.id,
      type: _type,
      title: _title.text.trim(),
      currencyCode: _existing?.currencyCode ?? s.currencyCode,
      expectedMinor: parseMoney(_expected, currency),
      expectedDate: _expectedDate,
      actualMinor: parseMoney(_actual, currency),
      earnedDate: _earnedDate,
      recurrence: _recurrence,
      nonCash: _nonCash,
      countsAsEarnings: _countsAsEarnings,
      includeInForecast: _includeInForecast,
      taxNote: _taxNote.text.trim().isEmpty ? null : _taxNote.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      cancelled: _existing?.cancelled ?? false,
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      Validators.item(item);
    } on ValidationException catch (e) {
      showMessage(context, e.message);
      return;
    }
    final ok = await runGuarded(
      context,
      () => ref.read(recordsRepositoryProvider).saveItem(item),
      success: _isEdit ? 'Saved' : 'Added',
    );
    if (ok && mounted) context.pop();
  }

  Future<void> _cancelItem() async {
    final item = _existing;
    if (item == null) return;
    final ok = await confirmDialog(
      context,
      title: 'Cancel "${item.title}"?',
      message: 'It will no longer count as expected or earned. Payments already recorded stay in your history.',
      confirm: 'Cancel item',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await runGuarded(
      context,
      () => ref.read(recordsRepositoryProvider).cancelItem(item.id),
      success: 'Item cancelled',
    );
    if (done && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(sourceProvider(widget.sourceId));
    if (source == null) return const MissingSourceScaffold(title: 'Bonus or benefit');
    final s = source;
    final currency = Currency.byCode(_existing?.currencyCode ?? s.currencyCode);
    if (!_ready && !_init(s, currency)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bonus or benefit')),
        body: const Center(
          child: EmptyState(icon: Icons.search_off_rounded, title: 'Not found', message: 'This item no longer exists.'),
        ),
      );
    }
    final cancelled = _existing?.cancelled ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit ${_type.label.toLowerCase()}' : 'Add bonus or benefit'),
        actions: [
          if (_isEdit && !cancelled)
            IconButton(tooltip: 'Cancel this item', icon: const Icon(Icons.cancel_outlined), onPressed: _cancelItem),
          const SizedBox(width: AppSpace.sm),
        ],
      ),
      body: Form(
        key: _formKey,
        child: PageList(
          children: [
            SourceContextChip(source: s),
            if (cancelled) ...[
              vGap,
              const InfoBanner(
                'This item was cancelled. It does not count in any totals.',
                tone: BannerTone.warning,
                icon: Icons.cancel_outlined,
              ),
            ],
            FormSection(
              title: 'What is it?',
              icon: Icons.redeem_rounded,
              children: [
                SelectField<CompensationType>(
                  label: 'Type',
                  value: _type,
                  values: CompensationType.values,
                  itemLabel: (t) => t.label,
                  onChanged: _onTypeChanged,
                ),
                vGap,
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Annual bonus 2026'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a title' : null,
                ),
              ],
            ),
            FormSection(
              title: 'Expected',
              subtitle: 'What you have been promised',
              icon: Icons.flag_outlined,
              color: AppColors.sky,
              children: [
                MoneyField(
                  controller: _expected,
                  currency: currency,
                  label: 'Expected amount',
                  helper: 'What you have been promised or expect. Leave empty if you only know the actual amount.',
                  required: false,
                ),
                vGap,
                DateField(
                  label: 'Expected date',
                  initial: _expectedDate,
                  optional: true,
                  onChanged: (d) => setState(() => _expectedDate = d),
                  validator: (d) => d == null && _expected.text.trim().isNotEmpty && _earnedDate == null
                      ? 'Pick when you expect it'
                      : null,
                ),
              ],
            ),
            FormSection(
              title: 'Actual',
              subtitle: 'Once it is confirmed',
              icon: Icons.verified_outlined,
              color: AppColors.mint,
              children: [
                MoneyField(
                  controller: _actual,
                  currency: currency,
                  label: 'Actual amount',
                  helper: 'Fill in once it is confirmed. This is what counts as earned.',
                  required: false,
                ),
                vGap,
                DateField(
                  label: 'Earned date',
                  initial: _earnedDate,
                  optional: true,
                  helper: 'The day it was earned (not necessarily the day it was paid).',
                  onChanged: (d) => setState(() => _earnedDate = d),
                  validator: (d) => d == null && _actual.text.trim().isNotEmpty ? 'When was it earned?' : null,
                ),
              ],
            ),
            FormSection(
              title: 'Options',
              icon: Icons.tune_rounded,
              color: AppColors.orchid,
              children: [
                SelectField<Recurrence>(
                  key: ValueKey(_recurrence),
                  label: 'Repeats',
                  value: _recurrence,
                  values: Recurrence.values,
                  itemLabel: (r) => r.label,
                  onChanged: (r) => setState(() => _recurrence = r),
                ),
                vGap,
                ToggleTile(
                  title: 'Non-cash benefit',
                  subtitle: 'Insurance, meal cards, vouchers and similar. Never counted as cash received.',
                  value: _nonCash,
                  onChanged: (v) => setState(() => _nonCash = v),
                ),
                vGapSmall,
                ToggleTile(
                  title: 'Counts as earnings',
                  subtitle: 'Turn off for reimbursements that only pay back money you spent.',
                  value: _countsAsEarnings,
                  onChanged: (v) => setState(() => _countsAsEarnings = v),
                ),
                vGapSmall,
                ToggleTile(
                  title: 'Include in forecasts',
                  subtitle: 'Turn off if it is uncertain and you prefer conservative projections.',
                  value: _includeInForecast,
                  onChanged: (v) => setState(() => _includeInForecast = v),
                ),
              ],
            ),
            ExpandableCard(
              title: 'Notes',
              subtitle: 'Tax note and personal notes (optional)',
              icon: Icons.sticky_note_2_outlined,
              color: AppColors.peach,
              initiallyExpanded: _taxNote.text.isNotEmpty || _notes.text.isNotEmpty,
              children: [
                TextFormField(
                  controller: _taxNote,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Tax note (optional)',
                    hintText: 'e.g. Taxable as perquisite',
                  ),
                ),
                vGap,
                TextFormField(
                  controller: _notes,
                  maxLines: 3,
                  minLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
              ],
            ),
            vGap,
            const InfoBanner(
              'Saving this does not record a payment. When the money arrives, use "Mark received" '
              'under Expected payments on the income page.',
            ),
            const SizedBox(height: AppSpace.xl),
            BusyButton(
              label: _isEdit ? 'Save changes' : 'Add',
              accent: true,
              onPressed: cancelled ? null : () => _save(s, currency),
            ),
          ],
        ),
      ),
    );
  }
}
