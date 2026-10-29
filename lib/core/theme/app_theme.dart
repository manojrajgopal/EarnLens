import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/widgets/organic.dart';
import 'tokens.dart';

/// Semantic colours not covered by [ColorScheme].
@immutable
class EarnColors extends ThemeExtension<EarnColors> {
  const EarnColors({
    required this.background,
    required this.card,
    required this.cardHigh,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.accent,
    required this.accentText,
    required this.accentSoft,
    required this.positive,
    required this.positiveSoft,
    required this.warning,
    required this.warningSoft,
    required this.overdue,
    required this.error,
    required this.errorSoft,
    required this.navBar,
    required this.navBarInk,
  });

  final Color background;
  final Color card;
  final Color cardHigh;
  final Color ink;
  final Color inkMuted;
  final Color line;
  final Color accent;

  /// Accent usable as text on [card] with AA contrast.
  final Color accentText;
  final Color accentSoft;
  final Color positive;
  final Color positiveSoft;
  final Color warning;
  final Color warningSoft;
  final Color overdue;
  final Color error;
  final Color errorSoft;
  final Color navBar;
  final Color navBarInk;

  static const light = EarnColors(
    background: AppColors.pageLight,
    card: AppColors.white,
    cardHigh: Color(0xFFF6F2FC),
    ink: AppColors.ink,
    inkMuted: AppColors.inkMuted,
    line: Color(0xFFECE7F4),
    accent: AppColors.lavender,
    accentText: AppColors.violet,
    accentSoft: AppColors.lilacSoft,
    positive: AppColors.positive,
    positiveSoft: AppColors.positiveSoft,
    warning: AppColors.warning,
    warningSoft: AppColors.warningSoft,
    overdue: AppColors.overdue,
    error: AppColors.error,
    errorSoft: AppColors.errorSoft,
    navBar: AppColors.white,
    navBarInk: AppColors.ink,
  );

  static const dark = EarnColors(
    background: AppColors.darkBackground,
    card: AppColors.darkSurface,
    cardHigh: AppColors.darkSurfaceHigh,
    ink: Color(0xFFF4F4F6),
    inkMuted: AppColors.darkInkMuted,
    line: AppColors.darkLine,
    accent: AppColors.lavender,
    accentText: AppColors.lavenderOnDark,
    accentSoft: Color(0xFF3A2547),
    positive: Color(0xFF5CCB94),
    positiveSoft: Color(0xFF173A2A),
    warning: Color(0xFFF2B36B),
    warningSoft: Color(0xFF3D2B12),
    overdue: Color(0xFFFF8A5C),
    error: Color(0xFFFF8A80),
    errorSoft: Color(0xFF3F1D1B),
    navBar: AppColors.darkSurfaceHigh,
    navBarInk: AppColors.white,
  );

  @override
  EarnColors copyWith() => this;

  @override
  EarnColors lerp(ThemeExtension<EarnColors>? other, double t) {
    if (other is! EarnColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return EarnColors(
      background: l(background, other.background),
      card: l(card, other.card),
      cardHigh: l(cardHigh, other.cardHigh),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      line: l(line, other.line),
      accent: l(accent, other.accent),
      accentText: l(accentText, other.accentText),
      accentSoft: l(accentSoft, other.accentSoft),
      positive: l(positive, other.positive),
      positiveSoft: l(positiveSoft, other.positiveSoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      overdue: l(overdue, other.overdue),
      error: l(error, other.error),
      errorSoft: l(errorSoft, other.errorSoft),
      navBar: l(navBar, other.navBar),
      navBarInk: l(navBarInk, other.navBarInk),
    );
  }
}

extension EarnThemeX on BuildContext {
  /// Brand colours; falls back to the default palette when a widget is used
  /// under a theme without the extension (dialogs from packages, tests).
  EarnColors get colors {
    final theme = Theme.of(this);
    return theme.extension<EarnColors>() ??
        (theme.brightness == Brightness.dark ? EarnColors.dark : EarnColors.light);
  }
  TextTheme get text => Theme.of(this).textTheme;
}

/// Edge-to-edge system bars: transparent, with icon contrast matching the
/// theme. Content handles insets through MediaQuery padding.
SystemUiOverlayStyle systemBarsFor(Brightness b) {
  final darkIcons = b == Brightness.light;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    statusBarIconBrightness: darkIcons ? Brightness.dark : Brightness.light,
    statusBarBrightness: b, // iOS
    systemNavigationBarIconBrightness: darkIcons ? Brightness.dark : Brightness.light,
  );
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, EarnColors.light);
  static ThemeData dark() => _build(Brightness.dark, EarnColors.dark);

  static ThemeData _build(Brightness brightness, EarnColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: AppColors.black,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.ink,
      secondary: c.ink,
      onSecondary: c.card,
      surface: c.card,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.background,
      surfaceContainer: c.card,
      surfaceContainerHigh: c.cardHigh,
      surfaceContainerHighest: c.cardHigh,
      outline: c.line,
      outlineVariant: c.line,
      error: c.error,
      onError: AppColors.white,
    );

    final textTheme = TextTheme(
      displayLarge: AppType.displayLight,
      displayMedium: AppType.amountHero,
      displaySmall: AppType.amountLarge,
      headlineMedium: AppType.headlineLight,
      headlineSmall: AppType.amountMedium,
      titleLarge: AppType.title,
      titleMedium: AppType.section,
      titleSmall: AppType.label,
      bodyLarge: AppType.body,
      bodyMedium: AppType.body,
      bodySmall: AppType.bodySmall,
      labelLarge: AppType.button,
      labelMedium: AppType.label,
      labelSmall: AppType.caption,
    ).apply(bodyColor: c.ink, displayColor: c.ink);

    final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      fontFamily: AppType.family,
      textTheme: textTheme,
      extensions: [c],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppType.title.copyWith(color: c.ink, fontWeight: FontWeight.w700),
        systemOverlayStyle: systemBarsFor(brightness),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: BlobBorder(BlobShapes.cloud(1)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brightness == Brightness.dark ? c.accent : AppColors.violet,
          foregroundColor: brightness == Brightness.dark ? AppColors.black : AppColors.white,
          disabledBackgroundColor: c.line,
          minimumSize: const Size(64, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: AppType.button,
          shape: pill,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: AppColors.black,
          elevation: 0,
          minimumSize: const Size(64, 54),
          textStyle: AppType.button,
          shape: pill,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.line, width: 1.2),
          minimumSize: const Size(64, 50),
          textStyle: AppType.button,
          shape: pill,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.accentText, textStyle: AppType.button, shape: pill),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.card,
        selectedColor: c.accentSoft,
        side: BorderSide(color: c.line),
        labelStyle: AppType.label.copyWith(color: c.ink),
        secondaryLabelStyle: AppType.label.copyWith(color: c.accentText, fontWeight: FontWeight.w700),
        shape: pill,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: AppType.label.copyWith(color: c.inkMuted),
        floatingLabelStyle: AppType.label.copyWith(color: c.accentText),
        helperStyle: AppType.bodySmall.copyWith(color: c.inkMuted),
        helperMaxLines: 3,
        errorMaxLines: 3,
        errorStyle: AppType.bodySmall.copyWith(color: c.error),
        border: BlobInputBorder(borderSide: BorderSide(color: c.line, width: 1.2)),
        enabledBorder: BlobInputBorder(borderSide: BorderSide(color: c.accent.withValues(alpha: 0.28), width: 1.2)),
        focusedBorder: BlobInputBorder(borderSide: BorderSide(color: c.accent, width: 2)),
        errorBorder: BlobInputBorder(borderSide: BorderSide(color: c.error, width: 1.2)),
        focusedErrorBorder: BlobInputBorder(borderSide: BorderSide(color: c.error, width: 2)),
        disabledBorder: BlobInputBorder(borderSide: BorderSide(color: c.line)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.white : null),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.accent : null),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(pill),
          backgroundColor:
              WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.accentSoft : c.card),
          foregroundColor:
              WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.accentText : c.ink),
          side: WidgetStatePropertyAll(BorderSide(color: c.line)),
          textStyle: WidgetStatePropertyAll(AppType.label),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.accent.withValues(alpha: 0.5),
        dragHandleSize: const Size(44, 5),
        modalBarrierColor: AppColors.violetNight.withValues(alpha: 0.35),
        shape: const BlobBorder(BlobShapes.sheet),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        barrierColor: AppColors.violetNight.withValues(alpha: 0.35),
        shape: const BlobBorder(BlobShapes.dialog),
        titleTextStyle: AppType.title.copyWith(color: c.ink, fontWeight: FontWeight.w700),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: c.accentText,
        textColor: c.ink,
        collapsedIconColor: c.inkMuted,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.violetNight,
        contentTextStyle: AppType.label.copyWith(color: AppColors.white),
        actionTextColor: AppColors.lavender,
        shape: BlobBorder(BlobShapes.chip(4)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.ink,
        titleTextStyle: AppType.label.copyWith(color: c.ink, fontSize: 15),
        subtitleTextStyle: AppType.bodySmall.copyWith(color: c.inkMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      popupMenuTheme: PopupMenuThemeData(
        color: c.card,
        surfaceTintColor: Colors.transparent,
        shape: BlobBorder(BlobShapes.cloud(9, radius: 22, wobble: 0.4)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        shape: const BlobBorder(BlobShapes.dialog),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: c.card,
        shape: const BlobBorder(BlobShapes.dialog),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent, linearTrackColor: c.accentSoft),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.card,
        indicatorColor: c.accent,
        selectedIconTheme: const IconThemeData(color: AppColors.black),
        unselectedIconTheme: IconThemeData(color: c.inkMuted),
        selectedLabelTextStyle: AppType.label.copyWith(color: c.ink),
        unselectedLabelTextStyle: AppType.label.copyWith(color: c.inkMuted),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
