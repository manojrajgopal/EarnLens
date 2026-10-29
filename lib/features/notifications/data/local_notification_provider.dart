import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/notification_models.dart';

typedef NotificationTapHandler = void Function(String route);

/// Device notifications through flutter_local_notifications.
///
/// * Android/iOS: scheduled with the OS (`zonedSchedule`), delivered even when
///   the app is closed. Android uses inexact alarms unless exact alarms are
///   permitted, so delivery can drift by some minutes.
/// * Web: browsers cannot schedule notifications in the background, so they
///   are shown by in-page timers only while EarnLens is open in a tab.
class LocalNotificationProvider implements NotificationProvider {
  LocalNotificationProvider({this.onTap});

  final NotificationTapHandler? onTap;
  final _plugin = FlutterLocalNotificationsPlugin();
  final List<Timer> _webTimers = [];
  bool _initialized = false;
  bool _exactAllowed = false;

  static const _channel = AndroidNotificationDetails(
    'earnlens_reminders',
    'Reminders',
    channelDescription: 'Payment, review and backup reminders',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    visibility: NotificationVisibility.private,
  );

  static const _details = NotificationDetails(
    android: _channel,
    iOS: DarwinNotificationDetails(),
  );

  @override
  String get id => 'local';

  @override
  bool get isSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  bool get exactTiming => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || _exactAllowed);

  Future<void> _init() async {
    if (_initialized || !isSupported) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        web: WebInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (r) {
        final route = r.payload;
        if (route != null && route.startsWith('/')) onTap?.call(route);
      },
    );
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _exactAllowed = await _android?.canScheduleExactNotifications() ?? false;
    }
    _initialized = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Route of the notification that launched the app, if any.
  Future<String?> launchRoute() async {
    if (!isSupported || kIsWeb) return null;
    await _init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    final payload = details?.notificationResponse?.payload;
    return details?.didNotificationLaunchApp == true ? payload : null;
  }

  @override
  Future<NotificationPermission> permissionStatus() async {
    if (!isSupported) return NotificationPermission.unsupported;
    await _init();
    if (kIsWeb) {
      final web = _plugin.resolvePlatformSpecificImplementation<WebFlutterLocalNotificationsPlugin>();
      return web?.permissionStatus == WebNotificationPermission.granted
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return (await _android?.areNotificationsEnabled() ?? false)
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final options = await ios?.checkPermissions();
    return options?.isEnabled == true ? NotificationPermission.granted : NotificationPermission.denied;
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    if (!isSupported) return NotificationPermission.unsupported;
    await _init();
    bool? granted;
    if (kIsWeb) {
      granted = await _plugin
          .resolvePlatformSpecificImplementation<WebFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      granted = await _android?.requestNotificationsPermission();
    } else {
      granted = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    return granted == true ? NotificationPermission.granted : NotificationPermission.denied;
  }

  @override
  Future<void> replaceAll(List<PlannedNotification> planned) async {
    if (!isSupported) return;
    await _init();
    await cancelAll();
    if (kIsWeb) {
      _scheduleWebTimers(planned);
      return;
    }
    final mode = _exactAllowed ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;
    for (final n in planned) {
      await _plugin.zonedSchedule(
        id: n.platformId,
        title: n.title,
        body: n.body,
        scheduledDate: tz.TZDateTime.fromMicrosecondsSinceEpoch(tz.UTC, n.atMicros),
        notificationDetails: _details,
        androidScheduleMode: mode,
        payload: n.route,
      );
    }
  }

  void _scheduleWebTimers(List<PlannedNotification> planned) {
    final now = DateTime.now().microsecondsSinceEpoch;
    for (final n in planned) {
      final delay = n.atMicros - now;
      if (delay <= 0 || delay > const Duration(hours: 24).inMicroseconds) continue;
      _webTimers.add(Timer(Duration(microseconds: delay), () {
        _plugin.show(id: n.platformId, title: n.title, body: n.body, payload: n.route);
      }));
    }
  }

  @override
  Future<void> cancelAll() async {
    for (final t in _webTimers) {
      t.cancel();
    }
    _webTimers.clear();
    if (!isSupported) return;
    await _init();
    if (!kIsWeb) await _plugin.cancelAllPendingNotifications();
  }
}
