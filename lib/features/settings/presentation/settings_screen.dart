import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/profile.dart';
import '../../../domain/models/settings.dart';
import '../../../shared/widgets/components.dart';
import '../../../domain/models/account.dart';
import '../../accounts/presentation/account_avatar.dart';
import '../../accounts/presentation/account_switcher_sheet.dart';
import '../../authentication/application/session_controller.dart';
import 'settings_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileStreamProvider).value;
    final appearance = ref.watch(appearanceProvider);
    final notifications = ref.watch(notificationSettingsProvider);
    final security = ref.watch(securitySettingsProvider);
    final pin = ref.watch(pinConfiguredProvider);
    final backup = ref.watch(backupStateProvider);
    final calc = ref.watch(calculationSettingsProvider);
    final account = ref.watch(activeAccountProvider);
    final combined = ref.watch(activeCombinedProvider);
    final accountCount = ref.watch(accountsProvider).length;
    // Calculation defaults, holidays and reminders belong to one account;
    // a combined account shows where to change them instead.
    final perAccount = account != null;
    final viewName = account?.name ?? combined?.name ?? '';
    final c = context.colors;
    void go(String path) => context.go('/settings/$path');

    return SettingsPage(
      title: 'Settings',
      subtitle: 'Make EarnLens work the way you do.',
      root: true,
      children: [
        EntranceScale(child: _ProfileCard(profile: profile, onTap: () => go('profile'))),
        SettingsGroup(title: 'Accounts', children: [
          SettingsTile(
            icon: Icons.switch_account_outlined,
            title: viewName.isEmpty ? 'Switch account' : 'Open: $viewName',
            subtitle: combined != null ? 'Combined · read-only' : 'Tap to switch or combine accounts',
            trailing: account != null
                ? AccountAvatar.of(account, size: 34)
                : combined != null
                    ? AccountAvatar.combined(combined, size: 34)
                    : null,
            onTap: () => showAccountSwitcher(context),
          ),
          SettingsTile(
            icon: Icons.manage_accounts_outlined,
            tone: SettingsTone.sky,
            title: 'Manage accounts',
            subtitle: 'Create, edit, protect, combine or delete',
            value: '$accountCount/${Account.maxAccounts}',
            onTap: () => go('accounts'),
          ),
          if (account != null)
            SettingsTile(
              icon: Icons.badge_outlined,
              tone: SettingsTone.mint,
              title: 'This account',
              subtitle: 'Name, avatar, currency, target and PIN',
              onTap: () => go('accounts/${account.id}'),
            ),
        ]),
        SettingsGroup(title: 'Personalise', children: [
          SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Profile',
            subtitle: 'Name, currency, region and timezone',
            onTap: () => go('profile'),
          ),
          SettingsTile(
            icon: Icons.palette_outlined,
            tone: SettingsTone.rose,
            title: 'Appearance',
            subtitle: 'Theme and motion',
            value: switch (appearance.themeMode) {
              AppThemeMode.light => 'Light',
              AppThemeMode.dark => 'Dark',
              AppThemeMode.system => 'System',
            },
            onTap: () => go('appearance'),
          ),
          SettingsTile(
            icon: Icons.dashboard_customize_outlined,
            tone: SettingsTone.sky,
            title: 'Dashboard',
            subtitle: 'Cards, earning units and live counter of $viewName',
            onTap: () => go('dashboard'),
          ),
        ]),
        SettingsGroup(
          title: 'Earnings',
          footer: perAccount ? null : 'These are set per account. Open a member account to change them.',
          children: [
            SettingsTile(
              icon: Icons.calculate_outlined,
              tone: SettingsTone.mint,
              title: 'Earnings calculation',
              subtitle: perAccount ? 'Default: ${calc.defaultPolicy.label.toLowerCase()}' : 'Set in each account',
              onTap: perAccount ? () => go('calculation') : null,
            ),
            SettingsTile(
              icon: Icons.beach_access_outlined,
              tone: SettingsTone.peach,
              title: 'Holidays & leave',
              subtitle: perAccount ? 'Days that change how pay accrues' : 'Set in each account',
              onTap: perAccount ? () => go('holidays') : null,
            ),
          ],
        ),
        SettingsGroup(title: 'Alerts & security', children: [
          SettingsTile(
            icon: Icons.notifications_none_rounded,
            tone: SettingsTone.peach,
            title: 'Notifications',
            subtitle: perAccount ? 'Reminders for $viewName' : 'Set in each account',
            value: perAccount ? (notifications.masterEnabled ? 'On' : 'Off') : null,
            onTap: perAccount ? () => go('notifications') : null,
          ),
          SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: 'Security',
            subtitle: [
              if (security.biometricsEnabled) 'Biometrics',
              if (security.privacyMode) 'Privacy mode',
              if (!security.biometricsEnabled && !security.privacyMode) 'PIN, biometrics and privacy',
            ].join(' · '),
            value: pin ? 'PIN on' : 'No PIN',
            onTap: () => go('security'),
          ),
        ]),
        SettingsGroup(title: 'Your data', children: [
          SettingsTile(
            icon: Icons.storage_rounded,
            tone: SettingsTone.sky,
            title: 'Data management',
            subtitle: backup.lastBackupAt == null
                ? 'Backup, restore, export and import · no backup yet'
                : 'Backup, restore, export and import',
            onTap: () => go('data'),
          ),
          SettingsTile(
            icon: Icons.history_rounded,
            tone: SettingsTone.mint,
            title: 'Change history',
            subtitle: 'Every change to your income records',
            onTap: () => go('audit'),
          ),
        ]),
        SettingsGroup(title: 'About', children: [
          SettingsTile(
            icon: Icons.help_outline_rounded,
            tone: SettingsTone.sky,
            title: 'Help',
            subtitle: 'How EarnLens calculates, and troubleshooting',
            onTap: () => go('help'),
          ),
          SettingsTile(
            icon: Icons.privacy_tip_outlined,
            tone: SettingsTone.mint,
            title: 'Privacy',
            subtitle: 'Your data stays on this device',
            onTap: () => go('privacy'),
          ),
          SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'About EarnLens',
            subtitle: ref.watch(displayVersionProvider),
            onTap: () => go('about'),
          ),
        ]),
        if (pin) ...[
          const SizedBox(height: AppSpace.xl),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => ref.read(sessionProvider.notifier).lock(),
              icon: const Icon(Icons.lock_rounded, size: 18),
              label: const Text('Lock now'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(168, 48),
                foregroundColor: c.accentText,
                backgroundColor: c.card,
                side: BorderSide(color: c.accentText.withValues(alpha: 0.25)),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Purple profile header with an initials avatar.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.onTap});
  final UserProfile? profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final name = (p?.displayName.trim().isNotEmpty ?? false) ? p!.displayName.trim() : 'You';
    final initials =
        name.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).take(2).map((s) => s.characters.first.toUpperCase()).join();
    final chips = p == null ? const <String>[] : [p.currencyCode, p.timezone.replaceAll('_', ' ')];
    return EarnCard(
      accent: true,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(20, 20, 14, 20),
      semanticLabel: 'Profile: $name. Edit profile',
      child: Row(children: [
        Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.orb,
            border: Border.all(color: AppColors.white, width: 3),
          ),
          child: Text(
            initials.isEmpty ? '•' : initials,
            style: AppType.title.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: AppSpace.lg),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.title.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (chips.isEmpty)
              Text('Profile', style: AppType.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.85)))
            else
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final t in chips)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(t, style: AppType.caption.copyWith(color: AppColors.white)),
                  ),
              ]),
          ]),
        ),
        const SizedBox(width: AppSpace.xs),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: const Icon(Icons.chevron_right_rounded, color: AppColors.white),
        ),
      ]),
    );
  }
}
