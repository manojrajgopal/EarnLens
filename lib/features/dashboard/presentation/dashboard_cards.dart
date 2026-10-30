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
import '../../../domain/calculation/earnings_calculator.dart';
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
  DashboardCardType.lifetime => LifetimeCard(config: c),
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
  const _CardTitle(this.title, {this.action, this.onAction, this.info, this.compact = false});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final (String, String)? info;

  /// Half-width cards: smaller heading that may wrap, smaller link.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      // Narrow cards: heading wraps by word; the link drops below if needed.
      return Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 0,
        children: [
          Semantics(header: true, child: Text(title, style: AppType.sectionStrong.copyWith(fontSize: 15.5))),
          if (action != null) LinkAction(label: action!, onTap: onAction, compact: true),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(title, style: AppType.sectionStrong, overflow: TextOverflow.ellipsis),
                ),
              ),
              if (info != null)
                InfoTip(title: info!.$1, message: info!.$2, color: context.colors.ink.withValues(alpha: 0.7)),
            ],
          ),
        ),
        if (action != null) LinkAction(label: action!, onTap: onAction),
      ],
    );
  }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardTitle(
          'Earning rates',
          action: 'Edit',
          onAction: () => context.push('/home/customize'),
          info: (
            'How rates are calculated',
            'Rates come from your current pay rules. Per day uses this month\'s actual number of days. '
                'Hourly, minute and second rates use ${dash.rateBasis.label.toLowerCase()}. '
                'Change this in Settings › Earnings calculation.',
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, c) {
            // As many columns as fit (≥ 84 px each, max 4), never more than the
            // number of visible rates — so three rates fill one row, not 2 + 1.
            final fit = (c.maxWidth / 84).floor().clamp(2, 4);
            final cols = math.min(fit, math.max(dash.units.length, 1));
            const gap = 8.0;
            final w = (c.maxWidth - gap * (cols - 1)) / cols;
            return AnimatedSize(
              duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppDurations.medium,
              curve: AppCurves.emphasized,
              alignment: Alignment.topCenter,
              child: Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final (i, u) in dash.units.indexed)
                    SizedBox(
                      key: ValueKey(u),
                      width: w,
                      child: EntranceScale(
                        child: Builder(
                          builder: (context) {
                            final (bg, fg) = _pastel(context, i);
                            final primary = u == dash.primaryUnit;
                            return OrganicTile(
                              spec: BlobShapes.pebble(i),
                              color: bg,
                              padding: const EdgeInsets.fromLTRB(14, 16, 16, 18),
                              semanticLabel: '${u.label} ${money.fraction(rates[u]!)}',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(alpha: 0.55),
                                          border: Border.all(color: fg.withValues(alpha: 0.22), width: 1.2),
                                          boxShadow: [BoxShadow(color: fg.withValues(alpha: 0.25), blurRadius: 10)],
                                        ),
                                        child: Icon(_unitIcon(u), color: fg, size: 19),
                                      ),
                                      const Spacer(),
                                      if (primary) Icon(Icons.star_rounded, size: 14, color: fg),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    u.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppType.label.copyWith(
                                      color: context.colors.ink.withValues(alpha: 0.75),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: AmountText(
                                      u.isSubDay
                                          ? money.rate(rates[u]!, decimals: dash.precision)
                                          : money.fraction(
                                              rates[u]!,
                                              decimals: u == EarningUnit.day
                                                  ? dash.precision
                                                  : (dash.compact ? 0 : 2),
                                            ),
                                      style: AppType.amountMedium.copyWith(color: context.colors.ink, fontSize: 19),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          // The account's own monthly goal, when one is set.
          if (ref.watch(activeAccountProvider)?.monthlyTargetMinor case final target? when target > 0) ...[
            const SizedBox(height: 12),
            GradientProgress(value: (earned / target).clamp(0.0, 1.0), semanticsLabel: 'Progress toward monthly target'),
            const SizedBox(height: 8),
            AmountText(
              '${(earned * 100 / target).round()}% of ${money.minor(target, showMinor: false)} target',
              style: AppType.caption.copyWith(color: c.inkMuted),
            ),
          ],
        ],
      ),
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

    final chip = _MonthChip(
      label: '${formatMonthShort(month)} ${month.year}',
      onPrevious: () => setState(() => _back = math.min(_back + 1, 24)),
      onNext: _back == 0 ? null : () => setState(() => _back--),
    );
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            'Expected vs actual',
            overflow: TextOverflow.ellipsis,
            style: AppType.sectionStrong.copyWith(color: fg),
          ),
        ),
        const InfoTip(
          title: 'Expected vs actual',
          message:
              '"Expected" is what your plan and estimates say you should earn. "Actual" is what you '
              'really earned — from your pay rules plus any corrections, or the actual amounts you recorded '
              'for variable income. Neither is the same as money received.',
          color: Colors.white70,
        ),
      ],
    );

    final status = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: current
            ? Colors.white.withValues(alpha: 0.12)
            : (ahead ? const Color(0xFF14B87A) : const Color(0xFFF59E0B)).withValues(alpha: 0.24),
      ),
      // A month in progress is always "below" its full-month plan, so
      // variance is only shown once the month has ended.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: current
            ? [
                const Icon(Icons.timelapse_rounded, size: 16, color: Color(0xFFC4B5FD)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Month in progress · day ${today.day} of ${month.lengthInDays}',
                    style: AppType.label.copyWith(color: fg, fontSize: 13),
                  ),
                ),
              ]
            : [
                Icon(
                  ahead ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 16,
                  color: ahead ? const Color(0xFF5EF0B0) : const Color(0xFFFCD34D),
                ),
                const SizedBox(width: 6),
                Text(
                  ahead ? 'Above plan' : 'Below plan',
                  style: AppType.label.copyWith(color: ahead ? const Color(0xFF5EF0B0) : const Color(0xFFFCD34D)),
                ),
                const SizedBox(width: 6),
                AmountText(
                  money.signed(variance),
                  style: AppType.label.copyWith(
                    color: ahead ? const Color(0xFF5EF0B0) : const Color(0xFFFCD34D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
      ),
    );

    return Semantics(
      container: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final roomy = box.maxWidth >= 360;
          return BlobSurface(
            spec: BlobShapes.night,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2B1470), Color(0xFF3A1D92), Color(0xFF5530C4)],
            ),
            shadows: const [BoxShadow(color: Color(0x503F1D9C), blurRadius: 34, offset: Offset(0, 16))],
            rim: const Color(0x66CB7EEF),
            backdrop: _SummitPainter(progress: (pct ?? 0).clamp(0.0, 1.0)),
            foreground: fg,
            child: Stack(
              children: [
                if (roomy)
                  Positioned(
                    right: box.maxWidth * 0.06,
                    top: box.maxWidth >= 420 ? 82 : 104,
                    child: _TargetBadge(pct: pct),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 18, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The month chip shares the title row only on wider cards.
                      if (box.maxWidth >= 420)
                        Row(
                          children: [
                            Expanded(child: title),
                            chip,
                          ],
                        )
                      else ...[
                        title,
                        const SizedBox(height: 2),
                        chip,
                      ],
                      const SizedBox(height: 12),
                      FractionallySizedBox(
                        widthFactor: roomy ? 0.78 : 1,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Metric(
                                label: current ? 'Expected this month' : 'Expected',
                                value: money.minor(s.expected),
                                color: fg,
                                style: AppType.amountMedium.copyWith(fontSize: 21),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Metric(
                                label: current ? 'Earned so far' : 'Actual',
                                value: money.minor(earned),
                                color: fg,
                                style: AppType.amountMedium.copyWith(fontSize: 21),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FractionallySizedBox(
                        widthFactor: roomy ? 0.7 : 1,
                        alignment: Alignment.centerLeft,
                        child: GradientProgress(
                          value: (pct ?? 0).clamp(0.0, 1.0),
                          onDark: true,
                          semanticsLabel: 'Of target',
                          height: 9,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Flexible(
                            child: AmountText(
                              '${money.minor(earned)} of ${money.minor(s.expected)}',
                              style: AppType.label.copyWith(color: fg.withValues(alpha: 0.9), fontSize: 13),
                            ),
                          ),
                          if (!roomy) ...[
                            const SizedBox(width: 8),
                            Text(
                              pct == null ? '—' : '${(pct * 100).round()}%',
                              style: AppType.label.copyWith(color: fg, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      FractionallySizedBox(
                        widthFactor: roomy ? 0.76 : 1,
                        alignment: Alignment.centerLeft,
                        child: Align(alignment: Alignment.centerLeft, child: status),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// "91% of target" glass bubble with a pennant, floating over the summit.
class _TargetBadge extends StatelessWidget {
  const _TargetBadge({required this.pct});
  final double? pct;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: ShapeDecoration(
          shape: const StadiumBorder(side: BorderSide(color: Color(0x66FFFFFF))),
          color: Colors.white.withValues(alpha: 0.12),
        ),
        child: Text(
          pct == null ? '—' : '${(pct! * 100).round()}%',
          style: AppType.label.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      const SizedBox(height: 3),
      Text('of target', style: AppType.caption.copyWith(color: Colors.white.withValues(alpha: 0.8))),
    ],
  );
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({required this.label, required this.onPrevious, required this.onNext});
  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Container(
    decoration: ShapeDecoration(
      shape: const StadiumBorder(side: BorderSide(color: Color(0x40FFFFFF))),
      color: Colors.white.withValues(alpha: 0.13),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chipButton(Icons.chevron_left_rounded, 'Previous month', onPrevious),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppType.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
        ),
        _chipButton(Icons.chevron_right_rounded, 'Next month', onNext),
      ],
    ),
  );

  Widget _chipButton(IconData icon, String tooltip, VoidCallback? onTap) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 36, height: 40),
    icon: Icon(icon, size: 20, color: onTap == null ? Colors.white30 : Colors.white),
  );
}

/// Night landscape: stars, layered ridges, a dotted climbing trail and a
/// glowing trophy on a rock — the goal summit of the reference design.
/// The trail lights up to [progress].
class _SummitPainter extends CustomPainter {
  const _SummitPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    void glow(Offset c, double r, Color color) => canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: r)),
    );
    glow(Offset(w * 0.84, h * 0.62), h * 0.55, const Color(0x70CB7EEF));
    glow(Offset(w * 0.1, h * 0.05), h * 0.6, const Color(0x306B3BEA));

    // Stars.
    final star = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (final (x, y, r) in const [
      (0.56, 0.12, 1.2),
      (0.64, 0.3, 1.6),
      (0.73, 0.1, 1.0),
      (0.9, 0.22, 1.4),
      (0.47, 0.5, 1.0),
      (0.97, 0.45, 1.1),
      (0.6, 0.62, 0.9),
      (0.38, 0.08, 0.9),
    ]) {
      canvas.drawCircle(Offset(w * x, h * y), r, star);
    }

    // Far ridges.
    final far = Path()
      ..moveTo(w * 0.36, h)
      ..cubicTo(w * 0.48, h * 0.86, w * 0.55, h * 0.74, w * 0.63, h * 0.76)
      ..cubicTo(w * 0.7, h * 0.78, w * 0.74, h * 0.6, w * 0.82, h * 0.56)
      ..cubicTo(w * 0.9, h * 0.52, w * 0.95, h * 0.64, w, h * 0.6)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      far,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF7A55D6).withValues(alpha: 0.55), const Color(0xFF3A1D92).withValues(alpha: 0.2)],
        ).createShader(Offset.zero & size),
    );
    // Ridge rim light.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.55, h * 0.8)
        ..cubicTo(w * 0.6, h * 0.75, w * 0.66, h * 0.78, w * 0.7, h * 0.72)
        ..cubicTo(w * 0.74, h * 0.62, w * 0.78, h * 0.58, w * 0.82, h * 0.56),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x88E0B8FF),
    );

    // Near hill (darker) with the trophy rock.
    final near = Path()
      ..moveTo(w * 0.5, h)
      ..cubicTo(w * 0.62, h * 0.9, w * 0.7, h * 0.86, w * 0.78, h * 0.78)
      ..lineTo(w * 0.8, h * 0.73)
      ..lineTo(w * 0.87, h * 0.72)
      ..lineTo(w * 0.9, h * 0.78)
      ..cubicTo(w * 0.94, h * 0.84, w * 0.98, h * 0.86, w, h * 0.88)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      near,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1560), Color(0xFF180A3D)],
        ).createShader(Rect.fromLTWH(0, h * 0.7, w, h * 0.3)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.78, h * 0.78)
        ..lineTo(w * 0.8, h * 0.73)
        ..lineTo(w * 0.87, h * 0.72),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0x99F2B36B),
    );

    // Dotted trail from the lower left up to the summit; lit up to progress.
    final trail = Path()
      ..moveTo(w * 0.52, h * 0.97)
      ..cubicTo(w * 0.62, h * 0.9, w * 0.7, h * 0.92, w * 0.74, h * 0.84)
      ..quadraticBezierTo(w * 0.77, h * 0.78, w * 0.83, h * 0.73);
    for (final m in trail.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7) {
        final p = m.getTangentForOffset(d)!.position;
        final lit = d / m.length <= progress;
        canvas.drawCircle(
          p,
          lit ? 1.7 : 1.2,
          Paint()..color = lit ? const Color(0xFFE9C6FF) : Colors.white.withValues(alpha: 0.3),
        );
      }
    }

    // Trophy.
    final cx = w * 0.835, base = h * 0.72;
    final s = (h / 200).clamp(0.6, 1.2);
    glow(Offset(cx, base - 26 * s), 38 * s, const Color(0x99FFC94D));
    final gold = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFE7A0), Color(0xFFF5B83D), Color(0xFFC77D12)],
      ).createShader(Rect.fromLTWH(cx - 16 * s, base - 46 * s, 32 * s, 46 * s));
    // Base and stem.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, base - 3 * s), width: 22 * s, height: 6 * s),
        Radius.circular(2 * s),
      ),
      gold,
    );
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, base - 11 * s), width: 6 * s, height: 10 * s), gold);
    // Cup.
    final cup = Path()
      ..moveTo(cx - 14 * s, base - 44 * s)
      ..lineTo(cx + 14 * s, base - 44 * s)
      ..cubicTo(cx + 14 * s, base - 26 * s, cx + 8 * s, base - 16 * s, cx, base - 16 * s)
      ..cubicTo(cx - 8 * s, base - 16 * s, cx - 14 * s, base - 26 * s, cx - 14 * s, base - 44 * s)
      ..close();
    canvas.drawPath(cup, gold);
    // Handles.
    final handle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * s
      ..color = const Color(0xFFF5B83D);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 14 * s, base - 36 * s), width: 12 * s, height: 14 * s),
      math.pi / 2,
      math.pi,
      false,
      handle,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 14 * s, base - 36 * s), width: 12 * s, height: 14 * s),
      -math.pi / 2,
      math.pi,
      false,
      handle,
    );
    // Highlight.
    canvas.drawPath(
      Path()
        ..moveTo(cx - 9 * s, base - 41 * s)
        ..quadraticBezierTo(cx - 9 * s, base - 26 * s, cx - 3 * s, base - 21 * s),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * s
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_SummitPainter old) => old.progress != progress;
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

    Widget sources(double width) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardTitle('Income sources', action: 'See all', onAction: () => context.go('/income')),
        const SizedBox(height: 6),
        if (items.isEmpty)
          EarnCard(
            seed: 5,
            onTap: () => context.go('/income'),
            child: Row(
              children: [
                const _IconBadge(Icons.add_rounded, AppColors.violet),
                const SizedBox(width: 12),
                Expanded(child: Text('Add salary, freelance, business or rental income', style: AppType.label)),
              ],
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // Clip so a second card never slides under Quick stats; the
            // bottom padding leaves room for the glow shadow.
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.only(bottom: 20),
            // Cards size to their content (large text never overflows) and
            // share the tallest height.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, item) in items.indexed) ...[
                    if (i > 0) const SizedBox(width: 12),
                    SizedBox(
                      width: items.length == 1 ? width : math.min(width * 0.92, 300),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 132),
                        child: _SourceBlob(item: item, money: money, index: i),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );

    final quick = EarnCard(
      seed: 23,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      backdrop: const _LeavesPainter(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Quick stats', style: AppType.sectionStrong.copyWith(fontSize: 16.5)),
              Pill('This month', color: context.colors.accentSoft, textColor: context.colors.accentText),
            ],
          ),
          const SizedBox(height: 12),
          _StatRow(
            icon: Icons.download_rounded,
            color: AppColors.peach,
            value: '${stats.receivedThisMonth}',
            label: 'Payments received',
          ),
          const SizedBox(height: 10),
          _StatRow(
            icon: Icons.event_note_rounded,
            color: AppColors.violet,
            value: '${stats.upcoming}',
            label: 'Upcoming payments',
          ),
          if (stats.overdue > 0) ...[
            const SizedBox(height: 10),
            _StatRow(
              icon: Icons.warning_amber_rounded,
              color: context.colors.overdue,
              value: '${stats.overdue}',
              label: 'Overdue or partial',
            ),
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 340) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [sources(c.maxWidth), const SizedBox(height: 14), quick],
          );
        }
        const gap = 12.0;
        final left = (c.maxWidth - gap) * 0.57;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: left, child: sources(left)),
            const SizedBox(width: gap),
            Expanded(child: quick),
          ],
        );
      },
    );
  }
}

/// Floating purple income card with a glass laptop vignette.
class _SourceBlob extends StatelessWidget {
  const _SourceBlob({required this.item, required this.money, required this.index});
  final SourceSummary item;
  final MoneyFormatter money;
  final int index;

  @override
  Widget build(BuildContext context) {
    final x = item;
    return BlobSurface(
      spec: BlobShapes.source.copyWith(seed: index),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF5A2BE0), Color(0xFF8B4DF0), Color(0xFFCB8BF2)],
      ),
      shadows: const [BoxShadow(color: Color(0x4D6B3BEA), blurRadius: 24, offset: Offset(0, 12))],
      rim: Colors.white.withValues(alpha: 0.4),
      sheen: 0.12,
      backdrop: const _LaptopPainter(),
      foreground: Colors.white,
      onTap: () => context.push('/income/${x.source.id}'),
      semanticLabel: x.source.name,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.violetNight.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(IncomeVisuals.categoryIcon(x.source.category), color: AppColors.violet, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  x.source.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.label.copyWith(color: Colors.white, fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AnimatedAmount(
                    minor: x.actual,
                    formatter: money,
                    style: AppType.amountMedium.copyWith(color: Colors.white, fontSize: 20),
                  ),
                ),
                Text(
                  '${x.source.kind == IncomeKind.variable && !x.hasActual ? 'No actuals yet' : 'this month'}'
                  '${x.source.isSample ? ' · sample' : ''}',
                  style: AppType.caption.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
        ],
      ),
    );
  }
}

/// A translucent laptop and leaves tucked into the lower right of a card.
class _LaptopPainter extends CustomPainter {
  const _LaptopPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final leaf = Paint()..color = Colors.white.withValues(alpha: 0.14);
    for (final (x, y, r, a) in const [(0.9, 0.62, 26.0, -0.5), (0.97, 0.75, 22.0, 0.2), (0.72, 0.8, 18.0, -1.0)]) {
      canvas.save();
      canvas.translate(w * x, h * y);
      canvas.rotate(a);
      canvas.drawPath(
        Path()
          ..moveTo(0, -r)
          ..quadraticBezierTo(r * 0.55, 0, 0, r)
          ..quadraticBezierTo(-r * 0.55, 0, 0, -r),
        leaf,
      );
      canvas.restore();
    }
    // Laptop: screen + base, glassy.
    final sw = math.min(56.0, w * 0.26), sh = sw * 0.62;
    final origin = Offset(w * 0.78 - sw / 2, h * 0.86 - sh - 6);
    final screen = RRect.fromRectAndRadius(origin & Size(sw, sh), const Radius.circular(4));
    canvas.save();
    canvas.translate(origin.dx + sw / 2, origin.dy + sh);
    canvas.skew(-0.25, 0);
    canvas.translate(-(origin.dx + sw / 2), -(origin.dy + sh));
    canvas.drawRRect(
      screen,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.45), Colors.white.withValues(alpha: 0.12)],
        ).createShader(screen.outerRect),
    );
    canvas.drawRRect(screen.deflate(3), Paint()..color = const Color(0x553A1D92));
    canvas.restore();
    final base = Path()
      ..moveTo(origin.dx - 10, origin.dy + sh + 1)
      ..lineTo(origin.dx + sw + 4, origin.dy + sh + 1)
      ..lineTo(origin.dx + sw + 14, origin.dy + sh + 7)
      ..lineTo(origin.dx - 4, origin.dy + sh + 7)
      ..close();
    canvas.drawPath(base, Paint()..color = Colors.white.withValues(alpha: 0.4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft lavender leaves on the right edge of white cards.
class _LeavesPainter extends CustomPainter {
  const _LeavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    for (final (x, y, r, a, o) in const [
      (0.94, 0.42, 30.0, 0.35, 0.22),
      (0.9, 0.72, 24.0, -0.4, 0.16),
      (0.99, 0.6, 18.0, 0.9, 0.12),
    ]) {
      canvas.save();
      canvas.translate(w * x, h * y);
      canvas.rotate(a);
      final rect = Rect.fromCenter(center: Offset.zero, width: r, height: r * 2);
      canvas.drawPath(
        Path()
          ..moveTo(0, -r)
          ..quadraticBezierTo(r * 0.6, 0, 0, r)
          ..quadraticBezierTo(-r * 0.6, 0, 0, -r),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.lavender.withValues(alpha: o),
              AppColors.violet.withValues(alpha: o * 0.5),
            ],
          ).createShader(rect),
      );
      canvas.drawLine(
        Offset(0, -r * 0.85),
        Offset(0, r * 0.85),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = 0.8,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    child: Row(
      children: [
        BlobBadge(
          color: color.withValues(alpha: 0.13),
          size: 38,
          seed: icon.codePoint,
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppType.amountMedium.copyWith(fontSize: 18)),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppType.caption.copyWith(color: context.colors.inkMuted, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ],
    ),
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
    final summary = series
        .map((s) => '${formatMonthShort(s.range.start.yearMonth)} ${money.minor(s.actual)}')
        .join(', ');
    final expectedColor = Color.alphaBlend(c.accent.withValues(alpha: 0.12), c.cardHigh);
    final legend = Wrap(spacing: 12, children: [_legend(c.accent, 'Actual'), _legend(expectedColor, 'Expected')]);
    return LayoutBuilder(
      builder: (context, box) {
        // Legend sits beside the title only when the card itself is wide.
        final legendInline = box.maxWidth >= 520;
        return EarnCard(
          seed: 61,
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text('Monthly trend', overflow: TextOverflow.ellipsis, style: AppType.sectionStrong),
                        ),
                        if (legendInline) ...[const SizedBox(width: 12), legend],
                      ],
                    ),
                  ),
                  _RangeChip(
                    label: 'Last $_months months',
                    onTap: () => setState(() => _months = _months == 6 ? 12 : 6),
                  ),
                ],
              ),
              if (!legendInline) ...[const SizedBox(height: 4), legend],
              const SizedBox(height: 12),
              Semantics(
                label: hidden ? 'Monthly trend chart' : 'Monthly earnings: $summary',
                excludeSemantics: true,
                child: SizedBox(
                  height: 170,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final barW = (box.maxWidth / (series.length * 3.4)).clamp(4.0, 15.0);
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
                                  child: Text(
                                    _axis(v, money.currency),
                                    style: AppType.caption.copyWith(color: c.inkMuted, fontSize: 10),
                                  ),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 26,
                                getTitlesWidget: (v, meta) {
                                  final i = v.toInt();
                                  if (i % labelEvery != (series.length - 1) % labelEvery) {
                                    return const SizedBox.shrink();
                                  }
                                  return SideTitleWidget(
                                    meta: meta,
                                    child: Text(
                                      formatMonthShort(series[i].range.start.yearMonth),
                                      style: AppType.caption.copyWith(color: c.inkMuted),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            for (var i = 0; i < series.length; i++)
                              BarChartGroupData(
                                x: i,
                                barsSpace: 3,
                                barRods: [
                                  BarChartRodData(
                                    toY: series[i].expected.toDouble(),
                                    width: barW,
                                    color: expectedColor,
                                    borderRadius: BorderRadius.circular(barW / 2),
                                  ),
                                  BarChartRodData(
                                    toY: series[i].actual.toDouble(),
                                    width: barW,
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: i == series.length - 1
                                          ? const [AppColors.violetNight, AppColors.violetDeep]
                                          : const [AppColors.orchid, Color(0xFFDDA2F5)],
                                    ),
                                    borderRadius: BorderRadius.circular(barW / 2),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppDurations.chart,
                        curve: AppCurves.emphasized,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _axis(double minorUnits, Currency currency) {
    final major = minorUnits / currency.minorPerMajor;
    if (major >= 10000000) return '${(major / 10000000).toStringAsFixed(1)}Cr';
    if (major >= 100000) return '${(major / 100000).toStringAsFixed(1)}L';
    if (major >= 1000) return '${(major / 1000).round()}K';
    return major.round().toString();
  }

  static Widget _legend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: AppType.caption.copyWith(fontSize: 12.5)),
    ],
  );
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppType.caption.copyWith(color: context.colors.accentText, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: context.colors.accentText),
            ],
          ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle('Income breakdown · $year'),
          const SizedBox(height: 12),
          if (total == 0)
            Text('Nothing earned yet this year.', style: AppType.body.copyWith(color: c.inkMuted))
          else
            Row(
              children: [
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
                  child: Column(
                    children: [
                      for (final x in parts.take(5))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: IncomeVisuals.color(x.source), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  x.source.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppType.bodySmall,
                                ),
                              ),
                              Text('${(x.actual * 100 / total).round()}%', style: AppType.label),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AmountText(money.minor(total), style: AppType.section),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payments
// ---------------------------------------------------------------------------

class PaymentRow extends ConsumerWidget {
  const PaymentRow(this.p, {super.key, this.compact = false});
  final ExpectedPayment p;

  /// Tighter type for half-width cards.
  final bool compact;

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
      customBorder: BlobBorder(BlobShapes.chip(p.dueDate.day)),
      onTap: () => context.push(
        '/income/${p.sourceId}/entry?type=received&period=${p.periodMonth.toIso()}${p.itemId == null ? '' : '&item=${p.itemId}'}',
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8),
        child: compact
            ? Row(
                children: [
                  _DateBadge(p.dueDate, compact: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.label.copyWith(fontSize: 12.5, height: 1.2),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Pill(p.status.label, color: bg, textColor: fg),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: AmountText(
                                  money.minor(p.outstandingMinor),
                                  style: AppType.label.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: c.inkMuted, size: 18),
                ],
              )
            : Row(
                children: [
                  _DateBadge(p.dueDate),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.label),
                        const SizedBox(height: 4),
                        Pill(p.status.label, color: bg, textColor: fg),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: AmountText(
                        money.minor(p.outstandingMinor),
                        style: AppType.label.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: c.inkMuted),
                ],
              ),
      ),
    );
  }
}

/// Day/month badge on a soft organic white pebble.
class _DateBadge extends StatelessWidget {
  const _DateBadge(this.date, {this.compact = false});
  final LocalDate date;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: BlobBorder(
          BlobShapes.chip(date.day + date.month),
          side: BorderSide(color: c.accent.withValues(alpha: 0.22)),
        ),
        color: c.card,
        shadows: [BoxShadow(color: c.accent.withValues(alpha: 0.14), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: SizedBox(
        width: compact ? 42 : 48,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 5 : 6),
          child: Column(
            children: [
              Text(
                '${date.day}',
                style: AppType.section.copyWith(fontWeight: FontWeight.w700, fontSize: compact ? 15 : 17),
              ),
              Text(
                formatMonthShort(date.yearMonth),
                style: AppType.caption.copyWith(color: c.inkMuted, fontSize: compact ? 11 : 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UpcomingPaymentsCard extends ConsumerWidget {
  const UpcomingPaymentsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(openPaymentsProvider);
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 280;
        return EarnCard(
          seed: 77,
          padding: EdgeInsets.fromLTRB(compact ? 14 : 20, 18, compact ? 8 : 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardTitle(
                'Upcoming payments',
                action: 'Calendar',
                onAction: () => context.go('/calendar'),
                compact: compact,
              ),
              const SizedBox(height: 4),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No payments expected right now.',
                    style: AppType.body.copyWith(color: context.colors.inkMuted),
                  ),
                )
              else
                for (final p in list.take(4)) PaymentRow(p, compact: compact),
            ],
          ),
        );
      },
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Outstanding income', style: AppType.label)),
              const InfoTip(
                title: 'Outstanding income',
                message:
                    'Money you have earned and expected to be paid by now, but have not recorded as received. '
                    'Record the payment, or update the expected date if it changed.',
              ),
            ],
          ),
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
            style: AppType.caption,
          ),
        ],
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            'Forecast',
            info: (
              'Forecasts are estimates',
              'Salary and fixed income are projected from your pay rules. Variable income uses your estimate or '
                  'recent average (your choice per source). Nothing here is guaranteed income.',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              Metric(label: 'Month-end (estimate)', value: money.minor(month.total)),
              Metric(label: 'Year-end (estimate)', value: money.minor(year.total)),
            ],
          ),
          const SizedBox(height: 10),
          LinkAction(label: 'Try a what-if scenario', onTap: () => context.go('/insights/what-if')),
        ],
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        ],
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Year to date vs last year'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              Metric(label: '$year so far', value: money.minor(now.actual)),
              Metric(label: 'Same period ${year - 1}', value: money.minor(prev.actual)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            change == null ? 'No earnings last year to compare.' : '$change year over year',
            style: AppType.label.copyWith(color: context.colors.accentText),
          ),
        ],
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Income growth'),
          const SizedBox(height: 10),
          Metric(label: 'Monthly rate today', value: money.fraction(now)),
          const SizedBox(height: 8),
          AmountText(
            '12 months ago: ${money.fraction(then)}',
            style: AppType.caption.copyWith(color: context.colors.inkMuted),
          ),
          if (change != null) ...[
            const SizedBox(height: 6),
            Text(change, style: AppType.section.copyWith(color: context.colors.positive)),
          ],
        ],
      ),
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
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 280;
        return EarnCard(
          seed: 88,
          padding: EdgeInsets.fromLTRB(compact ? 14 : 20, 18, compact ? 10 : 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardTitle(
                'Recent transactions',
                action: 'See all',
                onAction: () => context.push('/home/search?q='),
                compact: compact,
              ),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: [
                      const SizedBox(width: 120, height: 92, child: CustomPaint(painter: _EmptyLedgerPainter())),
                      const SizedBox(height: 8),
                      Text(
                        'Payments you record will appear here.',
                        textAlign: TextAlign.center,
                        style: AppType.bodySmall.copyWith(color: c.inkMuted, fontSize: 12.5),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: GradientButton(
                          onPressed: () => recordPaymentFlow(context, ref),
                          child: Text(
                            compact ? 'Add payment' : 'Add your first payment',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final e in entries.take(compact ? 4 : entries.length))
                  Builder(
                    builder: (context) {
                      final money = MoneyFormatter(locale, Currency.byCode(e.currencyCode));
                      final source = snap.source(e.sourceId);
                      final negative =
                          e.type == LedgerType.reversal || e.type == LedgerType.deduction || e.amountMinor < 0;
                      final amount = AmountText(
                        '${negative ? '−' : '+'}${money.minor(e.amountMinor.abs(), compact: compact)}',
                        style: AppType.label.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 12.5 : 14,
                          color: !e.status.counts ? c.inkMuted : (negative ? c.inkMuted : c.positive),
                          decoration: e.status.counts || e.status == LedgerStatus.pending
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      );
                      if (compact) {
                        return InkWell(
                          customBorder: BlobBorder(BlobShapes.chip(e.date.day)),
                          onTap: () => context.push('/income/${e.sourceId}/entry?entry=${e.id}'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                if (source != null) ...[SourceAvatar(source, size: 32), const SizedBox(width: 8)],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        source?.name ?? 'Income',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppType.label.copyWith(fontSize: 12.5),
                                      ),
                                      Text(
                                        formatDate(e.date),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppType.caption.copyWith(color: c.inkMuted, fontSize: 11),
                                      ),
                                      amount,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: source == null ? null : SourceAvatar(source, size: 40),
                        title: Text(source?.name ?? 'Income', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${e.type.label} · ${formatDate(e.date)}'
                          '${e.status != LedgerStatus.completed ? ' · ${e.status.label}' : ''}',
                        ),
                        trailing: amount,
                        onTap: () => context.push('/income/${e.sourceId}/entry?entry=${e.id}'),
                      );
                    },
                  ),
            ],
          ),
        );
      },
    );
  }
}

/// Empty-ledger vignette: a receipt with a magnifier between two leaves.
class _EmptyLedgerPainter extends CustomPainter {
  const _EmptyLedgerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w / 2, h * 0.5);
    canvas.drawCircle(
      c,
      h * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors: [AppColors.lavender.withValues(alpha: 0.28), AppColors.lavender.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: h * 0.5)),
    );
    // Leaves either side.
    for (final (x, a) in const [(0.12, -0.6), (0.88, 0.6)]) {
      canvas.save();
      canvas.translate(w * x, h * 0.72);
      canvas.rotate(a);
      canvas.drawPath(
        Path()
          ..moveTo(0, -20)
          ..quadraticBezierTo(11, 0, 0, 20)
          ..quadraticBezierTo(-11, 0, 0, -20),
        Paint()..color = AppColors.lavender.withValues(alpha: 0.45),
      );
      canvas.restore();
    }
    // Receipt.
    final paper = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.47, h * 0.47), width: 40, height: 52),
      const Radius.circular(6),
    );
    canvas.drawRRect(paper, Paint()..color = Colors.white);
    canvas.drawRRect(
      paper,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.orchid,
    );
    final line = Paint()
      ..color = AppColors.lavender
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final y = paper.top + 12 + i * 9;
      canvas.drawLine(Offset(paper.left + 9, y), Offset(paper.right - (i.isOdd ? 16 : 9), y), line);
    }
    // Magnifier.
    final m = Offset(w * 0.62, h * 0.66);
    canvas.drawCircle(m, 10, Paint()..color = Colors.white.withValues(alpha: 0.9));
    canvas.drawCircle(
      m,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.violet,
    );
    canvas.drawLine(
      m + const Offset(7, 7),
      m + const Offset(15, 15),
      Paint()
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = AppColors.violet,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Picks a source and opens "payment received" for its latest earning period.
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
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
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
          ],
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        ],
      ),
    );
  }
}
