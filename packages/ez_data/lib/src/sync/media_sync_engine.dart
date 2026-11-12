import 'dart:async';

import 'package:ez_domain/ez_domain.dart';

import '../media/media_storage.dart';
import '../security/app_cipher.dart';
import 'sync_remote_store.dart';

/// Синхронизация вложений: самих файлов, а не ссылок на них.
///
/// Записи ездят слепками в одной таблице, которую прогон вычитывает целиком, —
/// снимку весом в мегабайты там не место. Поэтому файлы лежат отдельным
/// хранилищем, а связывает их с записью имя: оно одно на все устройства.
class MediaSyncEngine {
  const MediaSyncEngine({
    required this.remote,
    required this.storage,
    required this.vault,
    required this.atRest,
  });

  final SyncRemoteStore remote;
  final MediaStorage storage;

  /// Ключ хранилища. Им зашифровано всё, что уезжает в облако, — как и слепки
  /// записей.
  final AppCipher vault;

  /// Местное шифрование на диске. Null означает, что PIN не задан и файлы
  /// лежат открытыми. У каждого устройства своё, поэтому в облако байты
  /// всегда едут в одном виде — зашифрованные ключом хранилища.
  final AppCipher? atRest;

  /// [references] — все ссылки на вложения в слитых данных, см.
  /// `mediaReferencesOf`.
  Future<SyncRunResult> synchronize(Iterable<String> references) async {
    final referenced = MediaStorage.storedNames(references);
    final remoteNames = await remote.listMediaNames();
    var downloaded = 0;
    var uploaded = 0;
    var failed = 0;
    var missing = 0;

    for (final name in referenced) {
      try {
        if (remoteNames.contains(name)) {
          if (await storage.exists(name)) continue;
          await storage.writePlainBytes(
            name,
            await vault.decryptBytes(await remote.downloadMedia(name)),
            atRest,
          );
          downloaded++;
        } else {
          // Файла нет ни здесь, ни в облаке: другое устройство ещё не
          // дозалило его к приехавшей записи — или он потерян. Придумывать
          // нечего, карточка покажет пустое место, а сверка повторится.
          if (!await storage.exists(name)) {
            missing++;
            continue;
          }
          await remote.uploadMedia(
            name,
            await vault.encryptBytes(
              await storage.readPlainBytes(name, atRest),
            ),
          );
          uploaded++;
        }
      } on TimeoutException {
        // Stop an offline run instead of waiting again for every remaining file.
        rethrow;
      } on Object {
        // Сорвавшийся снимок не должен ронять прогон целиком: записи важнее,
        // а файл доедет на следующем заходе. Счёт неудач уходит в итог, чтобы
        // это не осталось незамеченным.
        failed++;
      }
    }

    // В облаке осталось то, на что не ссылаются данные, — значит, запись
    // удалили. Ссылки здесь из уже слитых данных, то есть и чужие; удаляется
    // только по-настоящему ничьё.
    final orphans = remoteNames.difference(referenced);
    await remote.deleteMedia(orphans);

    return SyncRunResult(
      downloaded: 0,
      uploaded: 0,
      deleted: 0,
      mediaDownloaded: downloaded,
      mediaUploaded: uploaded,
      mediaFailed: failed,
      mediaMissing: missing,
    );
  }
}
