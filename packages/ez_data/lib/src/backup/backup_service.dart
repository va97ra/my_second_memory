import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';

import '../accounts/account_repository.dart';
import '../finance/finance_repository.dart';
import 'package:ez_domain/ez_domain.dart';
import '../memory/memory_repository.dart';
import '../recurrence/recurrence_repository.dart';
import '../recurrence/recurrence_exception_repository.dart';
import '../shifts/shift_schedule_repository.dart';
import 'backup_media_store.dart';
import 'streaming_backup.dart';

class BackupService {
  const BackupService({
    required this.memoryRepository,
    required this.shiftScheduleRepository,
    required this.accountRepository,
    this.recurrenceRepository,
    this.recurrenceExceptionRepository,
    this.financeRepository,
  });

  static const format = 'ezhednevnik_v2_backup';
  static const version = 3;
  static const legacyVersion = 1;
  static const encryptedZipFormat = 'ezhednevnik_v2_encrypted_zip';
  static const streamingZipFormat = 'ezhednevnik_v2_streaming_zip';
  static const streamingZipVersion = 6;

  final MemoryRepository memoryRepository;
  final ShiftScheduleRepository shiftScheduleRepository;
  final AccountRepository accountRepository;
  final RecurrenceRepository? recurrenceRepository;
  final RecurrenceExceptionRepository? recurrenceExceptionRepository;
  final FinanceRepository? financeRepository;

  Future<String> createBackupJson() async {
    final memoryItems = await memoryRepository.loadAll();
    final shiftSchedules = await shiftScheduleRepository.loadSchedules();
    final accounts = await accountRepository.loadAccounts();
    final recurrenceSeries = await recurrenceRepository?.loadAll() ?? const [];
    final recurrenceExceptions =
        await recurrenceExceptionRepository?.loadAll() ?? const [];
    final financeEntries = await financeRepository?.loadAll() ?? const [];
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
      'financeEntries': financeEntries.map((item) => item.toJson()).toList(),
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
      financeEntries: await financeRepository?.loadAll() ?? const [],
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
        throw const BackupPasswordException('Backup password is required');
      }
      final streaming = await _tryParseStreamingZip(bytes, password);
      if (streaming != null) return streaming;
      return parseBackupJson(await _decryptBackupZip(bytes, password));
    }
    return parseBackupJson(utf8.decode(bytes));
  }

  Future<void> restore(BackupRestoreData data) async {
    final previous = await _readCurrentData();
    try {
      await _writeData(data);
      final restored = await _readCurrentData();
      if (!_sameData(restored, data)) {
        throw StateError('Backup verification failed');
      }
    } on Object catch (error, stackTrace) {
      try {
        await _writeData(previous);
      } on Object {
        // Preserve the original failure. The UI never reports success unless
        // every repository was written and then read back successfully.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<BackupRestoreData> _readCurrentData() async {
    return BackupRestoreData(
      memoryItems: await memoryRepository.loadAll(),
      shiftSchedules: await shiftScheduleRepository.loadSchedules(),
      accounts: await accountRepository.loadAccounts(),
      recurrenceSeries: await recurrenceRepository?.loadAll() ?? const [],
      recurrenceExceptions:
          await recurrenceExceptionRepository?.loadAll() ?? const [],
      financeEntries: await financeRepository?.loadAll() ?? const [],
    );
  }

  Future<void> _writeData(BackupRestoreData data) async {
    if (recurrenceRepository == null && data.recurrenceSeries.isNotEmpty) {
      throw StateError('Recurrence repository is unavailable');
    }
    if (recurrenceExceptionRepository == null &&
        data.recurrenceExceptions.isNotEmpty) {
      throw StateError('Recurrence exception repository is unavailable');
    }
    if (financeRepository == null && data.financeEntries.isNotEmpty) {
      throw StateError('Finance repository is unavailable');
    }

    await memoryRepository.replaceAll(data.memoryItems);
    await shiftScheduleRepository.saveSchedules(data.shiftSchedules);
    await accountRepository.saveAccounts(data.accounts);
    await recurrenceExceptionRepository?.replaceAll(
      data.recurrenceExceptions,
    );
    await recurrenceRepository?.replaceAll(data.recurrenceSeries);
    await financeRepository?.replaceAll(data.financeEntries);
  }

  bool _sameData(BackupRestoreData first, BackupRestoreData second) {
    return _sameJsonList(
          first.memoryItems.map((item) => item.toJson()),
          second.memoryItems.map((item) => item.toJson()),
        ) &&
        _sameJsonList(
          first.shiftSchedules.map((item) => item.toJson()),
          second.shiftSchedules.map((item) => item.toJson()),
        ) &&
        _sameJsonList(
          first.accounts.map((item) => item.toJson()),
          second.accounts.map((item) => item.toJson()),
        ) &&
        _sameJsonList(
          first.recurrenceSeries.map((item) => item.toJson()),
          second.recurrenceSeries.map((item) => item.toJson()),
        ) &&
        _sameJsonList(
          first.recurrenceExceptions.map((item) => item.toJson()),
          second.recurrenceExceptions.map((item) => item.toJson()),
        ) &&
        _sameJsonList(
          first.financeEntries.map((item) => item.toJson()),
          second.financeEntries.map((item) => item.toJson()),
        );
  }

  bool _sameJsonList(
    Iterable<Map<String, Object?>> first,
    Iterable<Map<String, Object?>> second,
  ) {
    final firstJson = first.map(jsonEncode).toList()..sort();
    final secondJson = second.map(jsonEncode).toList()..sort();
    if (firstJson.length != secondJson.length) return false;
    for (var index = 0; index < firstJson.length; index++) {
      if (firstJson[index] != secondJson[index]) return false;
    }
    return true;
  }

  Future<BackupRestoreData?> _tryParseStreamingZip(
    List<int> bytes,
    String password,
  ) async {
    final unencryptedArchive = ZipDecoder().decodeBytes(bytes);
    final unencryptedManifest = _readManifest(unencryptedArchive);
    if (unencryptedManifest != null &&
        unencryptedManifest['format'] == streamingZipFormat &&
        (unencryptedManifest['version'] == streamingZipVersion ||
            unencryptedManifest['version'] == 5)) {
      return _parseGcmStreamingZip(
        unencryptedArchive,
        unencryptedManifest,
        password,
      );
    }

    late final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, password: password);
    } on Object {
      return null;
    }
    final manifest = _readManifest(archive);
    if (manifest == null) return null;
    final manifestVersion = manifest['version'];
    if (manifest['format'] != streamingZipFormat ||
        (manifestVersion != 4 && manifestVersion != 3)) {
      return null;
    }
    return _parseStreamingData(archive, manifest);
  }

  Map<String, Object?>? _readManifest(Archive archive) {
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) return null;
    try {
      return Map<String, Object?>.from(
        jsonDecode(utf8.decode(manifestFile.content as List<int>)) as Map,
      );
    } on Object {
      return null;
    }
  }

  Future<BackupRestoreData> _parseGcmStreamingZip(
    Archive archive,
    Map<String, Object?> manifest,
    String password,
  ) async {
    if (manifest['kdf'] != 'pbkdf2-hmac-sha256' ||
        manifest['cipher'] != 'aes-256-gcm' ||
        manifest['iterations'] != 120000) {
      throw const FormatException('Unsupported backup encryption');
    }
    final payloadFile = archive.findFile('payload.bin');
    if (payloadFile == null) {
      throw const FormatException('Invalid backup archive');
    }
    final secretKey = await _keyFromPassword(
      password,
      base64Decode(manifest['salt'] as String),
    );
    late final Map<String, Object?> payload;
    try {
      final clearBytes = await AesGcm.with256bits().decrypt(
        SecretBox(
          payloadFile.content as List<int>,
          nonce: base64Decode(manifest['payloadNonce'] as String),
          mac: Mac(base64Decode(manifest['payloadMac'] as String)),
        ),
        secretKey: secretKey,
      );
      payload = Map<String, Object?>.from(
        jsonDecode(utf8.decode(clearBytes)) as Map,
      );
      return await _parseStreamingData(
        archive,
        payload,
        encryptionKey: secretKey,
      );
    } on BackupPasswordException {
      rethrow;
    } on Object {
      throw const BackupPasswordException('Invalid backup password');
    }
  }

  Future<BackupRestoreData> _parseStreamingData(
    Archive archive,
    Map<String, Object?> manifest, {
    SecretKey? encryptionKey,
  }) async {
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
      encryptionKey: encryptionKey,
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
    final financeEntries =
        (manifest['financeEntries'] as List<dynamic>? ?? const [])
            .map((entry) => FinanceEntry.fromJson(
                  Map<String, Object?>.from(entry as Map),
                ))
            .toList();
    return BackupRestoreData(
      memoryItems: restoredItems,
      shiftSchedules: shifts,
      accounts: accounts,
      recurrenceSeries: recurrenceSeries,
      recurrenceExceptions: recurrenceExceptions,
      financeEntries: financeEntries,
    );
  }

  Future<BackupRestoreData> parseBackupJson(String raw) async {
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    final backupVersion = decoded['version'];
    if (decoded['format'] != format ||
        (backupVersion != version &&
            backupVersion != 2 &&
            backupVersion != legacyVersion)) {
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
    final financeEntries =
        (decoded['financeEntries'] as List<dynamic>? ?? const []).map((entry) {
      return FinanceEntry.fromJson(Map<String, Object?>.from(entry as Map));
    }).toList();

    return BackupRestoreData(
      memoryItems: restoredItems,
      shiftSchedules: shiftSchedules,
      accounts: accounts,
      recurrenceSeries: recurrenceSeries,
      recurrenceExceptions: recurrenceExceptions,
      financeEntries: financeEntries,
    );
  }

  Future<String> _decryptBackupZip(List<int> bytes, String password) async {
    late final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const FormatException('Invalid backup archive');
    }
    final manifestFile = archive.findFile('manifest.json');
    final payloadFile = archive.findFile('payload.bin');
    if (manifestFile == null) {
      throw const FormatException('Invalid backup archive');
    }
    if (payloadFile == null) {
      throw const BackupPasswordException('Invalid backup password');
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
      throw const BackupPasswordException('Invalid backup password');
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

class BackupPasswordException extends FormatException {
  const BackupPasswordException([super.message]);
}

class BackupRestoreData {
  const BackupRestoreData({
    required this.memoryItems,
    required this.shiftSchedules,
    required this.accounts,
    this.recurrenceSeries = const [],
    this.recurrenceExceptions = const [],
    this.financeEntries = const [],
  });

  final List<MemoryItem> memoryItems;
  final List<ShiftSchedule> shiftSchedules;
  final List<AccountItem> accounts;
  final List<RecurrenceSeries> recurrenceSeries;
  final List<RecurrenceOccurrenceException> recurrenceExceptions;
  final List<FinanceEntry> financeEntries;
}
