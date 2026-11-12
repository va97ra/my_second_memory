import 'downloads_saver_stub.dart'
    if (dart.library.io) 'downloads_saver_io.dart'
    if (dart.library.html) 'downloads_saver_web.dart';

/// Кладёт файл в «Загрузки» телефона — туда, где человек его найдёт сам.
///
/// Тип файла система узнаёт по расширению имени. Возвращает, куда легло, или
/// `null`, если «Загрузок» здесь нет (Windows, веб) или запись не удалась:
/// тогда место спрашивают у человека.
abstract final class DownloadsSaver {
  static Future<String?> saveBytes({
    required String fileName,
    required List<int> bytes,
  }) =>
      saveBytesToDownloads(fileName: fileName, bytes: bytes);

  /// Крупный файл переписывается с диска потоком, не целиком в память.
  static Future<String?> saveFile({
    required String fileName,
    required String sourcePath,
  }) =>
      saveFileToDownloads(fileName: fileName, sourcePath: sourcePath);
}
