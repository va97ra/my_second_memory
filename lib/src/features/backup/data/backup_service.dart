import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';

import '../../accounts/data/account_repository.dart';
import '../../accounts/domain/account_item.dart';
import '../../memory_items/data/memory_repository.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../shift_schedules/data/shift_schedule_repository.dart';
import '../../shift_schedules/domain/shift_schedule.dart';
import 'backup_media_store.dart';

class BackupService {
  const BackupService({
    required this.memoryRepository,
    required this.shiftScheduleRepository,
    required this.accountRepository,
  });

  static const format = 'ezhednevnik_v2_backup';
  static const version = 2;
  static const legacyVersion = 1;
  static const encryptedZipFormat = 'ezhednevnik_v2_encrypted_zip';

  final MemoryRepository memoryRepository;
  final ShiftScheduleRepository shiftScheduleRepository;
  final AccountRepository accountRepository;

  Future<String> createBackupJson() async {
    final memoryItems = await memoryRepository.loadAll();
    final shiftSchedules = await shiftScheduleRepository.loadSchedules();
    final accounts = await accountRepository.loadAccounts();
    final mediaFiles = await collectBackupMedia(memoryItems);

    return const JsonEncoder.withIndent('  ').convert({
      'format': format,
      'version': version,
      'exportedAt': DateTime.now().toIso8601String(),
      'memoryItems': memoryItems.map((item) => item.toJson()).toList(),
      'shiftSchedules': shiftSchedules.map((item) => item.toJson()).toList(),
      'accounts': accounts.map((item) => item.toJson()).toList(),
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

  Future<BackupRestoreData> parseBackupBytes(
    List<int> bytes, {
    String? password,
  }) async {
    if (_looksLikeZip(bytes)) {
      if (password == null || password.isEmpty) {
        throw const FormatException('Backup password is required');
      }
      return parseBackupJson(await _decryptBackupZip(bytes, password));
    }
    return parseBackupJson(utf8.decode(bytes));
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

    return BackupRestoreData(
      memoryItems: restoredItems,
      shiftSchedules: shiftSchedules,
      accounts: accounts,
    );
  }

  Future<String> _decryptBackupZip(List<int> bytes, String password) async {
    final archive = ZipDecoder().decodeBytes(bytes);
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
  });

  final List<MemoryItem> memoryItems;
  final List<ShiftSchedule> shiftSchedules;
  final List<AccountItem> accounts;
}
