import 'package:flutter/material.dart';

/// EarnLens design tokens. Core palette is fixed by the brand brief:
/// lavender #CB7EEF, white, black and light grey #F3F3F3.
abstract final class AppColors {
  static const lavender = Color(0xFFCB7EEF);
  static const lavenderDeep = Color(0xFF8E3FBF); // text/icons on light surfaces (AA contrast)
  static const lavenderSoft = Color(0xFFF1E1FA);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const background = Color(0xFFF3F3F3);

  // Secondary, accessible support colours.
  static const ink = Color(0xFF111111);
  static const inkMuted = Color(0xFF6B6B70);
  static const line = Color(0xFFE6E6EA);
  static const positive = Color(0xFF1F8A5B);
  static const positiveSoft = Color(0xFFE2F4EA);
  static const warning = Color(0xFFB86E00);
  static const warningSoft = Color(0xFFFFF1DC);
  static const overdue = Color(0xFFC2410C);
  static const error = Color(0xFFB3261E);
  static const errorSoft = Color(0xFFFBE4E2);
  static const disabled = Color(0xFFBDBDC2);

  // Coordinated purple tones for emphasis, gradients and active states.
  static const violet = Color(0xFF6B3BEA);
  static const violetDeep = Color(0xFF3F1D9C);
  static const violetNight = Color(0xFF241056);
  static const orchid = Color(0xFFA35CF2);
  static const blush = Color(0xFFF3D9FB);

  /// Tinted page background used behind cards (lavender-white).
  static const pageLight = Color(0xFFF6F4FB);

  // Pastel accents for quick actions and rate tiles.
  static const peach = Color(0xFFFF9A5A);
  static const peachSoft = Color(0xFFFFE6D6);
  static const mint = Color(0xFF2FBF8A);
  static const mintSoft = Color(0xFFDDF6EA);
  static const sky = Color(0xFF3D8BF2);
  static const skySoft = Color(0xFFDDEBFF);
  static const lilacSoft = Color(0xFFEFE2FC);

  // Dark theme.
  static const darkBackground = Color(0xFF0E0C14);
  static const darkSurface = Color(0xFF1A1724);
  static const darkSurfaceHigh = Color(0xFF26222F);
  static const darkLine = Color(0xFF353041);
  static const darkInkMuted = Color(0xFFA8A3B5);
  static const lavenderOnDark = Color(0xFFDDA6F5);

  /// Chart / source series colours, lavender first.
  static const series = [
    Color(0xFFCB7EEF),
    Color(0xFF6B3BEA),
    Color(0xFF6FB7A8),
    Color(0xFFF2B36B),
    Color(0xFF7A9CF0),
    Color(0xFFE48AA6),
    Color(0xFFA7A7AE),
    Color(0xFF9BC46A),
  ];

  static Color seriesAt(int i) => series[i % series.length];
}

abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const gutter = 20.0;
}

abstract final class AppRadius {
  static const sm = 12.0;
  static const md = 20.0;
  static const lg = 28.0;
  static const xl = 36.0;
  static const pill = 999.0;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 420);
  static const chart = Duration(milliseconds: 600);
  static const entrance = Duration(milliseconds: 520);
}

/// Motion curves. Springs are used for direct-manipulation feedback
/// (pull-to-refresh, navigation pill); eased curves for entrances.
abstract final class AppCurves {
  static const emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const decelerate = Curves.easeOutCubic;
  static const standard = Curves.easeInOutCubic;
  static const overshoot = Curves.easeOutBack;

  /// Critically-damped-ish spring for settling indicators.
  static const spring = SpringDescription(mass: 1, stiffness: 420, damping: 32);
}

abstract final class AppIconSize {
  static const sm = 18.0;
  static const md = 22.0;
  static const lg = 26.0;
  static const badge = 44.0;
}

/// Width breakpoints (logical pixels).
abstract final class AppBreakpoints {
  /// Below this, compact phone tweaks apply (tighter gutters, 2-up tiles).
  static const compact = 360.0;

  /// Navigation rail instead of the floating bar.
  static const rail = 840.0;

  /// Multi-column dashboards.
  static const twoColumn = 700.0;
  static const threeColumn = 1100.0;

  /// Readable max width for single-column content.
  static const contentMax = 720.0;
  static const wideMax = 1280.0;
}

abstract final class AppGradients {
  /// Hero earnings card.
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B2BE0), Color(0xFF8A4CF0), Color(0xFFCB7EEF)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Deep night card (expected vs actual).
  static const night = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A1366), Color(0xFF3F1D9C), Color(0xFF6B3BEA)],
  );

  /// Progress bars (sky → lavender → orchid).
  static const progress = LinearGradient(colors: [Color(0xFF7BD3F7), Color(0xFFCB7EEF), Color(0xFFE58BF2)]);

  /// Raised central navigation button.
  static const orb = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA35CF2), Color(0xFF6B3BEA)],
  );

  /// Pull-to-refresh glow.
  static RadialGradient glow(double opacity) => RadialGradient(
        colors: [AppColors.lavender.withValues(alpha: 0.55 * opacity), AppColors.lavender.withValues(alpha: 0)],
      );
}

abstract final class AppShadows {
  /// Soft lavender-tinted elevation for cards on light backgrounds.
  static List<BoxShadow> card(Brightness b) => b == Brightness.dark
      ? const [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10))]
      : const [
          BoxShadow(color: Color(0x146B3BEA), blurRadius: 30, offset: Offset(0, 12)),
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ];

  /// Glow under purple surfaces (hero, active nav item, central orb).
  static const glow = [BoxShadow(color: Color(0x406B3BEA), blurRadius: 32, offset: Offset(0, 14))];

  static const nav = [
    BoxShadow(color: Color(0x1F6B3BEA), blurRadius: 40, offset: Offset(0, 14)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 3)),
  ];
}

/// Typography tokens. Urbanist is a variable font: weights are applied via
/// both [FontWeight] and the `wght` axis so every renderer picks them up.
abstract final class AppType {
  static const family = 'Urbanist';

  static TextStyle _s(double size, int weight, {double height = 1.2, double spacing = 0}) => TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: FontWeight.values[(weight ~/ 100) - 1],
        fontVariations: [FontVariation('wght', weight.toDouble())],
        height: height,
        letterSpacing: spacing,
      );

  /// Light display headings ("Your earnings, clearly.").
  static final displayLight = _s(40, 300, height: 1.05, spacing: -1);
  static final headlineLight = _s(30, 300, height: 1.1, spacing: -0.5);

  /// Big financial figures.
  static final amountHero = _s(44, 700, height: 1.0, spacing: -1.2);
  static final amountLarge = _s(30, 700, height: 1.05, spacing: -0.6);
  static final amountMedium = _s(22, 700, height: 1.1, spacing: -0.3);

  static final title = _s(20, 600, height: 1.2);
  static final section = _s(17, 600, height: 1.25);
  static final label = _s(14, 500, height: 1.3);
  static final body = _s(15, 400, height: 1.45);
  static final bodySmall = _s(13, 400, height: 1.4);
  static final caption = _s(12, 500, height: 1.3, spacing: 0.2);
  static final button = _s(15, 700, height: 1.2);
}
