import 'package:flutter/services.dart';

const _channel = MethodChannel('ezhednevnik_v2/downloads');

Future<String?> saveBackupToDownloads({
  required String fileName,
  required List<int> bytes,
}) async {
  try {
    return _channel.invokeMethod<String>('saveBackupToDownloads', {
      'fileName': fileName,
      'bytes': Uint8List.fromList(bytes),
    });
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}

Future<String?> saveBackupFileToDownloads({
  required String fileName,
  required String sourcePath,
}) async {
  try {
    return _channel.invokeMethod<String>('saveBackupFileToDownloads', {
      'fileName': fileName,
      'sourcePath': sourcePath,
    });
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}
