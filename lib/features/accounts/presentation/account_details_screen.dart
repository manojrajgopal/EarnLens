import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/account.dart';
import '../../../domain/money/currency.dart';
import '../../../shared/widgets/components.dart';
import '../../authentication/application/session_controller.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/account_controller.dart';
import '../application/account_summaries.dart';
import 'account_avatar.dart';
import 'account_form_screen.dart';
import 'account_pin_sheet.dart';
import 'account_switcher_sheet.dart';

/// One individual account: its figures, combined memberships and the edit,
/// PIN, archive and delete actions.
class AccountDetailsScreen extends ConsumerWidget {
  const AccountDetailsScreen({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(accountByIdProvider(accountId));
    if (a == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Account not found',
          message: 'It may have been deleted.',
        ),
      );
    }
    final isOpen = ref.watch(activeViewProvider) == IndividualView(a.id);
    final locked = ref.watch(isAccountLockedProvider(a.id));
    final memberOf = ref.watch(combinedAccountsProvider).where((k) => k.memberIds.contains(a.id)).toList();
    final appPin = ref.watch(pinConfiguredProvider);

    return SettingsPage(
      title: a.name,
      children: [
        EarnCard(
          accent: true,
          child: Column(children: [
            AccountAvatar.of(a, size: 84, ring: true, locked: a.requiresPin),
            const SizedBox(height: AppSpace.md),
            Text(a.name, style: AppType.title.copyWith(color: AppColors.white), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              '${a.type.label} · ${a.currencyCode}${a.isArchived ? ' · Archived' : ''}',
              style: AppType.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.85)),
            ),
            if (a.description != null) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                a.description!,
                textAlign: TextAlign.center,
                style: AppType.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.85)),
              ),
            ],
            const SizedBox(height: AppSpace.md),
            if (locked)
              _HeroButton(
                icon: Icons.lock_open_rounded,
                label: 'Unlock to see figures',
                onTap: () => showAccountPinSheet(context, a),
              )
            else
              _Figures(account: a),
            const SizedBox(height: AppSpace.md),
            if (isOpen)
              Pill('Open now', icon: Icons.check_rounded, color: AppColors.white.withValues(alpha: 0.22), textColor: AppColors.white)
            else
              _HeroButton(
                icon: Icons.swap_horiz_rounded,
                label: 'Open this account',
                onTap: () async {
                  if (await openAccountView(context, ref, IndividualView(a.id)) && context.mounted) context.go('/home');
                },
              ),
          ]),
        ),
        SettingsGroup(
          title: 'Account',
          children: [
            SettingsTile(
              icon: Icons.edit_outlined,
              title: 'Edit details',
              subtitle: 'Name, avatar, type, currency and target',
              onTap: () => context.push('/settings/accounts/${a.id}/edit'),
            ),
            SettingsTile(
              icon: Icons.translate_rounded,
              tone: SettingsTone.sky,
              title: 'Number format',
              value: accountLocales[a.locale] == null ? a.locale : accountLocales[a.locale]!.split(' · ').first,
              onTap: () => context.push('/settings/accounts/${a.id}/edit'),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Privacy',
          footer: appPin
              ? 'An account PIN is asked whenever this account (or a combined account that includes it) is opened. '
                  'Reminders for a protected account never show amounts or names.'
              : 'Set an app PIN in Security first. An account PIN adds to it.',
          children: [
            if (a.requiresPin)
              SettingsTile(
                icon: Icons.lock_reset_rounded,
                title: 'Remove account PIN',
                onTap: () async {
                  if (await showAccountPinSheet(context, a, mode: AccountPinMode.remove) && context.mounted) {
                    showMessage(context, 'PIN removed from ${a.name}');
                  }
                },
              )
            else
              SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Protect with a PIN',
                subtitle: appPin ? null : 'Needs an app PIN',
                onTap: appPin
                    ? () async {
                        if (await showAccountPinSheet(context, a, mode: AccountPinMode.set) && context.mounted) {
                          showMessage(context, '${a.name} is now protected');
                        }
                      }
                    : () => context.push('/settings/security'),
              ),
          ],
        ),
        if (memberOf.isNotEmpty)
          SettingsGroup(
            title: 'Part of',
            children: [
              for (final k in memberOf)
                SettingsTile(
                  icon: Icons.groups_2_outlined,
                  tone: SettingsTone.mint,
                  title: k.name,
                  subtitle: '${k.memberIds.length} accounts',
                  onTap: () => context.push('/settings/accounts/combined/${k.id}'),
                ),
            ],
          ),
        SettingsGroup(
          title: 'Manage',
          children: [
            SettingsTile(
              icon: a.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
              tone: SettingsTone.peach,
              title: a.isArchived ? 'Restore account' : 'Archive account',
              subtitle: a.isArchived
                  ? 'Show it in the switcher again'
                  : 'Hide it from the switcher. Data and combined totals are kept.',
              onTap: () => runGuarded(
                context,
                () => ref.read(accountControllerProvider).setArchived(a.id, archived: !a.isArchived),
                success: a.isArchived ? 'Account restored' : 'Account archived',
              ),
            ),
            SettingsTile(
              icon: Icons.delete_outline_rounded,
              danger: true,
              title: 'Delete account',
              subtitle: 'Permanently delete it and its records',
              onTap: () => context.push('/settings/accounts/${a.id}/delete'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Figures extends ConsumerWidget {
  const _Figures({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(accountSummaryProvider((AccountScope.single(account.id), account.currencyCode))).value;
    if (summary == null) return const SizedBox(height: 48);
    final locale = account.locale ?? ref.watch(profileStreamProvider).value?.locale ?? 'en_IN';
    final money = MoneyFormatter(locale, Currency.byCode(account.currencyCode));
    final white = AppColors.white.withValues(alpha: 0.85);
    Widget stat(String value, String label, {bool amount = false}) => Expanded(
          child: Column(children: [
            amount
                ? AmountText(value, style: AppType.amountMedium.copyWith(color: AppColors.white))
                : Text(value, style: AppType.amountMedium.copyWith(color: AppColors.white)),
            Text(label, style: AppType.caption.copyWith(color: white)),
          ]),
        );
    return Row(children: [
      stat(money.fraction(summary.earnedThisMonth, decimals: 0), 'earned this month', amount: true),
      stat('${summary.sourceCount}', summary.sourceCount == 1 ? 'income source' : 'income sources'),
      if (account.monthlyTargetMinor != null)
        stat(money.minor(account.monthlyTargetMinor!, showMinor: false), 'monthly target', amount: true),
    ]);
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.violetDeep,
          minimumSize: const Size(48, 48),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
      );
}
