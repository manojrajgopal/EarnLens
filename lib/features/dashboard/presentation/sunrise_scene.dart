import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// Illustrated header backdrop for the dashboard: a pastel sunrise over
/// layered lavender mountains, a hiker resting on a rocky outcrop and the
/// hand-lettered "Track · Earn · Grow" motto. Purely decorative.
///
/// [groundY] is the distance from the scene's bottom edge to where the
/// outcrop meets the hero card; the scene is laid out relative to it so it
/// adapts to any header height. [mottoTop] positions the hand lettering.
class SunriseScene extends StatelessWidget {
  const SunriseScene({super.key, required this.groundY, required this.mottoTop});
  final double groundY;
  final double mottoTop;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ExcludeSemantics(
          child: CustomPaint(
            painter: _ScenePainter(
              groundY: groundY,
              mottoTop: mottoTop,
              dark: Theme.of(context).brightness == Brightness.dark,
              background: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
        ),
      );
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({required this.groundY, required this.mottoTop, required this.dark, required this.background});
  final double groundY;
  final double mottoTop;
  final bool dark;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final full = Offset.zero & size;
    final g = h - groundY;
    // Everything fades out at the bottom so the scene melts into the page.
    canvas.saveLayer(full, Paint());

    // Sky: lavender at the top melting into a peach sunrise, then into the page.
    canvas.drawRect(
      full,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [const Color(0xFF1C1534), const Color(0xFF2A1C45), background.withValues(alpha: 0)]
              : [const Color(0xFFE9E2FB), const Color(0xFFF6E6F2), background.withValues(alpha: 0)],
          stops: const [0, 0.62, 1],
        ).createShader(full),
    );
    void glow(Offset c, double r, Color color) => canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader =
                RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)),
        );
    final sun = Offset(w * 0.76, g - 96);
    glow(sun, w * 0.5, dark ? const Color(0x556B3BEA) : const Color(0xCCFFD9C4));
    glow(sun, w * 0.18, dark ? const Color(0x66CB7EEF) : const Color(0xFFFFEBD9));
    glow(Offset(w * 0.08, h * 0.12), w * 0.5, dark ? const Color(0x22CB7EEF) : const Color(0x55DCCBFA));

    // Far ridges.
    Paint ridge(Color top, Color bottom) => Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom])
          .createShader(Rect.fromLTWH(0, g - 150, w, 190));
    final far = Path()
      ..moveTo(w * 0.28, g + 10)
      ..cubicTo(w * 0.4, g - 60, w * 0.48, g - 92, w * 0.56, g - 104)
      ..cubicTo(w * 0.62, g - 112, w * 0.66, g - 92, w * 0.72, g - 98)
      ..cubicTo(w * 0.8, g - 108, w * 0.86, g - 134, w * 0.94, g - 126)
      ..cubicTo(w * 0.98, g - 122, w, g - 116, w + 2, g - 112)
      ..lineTo(w + 2, g + 10)
      ..close();
    canvas.drawPath(
        far,
        ridge(dark ? const Color(0xFF3D2C66) : const Color(0xFFD3C3F2),
            dark ? const Color(0x003D2C66) : const Color(0x00D3C3F2)));
    final mid = Path()
      ..moveTo(w * 0.36, g + 10)
      ..cubicTo(w * 0.46, g - 40, w * 0.54, g - 66, w * 0.6, g - 70)
      ..cubicTo(w * 0.66, g - 74, w * 0.7, g - 56, w * 0.76, g - 60)
      ..cubicTo(w * 0.84, g - 66, w * 0.9, g - 84, w + 2, g - 74)
      ..lineTo(w + 2, g + 10)
      ..close();
    canvas.drawPath(
        mid,
        ridge(dark ? const Color(0xFF4A3478) : const Color(0xFFBDA6EC),
            dark ? const Color(0x204A3478) : const Color(0x40BDA6EC)));

    // Pines along the far right ridge.
    final pine = Paint()..color = dark ? const Color(0xFF2A1E48) : const Color(0xFF8F78C8).withValues(alpha: 0.7);
    for (final (x, y, s) in const [(0.9, -78.0, 1.0), (0.94, -74.0, 1.3), (0.97, -76.0, 0.9), (0.86, -70.0, 0.8)]) {
      final px = w * x, py = g + y;
      canvas.drawPath(
        Path()
          ..moveTo(px, py - 16 * s)
          ..lineTo(px + 5 * s, py)
          ..lineTo(px - 5 * s, py)
          ..close(),
        pine,
      );
    }

    // Rocky outcrop (dark) the hiker sits on; its foot disappears behind the hero.
    final rockTop = g - 58;
    final rock = Path()
      ..moveTo(w * 0.5, g + 40)
      ..cubicTo(w * 0.56, g - 10, w * 0.6, rockTop + 8, w * 0.64, rockTop + 2)
      ..lineTo(w * 0.7, rockTop - 2)
      ..cubicTo(w * 0.74, rockTop - 2, w * 0.77, rockTop + 4, w * 0.8, rockTop + 14)
      ..cubicTo(w * 0.86, rockTop + 26, w * 0.93, rockTop + 34, w + 2, rockTop + 30)
      ..lineTo(w + 2, g + 40)
      ..close();
    canvas.drawPath(
      rock,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark ? const [Color(0xFF2B1F4D), Color(0xFF120B26)] : const [Color(0xFF55408C), Color(0xFF2C1F57)],
        ).createShader(Rect.fromLTWH(0, rockTop, w, g + 40 - rockTop)),
    );
    // Sunlit rim along the rock.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.64, rockTop + 2)
        ..lineTo(w * 0.7, rockTop - 2)
        ..cubicTo(w * 0.74, rockTop - 2, w * 0.77, rockTop + 4, w * 0.8, rockTop + 14)
        ..cubicTo(w * 0.86, rockTop + 26, w * 0.93, rockTop + 34, w + 2, rockTop + 30),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = dark ? const Color(0x66CB7EEF) : const Color(0xCCFFC9A8),
    );

    _hiker(canvas, Offset(w * 0.7, rockTop - 1), (w / 412).clamp(0.8, 1.3));
    _motto(canvas, Offset(w * 0.8, mottoTop), (w / 412).clamp(0.85, 1.2));
    final fade = Rect.fromLTWH(0, h - 90, w, 90);
    canvas.drawRect(
      fade,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Color(0x00000000)],
        ).createShader(fade),
    );
    canvas.restore();
  }

  /// A hiker seated on the edge, facing the sunrise (to the right).
  void _hiker(Canvas canvas, Offset seat, double k) {
    canvas.save();
    canvas.translate(seat.dx, seat.dy);
    canvas.scale(k);
    final jacket = Paint()..color = dark ? const Color(0xFF3B4C86) : const Color(0xFF2B3D72);
    final jeans = Paint()..color = dark ? const Color(0xFF2E3A66) : const Color(0xFF3B4E86);
    final skin = Paint()..color = const Color(0xFFC98E6E);
    final hair = Paint()..color = const Color(0xFF1C1726);
    final pack = Paint()..color = dark ? const Color(0xFF1E2238) : const Color(0xFF242A44);
    Paint limb(Paint p, double width) => Paint.from(p)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Legs: thigh forward, shin dangling over the edge.
    canvas.drawPath(
      Path()
        ..moveTo(0, -6)
        ..lineTo(17, -7)
        ..lineTo(21, 9),
      limb(jeans, 7.5),
    );
    canvas.drawOval(Rect.fromCenter(center: const Offset(23, 12), width: 10, height: 5), Paint()..color = const Color(0xFFEDEBF4));
    // Backpack.
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-17, -34, 13, 24), const Radius.circular(5)), pack);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-16, -36, 11, 8), const Radius.circular(4)),
        Paint()..color = const Color(0xFF353C5C));
    // Torso.
    canvas.drawPath(
      Path()
        ..moveTo(-6, -36)
        ..quadraticBezierTo(4, -38, 6, -30)
        ..lineTo(5, -6)
        ..lineTo(-6, -5)
        ..close(),
      jacket,
    );
    // Arm resting on the knee.
    canvas.drawPath(
      Path()
        ..moveTo(1, -31)
        ..quadraticBezierTo(8, -20, 15, -10),
      limb(jacket, 5.5),
    );
    canvas.drawCircle(const Offset(15.5, -9.5), 2.6, skin);
    // Head and hair.
    canvas.drawCircle(const Offset(2, -43), 6.3, skin);
    canvas.drawPath(
      Path()
        ..moveTo(-4.6, -43)
        ..cubicTo(-5.4, -51, 3, -53, 7.6, -46.5)
        ..quadraticBezierTo(3, -47.5, 0.5, -45.5)
        ..quadraticBezierTo(-1.4, -43, -4.6, -41)
        ..close(),
      hair,
    );
    canvas.restore();
  }

  /// Hand-lettered "Track / Earn / Grow" with a violet swoosh.
  void _motto(Canvas canvas, Offset at, double k) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(-0.2);
    canvas.scale(k);
    final ink = dark ? const Color(0xFFE9DDFB) : const Color(0xFF2E2350);
    var y = 0.0;
    for (final (i, word) in const ['Track', 'Earn', 'Grow'].indexed) {
      final tp = TextPainter(
        text: TextSpan(
          text: word,
          style: TextStyle(
            fontFamily: AppType.family,
            fontStyle: FontStyle.italic,
            fontSize: 17,
            fontWeight: FontWeight.w500,
            fontVariations: const [FontVariation('wght', 500)],
            color: ink,
            letterSpacing: 0.3,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(i * 6.0, y));
      y += tp.height + 2;
    }
    final swoosh = Path()
      ..moveTo(4, y + 3)
      ..cubicTo(18, y + 1, 34, y - 2, 56, y - 6);
    canvas.drawPath(
      swoosh,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(colors: [AppColors.violet, AppColors.lavender])
            .createShader(Rect.fromLTWH(0, y - 8, 60, 12)),
    );
    canvas.restore();
    // Tiny sparkles near the motto.
    final spark = Paint()..color = (dark ? AppColors.lavenderOnDark : AppColors.violet).withValues(alpha: 0.5);
    for (final (dx, dy, r) in const [(-14.0, 6.0, 1.6), (66.0, 4.0, 1.3), (60.0, 58.0, 1.1)]) {
      canvas.drawCircle(at + Offset(dx, dy) * k, r, spark);
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.groundY != groundY || old.mottoTop != mottoTop || old.dark != dark || old.background != background;
}
