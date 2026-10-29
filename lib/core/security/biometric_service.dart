import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Device biometrics (fingerprint / Face ID). Not available on the web —
/// the app never pretends otherwise.
abstract interface class BiometricService {
  Future<bool> isAvailable();
  Future<bool> authenticate(String reason);
}

class PlatformBiometricService implements BiometricService {
  PlatformBiometricService() : _auth = LocalAuthentication();
  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: true);
    } on Object {
      return false;
    }
  }
}

class UnavailableBiometricService implements BiometricService {
  const UnavailableBiometricService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate(String reason) async => false;
}
