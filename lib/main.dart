import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap/app_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = await initializeApp();
  runApp(UncontrolledProviderScope(container: container, child: const EarnLensApp()));
}
