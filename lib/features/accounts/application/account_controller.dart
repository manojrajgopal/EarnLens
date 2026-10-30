import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/security/pin_service.dart';
import '../../../domain/models/account.dart';
import '../../authentication/application/session_controller.dart';
import '../../notifications/application/notification_service.dart';
import '../../widgets/home_widget_service.dart';

/// Account-level actions that involve more than the database: switching the
/// active view, account PINs, and keeping reminders and the widget in step.
///
/// Switching only changes which records are read. It never writes, copies or
/// deletes financial records.
class AccountController {
  AccountController(this._ref);
  final Ref _ref;

  /// PIN-protected accounts of [view] that have not been unlocked yet.
  List<Account> lockedAccountsFor(AccountView view) {
    final unlocked = _ref.read(accountUnlocksProvider);
    final ids = switch (view) {
      IndividualView(:final id) => [id],
      CombinedView(:final id) => _ref.read(combinedByIdProvider(id))?.memberIds ?? const <String>[],
    };
    return [
      for (final id in ids)
        if (_ref.read(accountByIdProvider(id)) case final a? when a.requiresPin && !unlocked.contains(id)) a,
    ];
  }

  AccountScope _scopeFor(AccountView view) => switch (view) {
        IndividualView(:final id) => AccountScope.single(id),
        CombinedView(:final id) => AccountScope.readOnly({...?_ref.read(combinedByIdProvider(id))?.memberIds}),
      };

  /// Shows [view]. Its data is loaded before the switch, so the screen goes
  /// straight from the old account to the new one, never through a blank
  /// state or a mix of both. The choice is remembered across launches.
  Future<void> open(AccountView view) async {
    if (_ref.read(activeViewProvider) == view) return;
    ProviderSubscription<AsyncValue<Object>>? keepAlive;
    final scope = _scopeFor(view);
    if (lockedAccountsFor(view).isEmpty && scope.visibleAccountIds.isNotEmpty) {
      final provider = scopedSnapshotProvider(scope);
      keepAlive = _ref.listen(provider, (_, _) {});
      try {
        await _ref.read(provider.future).timeout(const Duration(seconds: 5));
      } on Object {
        // Switch anyway; the screen shows its loading or error state.
      }
    }
    _ref.read(selectedViewProvider.notifier).select(view);
    // Re-evaluates the active snapshot now, while the preloaded one is held.
    _ref.read(snapshotStreamProvider);
    keepAlive?.close();
    await _ref.read(settingsRepositoryProvider).write(SettingsKeys.activeView, view.toJson());
    _ref.read(homeWidgetServiceProvider).requestPublish();
  }

  /// Creates an individual account. Throws [AccountLimitException] at the
  /// limit. With [open] the new account becomes the active view.
  Future<Account> createAccount(Account account, {bool open = false}) async {
    await _ref.read(accountRepositoryProvider).createAccount(account);
    if (open) await this.open(IndividualView(account.id));
    return account;
  }

  Future<void> updateAccount(Account account) async {
    final before = _ref.read(accountByIdProvider(account.id));
    // The PIN flag is only changed through setAccountPin/removeAccountPin.
    await _ref
        .read(accountRepositoryProvider)
        .updateAccount(account.copyWith(requiresPin: before?.requiresPin ?? account.requiresPin));
  }

  Future<AccountDeletionImpact> previewDelete(String id) => _ref.read(accountRepositoryProvider).previewDelete(id);

  /// Deletes the account, its records, settings and PIN. Other accounts are
  /// untouched; combined accounts lose it as a member.
  Future<AccountDeletionImpact> deleteAccount(String id) async {
    final impact = await _ref.read(accountRepositoryProvider).deleteAccount(id);
    await _ref.read(pinServiceProvider).forAccount(id).clear();
    _ref.read(notificationServiceProvider).requestSync();
    _ref.read(homeWidgetServiceProvider).requestPublish();
    return impact;
  }

  /// Archives (hides from the switcher) or restores an account. Archiving
  /// the open account opens the next active one.
  Future<void> setArchived(String id, {required bool archived}) async {
    await _ref.read(accountRepositoryProvider).setArchived(id, archived: archived);
    if (archived && _ref.read(activeViewProvider) == IndividualView(id)) {
      final next = (await _ref.read(accountRepositoryProvider).accounts())
          .where((a) => !a.isArchived && a.id != id)
          .firstOrNull;
      if (next != null) await open(IndividualView(next.id));
    }
  }

  // ---- Account PIN ----------------------------------------------------------

  /// Protects [accountId] with its own PIN. Requires the app PIN, so the
  /// account PIN is an extra layer rather than the only one.
  Future<void> setAccountPin(String accountId, String pin) async {
    if (!_ref.read(pinConfiguredProvider)) {
      throw const SecurityException('Set an app PIN first. An account PIN adds to it, not replaces it.');
    }
    final account = _ref.read(accountByIdProvider(accountId));
    if (account == null) throw const NotFoundException('Account not found');
    await _ref.read(pinServiceProvider).forAccount(accountId).setPin(pin);
    await _ref.read(accountRepositoryProvider).updateAccount(account.copyWith(requiresPin: true));
    _ref.read(accountUnlocksProvider.notifier).unlock([accountId]);
    _ref.read(notificationServiceProvider).requestSync();
  }

  /// Removes the account PIN after checking it.
  Future<PinCheck> removeAccountPin(String accountId, String currentPin) async {
    final pins = _ref.read(pinServiceProvider).forAccount(accountId);
    final check = await pins.verify(currentPin);
    if (check is! PinAccepted) return check;
    final account = _ref.read(accountByIdProvider(accountId));
    if (account == null) throw const NotFoundException('Account not found');
    await pins.clear();
    await _ref.read(accountRepositoryProvider).updateAccount(account.copyWith(requiresPin: false));
    _ref.read(notificationServiceProvider).requestSync();
    return check;
  }

  /// Unlocks a protected account until the app locks again.
  Future<PinCheck> unlockAccount(String accountId, String pin) async {
    final check = await _ref.read(pinServiceProvider).forAccount(accountId).verify(pin);
    if (check is PinAccepted) _ref.read(accountUnlocksProvider.notifier).unlock([accountId]);
    return check;
  }

  // ---- Combined accounts --------------------------------------------------

  /// Throws [DuplicateCombinationException] when these accounts are already
  /// combined (in any order).
  Future<void> createCombined(CombinedAccount combined, {bool open = false}) async {
    await _ref.read(combinedAccountRepositoryProvider).create(combined);
    if (open) await this.open(CombinedView(combined.id));
  }

  Future<void> updateCombined(CombinedAccount combined) =>
      _ref.read(combinedAccountRepositoryProvider).update(combined);

  Future<void> setMembers(String combinedId, List<String> accountIds) =>
      _ref.read(combinedAccountRepositoryProvider).setMembers(combinedId, accountIds);

  /// Deletes the combined configuration only; members keep all their data.
  Future<void> deleteCombined(String id) => _ref.read(combinedAccountRepositoryProvider).delete(id);

  /// Opens a route from a notification, switching to its account first.
  Future<void> openRoute(String route, void Function(String path) go) async {
    final uri = Uri.tryParse(route);
    if (uri == null) return;
    final accountId = uri.queryParameters['account'];
    if (accountId != null && _ref.read(accountByIdProvider(accountId)) != null) {
      await open(IndividualView(accountId));
    }
    final params = {...uri.queryParameters}..remove('account');
    go(Uri(path: uri.path.isEmpty ? '/' : uri.path, queryParameters: params.isEmpty ? null : params).toString());
  }
}

final accountControllerProvider = Provider<AccountController>((ref) => AccountController(ref));
