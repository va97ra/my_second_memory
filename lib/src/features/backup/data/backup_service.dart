import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';

import '../../accounts/data/account_repository.dart';
import '../../accounts/domain/account_item.dart';
import '../../memory_items/data/memory_repository.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../recurrence/data/recurrence_repository.dart';
import '../../recurrence/domain/recurrence_series.dart';
import '../../recurrence/data/recurrence_exception_repository.dart';
import '../../recurrence/domain/recurrence_occurrence_exception.dart';
import '../../shift_schedules/data/shift_schedule_repository.dart';
import '../../shift_schedules/domain/shift_schedule.dart';
import 'backup_media_store.dart';
import 'streaming_backup.dart';

class BackupService {
  const BackupService({
    required this.memoryRepository,
    required this.shiftScheduleRepository,
    required this.accountRepository,
    this.recurrenceRepository,
    this.recurrenceExceptionRepository,
  });

  static const format = 'ezhednevnik_v2_backup';
  static const version = 2;
  static const legacyVersion = 1;
  static const encryptedZipFormat = 'ezhednevnik_v2_encrypted_zip';
  static const streamingZipFormat = 'ezhednevnik_v2_streaming_zip';
  static const streamingZipVersion = 4;

  final MemoryRepository memoryRepository;
  final ShiftScheduleRepository shiftScheduleRepository;
  final AccountRepository accountRepository;
  final RecurrenceRepository? recurrenceRepository;
  final RecurrenceExceptionRepository? recurrenceExceptionRepository;

  Future<String> createBackupJson() async {
    final memoryItems = await memoryRepository.loadAll();
    final shiftSchedules = await shiftScheduleRepository.loadSchedules();
    final accounts = await accountRepository.loadAccounts();
    final recurrenceSeries = await recurrenceRepository?.loadAll() ?? const [];
    final recurrenceExceptions =
        await recurrenceExceptionRepository?.loadAll() ?? const [];
    final mediaFiles = await collectBackupMedia(memoryItems);

    return const JsonEncoder.withIndent('  ').convert({
      'format': format,
      'version': version,
      'exportedAt': DateTime.now().toIso8601String(),
      'memoryItems': memoryItems.map((item) => item.toJson()).toList(),
      'shiftSchedules': shiftSchedules.map((item) => item.toJson()).toList(),
      'accounts': accounts.map((item) => item.toJson()).toList(),
      'recurrenceSeries':
          recurrenceSeries.map((item) => item.toJson()).toList(),
      'recurrenceExceptions':
          recurrenceExceptions.map((item) => item.toJson()).toList(),
      'mediaFiles': mediaFiles,
    });
  }

  Future<Uint8List> createEncryptedBackupZip(String password) async {
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final secretKey = await _keyFromPassword(password, salt);
    final box = await AesGcm.with256bits().encrypt(
      utf8.encode(await createBackupJson()),
      secretKey: secretKey,
      nonce: nonce,
    );

    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'manifest.json',
          jsonEncode({
            'format': encryptedZipFormat,
            'version': 1,
            'kdf': 'pbkdf2-hmac-sha256',
            'iterations': 120000,
            'cipher': 'aes-256-gcm',
            'salt': base64Encode(salt),
            'nonce': base64Encode(nonce),
            'mac': base64Encode(box.mac.bytes),
          }),
        ),
      )
      ..addFile(ArchiveFile.bytes('payload.bin', box.cipherText));

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  Future<String?> createStreamingBackupFile(
    String password, {
    String? temporaryRoot,
  }) async {
    return createStreamingBackup(
      password: password,
      format: streamingZipFormat,
      version: streamingZipVersion,
      memoryItems: await memoryRepository.loadAll(),
      shiftSchedules: await shiftScheduleRepository.loadSchedules(),
      accounts: await accountRepository.loadAccounts(),
      recurrenceSeries: await recurrenceRepository?.loadAll() ?? const [],
      recurrenceExceptions:
          await recurrenceExceptionRepository?.loadAll() ?? const [],
      temporaryRoot: temporaryRoot,
    );
  }

  Future<void> deleteTemporaryBackup(String path) {
    return deleteStreamingBackup(path);
  }

  Future<BackupRestoreData> parseBackupBytes(
    List<int> bytes, {
    String? password,
  }) async {
    if (_looksLikeZip(bytes)) {
      if (password == null || password.isEmpty) {
        throw const FormatException('Backup password is required');
      }
      final streaming = await _tryParseStreamingZip(bytes, password);
      if (streaming != null) return streaming;
      return parseBackupJson(await _decryptBackupZip(bytes, password));
    }
    return parseBackupJson(utf8.decode(bytes));
  }

  Future<BackupRestoreData?> _tryParseStreamingZip(
    List<int> bytes,
    String password,
  ) async {
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, password: password);
    } catch (_) {
      return null;
    }
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) return null;
    Map<String, Object?> manifest;
    try {
      manifest = Map<String, Object?>.from(
        jsonDecode(utf8.decode(manifestFile.content as List<int>)) as Map,
      );
    } catch (_) {
      return null;
    }
    final manifestVersion = manifest['version'];
    if (manifest['format'] != streamingZipFormat ||
        (manifestVersion != streamingZipVersion && manifestVersion != 3)) {
      return null;
    }
    final items = (manifest['memoryItems'] as List<dynamic>? ?? const [])
        .map((entry) => MemoryItem.fromJson(
              Map<String, Object?>.from(entry as Map),
            ))
        .toList();
    final files = <String, List<int>>{
      for (final file in archive.files)
        if (file.isFile) file.name: file.content as List<int>,
    };
    final restoredItems = await restoreStreamingMedia(
      items: items,
      mediaEntries: manifest['mediaEntries'] as List<dynamic>? ?? const [],
      archiveFiles: files,
    );
    final shifts =
        (manifest['shiftSchedules'] as List<dynamic>? ?? const []).map((entry) {
      return ShiftSchedule.fromJson(Map<String, Object?>.from(entry as Map));
    }).toList();
    final accounts =
        (manifest['accounts'] as List<dynamic>? ?? const []).map((entry) {
      return AccountItem.fromJson(Map<String, Object?>.from(entry as Map));
    }).toList();
    final recurrenceSeries =
        (manifest['recurrenceSeries'] as List<dynamic>? ?? const [])
            .map((entry) {
      return RecurrenceSeries.fromJson(
        Map<String, Object?>.from(entry as Map),
      );
    }).toList();
    final recurrenceExceptions =
        (manifest['recurrenceExceptions'] as List<dynamic>? ?? const [])
            .map((entry) => RecurrenceOccurrenceException.fromJson(
                  Map<String, Object?>.from(entry as Map),
                ))
            .toList();
    return BackupRestoreData(
      memoryItems: restoredItems,
      shiftSchedules: shifts,
      accounts: accounts,
      recurrenceSeries: recurrenceSeries,
      recurrenceExceptions: recurrenceExceptions,
    );
  }

  Future<BackupRestoreData> parseBackupJson(String raw) async {
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    final backupVersion = decoded['version'];
    if (decoded['format'] != format ||
        (backupVersion != version && backupVersion != legacyVersion)) {
      throw const FormatException('Unsupported backup file');
    }

    final memoryItems =
        (decoded['memoryItems'] as List<dynamic>? ?? const []).map((entry) {
      return MemoryItem.fromJson(Map<String, Object?>.from(entry as Map));
    }).toList();
    final restoredItems = await restoreBackupMedia(
      memoryItems,
      decoded['mediaFiles'] as List<dynamic>? ?? const [],
    );
    final shiftSchedules =
        (decoded['shiftSchedules'] as List<dynamic>? ?? const []).map((entry) {
      return ShiftSchedule.fromJson(Map<String, Object?>.from(entry as Map));
    }).toList();
    final accounts =
        (decoded['accounts'] as List<dynamic>? ?? const []).map((entry) {
      return AccountItem.fromJson(Map<String, Object?>.from(entry as Map));
    }).toList();
    final recurrenceSeries =
        (decoded['recurrenceSeries'] as List<dynamic>? ?? const [])
            .map((entry) {
      return RecurrenceSeries.fromJson(
        Map<String, Object?>.from(entry as Map),
      );
    }).toList();
    final recurrenceExceptions =
        (decoded['recurrenceExceptions'] as List<dynamic>? ?? const [])
            .map((entry) => RecurrenceOccurrenceException.fromJson(
                  Map<String, Object?>.from(entry as Map),
                ))
            .toList();

    return BackupRestoreData(
      memoryItems: restoredItems,
      shiftSchedules: shiftSchedules,
      accounts: accounts,
      recurrenceSeries: recurrenceSeries,
      recurrenceExceptions: recurrenceExceptions,
    );
  }

  Future<String> _decryptBackupZip(List<int> bytes, String password) async {
    late final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const FormatException('Invalid backup password');
    }
    final manifestFile = archive.findFile('manifest.json');
    final payloadFile = archive.findFile('payload.bin');
    if (manifestFile == null || payloadFile == null) {
      throw const FormatException('Invalid backup archive');
    }

    final manifest = jsonDecode(utf8.decode(manifestFile.content as List<int>))
        as Map<String, Object?>;
    if (manifest['format'] != encryptedZipFormat) {
      throw const FormatException('Invalid backup archive');
    }

    final salt = base64Decode(manifest['salt'] as String);
    final nonce = base64Decode(manifest['nonce'] as String);
    final mac = Mac(base64Decode(manifest['mac'] as String));
    final secretKey = await _keyFromPassword(password, salt);

    try {
      final clearBytes = await AesGcm.with256bits().decrypt(
        SecretBox(payloadFile.content as List<int>, nonce: nonce, mac: mac),
        secretKey: secretKey,
      );
      return utf8.decode(clearBytes);
    } catch (_) {
      throw const FormatException('Invalid backup password');
    }
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

  bool _looksLikeZip(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04;
  }
}

class BackupRestoreData {
  const BackupRestoreData({
    required this.memoryItems,
    required this.shiftSchedules,
    required this.accounts,
    this.recurrenceSeries = const [],
    this.recurrenceExceptions = const [],
  });

  final List<MemoryItem> memoryItems;
  final List<ShiftSchedule> shiftSchedules;
  final List<AccountItem> accounts;
  final List<RecurrenceSeries> recurrenceSeries;
  final List<RecurrenceOccurrenceException> recurrenceExceptions;
}
