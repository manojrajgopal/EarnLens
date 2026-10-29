import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../widgets/earnlens_refresh_indicator.dart';

/// Application-level safe-area strategy
/// ------------------------------------
/// * The app renders edge-to-edge; system bars are transparent.
/// * Top insets (status bar, notch, punch-hole) are handled by [AppBar] or by
///   [SafeArea] on screens without an app bar.
/// * The shell's [Scaffold] uses `extendBody`, so Flutter reports the floating
///   navigation bar's real height — including the system gesture/button area —
///   as bottom [MediaQuery] padding to every screen in the shell. Pages derive
///   their bottom clearance from that value instead of hardcoding it.
/// * Left/right insets (landscape cutouts) are added to the gutters.
abstract final class AppInsets {
  /// Horizontal gutter for the current width.
  static double gutter(double width) => width < AppBreakpoints.compact ? 16 : AppSpace.gutter;

  /// Bottom space so the last item clears the floating nav / system bar.
  static double bottomClearance(BuildContext context) => MediaQuery.paddingOf(context).bottom + AppSpace.xl;

  /// Padding for a scrollable page whose content is centred at [maxWidth].
  static EdgeInsets page(BuildContext context, double width, {double maxWidth = AppBreakpoints.contentMax, double top = AppSpace.sm}) {
    final pad = MediaQuery.paddingOf(context);
    final side = math.max(gutter(width), (width - maxWidth) / 2);
    return EdgeInsets.fromLTRB(
      side + pad.left,
      top,
      side + pad.right,
      bottomClearance(context),
    );
  }
}

/// The standard scrollable page body.
///
/// The scroll view spans the full width (so pull-to-refresh and scrolling work
/// anywhere on screen) while content is centred at [maxWidth]. Pass
/// [onRefresh] to enable the branded pull-to-refresh.
class EarnPageList extends StatelessWidget {
  const EarnPageList({
    super.key,
    required this.children,
    this.onRefresh,
    this.maxWidth = AppBreakpoints.contentMax,
    this.top = AppSpace.sm,
    this.extraBottom = 0,
    this.refreshEdgeOffset = 0,
    this.controller,
  });

  /// Offset for the refresh indicator on screens without an app bar (e.g. the
  /// status-bar height) so it appears below the system bar.
  final double refreshEdgeOffset;

  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final double maxWidth;
  final double top;

  /// Additional bottom space, e.g. for a floating action pill above the nav.
  final double extraBottom;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final list = ListView(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppInsets.page(context, constraints.maxWidth, maxWidth: maxWidth, top: top)
              .copyWith(bottom: AppInsets.bottomClearance(context) + extraBottom),
          children: children,
        );
        return onRefresh == null
            ? list
            : EarnLensRefreshIndicator(onRefresh: onRefresh!, edgeOffset: refreshEdgeOffset, child: list);
      });
}

/// Soft lavender glows painted behind the main tab screens (reference-style
/// atmosphere) without affecting layout or readability.
class EarnBackdrop extends StatelessWidget {
  const EarnBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      child: Stack(children: [
        Positioned(
          top: -160,
          right: -120,
          child: _Glow(size: 420, color: AppColors.lavender.withValues(alpha: dark ? 0.22 : 0.28)),
        ),
        Positioned(
          top: 120,
          left: -180,
          child: _Glow(size: 380, color: AppColors.sky.withValues(alpha: dark ? 0.08 : 0.12)),
        ),
        Positioned.fill(child: child),
      ]),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
          ),
        ),
      );
}
