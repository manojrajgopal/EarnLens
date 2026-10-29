import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/settings.dart';
import '../../../domain/money/fraction.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/organic.dart';
import '../application/dashboard_providers.dart';

/// Live "money earned so far". Recomputed from the authoritative rules each
/// second (never incremented), so it is exact after suspension or restart.
Fraction liveEarned(WidgetRef ref, CounterRange range, Set<String>? sources) {
  final now = ref.watch(tickerProvider).value ?? ref.read(clockProvider).now();
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

/// Hero earnings card.
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

    return Semantics(
      container: true,
      label: 'Money earned so far ${dash.counterRange.label.toLowerCase()}',
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          shape: OrganicBorder(seed: 3, wobble: 0.9, radius: 40),
          shadows: AppShadows.glow,
          gradient: AppGradients.hero,
        ),
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: OrganicBorder(seed: 3, wobble: 0.9, radius: 40)),
          child: Stack(children: [
            // Decorative layer kept to the right/bottom so the amount stays legible.
            const Positioned.fill(child: _HeroDecoration()),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 24, 22, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      'Money earned so far ${dash.counterRange.label.toLowerCase()}',
                      style: AppType.label.copyWith(color: fg.withValues(alpha: 0.9)),
                    ),
                  ),
                  if (hasSources) const _LiveChip(),
                ]),
                const SizedBox(height: 14),
                Consumer(builder: (context, ref, _) {
                  final value = liveEarned(ref, dash.counterRange, config.sourceIds);
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AmountText(
                      money.fraction(value, decimals: decimals),
                      style: AppType.amountHero.copyWith(
                        color: fg,
                        fontSize: 46,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      semanticsLabel: 'Earned so far ${money.fraction(value)}',
                    ),
                  );
                }),
                const SizedBox(height: 18),
                if (hasSources)
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.violetNight.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFFFFC94D)),
                          const SizedBox(width: 6),
                          AmountText(
                            '${money.fraction(rates[primary]!, decimals: primary.isSubDay ? dash.precision : 2)} ${primary.shortLabel}',
                            style: AppType.label.copyWith(color: fg, fontWeight: FontWeight.w700),
                          ),
                        ]),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          'Estimate from your pay rules — not money received',
                          style: AppType.caption.copyWith(color: fg.withValues(alpha: 0.8)),
                        ),
                      ),
                    ],
                  )
                else
                  Row(children: [
                    Expanded(
                      child: Text('Add an income source to start counting.',
                          style: AppType.body.copyWith(color: fg)),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.white, foregroundColor: AppColors.violet),
                      onPressed: () => context.go('/income'),
                      child: const Text('Add income'),
                    ),
                  ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            FadeTransition(
              opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 6),
            Text('LIVE',
                style: AppType.caption.copyWith(color: AppColors.violetDeep, letterSpacing: 1.1, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

/// Rising glass bars and a growth arrow on the right of the hero card.
/// Animates once on entrance (skipped with reduced motion).
class _HeroDecoration extends StatelessWidget {
  const _HeroDecoration();

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduce ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 1100),
        curve: AppCurves.emphasized,
        builder: (context, t, _) => CustomPaint(painter: _HeroPainter(t)),
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Soft highlight blob top-right.
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.05),
      size.height * 0.75,
      Paint()
        ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: Offset(size.width * 0.92, size.height * 0.05), radius: size.height * 0.75)),
    );
    // Wave across the bottom.
    final wave = Path()
      ..moveTo(0, size.height * 0.86)
      ..cubicTo(size.width * 0.3, size.height * 0.72, size.width * 0.55, size.height * 1.0, size.width, size.height * 0.7)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(wave, Paint()..color = Colors.white.withValues(alpha: 0.07));

    // Glass bars (bottom-right), heights grow with t.
    final barW = math.min(26.0, size.width * 0.055);
    const heights = [0.22, 0.32, 0.44, 0.58];
    final baseY = size.height * 0.94;
    for (var i = 0; i < heights.length; i++) {
      final local = ((t * 1.3) - i * 0.1).clamp(0.0, 1.0);
      final h = size.height * heights[i] * Curves.easeOutBack.transform(local);
      final x = size.width * 0.70 + i * (barW + 8);
      if (x + barW > size.width - 8) break;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, baseY - h, barW, h),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0.08)],
          ).createShader(rect.outerRect),
      );
    }
    // Arrow trending up.
    if (t > 0.5) {
      final a = ((t - 0.5) * 2).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7 * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      // Kept to the lower-right, clear of the amount and the LIVE chip.
      final start = Offset(size.width * 0.66, size.height * 0.74);
      final end = Offset(size.width * 0.94, size.height * 0.42);
      final mid = Offset.lerp(start, end, a)!;
      canvas.drawLine(start, mid, paint);
      if (a == 1) {
        canvas.drawPath(
          Path()
            ..moveTo(end.dx - 14, end.dy + 1)
            ..lineTo(end.dx, end.dy)
            ..lineTo(end.dx - 2, end.dy + 14),
          paint,
        );
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
