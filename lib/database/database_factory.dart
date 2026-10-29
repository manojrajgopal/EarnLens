import 'package:drift_flutter/drift_flutter.dart';

import 'app_database.dart';

/// Opens the on-device database. Native platforms use SQLite in the app
/// documents directory; the web uses SQLite compiled to WebAssembly with
/// OPFS/IndexedDB storage (see docs/PLATFORM_SUPPORT.md).
AppDatabase openAppDatabase() => AppDatabase(
      driftDatabase(
        name: 'earnlens',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
      ),
    );
