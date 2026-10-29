import 'package:earnlens/core/routing/floating_nav_bar.dart';
import 'package:earnlens/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Same visual order as the app shell: Home in the centre.
const _items = [
  NavDestination(1, 'Income', NavGlyph.income, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded),
  NavDestination(2, 'Calendar', NavGlyph.calendar, Icons.calendar_month_outlined, Icons.calendar_month_rounded),
  NavDestination(0, 'Home', NavGlyph.home, Icons.home_outlined, Icons.home_rounded),
  NavDestination(3, 'Analytics', NavGlyph.analytics, Icons.insights_outlined, Icons.insights_rounded),
  NavDestination(4, 'Settings', NavGlyph.settings, Icons.settings_outlined, Icons.settings_rounded),
];

/// Hosts the bar with a single source of truth for the selected branch, like
/// the shell does.
class _Host extends StatefulWidget {
  const _Host({this.reduceMotion = false});
  final bool reduceMotion;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int current = 0;

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: widget.reduceMotion),
            child: Scaffold(
              extendBody: true,
              body: Center(child: Text('branch $current')),
              bottomNavigationBar: FloatingNavBar(
                destinations: _items,
                current: current,
                onSelect: (b) => setState(() => current = b),
              ),
            ),
          ),
        ),
      );
}

void main() {
  FloatingNavBarState nav(WidgetTester t) => t.state<FloatingNavBarState>(find.byType(FloatingNavBar));
  Rect iconRect(WidgetTester t, String label) => t.getRect(find.bySemanticsLabel(label).last);

  /// Orb centre in global coordinates, from the measured bar width.
  double orbX(WidgetTester t) {
    final bar = t.getRect(find.byType(LayoutBuilder).last);
    return bar.left + (nav(t).orbPosition + 0.5) * bar.width / _items.length;
  }

  for (final size in const [Size(320, 640), Size(393, 852), Size(820, 1180)]) {
    testWidgets('Home is centred by default and the orb reaches every icon at ${size.width.round()}px', (tester) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const _Host());
      await tester.pumpAndSettle();

      final bar = tester.getRect(find.byType(LayoutBuilder).last);
      expect(iconRect(tester, 'Home').center.dx, moreOrLessEquals(bar.center.dx, epsilon: 0.5));
      expect(nav(tester).orbPosition, 2);
      expect(orbX(tester), moreOrLessEquals(bar.center.dx, epsilon: 0.5));
      // The bar floats above the system gesture area.
      expect(bar.bottom, lessThanOrEqualTo(size.height - 34));
      expect(find.text('Home'), findsNothing, reason: 'icons only — no visible labels');

      for (final (slot, d) in _items.indexed) {
        await tester.tap(find.bySemanticsLabel(d.label).last);
        await tester.pumpAndSettle();
        expect(find.text('branch ${d.branch}'), findsOneWidget);
        expect(nav(tester).orbPosition, moreOrLessEquals(slot.toDouble(), epsilon: 0.001));
        expect(orbX(tester), moreOrLessEquals(iconRect(tester, d.label).center.dx, epsilon: 0.5),
            reason: '${d.label} icon sits centred in the orb');
      }
    });
  }

  testWidgets('rapid switching moves the orb continuously and lands on the last tap', (tester) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();

    final samples = <double>[nav(tester).orbPosition];
    for (final label in ['Income', 'Settings', 'Calendar', 'Analytics', 'Home', 'Settings']) {
      await tester.tap(find.bySemanticsLabel(label).last);
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        samples.add(nav(tester).orbPosition);
      }
    }
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      samples.add(nav(tester).orbPosition);
    }
    await tester.pumpAndSettle();

    for (var i = 1; i < samples.length; i++) {
      expect((samples[i] - samples[i - 1]).abs(), lessThan(0.6), reason: 'no jumps between frames');
    }
    expect(samples.every((p) => p > -0.4 && p < 4.4), isTrue, reason: 'orb stays inside the bar');
    expect(nav(tester).orbPosition, moreOrLessEquals(4, epsilon: 0.001));
    expect(find.text('branch 4'), findsOneWidget);
  });

  testWidgets('reduced motion moves the orb without animating', (tester) async {
    await tester.pumpWidget(const _Host(reduceMotion: true));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Settings').last);
    await tester.pump();
    // Already at its destination after a single frame.
    expect(nav(tester).orbPosition, 4);
  });
}
