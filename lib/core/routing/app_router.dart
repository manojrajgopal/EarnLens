import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../bootstrap/dependency_injection.dart';
import '../../core/date_time/local_date.dart';
import '../../domain/models/enums.dart';
import '../../features/analytics/presentation/insights_screen.dart';
import '../../features/authentication/application/session_controller.dart';
import '../../features/authentication/presentation/change_pin_screen.dart';
import '../../features/authentication/presentation/lock_screen.dart';
import '../../features/backup_restore/presentation/data_screen.dart';
import '../../features/bonuses/presentation/item_form_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/dashboard/presentation/dashboard_customize_screen.dart';
import '../../features/dashboard/presentation/home_screen.dart';
import '../../features/forecasts/presentation/what_if_screen.dart';
import '../../features/help/presentation/help_screen.dart';
import '../../features/history/presentation/month_history_screen.dart';
import '../../features/income_sources/presentation/income_list_screen.dart';
import '../../features/income_sources/presentation/source_detail_screen.dart';
import '../../features/income_sources/presentation/source_form_screen.dart';
import '../../features/notifications/presentation/notification_settings_screen.dart';
import '../../features/notifications/presentation/reminders_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/salary/presentation/day_overrides_screen.dart';
import '../../features/salary/presentation/revision_form_screen.dart';
import '../../features/settings/presentation/about_screens.dart';
import '../../features/settings/presentation/audit_log_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/settings_sections.dart';
import '../../features/transactions/presentation/ledger_entry_form_screen.dart';
import '../../features/variable_income/presentation/month_record_screen.dart';
import 'app_shell.dart';

/// Re-evaluates redirects when the session or profile changes.
class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(sessionProvider.select((s) => s.locked), (_, _) => refresh.ping());
  ref.listen(profileStreamProvider, (_, _) => refresh.ping());
  ref.onDispose(refresh.dispose);

  YearMonth? ym(String? s) {
    try {
      return s == null ? null : YearMonth.parse(s);
    } on FormatException {
      return null;
    }
  }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final profileAsync = ref.read(profileStreamProvider);
      if (profileAsync.isLoading && !profileAsync.hasValue) return null;
      final onboarded = profileAsync.value?.onboardingComplete ?? false;
      final loc = state.matchedLocation;
      final inOnboarding = loc == '/welcome' || loc == '/onboarding';
      if (!onboarded) return inOnboarding ? null : '/welcome';
      if (inOnboarding) return '/home';
      final locked = ref.read(sessionProvider).locked;
      if (locked && loc != '/lock') return '/lock?from=${Uri.encodeComponent(state.uri.toString())}';
      if (!locked && loc == '/lock') return state.uri.queryParameters['from'] ?? '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, s) => OnboardingScreen(withSampleData: s.uri.queryParameters['sample'] == '1'),
      ),
      GoRoute(path: '/lock', builder: (_, _) => const LockScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const HomeScreen(),
              routes: [
                GoRoute(path: 'customize', builder: (_, _) => const DashboardCustomizeScreen()),
                GoRoute(
                  path: 'search',
                  builder: (_, s) => SearchScreen(initialQuery: s.uri.queryParameters['q'] ?? ''),
                ),
                GoRoute(path: 'reminders', builder: (_, _) => const RemindersScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/income',
              builder: (_, _) => const IncomeListScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  // Keyed by URL so opening "new income" with a different kind
                  // builds a fresh form instead of reusing the previous state.
                  builder: (_, s) => SourceFormScreen(
                    key: ValueKey(s.uri.toString()),
                    kind: IncomeKind.values.where((k) => k.name == s.uri.queryParameters['kind']).firstOrNull,
                  ),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, s) => SourceDetailScreen(sourceId: s.pathParameters['id']!),
                  routes: [
                    GoRoute(path: 'edit', builder: (_, s) => SourceFormScreen(sourceId: s.pathParameters['id'])),
                    GoRoute(
                      path: 'revision',
                      builder: (_, s) => RevisionFormScreen(
                        sourceId: s.pathParameters['id']!,
                        revisionId: s.uri.queryParameters['rev'],
                      ),
                    ),
                    GoRoute(
                      path: 'item',
                      builder: (_, s) => ItemFormScreen(
                        sourceId: s.pathParameters['id']!,
                        itemId: s.uri.queryParameters['item'],
                      ),
                    ),
                    GoRoute(
                      path: 'entry',
                      builder: (_, s) => LedgerEntryFormScreen(
                        sourceId: s.pathParameters['id']!,
                        entryId: s.uri.queryParameters['entry'],
                        type: LedgerType.values.where((t) => t.name == s.uri.queryParameters['type']).firstOrNull,
                        period: ym(s.uri.queryParameters['period']),
                        itemId: s.uri.queryParameters['item'],
                      ),
                    ),
                    GoRoute(
                      path: 'month/:ym',
                      builder: (_, s) => MonthRecordScreen(
                        sourceId: s.pathParameters['id']!,
                        month: ym(s.pathParameters['ym']) ?? YearMonth(2000, 1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/insights',
              builder: (_, _) => const InsightsScreen(),
              routes: [
                GoRoute(
                  path: 'month/:ym',
                  builder: (_, s) => MonthHistoryScreen(month: ym(s.pathParameters['ym']) ?? YearMonth(2000, 1)),
                ),
                GoRoute(path: 'what-if', builder: (_, _) => const WhatIfScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsScreen(),
              routes: [
                GoRoute(path: 'profile', builder: (_, _) => const ProfileSettingsScreen()),
                GoRoute(path: 'appearance', builder: (_, _) => const AppearanceSettingsScreen()),
                GoRoute(path: 'dashboard', builder: (_, _) => const DashboardCustomizeScreen()),
                GoRoute(path: 'calculation', builder: (_, _) => const CalculationSettingsScreen()),
                GoRoute(path: 'holidays', builder: (_, _) => const DayOverridesScreen()),
                GoRoute(path: 'notifications', builder: (_, _) => const NotificationSettingsScreen()),
                GoRoute(
                  path: 'security',
                  builder: (_, _) => const SecuritySettingsScreen(),
                  routes: [GoRoute(path: 'change-pin', builder: (_, _) => const ChangePinScreen())],
                ),
                GoRoute(path: 'data', builder: (_, _) => const DataScreen()),
                GoRoute(path: 'audit', builder: (_, _) => const AuditLogScreen()),
                GoRoute(path: 'about', builder: (_, _) => const AboutScreen()),
                GoRoute(path: 'privacy', builder: (_, _) => const PrivacyScreen()),
                GoRoute(path: 'help', builder: (_, _) => const HelpScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
