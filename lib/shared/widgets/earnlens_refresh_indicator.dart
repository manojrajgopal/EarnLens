import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

enum _Phase { idle, dragging, armed, refreshing, success, failure, settling }

/// EarnLens' branded pull-to-refresh.
///
/// Wrap any vertical scrollable (use `AlwaysScrollableScrollPhysics` so short
/// and empty lists can be pulled). Pulling down from the top reveals a
/// lavender glow and a growth glyph whose bars rise with the pull; past the
/// threshold the badge fills purple with a light haptic tick; releasing runs
/// [onRefresh] while the bars pulse and a ring sweeps; completion shows a
/// check (or a warning on failure) and the indicator springs away.
///
/// * Only the outermost vertical scrollable (`depth == 0`) drives it, so
///   nested lists, horizontal carousels and charts never trigger a refresh.
/// * A refresh in progress ignores further pulls (no concurrent refreshes).
/// * Errors thrown by [onRefresh] are caught; the indicator always closes.
/// * Reduced-motion: no rotation or pulsing, short linear transitions.
class EarnLensRefreshIndicator extends StatefulWidget {
  const EarnLensRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.triggerDistance = 92,
    this.edgeOffset = 0,
    this.minimumVisible = const Duration(milliseconds: 550),
  });

  final Widget child;
  final Future<void> Function() onRefresh;

  /// Pull distance (after resistance) that arms a refresh.
  final double triggerDistance;

  /// Extra offset from the top of this widget (e.g. under a translucent header).
  final double edgeOffset;

  /// The refreshing state stays visible at least this long so the feedback is
  /// perceivable; it does not delay the data operation itself.
  final Duration minimumVisible;

  @override
  State<EarnLensRefreshIndicator> createState() => EarnLensRefreshIndicatorState();
}

class EarnLensRefreshIndicatorState extends State<EarnLensRefreshIndicator> with TickerProviderStateMixin {
  _Phase _phase = _Phase.idle;
  double _drag = 0;

  /// With clamping physics (Android) the list can't move past its top, so the
  /// content is translated down to open a gap for the indicator. With
  /// bouncing physics (iOS) the list already moves; translating would double it.
  bool _contentFollows = true;

  /// Displayed extent in logical pixels (resisted drag, or animated).
  late final AnimationController _extent = AnimationController.unbounded(vsync: this);
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _result = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

  double get _maxExtent => widget.triggerDistance * 1.55;
  double get _holdExtent => widget.triggerDistance * 0.95;

  bool get _busy =>
      _phase == _Phase.refreshing || _phase == _Phase.success || _phase == _Phase.failure || _phase == _Phase.settling;

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Visible for tests: whether a refresh is currently running.
  bool get isRefreshing => _phase == _Phase.refreshing;

  @override
  void dispose() {
    _extent.dispose();
    _loop.dispose();
    _result.dispose();
    super.dispose();
  }

  double _resist(double d) => _maxExtent * (1 - math.exp(-d / _maxExtent));

  void _setDrag(double d) {
    _drag = math.max(0, d);
    _extent.value = _resist(_drag);
    final armed = _extent.value >= widget.triggerDistance;
    if (armed && _phase == _Phase.dragging) {
      HapticFeedback.lightImpact();
      setState(() => _phase = _Phase.armed);
    } else if (!armed && _phase == _Phase.armed) {
      setState(() => _phase = _Phase.dragging);
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical || _busy) return false;
    final atTop = n.metrics.pixels <= n.metrics.minScrollExtent;
    if (n is ScrollStartNotification) {
      if (n.dragDetails != null && atTop) {
        _drag = 0;
        _contentFollows = true;
        setState(() => _phase = _Phase.dragging);
      }
    } else if (n is OverscrollNotification) {
      // Clamping physics (Android): the list cannot move, overscroll is reported.
      if (_phase == _Phase.idle && n.dragDetails != null && n.overscroll < 0) {
        _drag = 0;
        setState(() => _phase = _Phase.dragging);
      }
      if ((_phase == _Phase.dragging || _phase == _Phase.armed) && n.dragDetails != null) {
        _setDrag(_drag - n.overscroll);
      }
    } else if (n is ScrollUpdateNotification) {
      if (_phase == _Phase.dragging || _phase == _Phase.armed) {
        if (n.metrics.pixels < n.metrics.minScrollExtent) {
          // Bouncing physics (iOS): the list itself is pulled past the top.
          _contentFollows = false;
          _setDrag(n.metrics.minScrollExtent - n.metrics.pixels);
        } else if (n.dragDetails != null && (n.scrollDelta ?? 0) > 0) {
          _setDrag(_drag - n.scrollDelta!);
          if (_drag == 0) _cancel();
        } else if (n.dragDetails == null && _drag > 0 && !atTop) {
          _cancel();
        }
      }
    } else if (n is ScrollEndNotification ||
        (n is UserScrollNotification && n.direction == ScrollDirection.idle)) {
      if (_phase == _Phase.armed) {
        _start();
      } else if (_phase == _Phase.dragging) {
        _cancel();
      }
    }
    return false;
  }

  void _cancel() {
    setState(() => _phase = _Phase.settling);
    _animateExtentTo(0).whenComplete(() {
      if (mounted && _phase == _Phase.settling) setState(() => _phase = _Phase.idle);
    });
  }

  Future<void> _animateExtentTo(double target) {
    if (_reduceMotion) {
      return _extent.animateTo(target, duration: AppDurations.fast, curve: Curves.linear);
    }
    final sim = SpringSimulation(AppCurves.spring, _extent.value, target, 0);
    return _extent.animateWith(sim);
  }

  /// Starts a refresh programmatically (same lifecycle as a pull).
  Future<void> show() async {
    if (_busy) return;
    setState(() => _phase = _Phase.armed);
    await _start();
  }

  Future<void> _start() async {
    setState(() => _phase = _Phase.refreshing);
    HapticFeedback.selectionClick();
    unawaited(_animateExtentTo(_holdExtent));
    if (!_reduceMotion) _loop.repeat();
    var ok = true;
    try {
      await Future.wait([widget.onRefresh(), Future<void>.delayed(widget.minimumVisible)]);
    } on Object {
      ok = false;
    }
    if (!mounted) return;
    _loop.stop();
    setState(() => _phase = ok ? _Phase.success : _Phase.failure);
    SemanticsService.sendAnnouncement(
      View.of(context),
      ok ? 'Updated' : 'Could not refresh',
      Directionality.of(context),
    );
    await _result.forward(from: 0);
    await Future<void>.delayed(Duration(milliseconds: ok ? 380 : 900));
    if (!mounted) return;
    setState(() => _phase = _Phase.settling);
    await _animateExtentTo(0);
    if (!mounted) return;
    _result.value = 0;
    setState(() => _phase = _Phase.idle);
  }

  @override
  Widget build(BuildContext context) {
    final padTop = widget.edgeOffset;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: ScrollConfiguration(
        // The branded indicator replaces the platform stretch/glow at the top.
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: Stack(children: [
          AnimatedBuilder(
            animation: _extent,
            child: widget.child,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _contentFollows && !_reduceMotion ? math.max(0, _extent.value) : 0),
              child: child,
            ),
          ),
          if (_phase != _Phase.idle)
            Positioned(
              top: padTop,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_extent, _loop, _result]),
                  builder: (context, _) => _IndicatorView(
                    extent: math.max(0, _extent.value),
                    trigger: widget.triggerDistance,
                    phase: _phase,
                    loop: _loop.value,
                    result: _result.value,
                    reduceMotion: _reduceMotion,
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class _IndicatorView extends StatelessWidget {
  const _IndicatorView({
    required this.extent,
    required this.trigger,
    required this.phase,
    required this.loop,
    required this.result,
    required this.reduceMotion,
  });

  final double extent;
  final double trigger;
  final _Phase phase;
  final double loop;
  final double result;
  final bool reduceMotion;

  static const _badge = 48.0;

  String get _label => switch (phase) {
        _Phase.dragging => 'Pull to refresh',
        _Phase.armed => 'Release to refresh',
        _Phase.refreshing => 'Refreshing…',
        _Phase.success => 'Updated',
        _Phase.failure => "Couldn't refresh",
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final progress = (extent / trigger).clamp(0.0, 1.0);
    final filled = phase != _Phase.dragging;
    final scale = filled ? 1.0 : 0.6 + 0.4 * Curves.easeOut.transform(progress);
    final turns = reduceMotion || filled ? 0.0 : (progress - 1) * 0.25;
    final pop = phase == _Phase.success || phase == _Phase.failure
        ? 1 + 0.12 * math.sin(result * math.pi)
        : 1.0;
    // Centred in the gap opened above the content; the label appears below
    // the badge once there is room for it.
    final badgeTop = math.max(-_badge, extent / 2 - _badge / 2 - 9);
    final labelVisible = extent >= trigger * 0.9;

    return SizedBox(
      height: math.max(0, extent + 8),
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
        // Lavender glow revealed behind the badge as the pull grows.
        Positioned(
          top: badgeTop - 46,
          child: Opacity(
            opacity: progress,
            child: Container(
              width: 220,
              height: 140,
              decoration: BoxDecoration(gradient: AppGradients.glow(filled ? 1 : 0.7)),
            ),
          ),
        ),
        Positioned(
          top: badgeTop,
          child: Semantics(
            liveRegion: true,
            label: _label,
            child: Opacity(
              opacity: (progress * 1.4).clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: turns * 2 * math.pi,
                child: Transform.scale(
                  scale: scale * pop,
                  child: Container(
                    width: _badge,
                    height: _badge,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? null : c.card,
                      gradient: filled
                          ? (phase == _Phase.failure
                              ? LinearGradient(colors: [c.warning, c.overdue])
                              : AppGradients.orb)
                          : null,
                      boxShadow: filled ? AppShadows.glow : AppShadows.card(Theme.of(context).brightness),
                    ),
                    child: CustomPaint(
                      painter: _GrowthGlyphPainter(
                        grow: filled ? 1 : progress,
                        wave: phase == _Phase.refreshing && !reduceMotion ? loop : null,
                        ring: phase == _Phase.refreshing ? (reduceMotion ? 0.0 : loop) : null,
                        result: phase == _Phase.success || phase == _Phase.failure ? result : 0,
                        failure: phase == _Phase.failure,
                        color: filled ? Colors.white : AppColors.violet,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: badgeTop + _badge + 4,
          child: AnimatedOpacity(
            duration: AppDurations.fast,
            opacity: labelVisible && phase != _Phase.settling ? 1 : 0,
            child: Text(_label, style: AppType.caption.copyWith(color: c.accentText, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

/// Three rising bars with an arrow (EarnLens growth symbol). Morphs into a
/// check mark (success) or exclamation (failure) as [result] goes 0 → 1.
class _GrowthGlyphPainter extends CustomPainter {
  _GrowthGlyphPainter({
    required this.grow,
    required this.wave,
    required this.ring,
    required this.result,
    required this.failure,
    required this.color,
  });

  final double grow;
  final double? wave;
  final double? ring;
  final double result;
  final bool failure;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final glyph = Paint()
      ..color = color.withValues(alpha: 1 - result)
      ..style = PaintingStyle.fill;

    // Bars.
    const heights = [0.42, 0.66, 0.92];
    final barW = size.width * 0.12;
    final gap = size.width * 0.07;
    final baseY = size.height * 0.72;
    final maxH = size.height * 0.44;
    final startX = center.dx - (3 * barW + 2 * gap) / 2;
    for (var i = 0; i < 3; i++) {
      var h = heights[i] * Curves.easeOutBack.transform(((grow * 1.2) - i * 0.1).clamp(0.0, 1.0));
      if (wave != null) h *= 0.72 + 0.28 * (0.5 + 0.5 * math.sin((wave! * 2 * math.pi) - i * 0.9));
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(startX + i * (barW + gap), baseY - maxH * h, barW, maxH * h),
        Radius.circular(barW / 2),
      );
      canvas.drawRRect(rect, glyph);
    }

    // Arrow appears once the pull is armed.
    if (grow >= 1 && result < 1) {
      final stroke = Paint()
        ..color = color.withValues(alpha: 1 - result)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.055
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final a = Offset(size.width * 0.28, size.height * 0.40);
      final b = Offset(size.width * 0.70, size.height * 0.24);
      canvas.drawLine(a, b, stroke);
      canvas.drawPath(
        Path()
          ..moveTo(b.dx - size.width * 0.12, b.dy - size.height * 0.01)
          ..lineTo(b.dx, b.dy)
          ..lineTo(b.dx - size.width * 0.05, b.dy + size.height * 0.11),
        stroke,
      );
    }

    // Sweeping ring while refreshing.
    if (ring != null) {
      final r = Rect.fromCircle(center: center, radius: size.width / 2 + 5);
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [AppColors.lavender.withValues(alpha: 0), AppColors.lavender, AppColors.orchid],
          transform: GradientRotation(ring! * 2 * math.pi),
        ).createShader(r);
      canvas.drawArc(r, ring! * 2 * math.pi, math.pi * 1.3, false, ringPaint);
    }

    // Result symbol.
    if (result > 0) {
      final p = Paint()
        ..color = color.withValues(alpha: result)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.075
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (failure) {
        canvas.drawLine(
            Offset(center.dx, size.height * 0.3), Offset(center.dx, size.height * (0.3 + 0.28 * result)), p);
        canvas.drawCircle(Offset(center.dx, size.height * 0.72), size.width * 0.04 * result,
            Paint()..color = color.withValues(alpha: result));
      } else {
        final path = Path()
          ..moveTo(size.width * 0.3, size.height * 0.52)
          ..lineTo(size.width * 0.45, size.height * 0.66)
          ..lineTo(size.width * 0.71, size.height * 0.36);
        final metric = path.computeMetrics().first;
        canvas.drawPath(metric.extractPath(0, metric.length * result), p);
      }
    }
  }

  @override
  bool shouldRepaint(_GrowthGlyphPainter old) =>
      old.grow != grow ||
      old.wave != wave ||
      old.ring != ring ||
      old.result != result ||
      old.failure != failure ||
      old.color != color;
}
