import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/date_time/local_date.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/settings.dart';
import '../../../domain/money/fraction.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/organic.dart';
import '../application/dashboard_providers.dart';

/// Live "money earned so far". Recomputed from the authoritative rules each
/// second (never incremented), so it is exact after suspension or restart.
Fraction liveEarned(WidgetRef ref, CounterRange range, Set<String>? sources) {
  final now = ref.watch(liveNowProvider);
  final cal = ref.watch(financialCalendarProvider);
  final today = cal.today(now);
  return ref.watch(earningsCalculatorProvider).liveTotal(
        ref.watch(snapshotProvider),
        counterRangeFor(range, today),
        now.microsecondsSinceEpoch,
        currencyCode: ref.watch(currencyProvider).code,
        sourceIds: sources,
      );
}

/// Hero earnings card: a large flowing purple blob with glass bars.
class LiveCounterCard extends ConsumerWidget {
  const LiveCounterCard({super.key, required this.config});
  final DashboardCardConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(dashboardConfigProvider);
    final money = ref.watch(moneyFormatterProvider);
    final rates = ref.watch(ratesProvider);
    final primary = dash.primaryUnit;
    final hasSources = ref.watch(sourcesProvider).isNotEmpty;
    final decimals = dash.precision.clamp(2, 6);
    const fg = AppColors.white;
    final reduce = MediaQuery.disableAnimationsOf(context);

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(26, 30, 20, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Money earned so far ${dash.counterRange.label.toLowerCase()}',
          style: AppType.label.copyWith(color: fg.withValues(alpha: 0.92), fontSize: 14.5),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Consumer(builder: (context, ref, _) {
              final value = liveEarned(ref, dash.counterRange, config.sourceIds);
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AmountText(
                  money.fraction(value, decimals: decimals),
                  style: AppType.amountHero.copyWith(
                    color: fg,
                    fontSize: 42,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    shadows: [Shadow(color: AppColors.violetNight.withValues(alpha: 0.35), blurRadius: 18)],
                  ),
                  semanticsLabel: 'Earned so far ${money.fraction(value)}',
                ),
              );
            }),
          ),
          if (hasSources) ...[const SizedBox(width: 10), const _LiveChip()],
        ]),
        const SizedBox(height: 16),
        if (hasSources)
          _RateAndCaption(
            pill: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                gradient: const LinearGradient(colors: [Color(0xFF1E0F4D), Color(0xFF2E1772)]),
                shadows: [
                  BoxShadow(color: AppColors.violetNight.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 6)),
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFFFFC94D)),
                const SizedBox(width: 6),
                AmountText(
                  '${primary.isSubDay ? money.rate(rates[primary]!, decimals: dash.precision) : money.fraction(rates[primary]!)} '
                  '${primary.shortLabel}',
                  style: AppType.label.copyWith(color: fg, fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ]),
            ),
            caption: Text(
              'Estimate from your pay rules — not money received',
              maxLines: 3,
              style: AppType.caption.copyWith(color: fg.withValues(alpha: 0.85), fontSize: 12.5, height: 1.35),
            ),
          )
        else
          Row(children: [
            Expanded(
              child: Text('Add an income source to start counting.', style: AppType.body.copyWith(color: fg)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.white, foregroundColor: AppColors.violet),
              onPressed: () => context.go('/income'),
              child: const Text('Add income'),
            ),
          ]),
      ]),
    );

    return Semantics(
      container: true,
      label: 'Money earned so far ${dash.counterRange.label.toLowerCase()}',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduce ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 1100),
        curve: AppCurves.emphasized,
        builder: (context, t, child) => BlobSurface(
          spec: BlobShapes.hero,
          gradient: AppGradients.hero,
          shadows: const [
            BoxShadow(color: Color(0x556B3BEA), blurRadius: 36, offset: Offset(0, 18)),
            BoxShadow(color: Color(0x33CB7EEF), blurRadius: 12, offset: Offset(0, 4)),
          ],
          rim: Colors.white.withValues(alpha: 0.45),
          backdrop: _HeroPainter(t),
          child: child!,
        ),
        child: content,
      ),
    );
  }
}

/// Rate pill with the "estimate" caption beside it on wide cards and below
/// it on phones — always clear of the glass bars on the right.
class _RateAndCaption extends StatelessWidget {
  const _RateAndCaption({required this.pill, required this.caption});
  final Widget pill;
  final Widget caption;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        if (box.maxWidth >= 460) {
          return Row(children: [pill, const SizedBox(width: 14), Flexible(child: caption), const SizedBox(width: 112)]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          pill,
          const SizedBox(height: 10),
          Padding(padding: const EdgeInsets.only(right: 120), child: caption),
        ]);
      });
}

class _LiveChip extends StatefulWidget {
  const _LiveChip();

  @override
  State<_LiveChip> createState() => _LiveChipState();
}

class _LiveChipState extends State<_LiveChip> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 1;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Live',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: ShapeDecoration(
            shape: const StadiumBorder(side: BorderSide(color: Colors.white, width: 1.2)),
            color: AppColors.white.withValues(alpha: 0.9),
            shadows: [BoxShadow(color: AppColors.violetNight.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            FadeTransition(
              opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x8822C55E), blurRadius: 6)],
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text('LIVE',
                style: AppType.caption.copyWith(
                    color: AppColors.violetNight, fontSize: 12.5, letterSpacing: 0.8, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

/// Silky light ribbons, rising glass cylinders and a growth arrow on the
/// right of the hero card. [t] animates the bars once on entrance.
class _HeroPainter extends CustomPainter {
  _HeroPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    void glow(Offset c, double r, Color color) => canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader =
                RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)),
        );
    // Luminous swirl upper right, deep pool lower left.
    glow(Offset(w * 0.86, h * 0.1), h * 0.9, const Color(0x55F5B8FF));
    glow(Offset(w * 0.05, h * 0.95), h * 0.8, const Color(0x403A13A8));

    // Flowing ribbons (the reference's silky folds).
    for (var i = 0; i < 3; i++) {
      final ribbon = Path()
        ..moveTo(-10, h * (0.95 - i * 0.1))
        ..cubicTo(w * 0.28, h * (0.62 - i * 0.05), w * 0.52, h * (1.08 - i * 0.04), w * 0.78, h * (0.6 - i * 0.06))
        ..quadraticBezierTo(w * 0.9, h * (0.42 - i * 0.05), w + 10, h * (0.36 - i * 0.04))
        ..lineTo(w + 10, h + 10)
        ..lineTo(-10, h + 10)
        ..close();
      canvas.drawPath(
        ribbon,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.09 - i * 0.02),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      );
    }

    // Glass cylinders (bottom-right); heights grow with t.
    final barW = math.min(24.0, w * 0.055);
    const heights = [0.2, 0.32, 0.46, 0.62];
    final baseY = h * 0.9;
    final startX = w - 20 - heights.length * (barW + 7);
    for (var i = 0; i < heights.length; i++) {
      final local = ((t * 1.3) - i * 0.1).clamp(0.0, 1.0);
      final bh = h * heights[i] * Curves.easeOutBack.transform(local);
      if (bh <= 10) continue;
      final x = startX + i * (barW + 7);
      final r = Radius.elliptical(barW / 2, 5);
      final body = RRect.fromRectAndCorners(Rect.fromLTWH(x, baseY - bh, barW, bh),
          topLeft: r, topRight: r, bottomLeft: r, bottomRight: r);
      canvas.drawRRect(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: 0.62), Colors.white.withValues(alpha: 0.12)],
          ).createShader(body.outerRect),
      );
      canvas.drawRect(Rect.fromLTWH(x + barW * 0.18, baseY - bh + 6, barW * 0.16, bh - 10),
          Paint()..color = Colors.white.withValues(alpha: 0.35));
      canvas.drawOval(Rect.fromLTWH(x, baseY - bh, barW, 9), Paint()..color = Colors.white.withValues(alpha: 0.85));
    }
    canvas.drawOval(
      Rect.fromLTWH(startX - 8, baseY - 4, heights.length * (barW + 7) + 10, 12),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Arrow trending up over the bars.
    if (t > 0.5) {
      final a = ((t - 0.5) * 2).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.95 * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final start = Offset(startX - 6, baseY - h * 0.18);
      final end = Offset(w - 24, h * 0.16);
      final curve = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(start.dx + (end.dx - start.dx) * 0.55, start.dy - h * 0.08, end.dx, end.dy);
      for (final m in curve.computeMetrics()) {
        final part = m.extractPath(0, m.length * a);
        canvas.drawPath(part, Paint.from(paint)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawPath(part, paint);
        if (a == 1) {
          final dir = m.getTangentForOffset(m.length)!.vector;
          final normal = Offset(-dir.dy, dir.dx);
          canvas.drawPath(
            Path()
              ..moveTo(end.dx - dir.dx * 12 + normal.dx * 7, end.dy - dir.dy * 12 + normal.dy * 7)
              ..lineTo(end.dx, end.dy)
              ..lineTo(end.dx - dir.dx * 12 - normal.dx * 7, end.dy - dir.dy * 12 - normal.dy * 7),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_HeroPainter old) => old.t != t;
}

/// Today's earnings (live).
class TodayCard extends ConsumerWidget {
  const TodayCard({super.key, required this.config});
  final DashboardCardConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyFormatterProvider);
    final dash = ref.watch(dashboardConfigProvider);
    final value = liveEarned(ref, CounterRange.today, config.sourceIds);
    return EarnCard(
      seed: 41,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Today's earnings", style: AppType.label.copyWith(color: context.colors.inkMuted)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AmountText(money.fraction(value, decimals: dash.precision.clamp(2, 6)), style: AppType.amountLarge),
        ),
        const SizedBox(height: 4),
        Text('Since midnight', style: AppType.caption.copyWith(color: context.colors.inkMuted)),
      ]),
    );
  }
}

/// "Earned since you started": everything earned to date, ticking live.
/// Completed months come from [lifetimeHistoryProvider]; the current month is
/// recomputed from the pay rules every second, exactly as the hero counter.
class LifetimeCard extends ConsumerWidget {
  const LifetimeCard({super.key, required this.config});
  final DashboardCardConfig config;

  /// "2 yr 10 mo", "5 mo", "12 days".
  static String _span(LocalDate since, LocalDate today) {
    if (!since.isBefore(today)) return 'Today';
    var months = (today.year - since.year) * 12 + today.month - since.month;
    if (today.day < since.day) months--;
    if (months < 1) {
      final days = since.daysUntil(today);
      return '$days ${days == 1 ? 'day' : 'days'}';
    }
    final years = months ~/ 12;
    final rest = months % 12;
    return [if (years > 0) '$years yr', if (rest > 0) '$rest mo'].join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyFormatterProvider);
    final dash = ref.watch(dashboardConfigProvider);
    final history = ref.watch(lifetimeHistoryProvider);
    final today = ref.watch(todayProvider);
    const fg = AppColors.white;
    final muted = fg.withValues(alpha: 0.72);
    final since = history.since;

    Widget stat(String label, Widget value) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppType.caption.copyWith(color: muted)),
            const SizedBox(height: 3),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: value),
          ]),
        );
    final statStyle = AppType.label.copyWith(color: fg, fontWeight: FontWeight.w700, fontSize: 15);

    return EarnCard(
      dark: true,
      seed: 59,
      semanticLabel: 'Lifetime earnings',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          BlobBadge(
            size: 40,
            seed: 5,
            color: fg.withValues(alpha: 0.14),
            child: const Icon(Icons.all_inclusive_rounded, color: Color(0xFFFFC94D), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Lifetime earnings', style: AppType.label.copyWith(color: fg, fontWeight: FontWeight.w700)),
              Text(
                since == null ? 'Everything you have earned' : 'Since ${formatDate(since)}',
                style: AppType.caption.copyWith(color: muted),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        if (since == null)
          Text(
            'Add an income source and your lifetime total starts counting here.',
            style: AppType.bodySmall.copyWith(color: muted),
          )
        else ...[
          Consumer(builder: (context, ref, _) {
            final total = history.earned + liveEarned(ref, CounterRange.month, config.sourceIds);
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AmountText(
                money.fraction(total, decimals: dash.precision.clamp(2, 6)),
                style: AppType.amountLarge.copyWith(
                  color: fg,
                  fontSize: 34,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                semanticsLabel: 'Earned in total ${money.fraction(total)}',
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            'Across ${history.sourceCount} income ${history.sourceCount == 1 ? 'source' : 'sources'}, '
            'estimated from your pay rules and recorded income.',
            style: AppType.caption.copyWith(color: muted),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: fg.withValues(alpha: 0.16)),
          const SizedBox(height: 12),
          Row(children: [
            stat(
              'This year',
              Consumer(builder: (context, ref, _) {
                final year = history.earnedThisYear + liveEarned(ref, CounterRange.month, config.sourceIds);
                return AmountText(money.fraction(year, decimals: 0), style: statStyle);
              }),
            ),
            const SizedBox(width: 12),
            stat(
              'Received',
              AmountText(
                money.minor(history.received + ref.watch(monthSummaryProvider(DashboardCardType.lifetime)).received,
                    showMinor: false),
                style: statStyle,
              ),
            ),
            const SizedBox(width: 12),
            stat('Earning for', Text(_span(since, today), style: statStyle)),
          ]),
        ],
      ]),
    );
  }
}

