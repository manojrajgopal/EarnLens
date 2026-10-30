import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/account.dart';
import '../../../shared/widgets/components.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/account_controller.dart';
import 'account_avatar.dart';
import 'account_pin_sheet.dart';

/// Confirmation for deleting an individual account: shows exactly what will
/// be removed (its records, settings, and any combined account left with
/// fewer than two members) and requires typing the account's name.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key, required this.accountId});
  final String accountId;

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirm = TextEditingController();
  late final Future<AccountDeletionImpact> _impact =
      ref.read(accountControllerProvider).previewDelete(widget.accountId);

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _delete(Account account) async {
    final router = GoRouter.of(context);
    if (account.requiresPin &&
        !await showAccountPinSheet(context, account, mode: AccountPinMode.unlock)) {
      return;
    }
    if (!mounted) return;
    AccountDeletionImpact? done;
    final ok = await runGuarded(context, () async {
      done = await ref.read(accountControllerProvider).deleteAccount(account.id);
    });
    if (!ok || !mounted) return;
    final removed = done!.removedCombined.length;
    showMessage(
      context,
      'Deleted "${account.name}"${removed == 0 ? '' : ' and $removed combined account${removed == 1 ? '' : 's'}'}',
    );
    router.go('/settings/accounts');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final account = ref.watch(accountByIdProvider(widget.accountId));
    if (account == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox());
    }
    return SettingsPage(
      title: 'Delete account',
      children: [
        FutureBuilder<AccountDeletionImpact>(
          future: _impact,
          builder: (context, snap) {
            if (snap.hasError) {
              final message = snap.error is AppException ? (snap.error! as AppException).message : 'Could not check this account.';
              return EmptyState(icon: Icons.block_rounded, title: 'Can\'t delete this account', message: message);
            }
            final impact = snap.data;
            if (impact == null) return const LoadingState(label: 'Checking what will be deleted');
            final nameMatches = _confirm.text.trim() == account.name.trim();
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              EarnCard(
                tint: c.errorSoft,
                child: Column(children: [
                  AccountAvatar.of(account, size: 64),
                  const SizedBox(height: AppSpace.sm),
                  Text(account.name, style: AppType.title.copyWith(color: c.ink)),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    'This permanently deletes ${impact.sourceCount} income '
                    '${impact.sourceCount == 1 ? 'source' : 'sources'} and ${impact.recordCount} '
                    '${impact.recordCount == 1 ? 'record' : 'records'} (rates, payments, bonuses, monthly figures, '
                    'holidays and events) of this account, with its settings. Other accounts are not changed.',
                    textAlign: TextAlign.center,
                    style: AppType.bodySmall.copyWith(color: c.ink),
                  ),
                ]),
              ),
              if (impact.removedCombined.isNotEmpty || impact.updatedCombined.isNotEmpty)
                SettingsGroup(
                  title: 'Combined accounts',
                  footer: 'Only combined settings are removed — the other members keep all their data.',
                  children: [
                    for (final k in impact.removedCombined)
                      SettingsTile(
                        icon: Icons.group_remove_outlined,
                        danger: true,
                        title: k.name,
                        subtitle: k.memberIds.length <= 2
                            ? 'Will be removed: it would have fewer than two members'
                            : 'Will be removed: the same accounts are already combined',
                        chevron: false,
                      ),
                    for (final k in impact.updatedCombined)
                      SettingsTile(
                        icon: Icons.groups_2_outlined,
                        tone: SettingsTone.mint,
                        title: k.name,
                        subtitle: 'Keeps working with ${k.memberIds.length} accounts',
                        chevron: false,
                      ),
                  ],
                ),
              SettingsGroup(
                title: 'Before you delete',
                children: [
                  SettingsTile(
                    icon: Icons.backup_outlined,
                    tone: SettingsTone.sky,
                    title: 'Make a backup first',
                    subtitle: 'Deleted accounts can only come back from a backup',
                    onTap: () => context.push('/settings/data'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              TextField(
                controller: _confirm,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Type "${account.name}" to confirm',
                  prefixIcon: const Icon(Icons.keyboard_outlined),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: c.error, foregroundColor: Colors.white),
                  onPressed: nameMatches ? () => _delete(account) : null,
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: const Text('Delete account permanently'),
                ),
              ),
            ]);
          },
        ),
      ],
    );
  }
}
