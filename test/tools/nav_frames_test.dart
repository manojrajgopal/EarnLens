// Captures the floating navigation mid-animation (orb travelling, trail,
// icon flourishes) for visual review, in light and dark themes.
//
//   flutter test test/tools/nav_frames_test.dart --update-goldens --dart-define=SCREENSHOTS=true
//
// Writes PNGs to build/screens/nav/. Skipped in normal test runs.
import 'dart:io';

import 'package:earnlens/core/routing/floating_nav_bar.dart';
import 'package:earnlens/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _enabled = bool.fromEnvironment('SCREENSHOTS');

const _items = [
  NavDestination(1, 'Income', NavGlyph.income, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded),
  NavDestination(2, 'Calendar', NavGlyph.calendar, Icons.calendar_month_outlined, Icons.calendar_month_rounded),
  NavDestination(0, 'Home', NavGlyph.home, Icons.home_outlined, Icons.home_rounded),
  NavDestination(3, 'Analytics', NavGlyph.analytics, Icons.insights_outlined, Icons.insights_rounded),
  NavDestination(4, 'Settings', NavGlyph.settings, Icons.settings_outlined, Icons.settings_rounded),
];

class _Host extends StatefulWidget {
  const _Host({required this.dark});
  final bool dark;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int current = 0;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: widget.dark ? AppTheme.dark() : AppTheme.light(),
        home: Scaffold(
          extendBody: true,
          body: const SizedBox.expand(),
          bottomNavigationBar: FloatingNavBar(
            destinations: _items,
            current: current,
            onSelect: (b) => setState(() => current = b),
          ),
        ),
      );
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('nav frames ${dark ? 'dark' : 'light'}', skip: !_enabled, (tester) async {
      await tester.runAsync(() async {
        final root = Platform.environment['FLUTTER_ROOT'] ?? r'D:\flutter';
        final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
        await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)))).load();
      });
      tester.view.physicalSize = const Size(412, 140) * 3;
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(bottom: 24 * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_Host(dark: dark));
      await tester.pumpAndSettle();
      final dir = '../../build/screens/nav/${dark ? 'dark' : 'light'}';
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('$dir/00_home.png'));

      // Home → Settings (two slots right), sampled through the spring.
      await tester.tap(find.bySemanticsLabel('Settings').last);
      await tester.pump(); // The first frame after a tap starts the animation clock.
      var elapsed = 0;
      for (final ms in [60, 120, 200, 320, 900]) {
        await tester.pump(Duration(milliseconds: ms - elapsed));
        elapsed = ms;
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('$dir/settings_${ms}ms.png'));
      }
      // Settings → Income (full width), mid-flight and settled.
      await tester.tap(find.bySemanticsLabel('Income').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('$dir/income_140ms.png'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('$dir/income_settled.png'));
      // Analytics bars rising.
      await tester.tap(find.bySemanticsLabel('Analytics').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('$dir/analytics_260ms.png'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('$dir/analytics_settled.png'));
    });
  }
}
