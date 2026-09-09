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

  Future<SyncRunResult> synchronize(List<MemoryItem> items) async {
    final referenced = referencedNames(items);
    final remoteNames = await remote.listMediaNames();
    var downloaded = 0;
    var uploaded = 0;
    var failed = 0;

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
          // Файла нет ни здесь, ни в облаке: запись ссылается на потерянное.
          // Придумывать нечего, карточка и так покажет пустое место.
          if (!await storage.exists(name)) continue;
          await remote.uploadMedia(
            name,
            await vault.encryptBytes(
              await storage.readPlainBytes(name, atRest),
            ),
          );
          uploaded++;
        }
      } on Object {
        // Сорвавшийся снимок не должен ронять прогон целиком: записи важнее,
        // а файл доедет на следующем заходе. Счёт неудач уходит в итог, чтобы
        // это не осталось незамеченным.
        failed++;
      }
    }

    // В облаке осталось то, на что не ссылается ни одна запись, — значит,
    // запись удалили. Список записей здесь уже слитый, то есть содержит и
    // чужие; удаляется только по-настоящему ничьё.
    final orphans = remoteNames.difference(referenced);
    await remote.deleteMedia(orphans);

    return SyncRunResult(
      downloaded: 0,
      uploaded: 0,
      deleted: 0,
      mediaDownloaded: downloaded,
      mediaUploaded: uploaded,
      mediaFailed: failed,
    );
  }

  /// Имена вложений, на которые ссылаются записи.
  ///
  /// Снимки, оставшиеся строкой внутри самой записи, сюда не попадают: они
  /// уже уехали вместе с ней и отдельного файла у них нет.
  static Set<String> referencedNames(List<MemoryItem> items) => {
        for (final item in items)
          for (final reference in item.mediaReferences)
            if (!MediaStorage.isExternal(reference))
              MediaStorage.referenceFor(reference),
      };
}
