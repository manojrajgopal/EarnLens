import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/settings.dart';
import '../../../shared/layout/page_layout.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/earnlens_refresh_indicator.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/organic.dart';
import '../../authentication/application/session_controller.dart';
import '../../refresh/application/app_refresher.dart';
import '../application/dashboard_providers.dart';
import 'dashboard_cards.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting(int hour) => hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(dashboardConfigProvider);
    final snapAsync = ref.watch(snapshotStreamProvider);
    final visible = config.cards.where((x) => x.visible).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= AppBreakpoints.threeColumn ? 3 : (width >= AppBreakpoints.twoColumn ? 2 : 1);
        final maxWidth = columns == 1 ? 640.0 : AppBreakpoints.wideMax;
        final padding = AppInsets.page(context, width, maxWidth: maxWidth, top: MediaQuery.paddingOf(context).top + 12);
        final contentWidth = width - padding.horizontal;
        const gap = 16.0;
        final colWidth = (contentWidth - gap * (columns - 1)) / columns;

        double cardWidth(DashboardCardConfig card) {
          // Hero and sources span the full row (two columns on three-column layouts).
          if (card.type == DashboardCardType.liveCounter || card.type == DashboardCardType.rates) {
            return columns == 3 ? colWidth * 2 + gap : contentWidth;
          }
          if (card.size == CardSize.compact) return columns == 1 ? (contentWidth - gap) / 2 : colWidth;
          return colWidth;
        }

        Widget content;
        if (snapAsync.isLoading && snapAsync.value == null) {
          content = const LoadingState(label: 'Loading your earnings');
        } else if (snapAsync.hasError && snapAsync.value == null) {
          content = ErrorState(
            message: 'Your data could not be loaded. Pull down to try again.',
            onRetry: () => ref.read(appRefresherProvider).refresh(),
          );
        } else if (visible.isEmpty) {
          content = EmptyState(
            icon: Icons.dashboard_customize_outlined,
            title: 'Your dashboard is empty',
            message: 'Choose the cards you want to see.',
            action: 'Customize',
            onAction: () => context.push('/home/customize'),
          );
        } else {
          final cards = <Widget>[];
          for (final (i, card) in visible.indexed) {
            cards.add(SizedBox(
              width: cardWidth(card),
              child: EntranceScale(
                delay: Duration(milliseconds: 60 * (i.clamp(0, 6))),
                child: buildDashboardCard(card),
              ),
            ));
            if (i == 0 && card.type == DashboardCardType.liveCounter) {
              cards.add(SizedBox(
                width: columns == 3 ? colWidth : contentWidth,
                child: const EntranceScale(delay: Duration(milliseconds: 60), child: QuickActions()),
              ));
            }
          }
          content = Wrap(spacing: gap, runSpacing: 22, children: cards);
        }

        return EarnLensRefreshIndicator(
          edgeOffset: MediaQuery.paddingOf(context).top,
          onRefresh: () => ref.read(appRefresherProvider).refresh({RefreshScope.earnings, RefreshScope.calendar}),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            children: [
              const _Header(),
              const SizedBox(height: 22),
              content,
              const SizedBox(height: 20),
              Center(
                child: LinkAction(
                  label: 'Customize dashboard',
                  icon: Icons.tune_rounded,
                  onTap: () => context.push('/home/customize'),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileStreamProvider).value;
    final privacy = ref.watch(securitySettingsProvider).privacyMode;
    final hidden = ref.watch(hideAmountsProvider);
    final today = ref.watch(todayProvider);
    final hour = ref.watch(clockProvider).now().toLocal().hour;
    final overdue = ref.watch(quickStatsProvider).overdue;
    final c = context.colors;
    final name = profile?.displayName ?? '';
    final greeting = const HomeScreen()._greeting(hour);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(formatDate(today), style: AppType.label.copyWith(color: c.inkMuted))),
        _actions(context, ref, privacy: privacy, hidden: hidden, overdue: overdue, name: name),
      ]),
      const SizedBox(height: 10),
      Text('$greeting,', style: AppType.headlineLight.copyWith(fontSize: 26)),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          name,
          maxLines: 1,
          style: AppType.headlineLight.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            fontVariations: const [FontVariation('wght', 700)],
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text('Keep tracking your earnings and turn your goals into reality.',
          style: AppType.bodySmall.copyWith(color: c.inkMuted)),
    ]);
  }

  Widget _actions(BuildContext context, WidgetRef ref,
      {required bool privacy, required bool hidden, required int overdue, required String name}) {
    final c = context.colors;
    return Wrap(spacing: 8, children: [
        if (privacy)
          RoundIconButton(
            icon: hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            tooltip: hidden ? 'Show amounts' : 'Hide amounts',
            onPressed: () => ref.read(sessionProvider.notifier).toggleReveal(),
          ),
        RoundIconButton(icon: Icons.search_rounded, tooltip: 'Search', onPressed: () => context.push('/home/search')),
        Stack(clipBehavior: Clip.none, children: [
          RoundIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: overdue > 0 ? 'Reminders, $overdue need attention' : 'Reminders',
            onPressed: () => context.push('/home/reminders'),
          ),
          if (overdue > 0)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: c.overdue, shape: BoxShape.circle, border: Border.all(color: c.card, width: 1.5)),
              ),
            ),
        ]),
        _Avatar(name: name),
      ]);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();
    return Tooltip(
      message: 'Profile',
      child: Semantics(
        button: true,
        label: 'Profile',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.go('/settings/profile'),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.orb,
              border: Border.all(color: context.colors.card, width: 3),
              boxShadow: AppShadows.glow,
            ),
            alignment: Alignment.center,
            child: Text(initials.isEmpty ? '•' : initials,
                style: AppType.label.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}

/// Four colourful quick actions; 2×2 on narrow phones.
class QuickActions extends ConsumerWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(todayProvider).yearMonth;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final actions = [
      (Icons.add_rounded, 'Add income', 'Log your earnings', AppColors.violet, AppColors.lilacSoft, () => context.go('/income')),
      (Icons.north_east_rounded, 'Record payment', 'Track received pay', AppColors.peach, AppColors.peachSoft,
          () => recordPaymentFlow(context, ref)),
      (Icons.bar_chart_rounded, 'Month review', 'See insights', AppColors.mint, AppColors.mintSoft,
          () => context.go('/insights/month/${month.toIso()}')),
      (Icons.calendar_month_rounded, 'Calendar', 'View schedule', AppColors.sky, AppColors.skySoft, () => context.go('/calendar')),
    ];
    return LayoutBuilder(builder: (context, c) {
      // Four across like the reference; 2×2 only on very narrow layouts.
      final cols = c.maxWidth < 300 ? 2 : 4;
      final gap = c.maxWidth < 380 ? 8.0 : 12.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      final roomy = w >= 96;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final (i, a) in actions.indexed)
          SizedBox(
            width: w,
            child: OrganicTile(
              seed: i + 1,
              color: dark ? Color.alphaBlend(a.$4.withValues(alpha: 0.2), context.colors.card) : a.$5,
              semanticLabel: '${a.$2}. ${a.$3}',
              padding: EdgeInsets.fromLTRB(roomy ? 14 : 10, 14, roomy ? 10 : 8, 10),
              onTap: a.$6,
              child: SizedBox(
                height: roomy ? 128 : 116,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: roomy ? 40 : 34,
                    height: roomy ? 40 : 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: a.$4,
                      boxShadow: [BoxShadow(color: a.$4.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 5))],
                    ),
                    child: Icon(a.$1, color: Colors.white, size: roomy ? 22 : 19),
                  ),
                  const SizedBox(height: 10),
                  Text(a.$2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.label.copyWith(fontWeight: FontWeight.w700, fontSize: roomy ? 14 : 12.5, height: 1.15)),
                  const SizedBox(height: 2),
                  if (roomy)
                    Text(a.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.caption.copyWith(color: context.colors.inkMuted)),
                  const Spacer(),
                  Align(alignment: Alignment.bottomRight, child: Icon(Icons.chevron_right_rounded, size: 18, color: a.$4)),
                ]),
              ),
            ),
          ),
      ]);
    });
  }
}
