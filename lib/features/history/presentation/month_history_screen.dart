import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/calculation/earnings_calculator.dart';
import '../../../domain/models/enums.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/income_visuals.dart';
import '../../../shared/widgets/organic.dart';
import '../../analytics/presentation/analytics_widgets.dart';
import '../../refresh/application/app_refresher.dart';
import '../application/month_history_data.dart';
import 'month_picker.dart';

class MonthHistoryScreen extends ConsumerStatefulWidget {
  const MonthHistoryScreen({super.key, required this.month});
  final YearMonth month;

  @override
  ConsumerState<MonthHistoryScreen> createState() => _MonthHistoryScreenState();
}

class _MonthHistoryScreenState extends ConsumerState<MonthHistoryScreen> {
  // Selected month and custom range live in widget state, so they survive
  // pull-to-refresh.
  late YearMonth _month = widget.month;
  DateRange? _custom;

  @override
  void didUpdateWidget(MonthHistoryScreen old) {
    super.didUpdateWidget(old);
    if (old.month != widget.month) _month = widget.month;
  }

  Future<void> _refresh() => ref.read(appRefresherProvider).refresh({RefreshScope.earnings});

  Future<void> _pickMonth() async {
    final picked = await showMonthPicker(context, initial: _month);
    if (picked != null && mounted) setState(() => _month = picked);
  }

  Future<void> _pickCustomRange() async {
    final today = ref.read(todayProvider);
    final initial = _custom ?? DateRange.month(_month);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: today.addMonths(60).toDateTime(),
      currentDate: today.toDateTime(),
      initialDateRange: DateTimeRange(
        start: initial.start.toDateTime(),
        end: initial.endExclusive.addDays(-1).toDateTime(),
      ),
      helpText: 'Choose dates to summarise',
    );
    if (picked == null || !mounted) return;
    setState(() => _custom = DateRange(
          LocalDate.fromDateTime(picked.start),
          LocalDate.fromDateTime(picked.end).addDays(1),
        ));
  }

  Future<void> _recordMissed(MonthHistoryData d) async {
    final s = await pickSource(context, d.sources, title: 'Record missed income for…');
    if (s == null || !mounted) return;
    final type = s.kind == IncomeKind.variable || s.kind == IncomeKind.oneTime ? 'earned' : 'adjustment';
    context.push('/income/${s.id}/entry?type=$type&period=${_month.toIso()}');
  }

  Future<void> _recordPayment(MonthHistoryData d) async {
    final s = await pickSource(context, d.sources, title: 'Record a payment from…');
    if (s == null || !mounted) return;
    context.push('/income/${s.id}/entry?type=received&period=${_month.toIso()}');
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(monthHistoryProvider(_month));
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Month history')),
      body: AnalyticsBody(onRefresh: _refresh, children: [
        MonthNavPill(
          label: formatMonth(_month),
          semanticLabel: 'Showing ${formatMonth(_month)}. Choose another month',
          onPrevious: () => setState(() => _month = _month.previous),
          onNext: () => setState(() => _month = _month.next),
          onPick: _pickMonth,
        ),
        const SizedBox(height: AppSpace.xl - 4),
        if (d.sources.isEmpty)
          EarnCard(
            child: EmptyState(
              icon: Icons.calendar_view_month_rounded,
              title: 'Nothing to show yet',
              message: 'Add an income source to see what each month earned.',
              action: 'Add income',
              onAction: () => context.go('/income'),
            ),
          )
        else ...[
          if (d.isFuture) ...[
            EarnCard(
              tint: c.accentSoft,
              elevated: false,
              radius: AppRadius.md,
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Row(children: [
                Icon(Icons.update_rounded, color: c.accentText),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text('This month is in the future: figures show what is expected, nothing is earned yet.',
                      style: AppType.bodySmall.copyWith(color: c.ink)),
                ),
              ]),
            ),
            const SizedBox(height: AppSpace.lg),
          ],
          CardGrid(children: [
            EntranceScale(child: _SummaryCard(data: d)),
            EntranceScale(delay: const Duration(milliseconds: 60), child: _SourcesSection(data: d)),
            EntranceScale(delay: const Duration(milliseconds: 120), child: _YearToDateCard(data: d)),
            EntranceScale(
              delay: const Duration(milliseconds: 180),
              child: _CustomRangeCard(range: _custom, onPick: _pickCustomRange, onClear: () => setState(() => _custom = null)),
            ),
          ]),
          const SizedBox(height: AppSpace.xl),
          _Actions(onMissed: () => _recordMissed(d), onPayment: () => _recordPayment(d)),
        ],
      ]),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onMissed, required this.onPayment});
  final VoidCallback onMissed;
  final VoidCallback onPayment;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget tile(int i, IconData icon, String label, VoidCallback onTap) {
      final (bg, fg) = pastelAt(context, i);
      return OrganicTile(
        seed: i + 31,
        color: bg,
        onTap: onTap,
        semanticLabel: label,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconBadge(icon, color: AppColors.white, background: fg, size: 40),
            const SizedBox(height: AppSpace.md),
            Text(label, style: AppType.label.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: tile(0, Icons.add_circle_outline_rounded, 'Record missed income', onMissed)),
          const SizedBox(width: AppSpace.md),
          Expanded(child: tile(3, Icons.payments_outlined, 'Record a payment', onPayment)),
        ]),
      ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.data});
  final MonthHistoryData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatterProvider);
    final s = data.summary;
    final muted = AppColors.white.withValues(alpha: 0.72);
    final share = s.expected <= 0 ? 0.0 : (s.actual / s.expected).clamp(0.0, 1.0);
    return EarnCard(
      dark: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CardTitle(
          data.isCurrent ? 'This month so far' : 'Summary',
          info: const (
            'What these figures mean',
            'Expected: what your plan says this month should earn.\n'
                'Earned so far: money you have earned up to this moment, exactly.\n'
                'Actual: earned so far plus any adjustments, or the recorded actual for variable income.\n'
                'Received: cash that arrived for this month\'s work.\n'
                'Outstanding: earned but not yet received or withheld.',
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Text('Actual', style: AppType.label.copyWith(color: muted)),
        const SizedBox(height: 4),
        Wrap(spacing: AppSpace.md, runSpacing: AppSpace.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedAmount(minor: s.actual, formatter: f, style: AppType.amountLarge.copyWith(color: AppColors.white)),
          ),
          ChangeBadge(delta: data.momDelta, percent: data.momPercent),
        ]),
        const SizedBox(height: 2),
        Text('vs ${formatMonth(data.month.previous)}', style: AppType.caption.copyWith(color: muted)),
        const SizedBox(height: AppSpace.lg),
        GradientProgress(value: share, onDark: true, semanticsLabel: 'Actual as a share of expected'),
        const SizedBox(height: AppSpace.md),
        Divider(color: AppColors.white.withValues(alpha: 0.14)),
        AmountRow(label: 'Expected', minor: s.expected),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(children: [
            Expanded(child: Text('Earned so far', style: AppType.label.copyWith(color: muted))),
            const SizedBox(width: AppSpace.md),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: AmountText(f.fraction(s.accrued), style: AppType.label.copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ]),
        ),
        AmountRow(label: 'Received', minor: s.received),
        if (s.deductions != 0) AmountRow(label: 'Deductions', minor: s.deductions, caption: 'Tax, provident fund'),
        AmountRow(label: 'Outstanding', minor: s.outstanding),
        AmountRow(label: 'Variance', minor: s.variance, signed: true, caption: 'Actual minus expected'),
        AmountRow(label: 'Bonuses earned', minor: data.itemsEarned),
        AmountRow(label: 'Adjustments', minor: data.adjustments, signed: true),
      ]),
    );
  }
}

class _SourcesSection extends StatelessWidget {
  const _SourcesSection({required this.data});
  final MonthHistoryData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Padding(padding: EdgeInsets.only(left: 4), child: CardTitle('By source')),
      const SizedBox(height: AppSpace.sm),
      if (data.rows.isEmpty)
        EarnCard(
          child: Text('No income sources were active this month.', style: AppType.bodySmall.copyWith(color: c.inkMuted)),
        ),
      for (final (i, s) in data.rows.indexed) ...[
        if (i > 0) const SizedBox(height: AppSpace.md),
        _SourceCard(summary: s, month: data.month),
      ],
    ]);
  }
}

class _SourceCard extends ConsumerWidget {
  const _SourceCard({required this.summary, required this.month});
  final SourceSummary summary;
  final YearMonth month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatterProvider);
    final c = context.colors;
    final src = summary.source;
    final variable = src.kind == IncomeKind.variable;
    final path = variable ? '/income/${src.id}/month/${month.toIso()}' : '/income/${src.id}';
    Widget stat(String label, int minor) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: c.cardHigh, borderRadius: BorderRadius.circular(AppRadius.pill)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('$label ', style: AppType.caption.copyWith(color: c.inkMuted)),
            Flexible(child: AmountText(f.minor(minor), style: AppType.caption.copyWith(color: c.ink, fontWeight: FontWeight.w700))),
          ]),
        );
    return EarnCard(
      onTap: () => context.push(path),
      radius: AppRadius.md + 4,
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.sm, AppSpace.lg),
      child: Row(children: [
        SourceAvatar(src, size: 44),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(src.name, style: AppType.label.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AmountText(f.minor(summary.actual), style: AppType.amountMedium.copyWith(fontSize: 20)),
            ),
            const SizedBox(height: AppSpace.sm),
            Wrap(spacing: AppSpace.sm, runSpacing: AppSpace.xs, children: [
              stat('Expected', summary.expected),
              stat('Received', summary.received),
            ]),
            if (variable && !summary.hasActual) ...[
              const SizedBox(height: AppSpace.xs),
              Pill('No actual recorded yet', icon: Icons.edit_note_rounded, color: c.warningSoft, textColor: c.warning),
            ],
          ]),
        ),
        Icon(Icons.chevron_right_rounded, color: c.inkMuted),
      ]),
    );
  }
}

class _YearToDateCard extends ConsumerWidget {
  const _YearToDateCard({required this.data});
  final MonthHistoryData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatterProvider);
    final c = context.colors;
    final y = data.ytd;
    return EarnCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CardTitle(
          'Year to date',
          subtitle: 'Jan – ${formatMonthShort(data.month)} ${data.month.year}',
          info: (
            'Year to date',
            '1 January ${data.month.year} to the end of ${formatMonth(data.month)}.',
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Text('Actual', style: AppType.caption.copyWith(color: c.inkMuted)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AmountText(f.minor(y.actual), style: AppType.amountLarge),
        ),
        const SizedBox(height: AppSpace.md),
        GradientProgress(
          value: y.expected <= 0 ? 0 : (y.actual / y.expected).clamp(0.0, 1.0),
          height: 8,
          semanticsLabel: 'Year to date actual as a share of expected',
        ),
        const SizedBox(height: AppSpace.sm),
        AmountRow(label: 'Expected', minor: y.expected),
        AmountRow(label: 'Received', minor: y.received),
        AmountRow(label: 'Outstanding', minor: y.outstanding),
        AmountRow(label: 'Variance', minor: y.variance, signed: true),
      ]),
    );
  }
}

class _CustomRangeCard extends ConsumerWidget {
  const _CustomRangeCard({required this.range, required this.onPick, required this.onClear});
  final DateRange? range;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final r = range;
    final s = r == null ? null : ref.watch(customRangeSummaryProvider(r));
    return EarnCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle(
          'Custom dates',
          info: (
            'Custom date ranges',
            'Pick any start and end date. Salaries and fixed income count only the days inside your range. '
                'For variable income with only a monthly total, the total is shared out by days.',
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        if (r == null || s == null) ...[
          Text('Summarise any period, like a project or a financial year.', style: AppType.bodySmall.copyWith(color: c.inkMuted)),
          const SizedBox(height: AppSpace.lg),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: c.accentText, side: BorderSide(color: c.accent, width: 1.4)),
            onPressed: onPick,
            icon: const Icon(Icons.date_range_rounded),
            label: const Text('Choose dates'),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.only(left: AppSpace.md),
            decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Row(children: [
              Icon(Icons.date_range_rounded, size: AppIconSize.sm, color: c.accentText),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text('${formatDate(r.start)} – ${formatDate(r.endExclusive.addDays(-1))}',
                    style: AppType.label.copyWith(color: c.accentText, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                tooltip: 'Change dates',
                icon: Icon(Icons.edit_calendar_rounded, color: c.accentText),
                onPressed: onPick,
              ),
              IconButton(tooltip: 'Clear dates', icon: Icon(Icons.close_rounded, color: c.accentText), onPressed: onClear),
            ]),
          ),
          const SizedBox(height: AppSpace.sm),
          AmountRow(label: 'Actual', minor: s.actual, bold: true),
          AmountRow(label: 'Expected', minor: s.expected),
          AmountRow(label: 'Received', minor: s.received, caption: 'Payments dated within the range'),
          AmountRow(label: 'Outstanding', minor: s.outstanding),
          AmountRow(label: 'Variance', minor: s.variance, signed: true),
        ],
      ]),
    );
  }
}
