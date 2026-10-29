import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android: toggles FLAG_SECURE so the app-switcher preview and screenshots
/// do not reveal amounts while privacy mode is on (see MainActivity.kt).
/// Other platforms rely on the in-app privacy overlay.
class PrivacyChannel {
  static const _channel = MethodChannel('earnlens/privacy');

  static Future<void> setSecure(bool secure) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('setSecure', secure);
    } on PlatformException {
      // Not fatal: the overlay still hides amounts.
    } on MissingPluginException {
      // Running in a test or an embedding without the channel.
    }
  }
}
