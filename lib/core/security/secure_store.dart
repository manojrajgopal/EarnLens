import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal key-value contract over the platform keystore/keychain so
/// security services can be unit tested with an in-memory fake.
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Android Keystore / iOS Keychain backed storage. On the web the plugin
/// encrypts values with WebCrypto before storing them in localStorage, which
/// is weaker than hardware-backed storage (documented in docs/SECURITY.md).
class PlatformSecureStore implements SecureStore {
  const PlatformSecureStore();

  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class InMemorySecureStore implements SecureStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
