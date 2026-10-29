import '../../../domain/models/settings.dart';

/// A notification the app intends to schedule. [key] is stable for the
/// underlying event so rescheduling never produces duplicates.
class PlannedNotification {
  const PlannedNotification({
    required this.key,
    required this.category,
    required this.title,
    required this.body,
    required this.atMicros,
    this.route = '/',
  });

  final String key;
  final NotificationCategory category;
  final String title;
  final String body;

  /// UTC instant in microseconds.
  final int atMicros;

  /// In-app route opened when the notification is tapped.
  final String route;

  /// Stable 31-bit id derived from [key] (FNV-1a).
  int get platformId {
    var h = 0x811c9dc5;
    for (final c in key.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h & 0x7fffffff;
  }
}

enum NotificationPermission { granted, denied, unsupported }

/// Delivery channel abstraction. Local device notifications are implemented
/// today; email, SMS and push providers belong to a future backend and plug
/// in by implementing this interface (see docs/NOTIFICATIONS.md).
abstract interface class NotificationProvider {
  String get id;
  bool get isSupported;

  /// Whether scheduled times are exact on this platform.
  bool get exactTiming;
  Future<NotificationPermission> permissionStatus();
  Future<NotificationPermission> requestPermission();

  /// Replaces every pending notification with [planned].
  Future<void> replaceAll(List<PlannedNotification> planned);
  Future<void> cancelAll();
}
