import 'package:flutter/services.dart';

const _channel = MethodChannel('ezhednevnik_v2/downloads');

Future<String?> saveBytesToDownloads({
  required String fileName,
  required List<int> bytes,
}) =>
    _invoke('saveBytes', {
      'fileName': fileName,
      'bytes': Uint8List.fromList(bytes),
    });

Future<String?> saveFileToDownloads({
  required String fileName,
  required String sourcePath,
}) =>
    _invoke('saveFile', {'fileName': fileName, 'sourcePath': sourcePath});

Future<String?> _invoke(String method, Map<String, Object> arguments) async {
  try {
    return await _channel.invokeMethod<String>(method, arguments);
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}
