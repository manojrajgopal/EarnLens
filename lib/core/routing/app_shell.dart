import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/presentation/account_gate.dart';
import '../../shared/layout/page_layout.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'floating_nav_bar.dart';

// Shell destinations. Branch indices follow the StatefulShellRoute order
// (0 Home, 1 Income, 2 Calendar, 3 Analytics, 4 Settings).
const _home = NavDestination(0, 'Home', NavGlyph.home, Icons.home_outlined, Icons.home_rounded);
const _income = NavDestination(
    1, 'Income', NavGlyph.income, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded);
const _calendar =
    NavDestination(2, 'Calendar', NavGlyph.calendar, Icons.calendar_month_outlined, Icons.calendar_month_rounded);
const _analytics = NavDestination(3, 'Analytics', NavGlyph.analytics, Icons.insights_outlined, Icons.insights_rounded);
const _settings = NavDestination(4, 'Settings', NavGlyph.settings, Icons.settings_outlined, Icons.settings_rounded);

/// Visual order on phones: Home sits at the exact centre, the other four
/// symmetrically around it.
const _barItems = [_income, _calendar, _home, _analytics, _settings];

/// Rail order on tablets/web follows branch order.
const _railItems = [_home, _income, _calendar, _analytics, _settings];

/// App shell: floating icons-only navigation with a travelling selection orb
/// on phones; a navigation rail on wide screens (tablets, desktop web).
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
      child: EarnBackdrop(child: AccountGate(child: shell)),
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
      bottomNavigationBar: FloatingNavBar(destinations: _barItems, current: shell.currentIndex, onSelect: _go),
    );
  }
}

/// The EarnLens brand mark — the supplied app icon artwork
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
