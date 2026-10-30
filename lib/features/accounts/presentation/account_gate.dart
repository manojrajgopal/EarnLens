import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/account.dart';
import '../../../shared/widgets/components.dart';
import 'account_avatar.dart';
import 'account_pin_sheet.dart';
import 'account_switcher_sheet.dart';

/// Covers the app while the open account (or a member of the open combined
/// account) is PIN-protected and not unlocked. Its data is not even loaded
/// until then: the account scope stays empty.
class AccountGate extends ConsumerWidget {
  const AccountGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = ref.watch(lockedViewAccountsProvider);
    return Stack(children: [
      // Kept alive (tab state survives) but hidden and inert while locked.
      Visibility(
        visible: locked.isEmpty,
        maintainState: true,
        child: child,
      ),
      if (locked.isNotEmpty) Positioned.fill(child: _LockedView(accounts: locked)),
    ]);
  }
}

class _LockedView extends ConsumerWidget {
  const _LockedView({required this.accounts});
  final List<Account> accounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final combined = ref.watch(activeCombinedProvider);
    final title = combined == null ? '${accounts.first.name} is protected' : '${combined.name} includes protected accounts';
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: EarnCard(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Wrap(spacing: -10, children: [
                  for (final a in accounts.take(4)) AccountAvatar.of(a, size: 64, locked: true, ring: true),
                ]),
                const SizedBox(height: AppSpace.lg),
                Semantics(
                  header: true,
                  child: Text(title, textAlign: TextAlign.center, style: AppType.title.copyWith(color: c.ink)),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  accounts.length == 1
                      ? 'Enter its PIN to see its income and payments.'
                      : 'Enter the PIN of each protected account to continue.',
                  textAlign: TextAlign.center,
                  style: AppType.bodySmall.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: AppSpace.lg),
                BusyButton(
                  label: 'Unlock',
                  accent: true,
                  onPressed: () async {
                    for (final a in accounts) {
                      if (!context.mounted || !await showAccountPinSheet(context, a)) return;
                    }
                  },
                ),
                const SizedBox(height: AppSpace.sm),
                TextButton.icon(
                  onPressed: () => showAccountSwitcher(context),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Switch account'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps screens that change records. In a combined (read-only) view it
/// explains why nothing can be changed and offers to open the account that
/// owns [sourceId] (or picks an account when unknown).
class ReadOnlyGuard extends ConsumerWidget {
  const ReadOnlyGuard({super.key, required this.child, this.sourceId});
  final Widget child;
  final String? sourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isReadOnlyViewProvider)) return child;
    final c = context.colors;
    final ownerId = sourceId == null ? null : ref.watch(sourceProvider(sourceId!))?.accountId;
    final owner = ownerId == null ? null : ref.watch(accountByIdProvider(ownerId));
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(),
      body: EmptyState(
        icon: Icons.visibility_outlined,
        title: 'Combined accounts are read-only',
        message: owner == null
            ? 'Open an individual account to add or change income and payments.'
            : 'This belongs to ${owner.name}. Open ${owner.name}\'s account to make changes here.',
        action: owner == null ? 'Choose an account' : 'Open ${owner.name}',
        onAction: () async {
          if (owner == null) {
            await showAccountSwitcher(context);
          } else {
            // Stay on this screen: once the member's account is open the
            // guard steps aside and the form appears.
            await openAccountView(context, ref, IndividualView(owner.id));
          }
        },
      ),
    );
  }
}

/// Small banner for screens that stay readable in a combined view but whose
/// edit actions are hidden.
class ReadOnlyBanner extends ConsumerWidget {
  const ReadOnlyBanner({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combined = ref.watch(activeCombinedProvider);
    if (combined == null) return const SizedBox.shrink();
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Material(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => showAccountSwitcher(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(children: [
              Icon(Icons.visibility_outlined, size: 20, color: c.accentText),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  message ?? 'Viewing ${combined.name} (read-only). Switch to an account to make changes.',
                  style: AppType.bodySmall.copyWith(color: c.ink),
                ),
              ),
              Icon(Icons.swap_horiz_rounded, size: 20, color: c.accentText),
            ]),
          ),
        ),
      ),
    );
  }
}
