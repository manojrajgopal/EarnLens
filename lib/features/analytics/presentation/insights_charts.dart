import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/calculation/earnings_calculator.dart';
import '../../../features/authentication/application/session_controller.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/income_visuals.dart';
import '../application/insights_data.dart';
import 'analytics_widgets.dart';

Duration chartDuration(BuildContext context) =>
    MediaQuery.of(context).disableAnimations ? Duration.zero : AppDurations.chart;

/// Expected (soft) vs actual (lavender gradient) bars per month, oldest first.
/// Styled like the dashboard's Monthly trend card.
class TrendBarChart extends ConsumerWidget {
  const TrendBarChart({super.key, required this.series, required this.animationKey, this.height = 200});

  final List<PeriodSummary> series;

  /// Changing this replays the grow-in animation (e.g. on filter change).
  final Object animationKey;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final f = ref.watch(moneyFormatterProvider);
    final hidden = ref.watch(hideAmountsProvider);

    var maxValue = 0;
    for (final p in series) {
      maxValue = math.max(maxValue, math.max(p.expected, p.actual));
    }
    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.18;
    final interval = maxY / 4;

    final summary = StringBuffer('Bar chart of monthly earnings, expected versus actual. ');
    if (hidden) {
      summary.write('Amounts are hidden.');
    } else {
      for (final p in series) {
        summary.write('${formatMonth(p.range.start.yearMonth)}: actual ${f.minor(p.actual, showMinor: false)}, '
            'expected ${f.minor(p.expected, showMinor: false)}. ');
      }
    }

    return Semantics(
      label: summary.toString(),
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: LayoutBuilder(builder: (context, box) {
            final showAxis = !hidden && maxValue > 0 && box.maxWidth > 260;
            final plotWidth = box.maxWidth - (showAxis ? 40 : 0);
            final perGroup = plotWidth / math.max(1, series.length);
            final barW = (perGroup / 3.2).clamp(3.0, 12.0);
            final labelEvery = perGroup < 30 ? 3 : (perGroup < 40 ? 2 : 1);
            final last = series.length - 1;
            return TweenAnimationBuilder<double>(
              key: ValueKey(animationKey),
              tween: Tween(begin: 0, end: 1),
              duration: chartDuration(context),
              curve: AppCurves.emphasized,
              builder: (context, t, _) => BarChart(
                duration: Duration.zero,
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (_) => FlLine(color: c.line, strokeWidth: 1, dashArray: [4, 4]),
                  ),
                  barTouchData: BarTouchData(
                    enabled: !hidden,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.violetNight,
                      maxContentWidth: 160,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItem: (group, gi, rod, ri) {
                        final p = series[group.x];
                        final value = ri == 0 ? p.expected : p.actual;
                        return BarTooltipItem(
                          '${ri == 0 ? 'Expected' : 'Actual'}\n${f.minor(value, showMinor: false)}',
                          AppType.caption.copyWith(color: AppColors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: showAxis,
                        reservedSize: 40,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              compactAxis(value, f.currency),
                              style: AppType.caption.copyWith(color: c.inkMuted, fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= series.length) return const SizedBox.shrink();
                          if ((last - i) % labelEvery != 0) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              formatMonthShort(series[i].range.start.yearMonth),
                              style: AppType.caption.copyWith(
                                color: i == last ? c.accentText : c.inkMuted,
                                fontWeight: i == last ? FontWeight.w700 : null,
                                fontSize: perGroup < 34 ? 10 : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (final (i, p) in series.indexed)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 3,
                        barRods: [
                          BarChartRodData(
                            toY: math.max(0, p.expected) * t,
                            color: c.line,
                            width: barW,
                            borderRadius: BorderRadius.circular(barW / 2),
                          ),
                          BarChartRodData(
                            toY: math.max(0, p.actual) * t,
                            width: barW,
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: i == last
                                  ? const [AppColors.violetDeep, AppColors.violet]
                                  : const [AppColors.orchid, AppColors.lavender],
                            ),
                            borderRadius: BorderRadius.circular(barW / 2),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Legend for the trend chart (wraps on small widths).
class TrendLegend extends StatelessWidget {
  const TrendLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget item(Widget swatch, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          swatch,
          const SizedBox(width: 6),
          Text(label, style: AppType.caption.copyWith(color: c.ink)),
        ]);
    return Wrap(spacing: 14, runSpacing: 6, children: [
      item(
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppColors.orchid, AppColors.lavender]),
          ),
        ),
        'Actual',
      ),
      item(LegendDot(c.line), 'Expected'),
    ]);
  }
}

/// Donut of each source's share of actual earnings, with a legend.
class SourceDonut extends ConsumerWidget {
  const SourceDonut({super.key, required this.shares, required this.total, required this.animationKey});

  final List<SourceShare> shares;
  final int total;
  final Object animationKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final f = ref.watch(moneyFormatterProvider);
    final hidden = ref.watch(hideAmountsProvider);
    final label = StringBuffer('Donut chart of earnings by income source. ');
    for (final s in shares) {
      label.write('${s.source.name}: ${formatBps(s.shareBps)}'
          '${hidden ? '' : ', ${f.minor(s.amount, showMinor: false)}'}. ');
    }

    final chart = Semantics(
      label: label.toString(),
      child: ExcludeSemantics(
        child: SizedBox(
          height: 184,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(animationKey),
            tween: Tween(begin: 0, end: 1),
            duration: chartDuration(context),
            curve: AppCurves.emphasized,
            builder: (context, t, _) => Stack(alignment: Alignment.center, children: [
              PieChart(
                duration: Duration.zero,
                PieChartData(
                  centerSpaceRadius: 60,
                  sectionsSpace: 3,
                  startDegreeOffset: -90 + 360 * (1 - t) * 0.15,
                  sections: [
                    for (final s in shares)
                      PieChartSectionData(
                        value: s.amount.toDouble(),
                        color: IncomeVisuals.color(s.source),
                        radius: 22 * t + 4,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Total', style: AppType.caption.copyWith(color: c.inkMuted)),
                const SizedBox(height: 2),
                SizedBox(
                  width: 100,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AmountText(f.minor(total, compact: true, showMinor: false), style: AppType.amountMedium),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );

    final legend = Column(children: [
      for (final s in shares)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: IncomeVisuals.color(s.source), borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.source.name, style: AppType.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                AmountText(f.minor(s.amount, showMinor: false), style: AppType.label.copyWith(fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(width: AppSpace.sm),
            Container(
              constraints: const BoxConstraints(minWidth: 52),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: Text(formatBps(s.shareBps),
                  textAlign: TextAlign.center,
                  style: AppType.caption.copyWith(color: c.accentText, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
    ]);

    return LayoutBuilder(builder: (context, cons) {
      if (cons.maxWidth >= 480) {
        return Row(children: [
          SizedBox(width: 190, child: chart),
          const SizedBox(width: AppSpace.lg),
          Expanded(child: legend),
        ]);
      }
      return Column(children: [chart, const SizedBox(height: AppSpace.md), legend]);
    });
  }
}
