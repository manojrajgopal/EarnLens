import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/income_source.dart';
import '../../../domain/money/currency.dart';
import '../../../domain/money/fraction.dart';
import '../../../domain/money/money_parser.dart';
import '../../../domain/services/validators.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../income_sources/presentation/widgets/income_common.dart';

/// Adds a pay revision (hike, decrease, correction, estimate update) or
/// corrects an existing one. Past months before the effective date are
/// never changed by a new revision.
class RevisionFormScreen extends ConsumerStatefulWidget {
  const RevisionFormScreen({super.key, required this.sourceId, this.revisionId});

  final String sourceId;
  final String? revisionId;

  @override
  ConsumerState<RevisionFormScreen> createState() => _RevisionFormScreenState();
}

class _RevisionFormScreenState extends ConsumerState<RevisionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _percent = TextEditingController();
  final _note = TextEditingController();

  bool _ready = false;
  RateRevision? _existing;
  late LocalDate _effective;
  RevisionChangeType _type = RevisionChangeType.hike;
  RatePeriod? _period;

  bool get _isEdit => widget.revisionId != null;

  @override
  void dispose() {
    _amount.dispose();
    _percent.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Revisions of this source (oldest first), excluding the one being edited.
  List<RateRevision> _others() {
    final rules = ref.read(snapshotProvider).rules[widget.sourceId];
    return [
      for (final r in rules?.revisions ?? const <RateRevision>[])
        if (r.id != widget.revisionId) r,
    ];
  }

  /// Revision in force the day before the effective date.
  RateRevision? _previous() {
    final dayBefore = _effective.addDays(-1);
    RateRevision? current;
    for (final r in _others()) {
      if (r.effectiveFrom.isAfter(dayBefore)) break;
      current = r;
    }
    return current;
  }

  List<RatePeriod> _periodChoices(IncomeSource s) => switch (s.kind) {
    IncomeKind.salary => const [RatePeriod.month, RatePeriod.year],
    IncomeKind.variable => const [RatePeriod.month],
    IncomeKind.temporary =>
      s.accrualPolicy == AccrualPolicy.workingDay ? const [RatePeriod.hour, RatePeriod.day] : const [RatePeriod.day],
    _ => const [RatePeriod.day, RatePeriod.week, RatePeriod.month, RatePeriod.year],
  };

  List<RevisionChangeType> _typeChoices(IncomeSource s) {
    if (_existing?.changeType == RevisionChangeType.initial) return const [RevisionChangeType.initial];
    return s.kind == IncomeKind.variable
        ? const [RevisionChangeType.estimateUpdate, RevisionChangeType.correction]
        : const [RevisionChangeType.hike, RevisionChangeType.decrease, RevisionChangeType.correction];
  }

  void _init(IncomeSource s, Currency currency) {
    final today = currentDate(ref);
    if (_isEdit) {
      final rules = ref.read(snapshotProvider).rules[s.id];
      final rev = rules?.revisions.where((r) => r.id == widget.revisionId).firstOrNull;
      if (rev == null) return;
      _existing = rev;
      _effective = rev.effectiveFrom;
      _type = rev.changeType;
      _period = rev.period;
      _amount.text = MoneyParser.toInput(rev.amountMinor, currency);
      if (rev.percentBps != null) _percent.text = formatBps(rev.percentBps!);
      _note.text = rev.note ?? '';
    } else {
      _effective = today.addDays(1 - today.day); // first of this month
      _type = s.kind == IncomeKind.variable ? RevisionChangeType.estimateUpdate : RevisionChangeType.hike;
      _period = _previous()?.period ?? _periodChoices(s).last;
    }
    if (!_periodChoices(s).contains(_period) && _existing == null) _period = _periodChoices(s).first;
    _ready = true;
  }

  bool get _comparable {
    final prev = _previous();
    return prev != null && prev.period == _period && prev.amountMinor > 0;
  }

  void _onAmountChanged(String text, Currency currency) {
    final prev = _previous();
    final minor = MoneyParser.parseMinor(text, currency);
    if (!_comparable || minor == null) {
      setState(() {});
      return;
    }
    final bps = Fraction.fromInt(minor - prev!.amountMinor).timesInt(10000).divInt(prev.amountMinor).roundToInt();
    setState(() => _percent.text = formatBps(bps));
  }

  void _onPercentChanged(String text, Currency currency) {
    final prev = _previous();
    final bps = MoneyParser.parsePercentBps(text);
    if (!_comparable || bps == null) {
      setState(() {});
      return;
    }
    final minor = prev!.amountMinor + Fraction.fromInt(prev.amountMinor).timesInt(bps).divInt(10000).roundToInt();
    if (minor < 0) return;
    setState(() => _amount.text = MoneyParser.toInput(minor, currency));
  }

  Future<void> _save(IncomeSource s, Currency currency) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = parseMoney(_amount, currency);
    if (amount == null) return;
    final prev = _previous();
    final clock = ref.read(clockProvider);

    int? bps;
    if (prev != null && prev.period == _period && prev.amountMinor > 0) {
      bps = Fraction.fromInt(amount - prev.amountMinor).timesInt(10000).divInt(prev.amountMinor).roundToInt();
    }

    if (prev != null && prev.period == _period) {
      if (_type == RevisionChangeType.hike && amount <= prev.amountMinor) {
        showMessage(context, 'A hike should be higher than the previous amount. Choose "Decrease" or "Correction".');
        return;
      }
      if (_type == RevisionChangeType.decrease && amount >= prev.amountMinor) {
        showMessage(context, 'A decrease should be lower than the previous amount. Choose "Hike" or "Correction".');
        return;
      }
    }

    final revision = RateRevision(
      id: _existing?.id ?? ref.read(idProvider).newId(),
      sourceId: s.id,
      effectiveFrom: _effective,
      amountMinor: amount,
      period: _period!,
      changeType: _type,
      percentBps: bps,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      createdAt: _existing?.createdAt ?? clock.now(),
    );
    try {
      Validators.revision(revision, s);
    } on ValidationException catch (e) {
      showMessage(context, e.message);
      return;
    }
    final repo = ref.read(incomeRepositoryProvider);
    final ok = await runGuarded(
      context,
      () => _isEdit ? repo.updateRevision(revision) : repo.addRevision(revision),
      success: _isEdit ? 'Rate corrected' : 'Revision added',
    );
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(sourceProvider(widget.sourceId));
    if (source == null) return const MissingSourceScaffold(title: 'Pay revision');
    final s = source;
    final currency = Currency.byCode(s.currencyCode);
    if (!_ready) _init(s, currency);
    if (!_ready) {
      return Scaffold(
        appBar: AppBar(title: const Text('Correct rate')),
        body: const Center(
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Rate not found',
            message: 'This rate no longer exists. It may have been removed.',
          ),
        ),
      );
    }

    final c = context.colors;
    final fmt = moneyFormatterFor(ref, s.currencyCode);
    final prev = _previous();
    final variable = s.kind == IncomeKind.variable;
    final title = _isEdit
        ? 'Correct rate'
        : switch (s.kind) {
            IncomeKind.salary => 'Salary revision',
            IncomeKind.variable => 'Update estimate',
            _ => 'Rate change',
          };
    final periods = _periodChoices(s);
    final types = _typeChoices(s);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: PageList(
          children: [
            SourceContextChip(source: s),
            const SizedBox(height: AppSpace.lg),
            EarnCard(
              tint: c.accentSoft,
              elevated: false,
              child: Row(
                children: [
                  IconBadge(Icons.history_rounded, color: c.accentText, size: 44),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Previous ${variable ? 'estimate' : 'rate'}',
                          style: AppType.caption.copyWith(color: c.inkMuted),
                        ),
                        const SizedBox(height: 4),
                        if (prev == null)
                          Text(
                            _existing?.changeType == RevisionChangeType.initial
                                ? 'This is the starting rate'
                                : 'None before this date',
                            style: AppType.section.copyWith(fontWeight: FontWeight.w700),
                          )
                        else ...[
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: AmountText(
                              '${fmt.minor(prev.amountMinor)} ${prev.period.label}',
                              style: AppType.amountMedium,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'In force since ${formatDate(prev.effectiveFrom)}',
                            style: AppType.bodySmall.copyWith(color: c.inkMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            FormSection(
              title: 'Change',
              subtitle: variable ? 'Your new monthly estimate' : 'What changed and from when',
              icon: Icons.trending_up_rounded,
              color: AppColors.mint,
              children: [
                if (types.length > 1) ...[
                  ChoicePills<RevisionChangeType>(
                    values: types,
                    selected: _type,
                    label: (t) => t.label,
                    onSelected: (t) => setState(() => _type = t),
                  ),
                  vGap,
                ] else ...[
                  Align(alignment: Alignment.centerLeft, child: Pill(types.first.label)),
                  vGap,
                ],
                DateField(
                  label: 'Effective from',
                  initial: _effective,
                  helper: 'The first day the new amount applies.',
                  onChanged: (d) {
                    if (d == null) return;
                    setState(() => _effective = d);
                    _onAmountChanged(_amount.text, currency);
                  },
                  validator: (d) =>
                      d != null && d.isBefore(s.startDate) && _existing?.changeType != RevisionChangeType.initial
                      ? 'This is before the income started (${formatDate(s.startDate)})'
                      : null,
                ),
                vGap,
                MoneyField(
                  controller: _amount,
                  currency: currency,
                  label: variable ? 'New monthly estimate' : 'New amount',
                  onChanged: (v) => _onAmountChanged(v, currency),
                ),
                if (periods.length > 1) ...[
                  vGapSmall,
                  ChoicePills<RatePeriod>(
                    values: periods,
                    selected: _period!,
                    label: (p) => p.label,
                    onSelected: (p) => setState(() {
                      _period = p;
                      if (!_comparable) _percent.clear();
                    }),
                  ),
                ],
                vGap,
                TextFormField(
                  controller: _percent,
                  enabled: _comparable,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
                  decoration: InputDecoration(
                    labelText: 'Or change by percentage',
                    suffixText: '%',
                    helperText: _comparable
                        ? 'Type either the amount or the percentage — the other is worked out for you.'
                        : 'Percentage is available when the period matches the previous rate.',
                    helperMaxLines: 2,
                  ),
                  onChanged: (v) => _onPercentChanged(v, currency),
                  validator: (v) {
                    if (!_comparable || (v ?? '').trim().isEmpty) return null;
                    return MoneyParser.parsePercentBps(v!) == null ? 'Use up to two decimals, e.g. 12.5' : null;
                  },
                ),
              ],
            ),
            ExpandableCard(
              title: 'Note',
              subtitle: 'Optional — e.g. why your pay changed',
              icon: Icons.sticky_note_2_outlined,
              color: AppColors.peach,
              initiallyExpanded: _note.text.isNotEmpty,
              children: [
                TextFormField(
                  controller: _note,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'e.g. Annual appraisal'),
                ),
              ],
            ),
            vGap,
            InfoBanner(
              _isEdit
                  ? 'Correcting a rate changes the earnings calculated from ${formatDate(_effective)} until the next '
                        'change. The correction is recorded in history.'
                  : 'Months before ${formatDate(_effective)} stay exactly as they are. If this change applies to months '
                        'that were already paid (arrears), record the difference as an adjustment from the income page.',
            ),
            const SizedBox(height: AppSpace.xl),
            BusyButton(
              label: _isEdit ? 'Save correction' : 'Add revision',
              accent: true,
              onPressed: () => _save(s, currency),
            ),
          ],
        ),
      ),
    );
  }
}
