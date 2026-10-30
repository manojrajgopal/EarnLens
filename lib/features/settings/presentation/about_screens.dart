import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/routing/app_shell.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/components.dart';
import '../../../shared/widgets/organic.dart';
import 'settings_widgets.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(displayVersionProvider);
    final c = context.colors;
    return SettingsPage(
      title: 'About',
      children: [
        const SizedBox(height: AppSpace.sm),
        EntranceScale(
          child: EarnCard(
            accent: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: ShapeDecoration(
                  color: AppColors.white,
                  shape: BlobBorder(BlobShapes.chip(3)),
                  shadows: AppShadows.glow,
                ),
                child: const EarnLensMark(size: 52),
              ),
              const SizedBox(height: AppSpace.lg),
              Text('EarnLens', style: AppType.headlineLight.copyWith(color: AppColors.white)),
              const SizedBox(height: AppSpace.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('Version ${version.substring(1)}', style: AppType.caption.copyWith(color: AppColors.white)),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'See what you earn, as you earn it. An offline-first earnings tracker that keeps your data on '
                'your device.',
                style: AppType.body.copyWith(color: AppColors.white.withValues(alpha: 0.9)),
              ),
            ]),
          ),
        ),
        SettingsGroup(title: 'Platforms', children: [
          _platform(context, Icons.android_rounded, SettingsTone.mint, 'Android', 'Fully supported, including notifications and the '
              'home-screen widget.', 'Full'),
          _platform(context, Icons.phone_iphone_rounded, SettingsTone.sky, 'iOS', 'The app supports iOS, but builds must be '
              'produced on a Mac with Xcode. The home-screen widget is not available yet.', 'Build on macOS'),
          _platform(context, Icons.widgets_outlined, SettingsTone.peach, 'Home-screen widget', 'Available on Android only for now.',
              'Android'),
          _platform(context, Icons.language_rounded, SettingsTone.violet, 'Web', 'Runs in modern browsers using browser storage. '
              'Reminders only appear while the tab is open; back up regularly.', 'Browser'),
        ]),
        SettingsGroup(title: 'More', children: [
          SettingsTile(
            icon: Icons.privacy_tip_outlined,
            tone: SettingsTone.mint,
            title: 'Privacy',
            onTap: () => context.go('/settings/privacy'),
          ),
          SettingsTile(
            icon: Icons.help_outline_rounded,
            tone: SettingsTone.sky,
            title: 'Help',
            onTap: () => context.go('/settings/help'),
          ),
          SettingsTile(
            icon: Icons.description_outlined,
            title: 'Open-source licences',
            subtitle: 'Software EarnLens is built with',
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'EarnLens',
              applicationVersion: version,
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.xl),
          child: Text(
            'EarnLens provides estimates from the rules you enter. It is not financial, tax or legal advice.',
            textAlign: TextAlign.center,
            style: AppType.bodySmall.copyWith(color: c.inkMuted),
          ),
        ),
      ],
    );
  }

  Widget _platform(BuildContext context, IconData icon, SettingsTone tone, String name, String detail, String status) =>
      SettingsTile(
        icon: icon,
        tone: tone,
        title: name,
        subtitle: detail,
        trailing: Flexible(child: Pill(status, color: context.colors.accentSoft, textColor: context.colors.accentText)),
      );
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => SettingsPage(
        title: 'Privacy',
        children: [
          const SizedBox(height: AppSpace.sm),
          EntranceScale(
            child: EarnCard(
              accent: true,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                BlobBadge(
                  size: 48,
                  seed: 7,
                  color: AppColors.white.withValues(alpha: 0.2),
                  child: const Icon(Icons.verified_user_rounded, color: AppColors.white),
                ),
                const SizedBox(width: AppSpace.lg),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Private by design',
                        style: AppType.title.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Your income data stays on your device. EarnLens has no accounts, no analytics, no ads and no '
                      'servers that receive your data.',
                      style: AppType.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.9)),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          const _PrivacySection(icon: Icons.phone_android_rounded, tone: SettingsTone.sky, title: 'Where your data is stored', points: [
            'Android and iOS: in a private database inside the app\'s own storage, which other apps cannot read.',
            'Web: in this browser\'s site storage for this address. It is not synced to other browsers or devices '
                'and can be erased if you clear site data.',
            'Uninstalling the app (or clearing browser data) deletes it. Keep backups.',
          ]),
          const _PrivacySection(icon: Icons.ios_share_rounded, tone: SettingsTone.mint, title: 'What leaves your device', points: [
            'Nothing, unless you choose to export or share a file — a backup or CSV — and decide where it goes.',
            'No usage analytics, crash reporting, advertising or tracking.',
            'Notifications are generated on the device; no notification service sees your data.',
          ]),
          const _PrivacySection(icon: Icons.lock_outline_rounded, title: 'Security', points: [
            'Your PIN is never stored. Only a salted PBKDF2 hash of it is kept, in the platform secure storage '
                '(Android Keystore or iOS Keychain).',
            'Backups can be encrypted with AES-256-GCM using a password you choose. Without that password the '
                'backup cannot be read.',
            'The database on the device is not encrypted at rest. The PIN prevents casual access to the app; '
                'use your device lock and encrypted backups to protect the data itself.',
          ]),
          const _PrivacySection(icon: Icons.auto_awesome_outlined, tone: SettingsTone.peach, title: 'In the future', points: [
            'If cloud sync or other online features are ever added, they will be optional and off until you '
                'turn them on.',
          ]),
        ],
      );
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.icon, required this.title, required this.points, this.tone = SettingsTone.violet});
  final IconData icon;
  final SettingsTone tone;
  final String title;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SettingsGroup(title: title, children: [
      SettingsBlock(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SettingsIcon(icon, tone: tone),
          const SizedBox(height: AppSpace.sm),
          for (final p in points)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  margin: const EdgeInsets.only(top: 2, right: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, size: 14, color: c.accentText),
                ),
                Expanded(child: Text(p, style: AppType.body.copyWith(color: c.ink))),
              ]),
            ),
        ]),
      ),
    ]);
  }
}
