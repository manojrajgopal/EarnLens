import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../shared/layout/page_layout.dart';
import '../../shared/widgets/organic.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// A shell destination. [branch] is the StatefulShellRoute branch index
/// (0 Home, 1 Income, 2 Calendar, 3 Insights, 4 Settings).
class _Dest {
  const _Dest(this.branch, this.label, this.icon, this.activeIcon);
  final int branch;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _home = _Dest(0, 'Home', Icons.home_outlined, Icons.home_rounded);
const _income = _Dest(1, 'Income', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded);
const _calendar = _Dest(2, 'Calendar', Icons.calendar_month_outlined, Icons.calendar_month_rounded);
const _insights = _Dest(3, 'Insights', Icons.insights_outlined, Icons.insights_rounded);
const _settings = _Dest(4, 'Settings', Icons.settings_outlined, Icons.settings_rounded);

/// Visual order on phones: the raised centre orb is Insights.
const _barItems = [_home, _income, _calendar, _settings];

/// Rail order on tablets/web follows branch order.
const _railItems = [_home, _income, _calendar, _insights, _settings];

/// App shell: floating capsule navigation with a raised Insights orb on
/// phones; a navigation rail on wide screens (tablets, desktop web).
///
/// Back navigation: inside a tab, back pops that tab's own stack (handled by
/// the branch navigator). At the root of any tab other than Home, back
/// returns to Home instead of leaving the app.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  void _go(int branch) {
    HapticFeedback.selectionClick();
    // Re-selecting the current tab returns it to its root.
    shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.rail;
    final body = PopScope(
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(0);
      },
      child: EarnBackdrop(child: shell),
    );

    if (wide) {
      final c = context.colors;
      return Scaffold(
        backgroundColor: c.background,
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: _railItems.indexWhere((d) => d.branch == shell.currentIndex),
                onDestinationSelected: (i) => _go(_railItems[i].branch),
                labelType: NavigationRailLabelType.all,
                minWidth: 92,
                groupAlignment: -0.85,
                backgroundColor: c.card,
                indicatorColor: c.accentSoft,
                selectedIconTheme: IconThemeData(color: c.accentText),
                selectedLabelTextStyle: AppType.label.copyWith(color: c.accentText, fontWeight: FontWeight.w700),
                leading: const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: EarnLensMark(size: 44)),
                destinations: [
                  for (final d in _railItems)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.activeIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
            ),
            VerticalDivider(width: 1, color: c.line),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      extendBody: true,
      backgroundColor: context.colors.background,
      body: body,
      bottomNavigationBar: FloatingNavBar(current: shell.currentIndex, onSelect: _go),
    );
  }
}

//// Floating organic navigation capsule: white, with a glowing rim and a
/// raised centre swell that cradles the purple Insights orb.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key, required this.current, required this.onSelect});
  final int current;
  final ValueChanged<int> onSelect;

  static const barHeight = 70.0;
  static const orbSize = 64.0;

  /// Height of the centre swell above the capsule (matches [BlobShapes.nav]).
  static const swell = 22.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < AppBreakpoints.compact;
    final side = compact ? 10.0 : 16.0;
    const shape = BlobBorder(BlobShapes.nav);
    return SafeArea(
      // Keeps the bar above the gesture handle / 3-button bar and clear of
      // landscape cutouts, with a small floating gap.
      minimum: EdgeInsets.fromLTRB(side, 0, side, 10),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          // Never stretch the capsule across large screens.
          constraints: const BoxConstraints(maxWidth: 520),
          child: SizedBox(
            height: barHeight + swell,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: shape,
                      color: c.navBar,
                      shadows: [
                        ...AppShadows.nav,
                        BoxShadow(color: c.accent.withValues(alpha: dark ? 0.12 : 0.28), blurRadius: 18, spreadRadius: -2),
                      ],
                    ),
                    child: CustomPaint(painter: _NavRimPainter(c.accent, dark)),
                  ),
                ),
                SizedBox(
                  height: barHeight,
                  child: Row(
                    children: [
                      for (final d in _barItems.take(2))
                        Expanded(child: _NavItem(d, active: current == d.branch, compact: compact, onTap: onSelect)),
                      const SizedBox(width: orbSize + 16),
                      for (final d in _barItems.skip(2))
                        Expanded(child: _NavItem(d, active: current == d.branch, compact: compact, onTap: onSelect)),
                    ],
                  ),
                ),
                Positioned(
                  top: 2,
                  child: _Orb(active: current == _insights.branch, onTap: () => onSelect(_insights.branch)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft lavender glow along the capsule edge, brightest at the swell.
class _NavRimPainter extends CustomPainter {
  _NavRimPainter(this.accent, this.dark);
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
          accent.withValues(alpha: 0.5),
          accent.withValues(alpha: 0.12),
          accent.withValues(alpha: 0.7),
          accent.withValues(alpha: 0.12),
          accent.withValues(alpha: 0.5),
        ], stops: const [0, 0.3, 0.5, 0.7, 1])
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
            colors: [accent.withValues(alpha: 0.08), accent.withValues(alpha: 0)],
          ).createShader(top),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_NavRimPainter old) => old.accent != accent || old.dark != dark;
}

class _NavItem extends StatelessWidget {
  const _NavItem(this.dest, {required this.active, required this.compact, required this.onTap});
  final _Dest dest;
  final bool active;
  final bool compact;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final duration = reduce ? Duration.zero : AppDurations.medium;
    final color = active ? c.accentText : c.navBarInk.withValues(alpha: 0.78);
    return Semantics(
      selected: active,
      button: true,
      label: dest.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => onTap(dest.branch),
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: duration,
              curve: AppCurves.emphasized,
              width: active ? 56 : 40,
              height: 32,
              decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                gradient: active ? LinearGradient(colors: [c.accentSoft, Color.lerp(c.accentSoft, c.accent, 0.35)!]) : null,
                shadows: active ? [BoxShadow(color: c.accent.withValues(alpha: 0.35), blurRadius: 12)] : null,
              ),
              child: AnimatedScale(
                duration: duration,
                curve: AppCurves.overshoot,
                scale: active ? 1.08 : 1.0,
                child: Icon(active ? dest.activeIcon : dest.icon, size: AppIconSize.md, color: color),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: duration,
              style: AppType.caption.copyWith(
                color: color,
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(dest.label, maxLines: 1, overflow: TextOverflow.clip, softWrap: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final c = context.colors;
    return Semantics(
      selected: active,
      button: true,
      label: _insights.label,
      excludeSemantics: true,
      child: Tooltip(
        message: _insights.label,
        child: AnimatedScale(
          duration: reduce ? Duration.zero : AppDurations.slow,
          curve: AppCurves.overshoot,
          scale: active ? 1.06 : 1.0,
          child: Container(
            width: FloatingNavBar.orbSize,
            height: FloatingNavBar.orbSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.35, -0.45),
                radius: 1.0,
                colors: [Color(0xFFB57CF6), Color(0xFF7B45EE), Color(0xFF4E22C9)],
                stops: [0, 0.55, 1],
              ),
              boxShadow: [
                const BoxShadow(color: Color(0x666B3BEA), blurRadius: 22, offset: Offset(0, 10)),
                BoxShadow(color: c.accent.withValues(alpha: active ? 0.7 : 0.4), blurRadius: 16, spreadRadius: 1),
              ],
              border: Border.all(color: c.navBar, width: 4),
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Icon(
                  active ? _insights.activeIcon : Icons.bar_chart_rounded,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// The EarnLens brand mark — the supplied app icon artwork
/// (`assets/images/earnlens_mark.png`, cropped from earnlens_app_icon.png).
class EarnLensMark extends StatelessWidget {
  const EarnLensMark({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'EarnLens',
    image: true,
    child: Image.asset(
      'assets/images/earnlens_mark.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
    ),
  );
}
