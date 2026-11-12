import 'dart:typed_data';

import 'package:ez_data/ez_data.dart';
import 'package:file_selector/file_selector.dart';

/// Куда лёг файл, который человек сохраняет себе.
enum SavedTo {
  /// В «Загрузки» телефона, без вопросов.
  downloads,

  /// Туда, куда указал человек: «Загрузок» здесь нет.
  chosenPlace,

  /// Человек передумал и закрыл окно выбора.
  nowhere,
}

/// Отдаёт человеку файл: сначала в «Загрузки», а где их нет — спрашивает
/// место. Источник — либо [bytes], либо готовый файл [sourcePath] (крупный
/// переписывается потоком).
Future<SavedTo> saveUserFile({
  required String fileName,
  required XTypeGroup type,
  Uint8List? bytes,
  String? sourcePath,
}) async {
  assert((bytes == null) != (sourcePath == null), 'bytes или sourcePath');
  final downloaded = sourcePath != null
      ? await DownloadsSaver.saveFile(
          fileName: fileName,
          sourcePath: sourcePath,
        )
      : await DownloadsSaver.saveBytes(fileName: fileName, bytes: bytes!);
  if (downloaded != null) return SavedTo.downloads;

  final location = await getSaveLocation(
    acceptedTypeGroups: [type],
    suggestedName: fileName,
  );
  if (location == null) return SavedTo.nowhere;
  final file = sourcePath != null
      ? XFile(sourcePath)
      : XFile.fromData(
          bytes!,
          mimeType: type.mimeTypes?.firstOrNull,
          name: location.path.split(RegExp(r'[\/]')).last,
        );
  await file.saveTo(location.path);
  return SavedTo.chosenPlace;
}
