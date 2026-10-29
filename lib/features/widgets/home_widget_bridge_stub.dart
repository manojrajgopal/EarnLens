import 'home_widget_bridge.dart';

/// Web: there are no home-screen widgets.
class _UnsupportedBridge implements HomeWidgetBridge {
  @override
  bool get isSupported => false;

  @override
  Future<void> publish(WidgetPayload payload) async {}
}

HomeWidgetBridge createBridge() => _UnsupportedBridge();
