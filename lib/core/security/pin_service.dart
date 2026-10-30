import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../clock.dart';
import '../errors/app_exception.dart';
import 'secure_store.dart';

sealed class PinCheck {
  const PinCheck();
}

class PinAccepted extends PinCheck {
  const PinAccepted();
}

class PinRejected extends PinCheck {
  const PinRejected({required this.failedAttempts, this.lockedFor});
  final int failedAttempts;

  /// Non-null when further attempts are blocked for a while.
  final Duration? lockedFor;
}

class PinLockedOut extends PinCheck {
  const PinLockedOut(this.remaining);
  final Duration remaining;
}

/// Local PIN verification.
///
/// * The PIN is never stored: only a PBKDF2-HMAC-SHA256 verifier with a
///   unique 16-byte random salt, kept in the platform secure store.
/// * Comparison is constant-time.
/// * After [freeAttempts] failures each further failure locks input for an
///   exponentially growing delay (30 s, 60 s, ... capped at 1 h). The counter
///   survives app restarts because it lives in the secure store.
///
/// The app PIN uses the `pin.*` keys. An account PIN (optional extra lock on
/// one account) is an independent verifier under its own [keyPrefix], with
/// its own failure counter and lockout — see [forAccount].
class PinService {
  PinService(
    this.store,
    this.clock, {
    this.iterations = defaultIterations,
    this.useIsolate = true,
    this.keyPrefix = 'pin',
  });

  static const defaultIterations = 150000;
  static const freeAttempts = 5;
  static const minLength = 4;
  static const maxLength = 8;

  String get _kVerifier => '$keyPrefix.verifier';
  String get _kFailures => '$keyPrefix.failures';
  String get _kLockedUntil => '$keyPrefix.lockedUntil';

  final SecureStore store;
  final Clock clock;
  final int iterations;

  /// Secure-store key namespace of this verifier.
  final String keyPrefix;

  /// The independent PIN of one account, stored and rate-limited separately
  /// from the app PIN.
  PinService forAccount(String accountId) =>
      PinService(store, clock, iterations: iterations, useIsolate: useIsolate, keyPrefix: 'account.$accountId.pin');

  /// Derive keys on a background isolate (keeps the UI responsive). Tests
  /// running in a fake-async zone set this to false.
  final bool useIsolate;

  Future<bool> hasPin() async => (await store.read(_kVerifier)) != null;

  static String? validateNewPin(String pin) {
    if (!RegExp(r'^\d+$').hasMatch(pin)) return 'Use digits only';
    if (pin.length < minLength || pin.length > maxLength) {
      return 'Use $minLength to $maxLength digits';
    }
    if (RegExp(r'^(\d)\1+$').hasMatch(pin)) return 'Avoid repeating the same digit';
    const asc = '01234567890';
    const desc = '09876543210';
    if (asc.contains(pin) || desc.contains(pin)) return 'Avoid simple sequences like 1234';
    return null;
  }

  Future<void> setPin(String pin) async {
    final problem = validateNewPin(pin);
    if (problem != null) throw ValidationException(problem, field: 'pin');
    final rnd = Random.secure();
    final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
    final hash = await _derive(pin, salt, iterations, useIsolate);
    await store.write(
      _kVerifier,
      jsonEncode({
        'v': 1,
        'alg': 'pbkdf2-hmac-sha256',
        'it': iterations,
        'salt': base64Encode(salt),
        'hash': base64Encode(hash),
      }),
    );
    await _resetFailures();
  }

  Future<PinCheck> verify(String pin) async {
    final lockedUntil = await _lockedUntil();
    final now = clock.now();
    if (lockedUntil != null && lockedUntil.isAfter(now)) {
      return PinLockedOut(lockedUntil.difference(now));
    }
    final raw = await store.read(_kVerifier);
    if (raw == null) throw const SecurityException('No PIN has been set');
    final v = (jsonDecode(raw) as Map).cast<String, dynamic>();
    final salt = base64Decode(v['salt'] as String);
    final expected = base64Decode(v['hash'] as String);
    final actual = await _derive(pin, salt, v['it'] as int, useIsolate);
    if (_constantTimeEquals(expected, actual)) {
      await _resetFailures();
      return const PinAccepted();
    }
    final failures = (int.tryParse(await store.read(_kFailures) ?? '') ?? 0) + 1;
    await store.write(_kFailures, '$failures');
    final delay = lockoutFor(failures);
    if (delay != null) {
      await store.write(_kLockedUntil, '${now.add(delay).microsecondsSinceEpoch}');
    }
    return PinRejected(failedAttempts: failures, lockedFor: delay);
  }

  /// Lockout after the [failures]th consecutive failure.
  static Duration? lockoutFor(int failures) {
    if (failures < freeAttempts) return null;
    final exp = (failures - freeAttempts).clamp(0, 7);
    final seconds = 30 * (1 << exp);
    return Duration(seconds: seconds > 3600 ? 3600 : seconds);
  }

  Future<Duration?> remainingLockout() async {
    final until = await _lockedUntil();
    final now = clock.now();
    return until != null && until.isAfter(now) ? until.difference(now) : null;
  }

  Future<void> changePin(String current, String next) async {
    final check = await verify(current);
    if (check is! PinAccepted) throw const SecurityException('Current PIN is incorrect');
    await setPin(next);
  }

  /// Removes the PIN verifier. Callers must only do this after biometric
  /// re-authentication or as part of erasing all local data.
  Future<void> clear() async {
    await store.delete(_kVerifier);
    await _resetFailures();
  }

  Future<void> _resetFailures() async {
    await store.delete(_kFailures);
    await store.delete(_kLockedUntil);
  }

  Future<DateTime?> _lockedUntil() async {
    final raw = await store.read(_kLockedUntil);
    final micros = raw == null ? null : int.tryParse(raw);
    return micros == null ? null : DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true);
  }

  static Future<List<int>> _derive(String pin, List<int> salt, int iterations, bool isolate) =>
      isolate ? compute(_deriveSync, (pin, salt, iterations)) : _deriveSync((pin, salt, iterations));

  static Future<List<int>> _deriveSync((String, List<int>, int) args) async {
    final (pin, salt, iterations) = args;
    final kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
    final key = await kdf.deriveKey(secretKey: SecretKey(utf8.encode(pin)), nonce: salt);
    return key.extractBytes();
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
