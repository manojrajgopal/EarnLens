import '../../core/security/pin_service.dart';
import '../../database/app_database.dart';
import '../../features/notifications/domain/notification_models.dart';

/// Erases every local record, the PIN verifier and scheduled notifications.
/// Used by "Delete all data" and by the forgotten-PIN reset.
class DataWiper {
  const DataWiper(this.db, this.pins, this.notifications);

  final AppDatabase db;
  final PinService pins;
  final NotificationProvider notifications;

  Future<void> wipeEverything() async {
    await db.transaction(() async {
      for (final t in db.tablesInInsertOrder.reversed) {
        await db.delete(t).go();
      }
    });
    await pins.clear();
    try {
      await notifications.cancelAll();
    } on Object {
      // Notification plugin may be unavailable on this platform.
    }
  }
}
