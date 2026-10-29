import 'home_widget_bridge_stub.dart' if (dart.library.io) 'home_widget_bridge_io.dart' as impl;

/// One precomputed point for the home-screen widget.
class WidgetCheckpoint {
  const WidgetCheckpoint(this.atMillis, this.text);
  final int atMillis;
  final String text;

  Map<String, Object> toJson() => {'t': atMillis, 'v': text};
}

/// Data the native widget renders. Home-screen widgets cannot run the Dart
/// calculation engine, so the app precomputes exact values at checkpoints
/// for the next day; the widget shows the latest checkpoint and its time.
class WidgetPayload {
  const WidgetPayload({
    required this.title,
    required this.checkpoints,
    required this.rateText,
    required this.hidden,
    required this.generatedAtMillis,
  });

  final String title;
  final List<WidgetCheckpoint> checkpoints;
  final String rateText;

  /// When true the widget shows no amounts (privacy preference).
  final bool hidden;
  final int generatedAtMillis;
}

abstract interface class HomeWidgetBridge {
  bool get isSupported;
  Future<void> publish(WidgetPayload payload);
}

HomeWidgetBridge createHomeWidgetBridge() => impl.createBridge();
