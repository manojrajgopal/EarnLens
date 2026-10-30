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
import '../../accounts/application/account_summaries.dart';
import '../../accounts/presentation/account_avatar.dart';
import '../../accounts/presentation/account_switcher_sheet.dart';
import '../../accounts/presentation/combined_dashboard.dart';
import '../../authentication/application/session_controller.dart';
import '../../refresh/application/app_refresher.dart';
import '../application/dashboard_providers.dart';
import 'dashboard_cards.dart';
import 'sunrise_scene.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting(int hour) => hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(dashboardConfigProvider);
    final snapAsync = ref.watch(snapshotStreamProvider);
    final visible = config.cards.where((x) => x.visible).toList();
    final combined = ref.watch(isReadOnlyViewProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= AppBreakpoints.threeColumn ? 3 : (width >= AppBreakpoints.twoColumn ? 2 : 1);
          final maxWidth = columns == 1 ? 640.0 : AppBreakpoints.wideMax;
          final padding = AppInsets.page(
            context,
            width,
            maxWidth: maxWidth,
            top: MediaQuery.paddingOf(context).top + 12,
          );
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
            const paired = {DashboardCardType.upcomingPayments, DashboardCardType.recentTransactions};
            for (var i = 0; i < visible.length; i++) {
              final card = visible[i];
              // On phones, upcoming payments and recent transactions sit side by
              // side (like the reference) when both are shown consecutively.
              if (columns == 1 &&
                  contentWidth >= 360 &&
                  i + 1 < visible.length &&
                  paired.contains(card.type) &&
                  paired.contains(visible[i + 1].type) &&
                  card.type != visible[i + 1].type) {
                final wideFirst = card.type == DashboardCardType.upcomingPayments;
                cards.add(
                  SizedBox(
                    width: contentWidth,
                    child: EntranceScale(
                      delay: Duration(milliseconds: 60 * (i.clamp(0, 6))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: wideFirst ? 57 : 43, child: buildDashboardCard(card)),
                          const SizedBox(width: 12),
                          Expanded(flex: wideFirst ? 43 : 57, child: buildDashboardCard(visible[i + 1])),
                        ],
                      ),
                    ),
                  ),
                );
                i++;
                continue;
              }
              cards.add(
                SizedBox(
                  width: cardWidth(card),
                  child: EntranceScale(
                    delay: Duration(milliseconds: 60 * (i.clamp(0, 6))),
                    child: buildDashboardCard(card),
                  ),
                ),
              );
              if (i == 0 && card.type == DashboardCardType.liveCounter) {
                cards.add(
                  SizedBox(
                    width: columns == 3 ? colWidth : contentWidth,
                    child: const EntranceScale(delay: Duration(milliseconds: 60), child: QuickActions()),
                  ),
                );
                if (combined) {
                  cards.add(
                    SizedBox(
                      width: columns == 1 ? contentWidth : colWidth,
                      child: const EntranceScale(delay: Duration(milliseconds: 90), child: CombinedMembersCard()),
                    ),
                  );
                }
              }
            }
            // Without a live counter the members card still leads.
            if (combined && !visible.any((x) => x.type == DashboardCardType.liveCounter)) {
              cards.insert(0, SizedBox(width: contentWidth, child: const CombinedMembersCard()));
            }
            content = Wrap(spacing: gap, runSpacing: 24, children: cards);
          }
          // Cross-fade when switching accounts; the new account's data is
          // already loaded, so this never shows the previous account's figures.
          content = AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppDurations.medium,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous.map((p) => Positioned(top: 0, left: 0, right: 0, child: p)), ?current],
            ),
            child: KeyedSubtree(key: ValueKey(ref.watch(activeViewProvider)), child: content),
          );

          return EarnLensRefreshIndicator(
            edgeOffset: MediaQuery.paddingOf(context).top,
            onRefresh: () => ref.read(appRefresherProvider).refresh({RefreshScope.earnings, RefreshScope.calendar}),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: padding,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Full-bleed illustrated backdrop behind the header and the top
                    // of the hero card.
                    Positioned(
                      top: -padding.top,
                      left: -padding.left,
                      right: -padding.right,
                      bottom: -64,
                      child: SunriseScene(groundY: 40, mottoTop: padding.top + 66),
                    ),
                    const _Header(),
                  ],
                ),
                const SizedBox(height: 14),
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
        },
      ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(formatDate(today), style: AppType.label.copyWith(color: c.ink.withValues(alpha: 0.65))),
            ),
            _actions(context, ref, privacy: privacy, hidden: hidden, overdue: overdue, name: name),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$greeting,',
          style: AppType.headlineLight.copyWith(
            fontSize: 25,
            fontWeight: FontWeight.w400,
            fontVariations: const [FontVariation('wght', 450)],
            color: c.ink,
          ),
        ),
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
        const SizedBox(height: 8),
        const _AccountChip(),
        const SizedBox(height: 8),
        FractionallySizedBox(
          widthFactor: 0.6,
          alignment: Alignment.centerLeft,
          child: Text(
            'Keep tracking your earnings and turn your goals into reality.',
            style: AppType.bodySmall.copyWith(color: c.ink.withValues(alpha: 0.72), fontSize: 13.5),
          ),
        ),
        const SizedBox(height: 46),
      ],
    );
  }

  Widget _actions(
    BuildContext context,
    WidgetRef ref, {
    required bool privacy,
    required bool hidden,
    required int overdue,
    required String name,
  }) {
    final c = context.colors;
    return Wrap(
      spacing: 8,
      children: [
        if (privacy)
          RoundIconButton(
            icon: hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            tooltip: hidden ? 'Show amounts' : 'Hide amounts',
            onPressed: () => ref.read(sessionProvider.notifier).toggleReveal(),
          ),
        RoundIconButton(icon: Icons.search_rounded, tooltip: 'Search', onPressed: () => context.push('/home/search')),
        Stack(
          clipBehavior: Clip.none,
          children: [
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
                  decoration: BoxDecoration(
                    color: c.overdue,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.card, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        const _AccountButton(),
      ],
    );
  }
}

/// The open account's avatar; opens the account switcher.
class _AccountButton extends ConsumerWidget {
  const _AccountButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(activeAccountProvider);
    final combined = ref.watch(activeCombinedProvider);
    final name = account?.name ?? combined?.name;
    final avatar = account != null
        ? AccountAvatar.of(account, size: 48, ring: true)
        : combined != null
            ? AccountAvatar.combined(combined, size: 48, ring: true)
            : _Avatar(name: ref.watch(profileStreamProvider).value?.displayName ?? '');
    return Tooltip(
      message: 'Switch account',
      child: Semantics(
        button: true,
        label: name == null ? 'Switch account' : 'Switch account. Open: $name',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => showAccountSwitcher(context),
          child: ExcludeSemantics(child: avatar),
        ),
      ),
    );
  }
}

/// "🙂 Personal ▾" — which account the dashboard shows. Combined accounts
/// show their member avatars and a read-only marker.
class _AccountChip extends ConsumerWidget {
  const _AccountChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final account = ref.watch(activeAccountProvider);
    final combined = ref.watch(activeCombinedProvider);
    if (account == null && combined == null) return const SizedBox.shrink();
    final count = ref.watch(accountsProvider).length;
    final members = combined == null ? const <Never>[] : ref.watch(combinedMembersProvider(combined.id));
    final label = account?.name ?? combined!.name;
    final detail = combined != null
        ? '${members.length} accounts · read-only'
        : count <= 1
            ? 'Tap to add accounts'
            // The type adds nothing when the account is named after it.
            : (account!.type.label.toLowerCase() == account.name.trim().toLowerCase() ? '' : account.type.label);
    return Semantics(
      button: true,
      label: 'Account: $label${detail.isEmpty ? '' : ', $detail'}. Switch account',
      child: Material(
        color: c.card.withValues(alpha: 0.86),
        shape: const StadiumBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => showAccountSwitcher(context),
          child: ExcludeSemantics(
            child: AnimatedSize(
              duration: AppDurations.fast,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (combined != null)
                    MemberStack(members: members, size: 26, max: 3)
                  else
                    AccountAvatar.of(account!, size: 26),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: label,
                          style: AppType.label.copyWith(fontWeight: FontWeight.w700, color: c.ink),
                        ),
                        if (detail.isNotEmpty)
                          TextSpan(text: '  $detail', style: AppType.caption.copyWith(color: c.inkMuted)),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.expand_more_rounded, size: 20, color: c.inkMuted),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
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
            child: Text(
              initials.isEmpty ? '•' : initials,
              style: AppType.label.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

/// Four glossy pastel bubbles; 2×2 on very narrow layouts.
class QuickActions extends ConsumerWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(todayProvider).yearMonth;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // A combined account is read-only: its first two actions switch accounts
    // and open the member breakdown instead of adding records.
    final combined = ref.watch(activeCombinedProvider);
    final actions = [
      if (combined == null) ...[
        (
          Icons.add_rounded,
          'Add income',
          'Log your earnings',
          AppColors.violet,
          AppColors.lilacSoft,
          () => context.go('/income'),
        ),
        (
          Icons.north_east_rounded,
          'Record payment',
          'Track received pay',
          AppColors.peach,
          AppColors.peachSoft,
          () => recordPaymentFlow(context, ref),
        ),
      ] else ...[
        (
          Icons.swap_horiz_rounded,
          'Accounts',
          'Switch or edit',
          AppColors.violet,
          AppColors.lilacSoft,
          () => showAccountSwitcher(context),
        ),
        (
          Icons.groups_2_outlined,
          'Members',
          'Add or remove',
          AppColors.peach,
          AppColors.peachSoft,
          () => context.push('/settings/accounts/combined/${combined.id}'),
        ),
      ],
      (
        Icons.bar_chart_rounded,
        'Month review',
        'See insights',
        AppColors.mint,
        AppColors.mintSoft,
        () => context.go('/insights/month/${month.toIso()}'),
      ),
      (
        Icons.calendar_month_rounded,
        'Calendar',
        'View schedule',
        AppColors.sky,
        AppColors.skySoft,
        () => context.go('/calendar'),
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        // Four across like the reference; 2×2 only on very narrow layouts.
        final cols = c.maxWidth < 300 ? 2 : 4;
        final gap = c.maxWidth < 380 ? 6.0 : 8.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        final roomy = w >= 90;
        final minHeight = roomy ? 142.0 : 128.0;
        Widget bubble(int i) {
          final a = actions[i];
          return OrganicTile(
            spec: BlobShapes.bubble(i),
            color: dark ? Color.alphaBlend(a.$4.withValues(alpha: 0.2), context.colors.card) : a.$5,
            glow: a.$4.withValues(alpha: 0.45),
            semanticLabel: '${a.$2}. ${a.$3}',
            padding: EdgeInsets.fromLTRB(roomy ? 14 : 10, 16, roomy ? 8 : 6, 10),
            onTap: a.$6,
            child: ConstrainedBox(
              // Grows with large text instead of overflowing; bubbles in a
              // row share the tallest height.
              constraints: BoxConstraints(minHeight: minHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: roomy ? 40 : 34,
                    height: roomy ? 40 : 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color.lerp(a.$4, Colors.white, 0.2)!, a.$4],
                      ),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: a.$4.withValues(alpha: 0.45), blurRadius: 12, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Icon(a.$1, color: Colors.white, size: roomy ? 22 : 19),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    a.$2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.label.copyWith(
                      fontWeight: FontWeight.w700,
                      fontVariations: const [FontVariation('wght', 700)],
                      fontSize: roomy ? 14 : 12.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    a.$3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.caption.copyWith(color: context.colors.ink.withValues(alpha: 0.6), fontSize: 11.5),
                  ),
                  const Spacer(),
                  Center(
                    child: Icon(Icons.chevron_right_rounded, size: 20, color: Color.lerp(a.$4, Colors.black, 0.25)),
                  ),
                ],
              ),
            ),
          );
        }

        Widget row(List<int> slots) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (j, i) in slots.indexed) ...[
                if (j > 0) SizedBox(width: gap),
                SizedBox(width: w, child: bubble(i)),
              ],
            ],
          ),
        );
        if (cols == 4) return row(const [0, 1, 2, 3]);
        return Column(
          children: [
            row(const [0, 1]),
            SizedBox(height: gap),
            row(const [2, 3]),
          ],
        );
      },
    );
  }
}
