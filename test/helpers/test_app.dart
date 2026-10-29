import 'dart:typed_data';

import 'package:earnlens/app.dart';
import 'package:earnlens/bootstrap/dependency_injection.dart';
import 'package:earnlens/core/clock.dart';
import 'package:earnlens/core/platform/file_service.dart';
import 'package:earnlens/core/security/biometric_service.dart';
import 'package:earnlens/core/security/pin_service.dart';
import 'package:earnlens/core/security/secure_store.dart';
import 'package:earnlens/database/app_database.dart';
import 'package:earnlens/features/authentication/application/session_controller.dart';
import 'package:earnlens/features/notifications/domain/notification_models.dart';
import 'package:earnlens/features/widgets/home_widget_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fixtures.dart';

class FakeNotifications implements NotificationProvider {
  List<PlannedNotification> scheduled = [];

  @override
  String get id => 'fake';
  @override
  bool get isSupported => true;
  @override
  bool get exactTiming => true;
  @override
  Future<NotificationPermission> permissionStatus() async => NotificationPermission.granted;
  @override
  Future<NotificationPermission> requestPermission() async => NotificationPermission.granted;
  @override
  Future<void> replaceAll(List<PlannedNotification> planned) async => scheduled = planned;
  @override
  Future<void> cancelAll() async => scheduled = [];
}

class FakeBridge implements HomeWidgetBridge {
  WidgetPayload? last;
  @override
  bool get isSupported => true;
  @override
  Future<void> publish(WidgetPayload payload) async => last = payload;
}

class FakeFiles implements FileService {
  @override
  Future<PickedFile?> pick({List<String>? extensions}) async => null;
  @override
  Future<bool> save(String fileName, Uint8List bytes, String mimeType) async => true;
  @override
  Future<void> share(String fileName, Uint8List bytes, String mimeType) async {}
}

/// Builds the real app on an in-memory database with fake platform services.
Widget testApp({
  required AppDatabase db,
  required InMemorySecureStore store,
  required Clock clock,
  bool hasPin = false,
  FakeNotifications? notifications,
}) {
  calendarFor('Asia/Kolkata'); // initialises the tz database
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      deviceTimezoneProvider.overrideWithValue('Asia/Kolkata'),
      clockProvider.overrideWithValue(clock),
      secureStoreProvider.overrideWithValue(store),
      pinServiceProvider.overrideWithValue(PinService(store, clock, iterations: 1000, useIsolate: false)),
      biometricServiceProvider.overrideWithValue(const UnavailableBiometricService()),
      fileServiceProvider.overrideWithValue(FakeFiles()),
      homeWidgetBridgeProvider.overrideWithValue(FakeBridge()),
      notificationProviderProvider.overrideWithValue(notifications ?? FakeNotifications()),
      hasPinAtLaunchProvider.overrideWithValue(hasPin),
    ],
    child: const EarnLensApp(),
  );
}
