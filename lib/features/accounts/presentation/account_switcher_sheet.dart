import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/formatting/money_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/account.dart';
import '../../../domain/money/currency.dart';
import '../../../shared/widgets/components.dart';
import '../../authentication/application/session_controller.dart';
import '../application/account_controller.dart';
import '../application/account_summaries.dart';
import 'account_avatar.dart';
import 'account_pin_sheet.dart';

/// Opens [view], asking for the PIN of any protected account in it first.
/// Returns false when the user cancelled a PIN prompt.
Future<bool> openAccountView(BuildContext context, WidgetRef ref, AccountView view) async {
  final controller = ref.read(accountControllerProvider);
  for (final a in controller.lockedAccountsFor(view)) {
    if (!context.mounted || !await showAccountPinSheet(context, a)) return false;
  }
  await controller.open(view);
  return true;
}

/// The account switcher: every account with its headline figure, combined
/// accounts, and the create / combine / manage actions.
Future<void> showAccountSwitcher(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      // Above the floating navigation bar.
      useRootNavigator: true,
      builder: (_) => const _AccountSwitcherSheet(),
    );

class _AccountSwitcherSheet extends ConsumerWidget {
  const _AccountSwitcherSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final all = ref.watch(accountsProvider);
    final accounts = all.where((a) => !a.isArchived).toList();
    final combined = ref.watch(combinedAccountsProvider);
    final active = ref.watch(activeViewProvider);
    final atLimit = all.length >= Account.maxAccounts;

    Future<void> pick(AccountView view) async {
      final navigator = Navigator.of(context);
      if (await openAccountView(context, ref, view)) navigator.pop();
    }

    void go(String location) {
      Navigator.of(context).pop();
      context.push(location);
    }

    var index = 0;
    Widget entrance(Widget child) =>
        EntranceScale(delay: Duration(milliseconds: 40 * (index++).clamp(0, 8)), child: child);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xl + MediaQuery.paddingOf(context).bottom),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Accounts', style: AppType.title.copyWith(color: c.ink)),
              ),
            ),
            Pill('${all.length}/${Account.maxAccounts}', color: c.accentSoft, textColor: c.accentText),
          ]),
          const SizedBox(height: 4),
          Text(
            'Each account keeps its own income, payments and settings.',
            style: AppType.bodySmall.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: AppSpace.md),
          Row(children: [
            Expanded(
              child: _ActionBubble(
                icon: Icons.person_add_alt_1_rounded,
                label: 'New account',
                onTap: atLimit ? null : () => go('/settings/accounts/new'),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: _ActionBubble(
                icon: Icons.join_inner_rounded,
                label: 'Combine',
                onTap: accounts.length < 2 ? null : () => go('/settings/accounts/combined/new'),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: _ActionBubble(
                icon: Icons.manage_accounts_outlined,
                label: 'Manage',
                onTap: () => go('/settings/accounts'),
              ),
            ),
          ]),
          if (atLimit) ...[
            const SizedBox(height: AppSpace.sm),
            Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(color: c.warningSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Text(
                'You have reached the limit of ${Account.maxAccounts} accounts. Delete one in Manage to add '
                'another. Combined accounts do not count toward the limit.',
                style: AppType.bodySmall.copyWith(color: c.ink),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          for (final a in accounts)
            entrance(_AccountRow(account: a, active: active == IndividualView(a.id), onTap: () => pick(IndividualView(a.id)))),
          if (combined.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Text('Combined', style: AppType.section.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('Read-only totals across accounts.', style: AppType.bodySmall.copyWith(color: c.inkMuted)),
            const SizedBox(height: AppSpace.sm),
            for (final k in combined)
              entrance(_CombinedRow(combined: k, active: active == CombinedView(k.id), onTap: () => pick(CombinedView(k.id)))),
          ],
        ],
      ),
    );
  }
}

/// "₹12,340 this month", "Protected" or a masked amount.
class _SummaryText extends ConsumerWidget {
  const _SummaryText({required this.scope, required this.currencyCode, required this.locked});
  final AccountScope scope;
  final String currencyCode;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final style = AppType.bodySmall.copyWith(color: c.inkMuted);
    if (locked) return Text('Protected', style: style);
    final summary = ref.watch(accountSummaryProvider((scope, currencyCode))).value;
    if (summary == null) return Text(' ', style: style);
    final locale = ref.watch(profileStreamProvider).value?.locale ?? 'en_IN';
    final text = MoneyFormatter(locale, Currency.byCode(currencyCode)).fraction(summary.earnedThisMonth, decimals: 0);
    final hidden = ref.watch(hideAmountsProvider);
    return Text(
      '${hidden ? '••••' : text} this month',
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SelectableRow extends StatelessWidget {
  const _SelectableRow({required this.leading, required this.title, required this.subtitle, required this.active, required this.onTap, this.semanticLabel});
  final Widget leading;
  final String title;
  final Widget subtitle;
  final bool active;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Semantics(
        button: true,
        selected: active,
        label: semanticLabel,
        child: Material(
          color: active ? c.accentSoft : c.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: onTap,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              constraints: const BoxConstraints(minHeight: 68),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: active ? c.accent : c.line, width: active ? 1.5 : 1),
              ),
              child: Row(children: [
                leading,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.label.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink),
                    ),
                    const SizedBox(height: 2),
                    subtitle,
                  ]),
                ),
                AnimatedSwitcher(
                  duration: AppDurations.fast,
                  child: active
                      ? Icon(Icons.check_circle_rounded, key: const ValueKey(true), color: c.accentText)
                      : Icon(Icons.chevron_right_rounded, key: const ValueKey(false), color: c.inkMuted),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends ConsumerWidget {
  const _AccountRow({required this.account, required this.active, required this.onTap});
  final Account account;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = ref.watch(isAccountLockedProvider(account.id));
    return _SelectableRow(
      active: active,
      onTap: onTap,
      semanticLabel: '${account.name}, ${account.type.label}${active ? ', open' : ''}${locked ? ', protected' : ''}',
      leading: AccountAvatar.of(account, size: 46, locked: account.requiresPin, ring: active),
      title: account.name,
      subtitle: Row(children: [
        if (account.type.label.toLowerCase() != account.name.trim().toLowerCase())
          Text('${account.type.label} · ', style: AppType.bodySmall.copyWith(color: context.colors.inkMuted)),
        Flexible(
          child: _SummaryText(
            scope: AccountScope.single(account.id),
            currencyCode: account.currencyCode,
            locked: locked,
          ),
        ),
      ]),
    );
  }
}

class _CombinedRow extends ConsumerWidget {
  const _CombinedRow({required this.combined, required this.active, required this.onTap});
  final CombinedAccount combined;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(combinedMembersProvider(combined.id));
    final locked = members.any((m) => ref.watch(isAccountLockedProvider(m.id)));
    return _SelectableRow(
      active: active,
      onTap: onTap,
      semanticLabel: '${combined.name}, combined, ${members.length} accounts${active ? ', open' : ''}',
      leading: SizedBox(
        width: 46,
        height: 46,
        child: Stack(clipBehavior: Clip.none, children: [
          AccountAvatar.combined(combined, size: 46, ring: active),
          Positioned(right: -2, bottom: -2, child: MemberStack(members: members, size: 20, max: 2)),
        ]),
      ),
      title: combined.name,
      subtitle: Row(children: [
        Text('${members.length} accounts · ', style: AppType.bodySmall.copyWith(color: context.colors.inkMuted)),
        Flexible(
          child: _SummaryText(
            scope: AccountScope.readOnly(combined.memberIds.toSet()),
            currencyCode: combined.currencyCode,
            locked: locked,
          ),
        ),
      ]),
    );
  }
}

class _ActionBubble extends StatelessWidget {
  const _ActionBubble({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: EarnCard(
        tint: c.accentSoft,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        radius: AppRadius.md,
        onTap: onTap,
        semanticLabel: label,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: c.accentText),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.caption.copyWith(color: c.ink, fontWeight: FontWeight.w700),
          ),
        ]),
      ),
    );
  }
}
