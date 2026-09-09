import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:ez_domain/ez_domain.dart';

import '../media/media_storage_io.dart';

Future<String?> createStreamingBackup({
  required String password,
  required String format,
  required int version,
  required List<MemoryItem> memoryItems,
  required List<ShiftSchedule> shiftSchedules,
  required List<AccountItem> accounts,
  required List<RecurrenceSeries> recurrenceSeries,
  required List<RecurrenceOccurrenceException> recurrenceExceptions,
  required List<FinanceEntry> financeEntries,
  required ToolDataSnapshot toolData,
  String? temporaryRoot,
}) async {
  final temp = temporaryRoot == null
      ? await getTemporaryDirectory()
      : Directory(temporaryRoot);
  final token = DateTime.now().microsecondsSinceEpoch;
  final root = Directory(p.join(temp.path, 'backup_$token'));
  final staging = Directory(p.join(root.path, 'content'));
  final mediaDirectory = Directory(p.join(staging.path, 'media'));
  await mediaDirectory.create(recursive: true);
  final mediaEntries = <Map<String, String>>[];
  final seen = <String>{};
  var mediaIndex = 0;
  final salt = _randomBytes(16);
  final secretKey = await _keyFromPassword(password, salt);

  for (final item in memoryItems) {
    for (final reference in item.mediaReferences) {
      if (MediaStorage.isExternal(reference)) continue;
      final name = MediaStorage.referenceFor(reference);
      if (!seen.add(name)) continue;
      // Где файл лежит и в каком он виде, знает хранилище: в записи только имя.
      final source = await MediaStorage().storedFile(name);
      if (source == null) continue;
      final archivePath = 'media/${mediaIndex++}.bin';
      final nonce = _randomBytes(12);
      final box = await AesGcm.with256bits().encrypt(
        await source.readAsBytes(),
        secretKey: secretKey,
        nonce: nonce,
      );
      await File(p.join(staging.path, archivePath)).writeAsBytes(
        box.cipherText,
      );
      mediaEntries.add({
        // Имя сохраняется тем, какое на диске: с хвостом `.ezm`, если файл
        // лежит зашифрованным, — тогда копия вернётся в том же виде.
        'fileName': p.basename(source.path),
        'archivePath': archivePath,
        'nonce': base64Encode(nonce),
        'mac': base64Encode(box.mac.bytes),
      });
    }
  }

  final payload = utf8.encode(jsonEncode({
    'exportedAt': DateTime.now().toIso8601String(),
    'memoryItems': memoryItems.map((item) => item.toJson()).toList(),
    'shiftSchedules': shiftSchedules.map((item) => item.toJson()).toList(),
    'accounts': accounts.map((item) => item.toJson()).toList(),
    'recurrenceSeries': recurrenceSeries.map((item) => item.toJson()).toList(),
    'recurrenceExceptions':
        recurrenceExceptions.map((item) => item.toJson()).toList(),
    'financeEntries': financeEntries.map((item) => item.toJson()).toList(),
    'toolData': toolData.toJson(),
    'mediaEntries': mediaEntries,
  }));
  final payloadNonce = _randomBytes(12);
  final payloadBox = await AesGcm.with256bits().encrypt(
    payload,
    secretKey: secretKey,
    nonce: payloadNonce,
  );
  await File(p.join(staging.path, 'payload.bin')).writeAsBytes(
    payloadBox.cipherText,
  );
  final manifest = File(p.join(staging.path, 'manifest.json'));
  await manifest.writeAsString(jsonEncode({
    'format': format,
    'version': version,
    'kdf': 'pbkdf2-hmac-sha256',
    'iterations': 120000,
    'cipher': 'aes-256-gcm',
    'salt': base64Encode(salt),
    'payloadNonce': base64Encode(payloadNonce),
    'payloadMac': base64Encode(payloadBox.mac.bytes),
  }));

  final output = p.join(root.path, 'ezhednevnik_v2_backup.zip');
  await ZipFileEncoder().zipDirectory(staging, filename: output);
  await staging.delete(recursive: true);
  return output;
}

Future<List<MemoryItem>> restoreStreamingMedia({
  required List<MemoryItem> items,
  required List<dynamic> mediaEntries,
  required Map<String, List<int>> archiveFiles,
  SecretKey? encryptionKey,
}) async {
  if (mediaEntries.isEmpty) return items;
  await MediaStorage.initialize();
  for (final rawEntry in mediaEntries) {
    final entry = Map<String, Object?>.from(rawEntry as Map);
    final archivePath = entry['archivePath'] as String?;
    var bytes = archivePath == null ? null : archiveFiles[archivePath];
    if (archivePath == null || bytes == null) continue;
    if (encryptionKey != null) {
      final nonce = base64Decode(entry['nonce'] as String);
      final mac = Mac(base64Decode(entry['mac'] as String));
      bytes = await AesGcm.with256bits().decrypt(
        SecretBox(bytes, nonce: nonce, mac: mac),
        secretKey: encryptionKey,
      );
    }
    final fileName = entry['fileName'] as String? ?? p.basename(archivePath);
    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    await File(
      MediaStorage.resolve(
        safeName,
        encrypted: safeName.endsWith(MediaStorage.encryptedExtension),
      ),
    ).writeAsBytes(bytes);
  }
  // Ссылки в записях не трогаются: файл вернулся под своим именем, а имя и
  // есть ссылка.
  return items;
}

Future<SecretKey> _keyFromPassword(String password, List<int> salt) {
  return Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 120000,
    bits: 256,
  ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
}

List<int> _randomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(length, (_) => random.nextInt(256));
}

Future<void> deleteStreamingBackup(String path) async {
  final file = File(path);
  final parent = file.parent;
  if (await parent.exists()) await parent.delete(recursive: true);
}
