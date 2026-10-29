import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting/money_format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../features/authentication/application/session_controller.dart';

/// Rounded rectangle with gently uneven, slightly concave edges — the soft
/// "organic" card silhouette from the reference design. [seed] varies the
/// shape so neighbouring tiles don't look identical; [wobble] (0–1) controls
/// how pronounced the curves are. The path always stays inside its bounds.
class OrganicBorder extends OutlinedBorder {
  const OrganicBorder({this.seed = 0, this.wobble = 0.5, this.radius = 30, super.side});

  final int seed;
  final double wobble;
  final double radius;

  @override
  OrganicBorder copyWith({BorderSide? side}) =>
      OrganicBorder(seed: seed, wobble: wobble, radius: radius, side: side ?? this.side);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) => OrganicBorder(seed: seed, wobble: wobble, radius: radius * t, side: side.scale(t));

  double _v(int i) {
    // Deterministic pseudo-random in [0, 1).
    final x = math.sin((seed + 1) * 12.9898 + i * 78.233) * 43758.5453;
    return x - x.floorToDouble();
  }

  Path _path(Rect r) {
    final w = r.width, h = r.height;
    final maxR = math.min(radius, math.min(w, h) / 2);
    final radii = [for (var i = 0; i < 4; i++) maxR * (0.75 + 0.5 * _v(i)).clamp(0.0, 1.0)];
    final dent = math.min(w, h) * 0.06 * wobble;
    final k = [for (var i = 0; i < 4; i++) dent * _v(i + 4)];
    final p = Path()..moveTo(r.left + radii[0], r.top);
    // Top edge (dips inward slightly).
    p.quadraticBezierTo(r.left + w * (0.35 + 0.3 * _v(8)), r.top + k[0], r.right - radii[1], r.top);
    p.cubicTo(r.right - radii[1] * 0.35, r.top, r.right, r.top + radii[1] * 0.35, r.right, r.top + radii[1]);
    // Right edge.
    p.quadraticBezierTo(r.right - k[1], r.top + h * (0.35 + 0.3 * _v(9)), r.right, r.bottom - radii[2]);
    p.cubicTo(r.right, r.bottom - radii[2] * 0.35, r.right - radii[2] * 0.35, r.bottom, r.right - radii[2], r.bottom);
    // Bottom edge.
    p.quadraticBezierTo(r.left + w * (0.35 + 0.3 * _v(10)), r.bottom - k[2], r.left + radii[3], r.bottom);
    p.cubicTo(r.left + radii[3] * 0.35, r.bottom, r.left, r.bottom - radii[3] * 0.35, r.left, r.bottom - radii[3]);
    // Left edge.
    p.quadraticBezierTo(r.left + k[3], r.top + h * (0.35 + 0.3 * _v(11)), r.left, r.top + radii[0]);
    p.cubicTo(r.left, r.top + radii[0] * 0.35, r.left + radii[0] * 0.35, r.top, r.left + radii[0], r.top);
    return p..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect.deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(_path(rect), side.toPaint());
  }

  @override
  bool operator ==(Object other) =>
      other is OrganicBorder && other.seed == seed && other.wobble == wobble && other.radius == radius && other.side == side;

  @override
  int get hashCode => Object.hash(seed, wobble, radius, side);
}

/// A tappable pastel tile with an organic outline and soft tinted shadow.
class OrganicTile extends StatelessWidget {
  const OrganicTile({
    super.key,
    required this.child,
    required this.color,
    this.seed = 0,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.semanticLabel,
    this.gradient,
  });

  final Widget child;
  final Color color;
  final int seed;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final shape = OrganicBorder(seed: seed, radius: 30);
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      container: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          shadows: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Material(
          shape: shape,
          clipBehavior: Clip.antiAlias,
          color: gradient == null ? color : Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(gradient: gradient),
            child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
          ),
        ),
      ),
    );
  }
}

/// Rounded progress bar with the brand gradient; animates value changes.
class GradientProgress extends StatelessWidget {
  const GradientProgress({super.key, required this.value, this.height = 10, this.semanticsLabel, this.onDark = false});
  final double value;
  final double height;
  final String? semanticsLabel;

  /// Use on purple/night cards.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: semanticsLabel,
      value: '${(value * 100).round()}%',
      child: LayoutBuilder(builder: (context, c) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: onDark ? Colors.white.withValues(alpha: 0.16) : context.colors.accentSoft,
            borderRadius: BorderRadius.circular(height),
          ),
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: value.clamp(0.0, 1.0)),
            duration: reduce ? Duration.zero : AppDurations.chart,
            curve: AppCurves.emphasized,
            builder: (context, v, _) => Container(
              width: c.maxWidth * v,
              decoration: BoxDecoration(
                gradient: AppGradients.progress,
                borderRadius: BorderRadius.circular(height),
                boxShadow: [BoxShadow(color: AppColors.lavender.withValues(alpha: 0.5), blurRadius: 8)],
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Animates between amounts when the underlying data changes (display only —
/// the final frame is always the exact formatted value). Respects privacy
/// masking and reduced motion.
class AnimatedAmount extends ConsumerWidget {
  const AnimatedAmount({super.key, required this.minor, required this.formatter, this.style, this.compact = false});

  final int minor;
  final MoneyFormatter formatter;
  final TextStyle? style;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(hideAmountsProvider)) {
      return Text('••••••', style: style, semanticsLabel: 'Amount hidden');
    }
    final exact = formatter.minor(minor, compact: compact);
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(exact, style: style, maxLines: 1, softWrap: false, overflow: TextOverflow.fade);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(end: minor.toDouble()),
      duration: AppDurations.slow,
      curve: AppCurves.decelerate,
      builder: (context, v, _) {
        final text = v.round() == minor ? exact : formatter.minor(v.round(), compact: compact);
        return Text(text, style: style, maxLines: 1, softWrap: false, overflow: TextOverflow.fade, semanticsLabel: exact);
      },
    );
  }
}
