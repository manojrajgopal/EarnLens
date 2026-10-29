import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

import 'home_widget_bridge.dart';

/// Android: data is written to the plugin's SharedPreferences and rendered
/// by `EarningsWidgetProvider` (android/app/src/main/kotlin/...).
/// iOS: WidgetKit extension is not yet part of the project (see
/// docs/PLATFORM_SUPPORT.md), so publishing is a no-op there.
class _PlatformBridge implements HomeWidgetBridge {
  static const androidProvider = 'EarningsWidgetProvider';

  @override
  bool get isSupported => Platform.isAndroid;

  @override
  Future<void> publish(WidgetPayload p) async {
    if (!isSupported) return;
    try {
      await HomeWidget.saveWidgetData<String>('el_title', p.title);
      await HomeWidget.saveWidgetData<String>('el_rate', p.rateText);
      await HomeWidget.saveWidgetData<bool>('el_hidden', p.hidden);
      await HomeWidget.saveWidgetData<String>(
        'el_checkpoints',
        jsonEncode(p.checkpoints.map((c) => c.toJson()).toList()),
      );
      await HomeWidget.saveWidgetData<String>('el_generated', '${p.generatedAtMillis}');
      await HomeWidget.updateWidget(androidName: androidProvider);
    } on Object {
      // A missing widget host must never break the app.
    }
  }
}

HomeWidgetBridge createBridge() => _PlatformBridge();
