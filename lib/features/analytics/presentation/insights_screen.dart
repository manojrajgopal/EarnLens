import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/calculation/forecast_calculator.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/organic.dart';
import '../../refresh/application/app_refresher.dart';
import '../application/insights_data.dart';
import 'analytics_widgets.dart';
import 'insights_charts.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  // Filters live in widget state, so they survive pull-to-refresh.
  InsightsRange _range = InsightsRange.sixMonths;
  String? _sourceId;

  Future<void> _refresh() => ref.read(appRefresherProvider).refresh({RefreshScope.earnings});

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(insightsProvider((range: _range, sourceId: _sourceId)));
    final snapshotLoading = ref.watch(snapshotStreamProvider).isLoading && !ref.watch(snapshotStreamProvider).hasValue;

    final header = TabPageHeader(
      title: 'Insights',
      subtitle: 'Trends, forecasts and comparisons for your income.',
      actions: [
        if (data.hasSources && !snapshotLoading)
          RoundIconButton(
            icon: Icons.science_outlined,
            tooltip: 'What if…',
            onPressed: () => context.push('/insights/what-if'),
          ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: snapshotLoading
          ? const LoadingState(label: 'Loading insights')
          : !data.hasSources
              ? AnalyticsBody(safeTop: true, onRefresh: _refresh, children: [
                  header,
                  EarnCard(
                    child: EmptyState(
                      icon: Icons.insights_rounded,
                      title: 'No insights yet',
                      message: 'Add an income source and EarnLens will chart your earnings, '
                          'compare months and estimate the rest of the year.',
                      action: 'Add income',
                      onAction: () => context.go('/income'),
                    ),
                  ),
                ])
              : _content(context, data, header),
    );
  }

  Widget _content(BuildContext context, InsightsData d, Widget header) {
    final key = '${_range.name}|$_sourceId';
    final names = {for (final s in d.filterSources) s.id: s.name};
    // A filtered source that no longer exists falls back to "All sources".
    final selectedSource = _sourceId != null && names.containsKey(_sourceId) ? _sourceId! : '';
    Widget enter(int i, Widget w) => EntranceScale(delay: Duration(milliseconds: 60 * i.clamp(0, 6)), child: w);

    return AnalyticsBody(safeTop: true, onRefresh: _refresh, children: [
      header,
      FilterPills<InsightsRange>(
        values: InsightsRange.values,
        selected: _range,
        label: (r) => r.label,
        semanticPrefix: 'Range',
        onSelected: (r) => setState(() => _range = r),
      ),
      if (d.filterSources.length > 1) ...[
        const SizedBox(height: AppSpace.md),
        FilterPills<String>(
          scroll: true,
          values: ['', ...d.filterSources.map((s) => s.id)],
          selected: selectedSource,
          label: (id) => id.isEmpty ? 'All sources' : names[id]!,
          semanticPrefix: 'Income source',
          onSelected: (id) => setState(() => _sourceId = id.isEmpty ? null : id),
        ),
      ],
      const SizedBox(height: AppSpace.xl),
      enter(0, _ForecastCard(month: d.monthForecast, year: d.yearForecast)),
      const SizedBox(height: AppSpace.xl - 4),
      CardGrid(children: [
        enter(1, _TrendCard(data: d, animationKey: key, rangeLabel: _range.description)),
        enter(2, _ExpectedActualCard(data: d)),
        enter(3, _ChangeSection(data: d)),
        enter(4, _DistributionCard(data: d, animationKey: key)),
        enter(5, _CategoryCard(data: d)),
        enter(6, _OutstandingCard(data: d)),
        enter(6, _SalaryHistoryCard(data: d)),
        enter(6, _BonusHistoryCard(data: d)),
      ]),
      const SizedBox(height: AppSpace.xl - 4),
      Builder(builder: (context) {
        final (bg, fg) = pastelAt(context, 0);
        return EarnCard(
          tint: bg,
          onTap: () => context.push('/insights/what-if'),
          semanticLabel: 'What if. Preview a hike, extra income or a bonus without saving anything.',
          child: Row(children: [
            IconBadge(Icons.science_outlined, color: AppColors.white, background: fg),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('What if…', style: AppType.section.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Preview a hike, extra income or a bonus. Nothing is saved.',
                    style: AppType.bodySmall.copyWith(color: context.colors.inkMuted)),
              ]),
            ),
            const SizedBox(width: AppSpace.sm),
            Icon(Icons.arrow_forward_rounded, color: context.colors.accentText),
          ]),
        );
      }),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Forecast hero
// ---------------------------------------------------------------------------

class _ForecastCard extends ConsumerWidget {
  const _ForecastCard({required this.month, required this.year});
  final Forecast month;
  final Forecast year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatterProvider);
    final muted = AppColors.white.withValues(alpha: 0.75);

    Widget legend(Widget dot, String label, int minor) => Row(children: [
          dot,
          const SizedBox(width: 6),
          Text('$label ', style: AppType.caption.copyWith(color: muted)),
          Flexible(child: AmountText(f.minor(minor, showMinor: false), style: AppType.caption.copyWith(fontWeight: FontWeight.w700))),
        ]);

    Widget block(String title, Forecast fc) {
      final share = fc.total <= 0 ? 0.0 : (fc.known / fc.total).clamp(0.0, 1.0);
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppType.label.copyWith(color: muted)),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AnimatedAmount(minor: fc.total, formatter: f, style: AppType.amountLarge.copyWith(color: AppColors.white)),
        ),
        const SizedBox(height: AppSpace.md),
        GradientProgress(
          value: share,
          onDark: true,
          semanticsLabel: '$title: known share of the estimate',
        ),
        const SizedBox(height: AppSpace.md),
        Wrap(spacing: AppSpace.lg, runSpacing: 4, children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: legend(const LegendDot(AppColors.lavender), 'Known', fc.known),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: legend(const LegendDot(AppColors.white, ring: true), 'Projected', fc.projected),
          ),
        ]),
      ]);
    }

    return EarnCard(
      accent: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle(
          'Forecast',
          trailing: EstimatePill(),
          info: (
            'How the forecast works',
            '“Known” is what you have already earned or recorded. “Projected” is our estimate of the rest, '
                'based on your pay rates, your monthly estimates or recent averages for variable income, '
                'and bonuses you have planned. It is an estimate, not a promise.',
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        LayoutBuilder(builder: (context, cons) {
          final wide = cons.maxWidth >= 520;
          final a = block('By month end', month);
          final b = block('By year end', year);
          return wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: a),
                  const SizedBox(width: AppSpace.xl),
                  Expanded(child: b),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  a,
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
                    child: Divider(color: AppColors.white.withValues(alpha: 0.18)),
                  ),
                  b,
                ]);
        }),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Trend
// ---------------------------------------------------------------------------

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.data, required this.animationKey, required this.rangeLabel});
  final InsightsData data;
  final Object animationKey;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) => EarnCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CardTitle(
            'Monthly earnings',
            subtitle: 'Over $rangeLabel',
            info: const (
              'Expected vs actual',
              'The light bar is what your plan says the month should earn. The lavender bar is what you '
                  'actually earned (or have earned so far this month).',
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          const TrendLegend(),
          const SizedBox(height: AppSpace.lg),
          TrendBarChart(series: data.series, animationKey: animationKey),
        ]),
      );
}

// ---------------------------------------------------------------------------
// Expected vs actual (night card)
// ---------------------------------------------------------------------------

class _ExpectedActualCard extends ConsumerWidget {
  const _ExpectedActualCard({required this.data});
  final InsightsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatterProvider);
    final months = data.series.reversed.toList();
    final muted = AppColors.white.withValues(alpha: 0.72);
    final line = AppColors.white.withValues(alpha: 0.14);
    final share = data.totalExpected <= 0 ? 0.0 : (data.totalActual / data.totalExpected).clamp(0.0, 1.0);

    Widget metric(String label, Widget value) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: AppType.caption.copyWith(color: muted)),
          const SizedBox(height: 4),
          value,
        ]);

    return EarnCard(
      dark: true,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Builder(builder: (context) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardTitle(
            'Expected vs actual',
            info: (
              'What is variance?',
              'Variance is actual minus expected. A positive number means you earned more than planned; '
                  'a negative number means less (for example unpaid leave or a slow month).',
            ),
          ),
          const SizedBox(height: AppSpace.md),
          LayoutBuilder(builder: (context, cons) {
            final w = cons.maxWidth >= 360 ? (cons.maxWidth - 2 * AppSpace.md) / 3 : (cons.maxWidth - AppSpace.md) / 2;
            Widget fit(Widget child) => SizedBox(
                  width: w,
                  child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: child),
                );
            return Wrap(spacing: AppSpace.md, runSpacing: AppSpace.md, children: [
              fit(metric('Expected', AmountText(f.minor(data.totalExpected, showMinor: false), style: AppType.amountMedium))),
              fit(metric('Actual', AmountText(f.minor(data.totalActual, showMinor: false), style: AppType.amountMedium))),
              fit(metric(
                'Variance',
                AmountText(
                  f.signed(data.totalVariance),
                  style: AppType.amountMedium.copyWith(color: signedColor(context, data.totalVariance)),
                ),
              )),
            ]);
          }),
          const SizedBox(height: AppSpace.lg),
          GradientProgress(value: share, onDark: true, semanticsLabel: 'Actual as a share of expected'),
          const SizedBox(height: AppSpace.lg),
          Text('Months · tap for details', style: AppType.caption.copyWith(color: muted)),
          const SizedBox(height: 4),
          for (final (i, p) in months.indexed) ...[
            if (i > 0) Divider(color: line, height: 1),
            Semantics(
              button: true,
              label: 'Open ${formatMonth(p.range.start.yearMonth)}',
              child: InkWell(
                customBorder: BlobBorder(BlobShapes.cloud(i, radius: AppRadius.sm, wobble: 0.3)),
                onTap: () => context.push('/insights/month/${p.range.start.yearMonth.toIso()}'),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Text(formatMonth(p.range.start.yearMonth), style: AppType.label.copyWith(fontWeight: FontWeight.w600)),
                          Row(children: [
                            Text('Expected ', maxLines: 1, style: AppType.caption.copyWith(color: muted)),
                            Flexible(
                              child: AmountText(f.minor(p.expected, showMinor: false), style: AppType.caption.copyWith(color: muted)),
                            ),
                          ]),
                        ]),
                      ),
                      Flexible(
                        fit: FlexFit.tight,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                          AmountText(f.minor(p.actual, showMinor: false), style: AppType.label.copyWith(fontWeight: FontWeight.w700)),
                          AmountText(
                            f.signed(p.variance),
                            style: AppType.caption.copyWith(color: signedColor(context, p.variance) ?? muted),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: muted),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ]);
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Changes over time (organic tiles)
// ---------------------------------------------------------------------------

class _ChangeSection extends ConsumerWidget {
  const _ChangeSection({required this.data});
  final InsightsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatterProvider);
    final c = context.colors;

    Widget tile(int i, {required IconData icon, required String title, required List<Widget> body, VoidCallback? onTap, String? semantic}) {
      final (bg, fg) = pastelAt(context, i);
      return OrganicTile(
        seed: i + 21,
        color: bg,
        onTap: onTap,
        semanticLabel: semantic,
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: fg, size: AppIconSize.md),
          const SizedBox(height: AppSpace.sm),
          Text(title, maxLines: 2, style: AppType.caption.copyWith(color: c.inkMuted, fontSize: 12.5)),
          const SizedBox(height: 4),
          ...body,
        ]),
      );
    }

    Widget comparison(int i, String title, IconData icon, MonthComparison? m) => tile(
          i,
          icon: icon,
          title: title,
          body: m == null
              ? [Text('—', style: AppType.amountMedium.copyWith(color: c.ink)), Text('Not enough data', style: AppType.caption.copyWith(color: c.inkMuted))]
              : [
                  ChangeBadge(delta: m.delta, percent: m.percent),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AmountText(f.signed(m.delta),
                        style: AppType.label.copyWith(fontWeight: FontWeight.w700, color: signedColor(context, m.delta) ?? c.ink)),
                  ),
                  Text('${formatMonthShort(m.month)} vs ${formatMonthShort(m.otherMonth)} ${m.otherMonth.year}',
                      maxLines: 2, style: AppType.caption.copyWith(color: c.inkMuted)),
                ],
        );

    Widget extreme(int i, String title, IconData icon, MonthValue? v) => tile(
          i,
          icon: icon,
          title: title,
          onTap: v == null ? null : () => context.push('/insights/month/${v.month.toIso()}'),
          semantic: v == null ? null : '$title: ${formatMonth(v.month)}. Opens month history.',
          body: v == null
              ? [Text('—', style: AppType.amountMedium.copyWith(color: c.ink))]
              : [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AmountText(f.minor(v.amount, showMinor: false), style: AppType.amountMedium.copyWith(color: c.ink, fontSize: 19)),
                  ),
                  Text(formatMonth(v.month), style: AppType.caption.copyWith(color: c.inkMuted)),
                ],
        );

    Widget pair(Widget a, Widget b) => IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: a),
            const SizedBox(width: AppSpace.md),
            Expanded(child: b),
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Padding(
        padding: EdgeInsets.only(left: 4),
        child: CardTitle(
          'Changes over time',
          subtitle: 'Completed months in this range only.',
          info: (
            'How changes are compared',
            'We compare your latest complete month with the month before and with the same month last year. '
                'When the earlier month had no earnings, a percentage cannot be calculated and “—” is shown.',
          ),
        ),
      ),
      const SizedBox(height: AppSpace.md),
      pair(
        comparison(0, 'Month over month', Icons.swap_horiz_rounded, data.monthOverMonth),
        comparison(1, 'Year over year', Icons.event_repeat_rounded, data.yearOverYear),
      ),
      const SizedBox(height: AppSpace.md),
      pair(
        extreme(2, 'Best month', Icons.emoji_events_outlined, data.best),
        extreme(3, 'Lowest month', Icons.trending_down_rounded, data.lowest),
      ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Distribution & categories
// ---------------------------------------------------------------------------

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.data, required this.animationKey});
  final InsightsData data;
  final Object animationKey;

  @override
  Widget build(BuildContext context) {
    final total = data.distribution.fold(0, (a, s) => a + s.amount);
    return EarnCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('Where your income comes from'),
        const SizedBox(height: AppSpace.md),
        if (data.distribution.isEmpty)
          Text('No earnings recorded in this range yet.', style: AppType.bodySmall.copyWith(color: context.colors.inkMuted))
        else
          SourceDonut(shares: data.distribution, total: total, animationKey: animationKey),
      ]),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({required this.data});
  final InsightsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatterProvider);
    final c = context.colors;
    return EarnCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('Earnings by category'),
        const SizedBox(height: AppSpace.sm),
        if (data.categories.isEmpty)
          Text('No earnings recorded in this range yet.', style: AppType.bodySmall.copyWith(color: c.inkMuted)),
        for (final cat in data.categories)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Semantics(
              label: '${cat.label}: ${formatBps(cat.shareBps)}',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(cat.label, style: AppType.label, overflow: TextOverflow.ellipsis)),
                  Flexible(
                    child: AmountText(f.minor(cat.amount, showMinor: false), style: AppType.label.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 52,
                    child: Text(formatBps(cat.shareBps),
                        textAlign: TextAlign.end, style: AppType.caption.copyWith(color: c.accentText, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 8),
                ExcludeSemantics(child: GradientProgress(value: cat.shareBps / 10000, height: 8)),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Outstanding
// ---------------------------------------------------------------------------

class _OutstandingCard extends ConsumerWidget {
  const _OutstandingCard({required this.data});
  final InsightsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatterProvider);
    final c = context.colors;
    final none = data.outstandingCount == 0;
    return EarnCard(
      onTap: none ? null : () => context.go('/calendar'),
      semanticLabel: none ? null : 'Outstanding payments. Opens the calendar.',
      child: Row(children: [
        IconBadge(
          none ? Icons.check_rounded : Icons.schedule_rounded,
          color: none ? c.positive : c.warning,
          background: none ? c.positiveSoft : c.warningSoft,
          size: 48,
        ),
        const SizedBox(width: AppSpace.lg),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Outstanding payments', style: AppType.caption.copyWith(color: c.inkMuted)),
            const SizedBox(height: 2),
            if (none)
              Text('Nothing overdue', style: AppType.section.copyWith(fontWeight: FontWeight.w700))
            else ...[
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AmountText(f.minor(data.outstandingTotal), style: AppType.amountMedium),
              ),
              Text(
                '${data.outstandingCount} payment${data.outstandingCount == 1 ? '' : 's'} overdue or partly paid',
                style: AppType.caption.copyWith(color: c.inkMuted),
              ),
            ],
          ]),
        ),
        const InfoTip(
          title: 'Outstanding payments',
          message: 'Payments whose expected date has passed but which you have not marked as received, '
              'or which were only partly paid. Record a payment to clear it.',
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Salary growth timeline
// ---------------------------------------------------------------------------

class _SalaryHistoryCard extends ConsumerWidget {
  const _SalaryHistoryCard({required this.data});
  final InsightsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatterProvider);
    final c = context.colors;
    final rows = data.salaryHistory;
    return EarnCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle(
          'Salary growth',
          info: (
            'Salary revisions',
            'Every time your pay changes, EarnLens keeps the old rate and adds a new one from its effective '
                'date, so past months stay accurate.',
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        if (rows.isEmpty)
          Text('No salary sources in this view.', style: AppType.bodySmall.copyWith(color: c.inkMuted)),
        for (final (i, r) in rows.indexed)
          InkWell(
            customBorder: BlobBorder(BlobShapes.cloud(i + 20, radius: AppRadius.sm, wobble: 0.3)),
            onTap: () => context.push('/income/${r.source.id}'),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SizedBox(
                  width: 18,
                  child: Column(children: [
                    Container(width: 2, height: 14, color: i == 0 ? Colors.transparent : c.line),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: i == 0 ? AppGradients.orb : null,
                        color: i == 0 ? null : c.card,
                        border: i == 0 ? null : Border.all(color: c.accent, width: 2),
                        boxShadow: i == 0 ? AppShadows.glow : null,
                      ),
                    ),
                    Expanded(child: Container(width: 2, color: i < rows.length - 1 ? c.line : Colors.transparent)),
                  ]),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r.revision.changeType.label, style: AppType.label.copyWith(fontWeight: FontWeight.w600)),
                          Text('${formatDate(r.revision.effectiveFrom)} · ${r.source.name}',
                              style: AppType.caption.copyWith(color: c.inkMuted)),
                        ]),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Flexible(
                        fit: FlexFit.tight,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: AmountText('${f.minor(r.revision.amountMinor, showMinor: false)} ${r.revision.period.label}',
                                style: AppType.label.copyWith(fontWeight: FontWeight.w700)),
                          ),
                          if (r.changeFromPrevious != null) ...[
                            const SizedBox(height: 4),
                            Pill(
                              r.changeFromPrevious!,
                              color: r.changeFromPrevious!.startsWith('+') ? c.positiveSoft : c.errorSoft,
                              textColor: r.changeFromPrevious!.startsWith('+') ? c.positive : c.overdue,
                            ),
                          ],
                        ]),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Bonuses
// ---------------------------------------------------------------------------

class _BonusHistoryCard extends ConsumerWidget {
  const _BonusHistoryCard({required this.data});
  final InsightsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatterProvider);
    final c = context.colors;
    final rows = data.bonuses.take(8).toList();
    return EarnCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('Bonuses & one-time income'),
        const SizedBox(height: AppSpace.sm),
        if (rows.isEmpty)
          Text('No bonuses recorded yet.', style: AppType.bodySmall.copyWith(color: c.inkMuted)),
        for (final (i, b) in rows.indexed)
          InkWell(
            customBorder: BlobBorder(BlobShapes.cloud(i + 40, radius: AppRadius.sm, wobble: 0.3)),
            onTap: b.item.sourceId == null ? null : () => context.push('/income/${b.item.sourceId}/item?item=${b.item.id}'),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Builder(builder: (context) {
                    final (bg, fg) = pastelAt(context, i + 3);
                    return IconBadge(Icons.redeem_outlined, color: fg, background: bg, size: 40);
                  }),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.item.title, style: AppType.label.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text(
                        [
                          b.item.type.label,
                          if (b.sourceName != null) b.sourceName!,
                          if (b.item.planningDate != null) formatDate(b.item.planningDate!),
                        ].join(' · '),
                        style: AppType.caption.copyWith(color: c.inkMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Flexible(
                    fit: FlexFit.tight,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      AmountText(f.minor(b.item.actualMinor ?? b.item.expectedMinor ?? 0, showMinor: false),
                          style: AppType.label.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Pill(
                        b.item.isEarned ? 'Earned' : 'Expected',
                        color: b.item.isEarned ? c.positiveSoft : c.accentSoft,
                        textColor: b.item.isEarned ? c.positive : c.accentText,
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}
