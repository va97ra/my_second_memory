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
