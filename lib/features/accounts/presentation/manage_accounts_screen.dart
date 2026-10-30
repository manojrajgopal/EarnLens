import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/account.dart';
import '../../../shared/layout/page_layout.dart';
import '../../../shared/widgets/components.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/account_summaries.dart';
import 'account_avatar.dart';

/// All accounts: reorder, open details, create, and combined accounts.
class ManageAccountsScreen extends ConsumerWidget {
  const ManageAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final accounts = ref.watch(accountsProvider);
    final combined = ref.watch(combinedAccountsProvider);
    final active = ref.watch(activeViewProvider);
    final atLimit = accounts.length >= Account.maxAccounts;
    final activeCount = accounts.where((a) => !a.isArchived).length;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('Accounts')),
      body: LayoutBuilder(builder: (context, constraints) {
        final padding = AppInsets.page(context, constraints.maxWidth);
        return ReorderableListView.builder(
          padding: padding,
          buildDefaultDragHandles: false,
          header: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            EarnCard(
              accent: true,
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${accounts.length} of ${Account.maxAccounts}',
                        style: AppType.amountLarge.copyWith(color: AppColors.white)),
                    const SizedBox(height: 4),
                    Text(
                      atLimit
                          ? 'Limit reached. Delete an account you no longer need to add another.'
                          : 'individual accounts used. Combined accounts don\'t count.',
                      style: AppType.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.85)),
                    ),
                  ]),
                ),
                const SizedBox(width: AppSpace.md),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: accounts.length / Account.maxAccounts,
                    strokeWidth: 6,
                    color: AppColors.white,
                    backgroundColor: AppColors.white.withValues(alpha: 0.25),
                  ),
                ),
              ]),
            ),
            const SettingsGroupHeader('Your accounts'),
            Text('Drag to reorder the switcher. Tap an account for its details.',
                style: AppType.bodySmall.copyWith(color: c.inkMuted)),
            const SizedBox(height: AppSpace.sm),
          ]),
          footer: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: AppSpace.sm),
            BusyButton(
              label: atLimit ? 'Limit of ${Account.maxAccounts} reached' : 'New account',
              onPressed: atLimit ? null : () async => context.push('/settings/accounts/new'),
            ),
            SettingsGroup(
              title: 'Combined accounts',
              footer: 'A combined account adds up the figures of its members. It stores no records of its own and '
                  'can\'t change them; deleting it never deletes member data.',
              children: [
                for (final k in combined)
                  _CombinedTile(combined: k, active: active == CombinedView(k.id)),
                SettingsTile(
                  icon: Icons.join_inner_rounded,
                  title: 'Combine accounts',
                  subtitle: activeCount < 2 ? 'Needs at least two accounts' : 'Pick two or more accounts',
                  onTap: activeCount < 2 ? null : () => context.push('/settings/accounts/combined/new'),
                ),
              ],
            ),
          ]),
          itemCount: accounts.length,
          onReorderItem: (from, to) {
            final ids = accounts.map((a) => a.id).toList();
            ids.insert(to, ids.removeAt(from));
            runGuarded(context, () => ref.read(accountRepositoryProvider).reorder(ids));
          },
          itemBuilder: (context, i) {
            final a = accounts[i];
            return Padding(
              key: ValueKey(a.id),
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: _AccountTile(account: a, index: i, active: active == IndividualView(a.id)),
            );
          },
        );
      }),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile({required this.account, required this.index, required this.active});
  final Account account;
  final int index;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final memberOf = ref.watch(combinedAccountsProvider).where((k) => k.memberIds.contains(account.id)).length;
    final details = [
      account.type.label,
      account.currencyCode,
      if (memberOf > 0) 'in $memberOf combined',
    ].join(' · ');
    return EarnCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      radius: AppRadius.md,
      seed: account.id.hashCode & 0x3ff,
      onTap: () => context.push('/settings/accounts/${account.id}'),
      semanticLabel: '${account.name}, $details${active ? ', open now' : ''}',
      child: Row(children: [
        AccountAvatar.of(account, size: 46, locked: account.requiresPin, ring: active),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.label.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink),
                ),
              ),
              if (active) ...[const SizedBox(width: 6), Pill('Open', color: c.accentSoft, textColor: c.accentText)],
              if (account.isArchived) ...[const SizedBox(width: 6), const Pill('Archived')],
            ]),
            const SizedBox(height: 2),
            Text(details, style: AppType.bodySmall.copyWith(color: c.inkMuted)),
          ]),
        ),
        ReorderableDragStartListener(
          index: index,
          child: Tooltip(
            message: 'Drag to reorder',
            child: SizedBox(width: 48, height: 48, child: Icon(Icons.drag_indicator_rounded, color: c.inkMuted)),
          ),
        ),
      ]),
    );
  }
}

class _CombinedTile extends ConsumerWidget {
  const _CombinedTile({required this.combined, required this.active});
  final CombinedAccount combined;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(combinedMembersProvider(combined.id));
    return SettingsTile(
      icon: Icons.groups_2_outlined,
      title: combined.name,
      subtitle: '${active ? 'Open now · ' : ''}${members.map((m) => m.name).join(', ')} · ${combined.currencyCode}',
      trailing: MemberStack(members: members, size: 26, max: 3),
      onTap: () => context.push('/settings/accounts/combined/${combined.id}'),
    );
  }
}
