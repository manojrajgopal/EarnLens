import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../shared/widgets/organic.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Orb position as drawn: overshoot past the first or last slot is
/// compressed so the elastic settle never pushes the orb out of the bar.
double _visualSlot(double p, int count) {
  final last = (count - 1).toDouble();
  if (p < 0) return p * 0.2;
  if (p > last) return last + (p - last) * 0.2;
  return p;
}

/// Which animated glyph a destination uses.
enum NavGlyph { home, income, calendar, analytics, settings }

/// A bottom-navigation destination. [branch] is the shell branch index;
/// [label] is used for accessibility and the long-press tooltip (the bar
/// itself shows icons only).
class NavDestination {
  const NavDestination(this.branch, this.label, this.glyph, this.icon, this.activeIcon);
  final int branch;
  final String label;
  final NavGlyph glyph;
  final IconData icon;
  final IconData activeIcon;
}

/// Floating, icons-only organic capsule with a glowing purple selection orb
/// that travels between destinations on a spring.
///
/// [current] (the shell's branch index) is the single source of truth: the
/// orb position, icon styling and the visible screen are all derived from it.
/// Slot positions are measured from the bar's laid-out width, never hardcoded.
class FloatingNavBar extends StatefulWidget {
  const FloatingNavBar({super.key, required this.destinations, required this.current, required this.onSelect});

  /// Destinations in visual (left-to-right) order.
  final List<NavDestination> destinations;
  final int current;
  final ValueChanged<int> onSelect;

  static const barHeight = 72.0;
  static const orbSize = 56.0;

  /// Slightly under-damped: natural acceleration, a soft elastic settle.
  static const spring = SpringDescription(mass: 1, stiffness: 260, damping: 23);

  @override
  State<FloatingNavBar> createState() => FloatingNavBarState();
}

class FloatingNavBarState extends State<FloatingNavBar> with TickerProviderStateMixin {
  /// Orb position in slot units (0 = first slot). Unbounded so the spring can
  /// overshoot slightly past a slot before settling.
  late final AnimationController _pos =
      AnimationController.unbounded(vsync: this, value: _slotOf(widget.current).toDouble());

  /// One-shot selection animation per slot (rests at 1).
  late final List<AnimationController> _select = [
    for (final _ in widget.destinations)
      AnimationController(vsync: this, duration: const Duration(milliseconds: 760), value: 1),
  ];

  /// Current orb position in slot units (for tests).
  @visibleForTesting
  double get orbPosition => _pos.value;

  int _slotOf(int branch) => math.max(0, widget.destinations.indexWhere((d) => d.branch == branch));

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void didUpdateWidget(FloatingNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current) _moveTo(_slotOf(widget.current));
  }

  void _moveTo(int slot) {
    if (_reduceMotion) {
      _pos.value = slot.toDouble();
      _select[slot].value = 1;
      return;
    }
    // Starts from the orb's current position and velocity, so rapid taps
    // redirect it smoothly instead of restarting.
    _pos.animateWith(SpringSimulation(FloatingNavBar.spring, _pos.value, slot.toDouble(), _pos.velocity));
    _select[slot].forward(from: 0);
  }

  void _tap(int slot) {
    final branch = widget.destinations[slot].branch;
    // Re-selecting the current tab replays its flourish (the shell returns
    // the tab to its root).
    if (branch == widget.current && !_reduceMotion) _select[slot].forward(from: 0);
    widget.onSelect(branch);
  }

  @override
  void dispose() {
    _pos.dispose();
    for (final c in _select) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final side = width < AppBreakpoints.compact ? 10.0 : 16.0;
    return SafeArea(
      // Floats above the gesture handle / 3-button bar and clear of
      // landscape cutouts.
      minimum: EdgeInsets.fromLTRB(side, 0, side, 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SizedBox(
            height: FloatingNavBar.barHeight,
            child: LayoutBuilder(builder: (context, box) {
              final n = widget.destinations.length;
              final slotW = box.maxWidth / n;
              // Never wider than a slot, so the orb can't cover a neighbour.
              final orb = math.min(FloatingNavBar.orbSize, slotW - 8);
              return Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: const BlobBorder(BlobShapes.nav),
                      color: c.navBar,
                      shadows: [
                        ...AppShadows.nav,
                        BoxShadow(color: c.accent.withValues(alpha: dark ? 0.14 : 0.3), blurRadius: 22, spreadRadius: -4),
                      ],
                    ),
                    child: CustomPaint(painter: _RimPainter(c.accent, dark)),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _OrbPainter(
                        position: _pos,
                        count: n,
                        slotWidth: slotW,
                        diameter: orb,
                        glow: c.accent,
                        rim: c.navBar,
                      ),
                    ),
                  ),
                ),
                Row(children: [
                  for (var i = 0; i < n; i++)
                    Expanded(
                      child: _NavButton(
                        dest: widget.destinations[i],
                        slot: i,
                        count: n,
                        selected: widget.destinations[i].branch == widget.current,
                        position: _pos,
                        select: _select[i],
                        onTap: () => _tap(i),
                      ),
                    ),
                ]),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}

/// Soft lavender glow along the capsule edge with an inner top sheen.
class _RimPainter extends CustomPainter {
  _RimPainter(this.accent, this.dark);
  final Color accent;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = BlobPath.of(BlobShapes.nav, rect.deflate(0.8));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = LinearGradient(colors: [
          accent.withValues(alpha: 0.55),
          accent.withValues(alpha: 0.15),
          accent.withValues(alpha: 0.4),
          accent.withValues(alpha: 0.15),
          accent.withValues(alpha: 0.55),
        ], stops: const [0, 0.25, 0.5, 0.75, 1])
            .createShader(rect),
    );
    if (!dark) {
      canvas.save();
      canvas.clipPath(path);
      final top = Rect.fromLTWH(0, 0, size.width, size.height * 0.5);
      canvas.drawRect(
        top,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accent.withValues(alpha: 0.07), accent.withValues(alpha: 0)],
          ).createShader(top),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RimPainter old) => old.accent != accent || old.dark != dark;
}

/// The travelling selection orb: a glowing purple sphere with a lavender
/// trail whose length follows the orb's speed. Repaints from [position]
/// without rebuilding any widgets.
class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.position,
    required this.count,
    required this.slotWidth,
    required this.diameter,
    required this.glow,
    required this.rim,
  }) : super(repaint: position);
  final AnimationController position;
  final int count;
  final double slotWidth;
  final double diameter;
  final Color glow;
  final Color rim;

  @override
  void paint(Canvas canvas, Size size) {
    final x = (_visualSlot(position.value, count) + 0.5) * slotWidth;
    final c = Offset(x, size.height / 2);
    final r = diameter / 2;
    final v = position.isAnimating ? position.velocity * slotWidth : 0.0; // px/s

    // Trail: a tapered glow streaming behind the orb while it moves.
    final len = (v.abs() * 0.07).clamp(0.0, slotWidth * 1.3);
    if (len > 2) {
      final dir = v.sign;
      final tail = c.dx - dir * (len + r * 0.4);
      final trail = Rect.fromLTRB(math.min(c.dx, tail), c.dy - r * 0.62, math.max(c.dx, tail), c.dy + r * 0.62);
      canvas.drawRRect(
        RRect.fromRectAndRadius(trail, Radius.circular(r)),
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
          ..shader = LinearGradient(
            begin: dir > 0 ? Alignment.centerRight : Alignment.centerLeft,
            end: dir > 0 ? Alignment.centerLeft : Alignment.centerRight,
            colors: [glow.withValues(alpha: 0.7), glow.withValues(alpha: 0)],
          ).createShader(trail),
      );
    }

    // Halo and drop shadow.
    canvas.drawCircle(
      c,
      r + 7,
      Paint()
        ..color = glow.withValues(alpha: 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11),
    );
    canvas.drawCircle(
      c + const Offset(0, 6),
      r * 0.92,
      Paint()
        ..color = const Color(0x556B3BEA)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // Sphere.
    final orb = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 1.0,
          colors: [Color(0xFFB57CF6), Color(0xFF7B45EE), Color(0xFF4E22C9)],
          stops: [0, 0.55, 1],
        ).createShader(orb),
    );
    // Specular highlight and rim.
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(-r * 0.28, -r * 0.42), width: r * 0.9, height: r * 0.42),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.42), Colors.white.withValues(alpha: 0)],
        ).createShader(Rect.fromCenter(center: c + Offset(-r * 0.28, -r * 0.42), width: r * 0.9, height: r * 0.42)),
    );
    canvas.drawCircle(
      c,
      r - 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.38),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.count != count || old.slotWidth != slotWidth || old.diameter != diameter || old.glow != glow || old.rim != rim;
}

class _NavButton extends StatefulWidget {
  const _NavButton({
    required this.dest,
    required this.slot,
    required this.count,
    required this.selected,
    required this.position,
    required this.select,
    required this.onTap,
  });
  final NavDestination dest;
  final int slot;
  final int count;
  final bool selected;
  final AnimationController position;
  final AnimationController select;
  final VoidCallback onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = c.navBarInk.withValues(alpha: 0.82);
    return Semantics(
      selected: widget.selected,
      button: true,
      label: widget.dest.label,
      excludeSemantics: true,
      child: Tooltip(
        message: widget.dest.label,
        triggerMode: TooltipTriggerMode.longPress,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.84 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([widget.position, widget.select]),
                builder: (context, _) {
                  // Icons turn white while the orb is over them, so the colour
                  // change is driven by the same spring as the orb.
                  final pos = _visualSlot(widget.position.value, widget.count);
                  final near = (1 - (pos - widget.slot).abs()).clamp(0.0, 1.0);
                  final color = Color.lerp(ink, Colors.white, Curves.easeIn.transform(near))!;
                  return _Glyph(
                    dest: widget.dest,
                    t: widget.select.value,
                    active: widget.selected,
                    filled: near > 0.5,
                    color: color,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Destination icon with its own selection flourish. [t] runs 0 → 1 once
/// when the destination is selected; every pose at t = 1 is the resting
/// pose, so an interrupted flourish never leaves an icon displaced.
class _Glyph extends StatelessWidget {
  const _Glyph({required this.dest, required this.t, required this.active, required this.filled, required this.color});
  final NavDestination dest;
  final double t;
  final bool active;
  final bool filled;
  final Color color;

  static const size = 25.0;

  @override
  Widget build(BuildContext context) {
    final icon = filled ? dest.activeIcon : dest.icon;
    final pulse = math.sin(math.pi * t); // 0 → 1 → 0
    switch (dest.glyph) {
      case NavGlyph.home:
        // Scale up, bounce, gentle glow.
        final scale = t < 0.35
            ? 1 + 0.22 * Curves.easeOut.transform(t / 0.35)
            : 1 + 0.22 * (1 - Curves.elasticOut.transform((t - 0.35) / 0.65));
        return Transform.scale(
          scale: scale,
          child: Icon(icon, size: size, color: color, shadows: [
            if (active) Shadow(color: Colors.white.withValues(alpha: 0.35 + 0.45 * pulse), blurRadius: 6 + 8 * pulse),
          ]),
        );
      case NavGlyph.income:
        // Rises like growth; a small arrow lifts off above it.
        return SizedBox(
          width: size + 10,
          height: size + 10,
          child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
            Transform.translate(offset: Offset(0, -4 * pulse), child: Icon(icon, size: size, color: color)),
            if (active && t < 1)
              Positioned(
                right: 0,
                top: 4 - 10 * Curves.easeOut.transform(t),
                child: Opacity(
                  opacity: pulse,
                  child: Icon(Icons.arrow_upward_rounded, size: 11, color: color),
                ),
              ),
          ]),
        );
      case NavGlyph.calendar:
        // Page flips down into place from the top binding.
        final angle = (1 - Curves.easeOutBack.transform(t)) * -1.35;
        return Transform(
          alignment: Alignment.topCenter,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.004)
            ..rotateX(angle),
          child: Icon(icon, size: size, color: color),
        );
      case NavGlyph.analytics:
        return CustomPaint(size: const Size.square(size), painter: _BarsPainter(t: t, color: color, filled: filled));
      case NavGlyph.settings:
        // A controlled quarter turn (the gear is symmetric, so rest = start).
        return Transform.rotate(
          angle: Curves.easeOutBack.transform(t) * math.pi / 2,
          child: Icon(icon, size: size, color: color),
        );
    }
  }
}

/// Three rounded chart bars that rise, staggered, when selected.
class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.t, required this.color, required this.filled});
  final double t;
  final Color color;
  final bool filled;

  static const _heights = [0.5, 0.86, 0.66];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final barW = w * 0.2;
    final gap = (w - barW * 3) / 4;
    final base = h * 0.9;
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.9;
    for (var i = 0; i < 3; i++) {
      final local = ((t - i * 0.12) / 0.64).clamp(0.0, 1.0);
      final grow = 0.25 + 0.75 * Curves.easeOutBack.transform(local);
      final bh = h * 0.78 * _heights[i] * grow;
      final x = gap + i * (barW + gap);
      final rect = Rect.fromLTWH(x, base - bh, barW, bh);
      canvas.drawRRect(RRect.fromRectAndRadius(filled ? rect : rect.deflate(0.9), Radius.circular(barW / 2)), paint);
    }
    // Baseline.
    canvas.drawLine(
      Offset(gap * 0.5, base + 1.2),
      Offset(w - gap * 0.5, base + 1.2),
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.t != t || old.color != color || old.filled != filled;
}
