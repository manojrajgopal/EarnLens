import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/income_source.dart';
import '../../../domain/models/records.dart';
import '../../../domain/money/currency.dart';
import '../../../domain/money/money_parser.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/organic.dart';
import '../../income_sources/presentation/widgets/income_common.dart';
import '../../refresh/application/app_refresher.dart';

/// Estimate vs actual for one month of a variable income source.
class MonthRecordScreen extends ConsumerStatefulWidget {
  const MonthRecordScreen({super.key, required this.sourceId, required this.month});

  final String sourceId;
  final YearMonth month;

  @override
  ConsumerState<MonthRecordScreen> createState() => _MonthRecordScreenState();
}

class _MonthRecordScreenState extends ConsumerState<MonthRecordScreen> {
  final _estimateKey = GlobalKey<FormState>();
  final _actualKey = GlobalKey<FormState>();
  final _estimate = TextEditingController();
  final _actual = TextEditingController();
  final _notes = TextEditingController();
  bool _ready = false;

  @override
  void dispose() {
    _estimate.dispose();
    _actual.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _init(MonthlyRecord? rec, Currency currency) {
    final est = rec?.baselineEstimateMinor;
    if (est != null) _estimate.text = MoneyParser.toInput(est, currency);
    if (rec?.actualMinor != null) _actual.text = MoneyParser.toInput(rec!.actualMinor!, currency);
    _notes.text = rec?.notes ?? '';
    _ready = true;
  }

  MonthlyRecord _base(MonthlyRecord? rec) => MonthlyRecord(
    id: rec?.id ?? ref.read(idProvider).newId(),
    sourceId: widget.sourceId,
    month: widget.month,
    updatedAt: ref.read(clockProvider).now(),
    actualMinor: rec?.actualMinor,
    notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
  );

  Future<void> _saveEstimate(MonthlyRecord? rec, Currency currency) async {
    if (!(_estimateKey.currentState?.validate() ?? false)) return;
    final desired = parseMoney(_estimate, currency);
    final base = _base(rec);
    // The repository keeps the first estimate as the original and stores
    // later changes as the revised estimate.
    final record = MonthlyRecord(
      id: base.id,
      sourceId: base.sourceId,
      month: base.month,
      updatedAt: base.updatedAt,
      revisedEstimateMinor: desired,
      actualMinor: base.actualMinor,
      notes: base.notes,
    );
    await runGuarded(
      context,
      () => ref.read(recordsRepositoryProvider).saveMonthlyRecord(record),
      success: 'Estimate saved',
    );
  }

  Future<void> _saveActual(MonthlyRecord? rec, Currency currency) async {
    if (!(_actualKey.currentState?.validate() ?? false)) return;
    final actual = parseMoney(_actual, currency);
    if (actual == null && rec?.actualMinor != null) {
      final ok = await confirmDialog(
        context,
        title: 'Remove the monthly total?',
        message: 'This month will go back to adding up your detailed earned entries.',
        confirm: 'Remove total',
      );
      if (!ok || !mounted) return;
    }
    final base = _base(rec);
    final record = MonthlyRecord(
      id: base.id,
      sourceId: base.sourceId,
      month: base.month,
      updatedAt: base.updatedAt,
      actualMinor: actual,
      notes: base.notes,
    );
    await runGuarded(
      context,
      () => ref.read(recordsRepositoryProvider).saveMonthlyRecord(record),
      success: actual == null ? 'Monthly total removed' : 'Actual saved',
    );
  }

  Future<void> _finalize(
    MonthlyRecord? rec,
    int? effectiveActual,
    Currency currency,
    String Function(int) money,
  ) async {
    final typed = parseMoney(_actual, currency);
    final amount = typed ?? effectiveActual;
    if (amount == null) {
      showMessage(context, 'Enter the actual amount or add earned entries before finalising.');
      return;
    }
    final ok = await confirmDialog(
      context,
      title: 'Finalise ${formatMonth(widget.month)}?',
      message:
          'The actual will be locked at ${money(amount)}. You can reopen the month later if you need to change it.',
      confirm: 'Finalise',
    );
    if (!ok || !mounted) return;
    final done = await runGuarded(
      context,
      () => ref.read(recordsRepositoryProvider).finalizeMonth(widget.sourceId, widget.month, amount),
      success: 'Month finalised',
    );
    if (done) _actual.text = MoneyParser.toInput(amount, currency);
  }

  Future<void> _reopen() async {
    final reason = await showDialog<String>(context: context, builder: (_) => const _ReasonDialog());
    if (reason == null || !mounted) return;
    await runGuarded(
      context,
      () => ref.read(recordsRepositoryProvider).reopenMonth(widget.sourceId, widget.month, reason),
      success: 'Month reopened',
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(sourceProvider(widget.sourceId));
    if (source == null) return const MissingSourceScaffold(title: 'Month');
    final IncomeSource s = source;
    final currency = Currency.byCode(s.currencyCode);
    final snap = ref.watch(snapshotProvider);
    final rec = snap.record(s.id, widget.month);
    if (!_ready) _init(rec, currency);

    final c = context.colors;
    final fmt = moneyFormatterFor(ref, s.currencyCode);
    final today = currentDate(ref);
    final m = widget.month;
    final finalized = rec?.finalized ?? false;
    final isFuture = m.isAfter(today.yearMonth);
    final expected = snap.variableExpected(s.id, m);
    final defaultEstimate = snap.defaultEstimate(s.id, m.firstDay);
    final actual = snap.variableActual(s.id, m);
    final entries =
        snap.ledger.where((e) => e.sourceId == s.id && e.type == LedgerType.earned && m.contains(e.date)).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final entriesTotal = snap.earnedEntries(s.id, DateRange.month(m));
    final countedEntries = entries.where((e) => e.status.counts).length;
    final totalReplacesEntries = rec?.actualMinor != null && entries.isNotEmpty;

    const fg = AppColors.white;
    final muted = fg.withValues(alpha: 0.75);
    final progress = expected != null && expected > 0 && actual != null ? (actual / expected).clamp(0.0, 1.0) : null;

    return Scaffold(
      appBar: AppBar(title: Text(formatMonth(m))),
      body: PageList(
        onRefresh: () => ref.read(appRefresherProvider).refresh({RefreshScope.earnings, RefreshScope.audit}),
        children: [
          SourceContextChip(source: s),
          const SizedBox(height: AppSpace.lg),
          EntranceScale(
            child: HeroSurface(
              night: true,
              seed: 7,
              semanticLabel: '${formatMonth(m)} summary',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Actual earnings', style: AppType.label.copyWith(color: fg.withValues(alpha: 0.9))),
                      ),
                      if (finalized)
                        const HeroChip(icon: Icons.lock_outline_rounded, child: Text('Finalised'))
                      else if (isFuture)
                        const HeroChip(icon: Icons.schedule_rounded, child: Text('Upcoming')),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  if (actual == null)
                    Text('Not recorded yet', style: AppType.amountMedium.copyWith(color: fg))
                  else
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AmountText(
                        fmt.minor(actual),
                        style: AppType.amountHero.copyWith(
                          color: fg,
                          fontSize: 42,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  if (progress != null) ...[
                    const SizedBox(height: AppSpace.lg),
                    GradientProgress(value: progress, height: 8, onDark: true, semanticsLabel: 'Actual vs expected'),
                    const SizedBox(height: 6),
                    Text(
                      '${(actual! / expected! * 100).round()}% of expected',
                      style: AppType.caption.copyWith(color: muted),
                    ),
                  ],
                  const SizedBox(height: AppSpace.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroMetric(label: 'Expected', value: expected == null ? '—' : fmt.minor(expected)),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: _HeroMetric(
                          label: 'Difference',
                          value: expected == null || actual == null ? '—' : fmt.signed(actual - expected),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroMetric(
                          label: 'Original estimate',
                          value: rec?.originalEstimateMinor == null ? '—' : fmt.minor(rec!.originalEstimateMinor!),
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: _HeroMetric(
                          label: 'Revised estimate',
                          value: rec?.revisedEstimateMinor == null ? '—' : fmt.minor(rec!.revisedEstimateMinor!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          FormSection(
            title: 'Estimate',
            subtitle: 'What you planned for this month',
            icon: Icons.flag_outlined,
            color: AppColors.sky,
            topGap: AppSpace.xl,
            trailing: const InfoTip(
              title: 'Original and revised estimate',
              message:
                  'Your first estimate for the month is kept as the original. If you change it later, the new '
                  'figure is saved as the revised estimate, so you can always compare what you planned at the start.',
            ),
            children: [
              AmountRow(
                label: 'Original estimate',
                value: rec?.originalEstimateMinor == null ? '—' : fmt.minor(rec!.originalEstimateMinor!),
              ),
              AmountRow(
                label: 'Revised estimate',
                value: rec?.revisedEstimateMinor == null ? '—' : fmt.minor(rec!.revisedEstimateMinor!),
              ),
              if (rec?.baselineEstimateMinor == null && defaultEstimate != null)
                AmountRow(
                  label: 'Default monthly estimate',
                  value: fmt.minor(defaultEstimate),
                  caption: 'Used until you set an estimate for this month',
                ),
              vGap,
              Form(
                key: _estimateKey,
                child: MoneyField(
                  controller: _estimate,
                  currency: currency,
                  label: 'Estimate for this month',
                  allowZero: true,
                ),
              ),
              vGapSmall,
              OutlinedButton(onPressed: () => _saveEstimate(rec, currency), child: const Text('Save estimate')),
            ],
          ),
          FormSection(
            title: 'Actual',
            subtitle: 'Entries or one monthly total',
            icon: Icons.verified_outlined,
            color: AppColors.mint,
            trailing: const InfoTip(
              title: 'Monthly total vs entries',
              message:
                  'You can track a month in two ways: add individual earned entries (invoices, sales), or type '
                  'one total for the month. If you enter a total, it replaces the entries — they are never added on '
                  'top, so nothing is counted twice.',
            ),
            children: [
              AmountRow(
                label: 'Earned entries',
                value: fmt.minor(entriesTotal),
                caption: countedEntries == 1 ? '1 counted entry' : '$countedEntries counted entries',
              ),
              AmountRow(
                label: 'Recorded monthly total',
                value: rec?.actualMinor == null ? '—' : fmt.minor(rec!.actualMinor!),
              ),
              if (totalReplacesEntries) ...[
                vGapSmall,
                const InfoBanner(
                  'A monthly total is recorded, so it replaces the detailed entries below. They are kept for reference '
                  'only and are not added on top.',
                  tone: BannerTone.warning,
                  icon: Icons.info_outline_rounded,
                ),
              ],
              vGap,
              Form(
                key: _actualKey,
                child: MoneyField(
                  key: ValueKey('actual-$finalized'),
                  controller: _actual,
                  currency: currency,
                  label: 'Monthly total (optional)',
                  helper: finalized
                      ? 'This month is finalised. Reopen it to change the actual.'
                      : 'Leave empty to use the sum of your earned entries.',
                  required: false,
                  allowZero: true,
                ),
              ),
              vGap,
              TextField(
                controller: _notes,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Notes for this month (optional)'),
              ),
              vGapSmall,
              OutlinedButton(
                onPressed: finalized ? null : () => _saveActual(rec, currency),
                child: const Text('Save actual'),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          if (finalized) ...[
            if (rec?.finalizedAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: Text(
                  'Finalised on ${formatDateTime(rec!.finalizedAt!)}',
                  style: AppType.bodySmall.copyWith(color: c.inkMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            OutlinedButton.icon(
              onPressed: _reopen,
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('Reopen month'),
            ),
          ] else
            BusyButton(
              label: 'Finalise month',
              accent: true,
              onPressed: isFuture ? null : () => _finalize(rec, actual, currency, fmt.minor),
            ),
          if (isFuture && !finalized)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.sm),
              child: Text(
                'You can finalise once the month has started.',
                style: AppType.bodySmall.copyWith(color: c.inkMuted),
                textAlign: TextAlign.center,
              ),
            ),
          SectionHeader(
            'Earned entries',
            action: 'Add',
            onAction: () => context.push('/income/${s.id}/entry?type=earned&period=${m.toIso()}'),
            padding: const EdgeInsets.fromLTRB(4, AppSpace.xl, 0, AppSpace.sm),
          ),
          if (entries.isEmpty)
            const InfoBanner('No detailed entries this month. Add invoices or sales as you earn them.')
          else
            SectionCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              children: [
                for (final e in entries)
                  ListTile(
                    minVerticalPadding: AppSpace.md,
                    leading: IconBadge(
                      Icons.add_chart_rounded,
                      color: e.status.counts && !totalReplacesEntries ? c.accentText : c.inkMuted,
                    ),
                    title: Text(
                      e.notes?.isNotEmpty == true ? e.notes! : e.type.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.label.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${formatDate(e.date)}${e.status == LedgerStatus.completed ? '' : ' · ${e.status.label}'}',
                      style: AppType.bodySmall.copyWith(color: c.inkMuted),
                    ),
                    trailing: AmountText(
                      fmt.minor(e.amountMinor),
                      style: AppType.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: e.status.counts && !totalReplacesEntries ? null : c.inkMuted,
                      ),
                    ),
                    onTap: () => context.push('/income/${s.id}/entry?entry=${e.id}'),
                  ),
              ],
            ),
          if (rec != null)
            ExpandableCard(
              title: 'History of this month',
              subtitle: 'Estimates, totals and finalising',
              icon: Icons.history_rounded,
              children: [AuditHistoryList(entityId: rec.id)],
            ),
        ],
      ),
    );
  }
}

/// Label and amount on the night summary card.
class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppType.caption.copyWith(color: AppColors.white.withValues(alpha: 0.75)),
      ),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: AmountText(value, style: AppType.amountMedium.copyWith(color: AppColors.white, fontSize: 20)),
      ),
    ],
  );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog();

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Reopen this month?'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('You will be able to change the actual again. The reason is saved in the history.', style: AppType.body),
        vGap,
        TextField(
          controller: _reason,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Reason', hintText: 'e.g. Late invoice paid'),
        ),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.pop(context, _reason.text.trim()), child: const Text('Reopen')),
    ],
  );
}
