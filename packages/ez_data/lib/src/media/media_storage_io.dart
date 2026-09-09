import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../security/app_cipher.dart';

class MediaStorage {
  static const encryptedExtension = '.ezm';

  /// Каталог вложений. Читается один раз при запуске, потому что превью в
  /// списке нужен путь прямо в `build`, а `getApplicationDocumentsDirectory`
  /// асинхронен.
  static String? _root;

  static Future<String> initialize() async =>
      _root ??= (await getApplicationDocumentsDirectory()).path;

  /// Только для тестов: подменить каталог вложений.
  static set debugRoot(String? value) => _root = value;

  /// Ссылка на вложение → путь на этом устройстве.
  ///
  /// В записи хранится имя файла, а не путь: путь свой у каждого устройства,
  /// и запись, приехавшая с чужого телефона, указывала бы в пустоту. Каталог
  /// подставляется здесь и только здесь.
  ///
  /// [encrypted] — шифруются ли вложения на диске у этого устройства, то есть
  /// задан ли PIN. Флаг здесь не хранится: правда о нём одна и живёт в
  /// состоянии безопасности, сюда её передаёт тот, кто её и так знает.
  static String resolve(String reference, {bool encrypted = false}) {
    if (isExternal(reference)) return reference;
    final root = _root;
    if (root == null) {
      throw StateError('MediaStorage.initialize() has not been awaited');
    }
    final name = referenceFor(reference);
    return p.join(root, encrypted ? '$name$encryptedExtension' : name);
  }

  /// Путь или имя → то, что кладётся в запись: чистое имя без каталога и без
  /// хвоста шифрования.
  ///
  /// Шифрование на диске — дело устройства, и записи о нём знать нечего:
  /// иначе телефон с PIN рассылал бы остальным имена с `.ezm`, а телефон без
  /// PIN искал бы у себя файл, которого так не называл.
  ///
  /// Абсолютные пути и хвост `.ezm` ещё приходят от устройств со сборкой до
  /// 1.1.0. Условие уйдёт, когда обновятся все устройства.
  static String referenceFor(String path) {
    if (isExternal(path)) return path;
    final name = p.basename(path);
    return name.endsWith(encryptedExtension)
        ? name.substring(0, name.length - encryptedExtension.length)
        : name;
  }

  /// Ссылка, которую нельзя превратить в файл: снимок, оставшийся строкой
  /// внутри записи (веб), или адрес в сети.
  static bool isExternal(String value) =>
      value.startsWith('data:') ||
      value.startsWith('http') ||
      value.startsWith('blob:');

  /// Кладёт снимок так, как это устройство хранит вложения.
  ///
  /// [atRest] — ключ местного шифрования; без него файл ложится открытым.
  /// Раньше новые вложения всегда ложились открытыми, даже когда PIN задан:
  /// шифровал их только разовый переход при включении PIN, а всё добавленное
  /// после оставалось незащищённым.
  Future<String> saveImage(XFile file, AppCipher? atRest) async {
    final root = await initialize();
    final extension = _safeImageExtension(file.name);
    final name = 'image_${DateTime.now().microsecondsSinceEpoch}$extension';
    if (atRest == null) {
      await file.saveTo(p.join(root, name));
      return name;
    }
    await writePlainBytes(name, await file.readAsBytes(), atRest);
    return name;
  }

  /// Перекладывает только что записанный голос в ту форму, в какой устройство
  /// хранит вложения.
  ///
  /// Запись идёт прямо в файл, и зашифровать её на лету нечем — значит это
  /// делается сразу после остановки.
  Future<void> protectRecording(String reference, AppCipher? atRest) async {
    if (atRest == null) return;
    await initialize();
    final plain = File(resolve(reference));
    if (!await plain.exists()) return;
    await writePlainBytes(reference, await plain.readAsBytes(), atRest);
    await plain.delete();
  }

  Future<String> createVoicePath() async {
    final root = await initialize();
    return p.join(
      root,
      'voice_${DateTime.now().microsecondsSinceEpoch}.m4a',
    );
  }

  /// Файл вложения в том виде, в каком он на этом устройстве лежит.
  ///
  /// Форм две — открытая и зашифрованная, — и какая настоящая, решает не имя
  /// в записи, а состояние устройства. Поэтому ищется та, что есть.
  Future<File?> storedFile(String reference) async {
    if (isExternal(reference)) return null;
    await initialize();
    for (final encrypted in const [false, true]) {
      final file = File(resolve(reference, encrypted: encrypted));
      if (await file.exists()) return file;
    }
    return null;
  }

  Future<bool> exists(String reference) async {
    if (isExternal(reference)) return true;
    return await storedFile(reference) != null;
  }

  /// Открытые байты вложения. [atRest] нужен, только если файл лежит
  /// зашифрованным.
  Future<Uint8List> readPlainBytes(String reference, AppCipher? atRest) async {
    final file = await storedFile(reference);
    if (file == null) {
      throw StateError('Attachment $reference is not on this device');
    }
    final bytes = await file.readAsBytes();
    if (!p.basename(file.path).endsWith(encryptedExtension)) return bytes;
    if (atRest == null) {
      throw StateError('Attachment $reference is encrypted and locked');
    }
    return atRest.decryptBytes(bytes);
  }

  /// Положить пришедшие байты так, как их хранит это устройство.
  ///
  /// Имя не выдумывается заново: оно и есть общая опознавательная метка
  /// вложения, по ней же файл лежит в облаке.
  Future<void> writePlainBytes(
    String reference,
    Uint8List bytes,
    AppCipher? atRest,
  ) async {
    await initialize();
    await File(resolve(reference, encrypted: atRest != null)).writeAsBytes(
      atRest == null ? bytes : await atRest.encryptBytes(bytes),
      flush: true,
    );
  }

  Future<void> deleteOwnedFiles(
    Iterable<String> references, {
    required Set<String> usedPaths,
  }) async {
    if (references.isEmpty) return;
    await initialize();
    final used = usedPaths.map(referenceFor).toSet();
    for (final reference in references.toSet()) {
      final name = referenceFor(reference);
      if (used.contains(name) || !_isOwnedName(name)) continue;
      await _deleteBothForms(name);
    }
  }

  Future<void> cleanOrphans(Set<String> usedPaths) async {
    final root = await initialize();
    final used = usedPaths.map(referenceFor).toSet();
    await for (final entity in Directory(root).list()) {
      if (entity is! File) continue;
      final name = referenceFor(entity.path);
      if (used.contains(name) || !_isOwnedName(name)) continue;
      await entity.delete();
    }
  }

  /// Обе формы одного вложения: после смены режима на диске могла остаться
  /// вторая, и оставлять её — значит хранить незашифрованную копию.
  Future<void> _deleteBothForms(String name) async {
    for (final encrypted in const [false, true]) {
      final file = File(resolve(name, encrypted: encrypted));
      if (await file.exists()) await file.delete();
    }
  }

  Future<Map<String, String>> stageEncryption(
    Iterable<String> references,
    AppCipher cipher,
  ) async {
    if (references.isEmpty) return const {};
    await initialize();
    final mapping = <String, String>{};
    for (final reference in references.toSet()) {
      if (isExternal(reference)) continue;
      final name = referenceFor(reference);
      final source = File(resolve(name));
      if (!await source.exists()) continue;
      final destination = resolve(name, encrypted: true);
      await File(destination).writeAsBytes(
        await cipher.encryptBytes(await source.readAsBytes()),
        flush: true,
      );
      mapping[source.path] = destination;
    }
    return mapping;
  }

  Future<Map<String, String>> stageDecryption(
    Iterable<String> references,
    AppCipher cipher,
  ) async {
    if (references.isEmpty) return const {};
    await initialize();
    final mapping = <String, String>{};
    for (final reference in references.toSet()) {
      if (isExternal(reference)) continue;
      final name = referenceFor(reference);
      final source = File(resolve(name, encrypted: true));
      if (!await source.exists()) continue;
      final destination = resolve(name);
      await File(destination).writeAsBytes(
        await cipher.decryptBytes(await source.readAsBytes()),
        flush: true,
      );
      mapping[source.path] = destination;
    }
    return mapping;
  }

  Future<void> commitMigration(Map<String, String> mapping) async {
    if (mapping.isEmpty) return;
    for (final sourcePath in mapping.keys) {
      final source = File(sourcePath);
      if (await source.exists()) await source.delete();
    }
  }

  Future<void> rollbackMigration(Map<String, String> mapping) async {
    if (mapping.isEmpty) return;
    for (final destinationPath in mapping.values) {
      final destination = File(destinationPath);
      if (await destination.exists()) await destination.delete();
    }
  }

  Future<String> materializeAudio(String reference, AppCipher? atRest) async {
    final file = await storedFile(reference);
    if (file == null) return resolve(reference);
    if (!p.basename(file.path).endsWith(encryptedExtension)) return file.path;
    final cache = await getTemporaryDirectory();
    final destination = p.join(
      cache.path,
      'playing_${DateTime.now().microsecondsSinceEpoch}.m4a',
    );
    await File(destination).writeAsBytes(
      await readPlainBytes(reference, atRest),
      flush: true,
    );
    return destination;
  }

  Future<void> deleteTemporaryAudio(String path) async {
    final file = File(path);
    if (p.basename(path).startsWith('playing_') && await file.exists()) {
      await file.delete();
    }
  }

  bool _isOwnedName(String name) =>
      name.startsWith('image_') || name.startsWith('voice_');

  String _safeImageExtension(String name) {
    final extension = p.extension(name).toLowerCase();
    return switch (extension) {
      '.jpg' || '.jpeg' || '.png' || '.gif' || '.webp' => extension,
      _ => '.jpg',
    };
  }
}
