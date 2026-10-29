import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/calculation/payment_schedule.dart';
import '../../../domain/calculation/rate_calculator.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/settings.dart';
import '../../../domain/money/currency.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/income_visuals.dart';
import '../../../shared/widgets/organic.dart';
import '../../authentication/application/session_controller.dart';
import '../application/dashboard_providers.dart';
import 'live_widgets.dart';

/// Builds the widget for a dashboard card configuration.
Widget buildDashboardCard(DashboardCardConfig c) => switch (c.type) {
      DashboardCardType.liveCounter => LiveCounterCard(config: c),
      DashboardCardType.rates => const RatesCard(),
      DashboardCardType.monthToDate => const MonthToDateCard(),
      DashboardCardType.today => TodayCard(config: c),
      DashboardCardType.expectedVsActual => const ExpectedVsActualCard(),
      DashboardCardType.sources => SourcesCard(config: c),
      DashboardCardType.trend => const TrendCard(),
      DashboardCardType.breakdown => const BreakdownCard(),
      DashboardCardType.upcomingPayments => const UpcomingPaymentsCard(),
      DashboardCardType.outstanding => const OutstandingCard(),
      DashboardCardType.forecast => const ForecastCard(),
      DashboardCardType.bonuses => const BonusesCard(),
      DashboardCardType.yearly => const YearlyCard(),
      DashboardCardType.growth => const GrowthCard(),
      DashboardCardType.recentTransactions => const RecentTransactionsCard(),
      DashboardCardType.calendarPreview => const WeekPreviewCard(),
    };

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.title, {this.action, this.onAction, this.info});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final (String, String)? info;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Row(children: [
            Flexible(
              child: Semantics(
                header: true,
                child: Text(title, style: AppType.section.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              ),
            ),
            if (info != null) InfoTip(title: info!.$1, message: info!.$2),
          ]),
        ),
        if (action != null) LinkAction(label: action!, onTap: onAction),
      ]);
}

/// Pastel colour pairs (soft background, strong accent) for tiles.
const _pastels = [
  (AppColors.lilacSoft, AppColors.violet),
  (AppColors.peachSoft, AppColors.peach),
  (AppColors.skySoft, AppColors.sky),
  (AppColors.mintSoft, AppColors.mint),
];

(Color, Color) _pastel(BuildContext context, int i) {
  final p = _pastels[i % _pastels.length];
  if (Theme.of(context).brightness == Brightness.dark) {
    return (Color.alphaBlend(p.$2.withValues(alpha: 0.18), context.colors.card), p.$2);
  }
  return p;
}

class _IconBadge extends StatelessWidget {
  const _IconBadge(this.icon, this.color, {this.size = 40});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, Colors.white, 0.25)!, color],
          ),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Icon(icon, size: size * 0.52, color: Colors.white),
      );
}

// ---------------------------------------------------------------------------
// Earning rates
// ---------------------------------------------------------------------------

IconData _unitIcon(EarningUnit u) => switch (u) {
      EarningUnit.second => Icons.timer_outlined,
      EarningUnit.minute => Icons.schedule_rounded,
      EarningUnit.hour => Icons.bar_chart_rounded,
      EarningUnit.day => Icons.wb_sunny_outlined,
      EarningUnit.week => Icons.view_week_outlined,
      EarningUnit.month => Icons.calendar_month_outlined,
      EarningUnit.quarter => Icons.pie_chart_outline_rounded,
      EarningUnit.year => Icons.auto_graph_rounded,
    };

class RatesCard extends ConsumerWidget {
  const RatesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(dashboardConfigProvider);
    final rates = ref.watch(ratesProvider);
    final money = ref.watch(moneyFormatterProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _CardTitle(
        'Earning rates',
        action: 'Edit',
        onAction: () => context.push('/home/customize'),
        info: (
          'How rates are calculated',
          'Rates come from your current pay rules. Per day uses this month\'s actual number of days. '
              'Hourly, minute and second rates use ${dash.rateBasis.label.toLowerCase()}. '
              'Change this in Settings › Earnings calculation.'
        ),
      ),
      const SizedBox(height: 10),
      LayoutBuilder(builder: (context, c) {
        // As many columns as fit (≥ 84 px each, max 4), never more than the
        // number of visible rates — so three rates fill one row, not 2 + 1.
        final fit = (c.maxWidth / 84).floor().clamp(2, 4);
        final cols = math.min(fit, math.max(dash.units.length, 1));
        const gap = 10.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppDurations.medium,
          curve: AppCurves.emphasized,
          alignment: Alignment.topCenter,
          child: Wrap(spacing: gap, runSpacing: gap, children: [
            for (final (i, u) in dash.units.indexed)
              SizedBox(
                key: ValueKey(u),
                width: w,
                child: EntranceScale(
                  child: Builder(builder: (context) {
                    final (bg, fg) = _pastel(context, i);
                    final primary = u == dash.primaryUnit;
                    return OrganicTile(
                      seed: i + 11,
                      color: bg,
                      padding: const EdgeInsets.fromLTRB(12, 14, 10, 14),
                      semanticLabel: '${u.label} ${money.fraction(rates[u]!)}',
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(_unitIcon(u), color: fg, size: AppIconSize.md),
                          const Spacer(),
                          if (primary) Icon(Icons.star_rounded, size: 14, color: fg),
                        ]),
                        const SizedBox(height: 8),
                        Text(u.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.caption.copyWith(color: context.colors.inkMuted, fontSize: 12.5)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: AmountText(
                            money.fraction(
                              rates[u]!,
                              decimals: u.isSubDay || u == EarningUnit.day ? dash.precision : (dash.compact ? 0 : 2),
                            ),
                            style: AppType.amountMedium.copyWith(color: context.colors.ink, fontSize: 19),
                          ),
                        ),
                      ]),
                    );
                  }),
                ),
              ),
          ]),
        );
      }),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Month to date
// ---------------------------------------------------------------------------

class MonthToDateCard extends ConsumerWidget {
  const MonthToDateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(monthSummaryProvider(DashboardCardType.monthToDate));
    final money = ref.watch(moneyFormatterProvider);
    final c = context.colors;
    final earned = s.accrued.roundToInt();
    final progress = s.expected <= 0 ? 0.0 : (earned / s.expected).clamp(0.0, 1.0);
    return EarnCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Month to date', style: AppType.label.copyWith(color: c.inkMuted)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AnimatedAmount(minor: earned, formatter: money, style: AppType.amountLarge),
        ),
        const SizedBox(height: 12),
        GradientProgress(value: progress, semanticsLabel: 'Progress toward expected'),
        const SizedBox(height: 8),
        AmountText('of ${money.minor(s.expected)} expected', style: AppType.caption.copyWith(color: c.inkMuted)),
      ]),
    );
  }
}


// ---------------------------------------------------------------------------
// Expected vs actual (night card)
// ---------------------------------------------------------------------------

class ExpectedVsActualCard extends ConsumerStatefulWidget {
  const ExpectedVsActualCard({super.key});

  @override
  ConsumerState<ExpectedVsActualCard> createState() => _ExpectedVsActualCardState();
}

class _ExpectedVsActualCardState extends ConsumerState<ExpectedVsActualCard> {
  /// 0 = this month, 1 = last month, … (selection survives rebuilds/refresh).
  int _back = 0;

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final month = today.yearMonth.addMonths(-_back);
    final s = ref.watch(monthSummaryForProvider(month));
    final money = ref.watch(moneyFormatterProvider);
    final current = _back == 0;
    final earned = s.actual;
    final pct = s.expected <= 0 ? null : earned / s.expected;
    final variance = earned - s.expected;
    const fg = AppColors.white;
    final ahead = variance >= 0;

    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          shape: OrganicBorder(seed: 7, wobble: 0.8, radius: 38),
          gradient: AppGradients.night,
          shadows: AppShadows.glow,
        ),
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: OrganicBorder(seed: 7, wobble: 0.8, radius: 38)),
          child: Stack(children: [
            const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _MountainsPainter()))),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 22),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: fg),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  LayoutBuilder(builder: (context, box) {
                    final title = Row(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(
                        child: Text('Expected vs actual',
                            overflow: TextOverflow.ellipsis,
                            style: AppType.section.copyWith(color: fg, fontWeight: FontWeight.w700)),
                      ),
                      const InfoTip(
                        title: 'Expected vs actual',
                        message: '"Expected" is what your plan and estimates say you should earn. "Actual" is what you '
                            'really earned — from your pay rules plus any corrections, or the actual amounts you recorded '
                            'for variable income. Neither is the same as money received.',
                        color: Colors.white70,
                      ),
                    ]);
                    final chip = _MonthChip(
                      label: '${formatMonthShort(month)} ${month.year}',
                      onPrevious: () => setState(() => _back = math.min(_back + 1, 24)),
                      onNext: _back == 0 ? null : () => setState(() => _back--),
                    );
                    // Side by side when there is room, stacked on narrow cards.
                    if (box.maxWidth >= 380) {
                      return Row(children: [Expanded(child: title), chip]);
                    }
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      title,
                      const SizedBox(height: 6),
                      chip,
                    ]);
                  }),
                  const SizedBox(height: 14),
                  Wrap(spacing: 28, runSpacing: 12, children: [
                    Metric(label: current ? 'Expected this month' : 'Expected', value: money.minor(s.expected), color: fg),
                    Metric(label: current ? 'Earned so far' : 'Actual', value: money.minor(earned), color: fg),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: GradientProgress(value: (pct ?? 0).clamp(0.0, 1.0), onDark: true, semanticsLabel: 'Of target')),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(pct == null ? '—' : '${(pct * 100).round()}%',
                          style: AppType.label.copyWith(color: fg, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  AmountText('${money.minor(earned)} of ${money.minor(s.expected)}',
                      style: AppType.caption.copyWith(color: fg.withValues(alpha: 0.85))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: (current
                              ? Colors.white
                              : (ahead ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)))
                          .withValues(alpha: current ? 0.12 : 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    // A month in progress is always "below" its full-month plan,
                    // so variance is only shown once the month has ended.
                    child: Wrap(spacing: 6, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: current
                        ? [
                            const Icon(Icons.timelapse_rounded, size: 16, color: Color(0xFFC4B5FD)),
                            Text(
                              'Month in progress · day ${today.day} of ${month.lengthInDays}',
                              style: AppType.label.copyWith(color: fg),
                            ),
                          ]
                        : [
                            Icon(ahead ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                size: 16, color: ahead ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D)),
                            Text(ahead ? 'Above plan' : 'Below plan', style: AppType.label.copyWith(color: fg)),
                            AmountText(money.signed(variance),
                                style: AppType.label.copyWith(color: fg, fontWeight: FontWeight.w700)),
                          ]),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({required this.label, required this.onPrevious, required this.onNext});
  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _chipButton(Icons.chevron_left_rounded, 'Previous month', onPrevious),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: AppType.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          _chipButton(Icons.chevron_right_rounded, 'Next month', onNext),
        ]),
      );

  Widget _chipButton(IconData icon, String tooltip, VoidCallback? onTap) => IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        icon: Icon(icon, size: 20, color: onTap == null ? Colors.white30 : Colors.white),
      );
}

class _MountainsPainter extends CustomPainter {
  const _MountainsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Offset(size.width * 0.85, size.height * 0.55);
    canvas.drawCircle(
      glow,
      size.height * 0.45,
      Paint()
        ..shader = RadialGradient(colors: [const Color(0x66CB7EEF), const Color(0x00CB7EEF)])
            .createShader(Rect.fromCircle(center: glow, radius: size.height * 0.45)),
    );
    final far = Path()
      ..moveTo(size.width * 0.45, size.height)
      ..lineTo(size.width * 0.62, size.height * 0.7)
      ..lineTo(size.width * 0.72, size.height * 0.78)
      ..lineTo(size.width * 0.86, size.height * 0.52)
      ..lineTo(size.width, size.height * 0.66)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(far, Paint()..color = Colors.white.withValues(alpha: 0.06));
    final near = Path()
      ..moveTo(size.width * 0.55, size.height)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.78, size.width, size.height * 0.84)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(near, Paint()..color = Colors.black.withValues(alpha: 0.18));
    // Stars.
    final star = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (final (x, y) in const [(0.66, 0.18), (0.78, 0.3), (0.9, 0.14), (0.58, 0.4)]) {
      canvas.drawCircle(Offset(size.width * x, size.height * y), 1.4, star);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Income sources + quick stats
// ---------------------------------------------------------------------------

class SourcesCard extends ConsumerWidget {
  const SourcesCard({super.key, required this.config});
  final DashboardCardConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(monthSummaryProvider(DashboardCardType.sources));
    final money = ref.watch(moneyFormatterProvider);
    final items = s.sources.where((x) => x.source.status != SourceStatus.archived).toList();
    final stats = ref.watch(quickStatsProvider);

    final sources = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _CardTitle('Income sources', action: 'See all', onAction: () => context.go('/income')),
      const SizedBox(height: 8),
      if (items.isEmpty)
        EarnCard(
          onTap: () => context.go('/income'),
          child: Row(children: [
            const _IconBadge(Icons.add_rounded, AppColors.violet),
            const SizedBox(width: 12),
            Expanded(child: Text('Add salary, freelance, business or rental income', style: AppType.label)),
          ]),
        )
      else
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final x = items[i];
              return SizedBox(
                width: items.length == 1 ? 300 : 250,
                child: EarnCard(
                  accent: true,
                  padding: const EdgeInsets.all(16),
                  radius: AppRadius.xl,
                  onTap: () => context.push('/income/${x.source.id}'),
                  semanticLabel: x.source.name,
                  child: Row(children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(IncomeVisuals.categoryIcon(x.source.category), color: AppColors.violet),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Flexible(
                            child: Text(x.source.name,
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.label.copyWith(color: Colors.white)),
                          ),
                          if (x.source.isSample) ...[
                            const SizedBox(width: 6),
                            const Pill('Sample', color: Colors.white24, textColor: Colors.white),
                          ],
                        ]),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: AnimatedAmount(
                            minor: x.actual,
                            formatter: money,
                            style: AppType.amountMedium.copyWith(color: Colors.white),
                          ),
                        ),
                        Text(x.source.kind == IncomeKind.variable && !x.hasActual ? 'No actuals yet' : 'this month',
                            style: AppType.caption.copyWith(color: Colors.white70)),
                      ]),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                  ]),
                ),
              );
            },
          ),
        ),
    ]);

    final quick = EarnCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quick stats · this month', style: AppType.section.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _StatRow(icon: Icons.south_west_rounded, color: AppColors.peach, value: '${stats.receivedThisMonth}', label: 'Payments received'),
        const SizedBox(height: 10),
        _StatRow(icon: Icons.event_available_rounded, color: AppColors.violet, value: '${stats.upcoming}', label: 'Upcoming payments'),
        if (stats.overdue > 0) ...[
          const SizedBox(height: 10),
          _StatRow(icon: Icons.warning_amber_rounded, color: context.colors.overdue, value: '${stats.overdue}', label: 'Overdue or partial'),
        ],
      ]),
    );

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 600) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [sources, const SizedBox(height: 14), quick]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 3, child: sources),
        const SizedBox(width: 14),
        Expanded(flex: 2, child: Padding(padding: const EdgeInsets.only(top: 44), child: quick)),
      ]);
    });
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.icon, required this.color, required this.value, required this.label});
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$value $label',
        excludeSemantics: true,
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Text(value, style: AppType.amountMedium.copyWith(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppType.bodySmall.copyWith(color: context.colors.inkMuted))),
        ]),
      );
}

// ---------------------------------------------------------------------------
// Monthly trend
// ---------------------------------------------------------------------------

class TrendCard extends ConsumerStatefulWidget {
  const TrendCard({super.key});

  @override
  ConsumerState<TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends ConsumerState<TrendCard> {
  int _months = 6;

  @override
  Widget build(BuildContext context) {
    final series = ref.watch(trendProvider(_months));
    final money = ref.watch(moneyFormatterProvider);
    final hidden = ref.watch(hideAmountsProvider);
    final c = context.colors;
    final maxY = series.fold<int>(0, (m, s) => [m, s.actual, s.expected].reduce(math.max));
    final top = maxY <= 0 ? 1.0 : maxY * 1.18;
    final summary = series.map((s) => '${formatMonthShort(s.range.start.yearMonth)} ${money.minor(s.actual)}').join(', ');
    return EarnCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('Monthly trend',
                overflow: TextOverflow.ellipsis, style: AppType.section.copyWith(fontWeight: FontWeight.w700)),
          ),
          _RangeChip(
            label: 'Last $_months months',
            onTap: () => setState(() => _months = _months == 6 ? 12 : 6),
          ),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 14, children: [_legend(c.accent, 'Actual'), _legend(c.line, 'Expected')]),
        const SizedBox(height: 14),
        Semantics(
          label: hidden ? 'Monthly trend chart' : 'Monthly earnings: $summary',
          excludeSemantics: true,
          child: SizedBox(
            height: 180,
            child: LayoutBuilder(builder: (context, box) {
              final barW = (box.maxWidth / (series.length * 3.2)).clamp(4.0, 12.0);
              final labelEvery = box.maxWidth / series.length < 34 ? 2 : 1;
              return BarChart(
                BarChartData(
                  maxY: top,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: top / 4,
                    getDrawingHorizontalLine: (_) => FlLine(color: c.line, strokeWidth: 1, dashArray: [4, 4]),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: !hidden,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.violetNight,
                      getTooltipItem: (g, _, rod, _) => BarTooltipItem(
                        money.minor(rod.toY.round(), compact: true),
                        AppType.caption.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: !hidden && box.maxWidth > 260,
                        reservedSize: 46,
                        interval: top / 4,
                        getTitlesWidget: (v, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(_axis(v, money.currency),
                              style: AppType.caption.copyWith(color: c.inkMuted, fontSize: 10)),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i % labelEvery != (series.length - 1) % labelEvery) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(formatMonthShort(series[i].range.start.yearMonth),
                                style: AppType.caption.copyWith(color: c.inkMuted)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < series.length; i++)
                      BarChartGroupData(x: i, barsSpace: 3, barRods: [
                        BarChartRodData(
                          toY: series[i].expected.toDouble(),
                          width: barW,
                          color: c.line,
                          borderRadius: BorderRadius.circular(barW / 2),
                        ),
                        BarChartRodData(
                          toY: series[i].actual.toDouble(),
                          width: barW,
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: i == series.length - 1
                                ? const [AppColors.violetDeep, AppColors.violet]
                                : const [AppColors.orchid, AppColors.lavender],
                          ),
                          borderRadius: BorderRadius.circular(barW / 2),
                        ),
                      ]),
                  ],
                ),
                duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppDurations.chart,
                curve: AppCurves.emphasized,
              );
            }),
          ),
        ),
      ]),
    );
  }

  static String _axis(double minorUnits, Currency currency) {
    final major = minorUnits / currency.minorPerMajor;
    if (major >= 10000000) return '${(major / 10000000).toStringAsFixed(1)}Cr';
    if (major >= 100000) return '${(major / 100000).toStringAsFixed(1)}L';
    if (major >= 1000) return '${(major / 1000).round()}K';
    return major.round().toString();
  }

  static Widget _legend(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppType.caption),
      ]);
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: context.colors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label, style: AppType.caption.copyWith(color: context.colors.accentText, fontWeight: FontWeight.w700)),
                Icon(Icons.swap_vert_rounded, size: 16, color: context.colors.accentText),
              ]),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Breakdown
// ---------------------------------------------------------------------------

class BreakdownCard extends ConsumerWidget {
  const BreakdownCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(todayProvider).year;
    final s = ref.watch(yearSummaryProvider((year, DashboardCardType.breakdown)));
    final money = ref.watch(moneyFormatterProvider);
    final parts = s.sources.where((x) => x.actual > 0).toList()..sort((a, b) => b.actual.compareTo(a.actual));
    final total = parts.fold<int>(0, (a, x) => a + x.actual);
    final c = context.colors;
    return EarnCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardTitle('Income breakdown · $year'),
        const SizedBox(height: 12),
        if (total == 0)
          Text('Nothing earned yet this year.', style: AppType.body.copyWith(color: c.inkMuted))
        else
          Row(children: [
            SizedBox(
              width: 120,
              height: 120,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 34,
                  sections: [
                    for (final x in parts)
                      PieChartSectionData(
                        value: x.actual.toDouble(),
                        color: IncomeVisuals.color(x.source),
                        radius: 22,
                        showTitle: false,
                      ),
                  ],
                ),
                duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppDurations.chart,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(children: [
                for (final x in parts.take(5))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: IncomeVisuals.color(x.source), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(x.source.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.bodySmall)),
                      Text('${(x.actual * 100 / total).round()}%', style: AppType.label),
                    ]),
                  ),
                const SizedBox(height: 4),
                Align(alignment: Alignment.centerRight, child: AmountText(money.minor(total), style: AppType.section)),
              ]),
            ),
          ]),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Payments
// ---------------------------------------------------------------------------

class PaymentRow extends ConsumerWidget {
  const PaymentRow(this.p, {super.key});
  final ExpectedPayment p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final money = ref.watch(moneyFormatterProvider);
    final (bg, fg) = switch (p.status) {
      PaymentStatus.overdue => (c.errorSoft, c.overdue),
      PaymentStatus.dueToday => (c.accentSoft, c.accentText),
      PaymentStatus.partiallyReceived => (c.warningSoft, c.warning),
      PaymentStatus.received => (c.positiveSoft, c.positive),
      PaymentStatus.upcoming => (c.cardHigh, c.inkMuted),
    };
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => context.push(
          '/income/${p.sourceId}/entry?type=received&period=${p.periodMonth.toIso()}${p.itemId == null ? '' : '&item=${p.itemId}'}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          _DateBadge(p.dueDate),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.label),
              const SizedBox(height: 4),
              Pill(p.status.label, color: bg, textColor: fg),
            ]),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: AmountText(money.minor(p.outstandingMinor), style: AppType.label.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.inkMuted),
        ]),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge(this.date);
  final LocalDate date;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Column(children: [
        Text('${date.day}', style: AppType.section.copyWith(fontWeight: FontWeight.w700)),
        Text(formatMonthShort(date.yearMonth), style: AppType.caption.copyWith(color: c.inkMuted)),
      ]),
    );
  }
}

class UpcomingPaymentsCard extends ConsumerWidget {
  const UpcomingPaymentsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(openPaymentsProvider);
    return EarnCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardTitle('Upcoming payments', action: 'Calendar', onAction: () => context.go('/calendar')),
        const SizedBox(height: 4),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No payments expected right now.', style: AppType.body.copyWith(color: context.colors.inkMuted)),
          )
        else
          for (final p in list.take(4)) PaymentRow(p),
      ]),
    );
  }
}

class OutstandingCard extends ConsumerWidget {
  const OutstandingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(outstandingPaymentsProvider);
    final money = ref.watch(moneyFormatterProvider);
    final total = list.fold<int>(0, (a, p) => a + p.outstandingMinor);
    return EarnCard(
      dark: total > 0,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Outstanding income', style: AppType.label)),
          const InfoTip(
            title: 'Outstanding income',
            message: 'Money you have earned and expected to be paid by now, but have not recorded as received. '
                'Record the payment, or update the expected date if it changed.',
          ),
        ]),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AnimatedAmount(
            minor: total,
            formatter: money,
            style: AppType.amountLarge.copyWith(color: total > 0 ? Colors.white : null),
          ),
        ),
        const SizedBox(height: 4),
        Text(
            total == 0
                ? 'Everything expected has been received.'
                : '${list.length} payment${list.length == 1 ? '' : 's'} overdue or partial',
            style: AppType.caption),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Forecast, bonuses, yearly, growth
// ---------------------------------------------------------------------------

class ForecastCard extends ConsumerWidget {
  const ForecastCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(monthForecastProvider);
    final year = ref.watch(yearForecastProvider);
    final money = ref.watch(moneyFormatterProvider);
    return EarnCard(
      onTap: () => context.go('/insights/what-if'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _CardTitle('Forecast', info: (
          'Forecasts are estimates',
          'Salary and fixed income are projected from your pay rules. Variable income uses your estimate or '
              'recent average (your choice per source). Nothing here is guaranteed income.'
        )),
        const SizedBox(height: 8),
        Wrap(spacing: 24, runSpacing: 12, children: [
          Metric(label: 'Month-end (estimate)', value: money.minor(month.total)),
          Metric(label: 'Year-end (estimate)', value: money.minor(year.total)),
        ]),
        const SizedBox(height: 10),
        LinkAction(label: 'Try a what-if scenario', onTap: () => context.go('/insights/what-if')),
      ]),
    );
  }
}

class BonusesCard extends ConsumerWidget {
  const BonusesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(bonusesThisYearProvider);
    final money = ref.watch(moneyFormatterProvider);
    final c = context.colors;
    return EarnCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardTitle('Bonuses & benefits · ${ref.watch(todayProvider).year}'),
        const SizedBox(height: 4),
        if (items.isEmpty)
          Text('No bonuses recorded this year.', style: AppType.body.copyWith(color: c.inkMuted))
        else
          for (final i in items.take(4))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const _IconBadge(Icons.card_giftcard_rounded, AppColors.orchid, size: 38),
              title: Text(i.title),
              subtitle: Text('${i.type.label} · ${formatDate(i.planningDate!)}${i.nonCash ? ' · non-cash' : ''}'),
              trailing: AmountText(
                i.actualMinor != null ? money.minor(i.actualMinor!) : '~${money.minor(i.expectedMinor ?? 0)}',
                style: AppType.label.copyWith(fontWeight: FontWeight.w700),
              ),
              onTap: i.sourceId == null ? null : () => context.push('/income/${i.sourceId}/item?item=${i.id}'),
            ),
      ]),
    );
  }
}

class YearlyCard extends ConsumerWidget {
  const YearlyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(todayProvider).year;
    final now = ref.watch(yearSummaryProvider((year, DashboardCardType.yearly)));
    final prev = ref.watch(yearSummaryProvider((year - 1, DashboardCardType.yearly)));
    final money = ref.watch(moneyFormatterProvider);
    final change = percentChange(prev.actual, now.actual);
    return EarnCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _CardTitle('Year to date vs last year'),
        const SizedBox(height: 10),
        Wrap(spacing: 24, runSpacing: 12, children: [
          Metric(label: '$year so far', value: money.minor(now.actual)),
          Metric(label: 'Same period ${year - 1}', value: money.minor(prev.actual)),
        ]),
        const SizedBox(height: 8),
        Text(change == null ? 'No earnings last year to compare.' : '$change year over year',
            style: AppType.label.copyWith(color: context.colors.accentText)),
      ]),
    );
  }
}

class GrowthCard extends ConsumerWidget {
  const GrowthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (now, then) = ref.watch(growthProvider);
    final money = ref.watch(moneyFormatterProvider);
    final change = percentChange(then.roundToInt(), now.roundToInt());
    return EarnCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _CardTitle('Income growth'),
        const SizedBox(height: 10),
        Metric(label: 'Monthly rate today', value: money.fraction(now)),
        const SizedBox(height: 8),
        AmountText('12 months ago: ${money.fraction(then)}', style: AppType.caption.copyWith(color: context.colors.inkMuted)),
        if (change != null) ...[
          const SizedBox(height: 6),
          Text(change, style: AppType.section.copyWith(color: context.colors.positive)),
        ],
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent transactions, week preview
// ---------------------------------------------------------------------------

class RecentTransactionsCard extends ConsumerWidget {
  const RecentTransactionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(recentLedgerProvider);
    final snap = ref.watch(snapshotProvider);
    final locale = ref.watch(moneyFormatterProvider).locale;
    final c = context.colors;
    return EarnCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardTitle('Recent transactions',
            action: entries.isEmpty ? null : 'See all', onAction: () => context.push('/home/search?q=')),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(children: [
              const _IconBadge(Icons.receipt_long_rounded, AppColors.lavender, size: 56),
              const SizedBox(height: 12),
              Text('Payments you record will appear here.',
                  textAlign: TextAlign.center, style: AppType.bodySmall.copyWith(color: c.inkMuted)),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => recordPaymentFlow(context, ref), child: const Text('Add your first payment')),
            ]),
          )
        else
          for (final e in entries)
            Builder(builder: (context) {
              final money = MoneyFormatter(locale, Currency.byCode(e.currencyCode));
              final source = snap.source(e.sourceId);
              final negative = e.type == LedgerType.reversal || e.type == LedgerType.deduction || e.amountMinor < 0;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: source == null ? null : SourceAvatar(source, size: 40),
                title: Text(source?.name ?? 'Income', maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${e.type.label} · ${formatDate(e.date)}'
                    '${e.status != LedgerStatus.completed ? ' · ${e.status.label}' : ''}'),
                trailing: AmountText(
                  '${negative ? '−' : '+'}${money.minor(e.amountMinor.abs())}',
                  style: AppType.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: !e.status.counts ? c.inkMuted : (negative ? c.inkMuted : c.positive),
                    decoration: e.status.counts || e.status == LedgerStatus.pending ? null : TextDecoration.lineThrough,
                  ),
                ),
                onTap: () => context.push('/income/${e.sourceId}/entry?entry=${e.id}'),
              );
            }),
      ]),
    );
  }
}

/// Picks a source and opens "payment received" for its latest earning period.
Future<void> recordPaymentFlow(BuildContext context, WidgetRef ref) async {
  final sources = ref.read(sourcesProvider).where((s) => s.status != SourceStatus.archived).toList();
  if (sources.isEmpty) {
    context.go('/income');
    return;
  }
  final today = ref.read(todayProvider);
  final picked = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.only(bottom: 16), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('Record a payment for…', style: AppType.title),
          ),
          for (final s in sources)
            ListTile(
              leading: SourceAvatar(s, size: 40),
              title: Text(s.name),
              subtitle: Text(s.kind.label),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pop(ctx, s.id),
            ),
        ]),
      ),
    ),
  );
  if (picked == null || !context.mounted) return;
  final s = ref.read(sourceProvider(picked));
  final period = s != null && s.payOffsetMonths > 0 && s.kind.accruesContinuously
      ? today.yearMonth.addMonths(-s.payOffsetMonths)
      : today.yearMonth;
  context.push('/income/$picked/entry?type=received&period=${period.toIso()}');
}

class WeekPreviewCard extends ConsumerWidget {
  const WeekPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(weekEventsProvider);
    final c = context.colors;
    return EarnCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardTitle('Next 7 days', action: 'Calendar', onAction: () => context.go('/calendar')),
        if (events.isEmpty)
          Text('Nothing scheduled this week.', style: AppType.body.copyWith(color: c.inkMuted))
        else
          for (final e in events.take(5))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _DateBadge(e.date),
              title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(e.kind),
              onTap: e.route == null ? null : () => context.push(e.route!),
            ),
      ]),
    );
  }
}
