import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

class PickedFile {
  const PickedFile(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

/// Saving, sharing and opening user files. Android uses the system document
/// picker (Storage Access Framework), iOS the Files app, and the web a
/// browser download / file input — no storage permissions are requested.
abstract interface class FileService {
  /// Returns false when the user cancelled.
  Future<bool> save(String fileName, Uint8List bytes, String mimeType);
  Future<void> share(String fileName, Uint8List bytes, String mimeType);
  Future<PickedFile?> pick({List<String>? extensions});
}

class PlatformFileService implements FileService {
  const PlatformFileService();

  @override
  Future<bool> save(String fileName, Uint8List bytes, String mimeType) async {
    final uri = await FilePicker.saveFile(fileName: fileName, bytes: bytes, mimeType: mimeType);
    return uri != null;
  }

  @override
  Future<void> share(String fileName, Uint8List bytes, String mimeType) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(bytes, name: fileName, mimeType: mimeType)],
      fileNameOverrides: [fileName],
    ));
  }

  @override
  Future<PickedFile?> pick({List<String>? extensions}) async {
    final file = await FilePicker.pickFile(
      type: extensions == null ? FileType.any : FileType.custom,
      allowedExtensions: extensions,
    );
    if (file == null) return null;
    return PickedFile(file.name, await file.readAsBytes());
  }
}
