import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/dependency_injection.dart';
import '../../../domain/models/settings.dart';

class SessionState {
  const SessionState({required this.locked, this.backgroundedAt, this.revealAmounts = false});

  final bool locked;
  final DateTime? backgroundedAt;

  /// Privacy mode: amounts are shown only after the user taps "show".
  final bool revealAmounts;

  SessionState copyWith({bool? locked, DateTime? backgroundedAt, bool clearBackgrounded = false, bool? revealAmounts}) =>
      SessionState(
        locked: locked ?? this.locked,
        backgroundedAt: clearBackgrounded ? null : (backgroundedAt ?? this.backgroundedAt),
        revealAmounts: revealAmounts ?? this.revealAmounts,
      );
}

/// App lock state. Starts locked whenever a PIN exists ([hasPinAtLaunch]);
/// re-locks on resume according to the auto-lock preference.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => SessionState(locked: ref.read(hasPinAtLaunchProvider));

  void unlock() => state = state.copyWith(locked: false, clearBackgrounded: true);

  /// Locks the app. PIN-protected accounts need their own PIN again too.
  void lock() {
    state = state.copyWith(locked: true, revealAmounts: false);
    ref.read(accountUnlocksProvider.notifier).clear();
  }

  void toggleReveal() => state = state.copyWith(revealAmounts: !state.revealAmounts);

  void onBackgrounded() {
    if (state.backgroundedAt == null) {
      state = state.copyWith(backgroundedAt: ref.read(clockProvider).now());
    }
    final policy = ref.read(securitySettingsProvider).autoLock;
    if (policy == AutoLock.immediately && _pinEnabled) lock();
  }

  void onResumed() {
    final since = state.backgroundedAt;
    state = state.copyWith(clearBackgrounded: true);
    if (since == null || !_pinEnabled) return;
    final delay = ref.read(securitySettingsProvider).autoLock.delay;
    if (delay == null) return; // only lock on restart
    if (ref.read(clockProvider).now().difference(since) >= delay) lock();
  }

  bool get _pinEnabled => ref.read(pinConfiguredProvider);
}

/// Whether a PIN existed when the app started (set during bootstrap).
final hasPinAtLaunchProvider = Provider<bool>((ref) => false);

/// Whether a PIN is currently configured (updated after setup/reset).
final pinConfiguredProvider = NotifierProvider<PinConfigured, bool>(PinConfigured.new);

class PinConfigured extends Notifier<bool> {
  @override
  bool build() => ref.read(hasPinAtLaunchProvider);

  void set(bool value) => state = value;
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);

/// True when amounts should be masked right now.
final hideAmountsProvider = Provider<bool>((ref) {
  final privacy = ref.watch(securitySettingsProvider).privacyMode;
  return privacy && !ref.watch(sessionProvider).revealAmounts;
});
