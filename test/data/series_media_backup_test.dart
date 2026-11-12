import 'dart:convert';
import 'dart:io';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../support/backup_test_support.dart';
import '../support/recurrence_test_support.dart';

/// Б3: вложения повторов в резервной копии, и порядок записи файлов при
/// восстановлении.
void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('series_media_backup');
    MediaStorage.debugRoot = root.path;
  });

  tearDown(() {
    MediaStorage.debugRoot = null;
    root.deleteSync(recursive: true);
  });

  File onDisk(String name) => File(p.join(root.path, name));

  BackupService serviceWithSeries({AccountRepository? accounts}) {
    final (:series, :override) = seriesWithMedia();
    return BackupService(
      memoryRepository: FakeMemoryRepository(const []),
      shiftScheduleRepository: FakeShiftRepository(const []),
      accountRepository: accounts ?? FakeAccountRepository(const []),
      recurrenceRepository: FakeRecurrenceRepository([series]),
      recurrenceExceptionRepository: FakeRecurrenceExceptionRepository([
        override,
      ]),
    );
  }

  void writeSeriesFiles() {
    onDisk('image_series.jpg').writeAsBytesSync([1]);
    onDisk('image_override.jpg').writeAsBytesSync([2]);
  }

  void loseSeriesFiles() {
    onDisk('image_series.jpg').deleteSync();
    onDisk('image_override.jpg').deleteSync();
  }

  test('a JSON backup carries series photos and brings them back', () async {
    writeSeriesFiles();
    final service = serviceWithSeries();

    final json = await service.createBackupJson();
    loseSeriesFiles();
    await service.restore(await service.parseBackupJson(json));

    expect(onDisk('image_series.jpg').readAsBytesSync(), [1]);
    expect(onDisk('image_override.jpg').readAsBytesSync(), [2]);
  });

  test('a streaming backup carries series photos and brings them back',
      () async {
    writeSeriesFiles();
    final service = serviceWithSeries();
    final temp = Directory.systemTemp.createTempSync('series_stream');
    addTearDown(() => temp.deleteSync(recursive: true));

    final path = await service.createStreamingBackupFile(
      'password',
      temporaryRoot: temp.path,
    );
    loseSeriesFiles();
    await service.restore(await service.parseBackupBytes(
      await File(path!).readAsBytes(),
      password: 'password',
    ));

    expect(onDisk('image_series.jpg').readAsBytesSync(), [1]);
    expect(onDisk('image_override.jpg').readAsBytesSync(), [2]);
  });

  test('a restore that failed and rolled back leaves no new files', () async {
    final date = DateTime(2026, 11, 12);
    final service = serviceWithSeries(
      accounts: FailOnceAccountRepository(const []),
    );
    final backup = jsonEncode({
      'format': BackupService.format,
      'version': BackupService.version,
      'memoryItems': [
        MemoryItem(
          id: 'record',
          type: MemoryType.note,
          title: 'Запись',
          memoryDate: date,
          createdAt: date,
          updatedAt: date,
          imagePaths: const ['image_from_backup.jpg'],
        ).toJson(),
      ],
      'shiftSchedules': const [],
      'accounts': const [],
      'mediaFiles': [
        {
          'fileName': 'image_from_backup.jpg',
          'bytesBase64': base64Encode([9]),
        },
      ],
    });

    final data = await service.parseBackupJson(backup);
    await expectLater(service.restore(data), throwsStateError);

    expect(onDisk('image_from_backup.jpg').existsSync(), isFalse);
  });

  test('a rolled back restore keeps a file that was already here', () async {
    onDisk('image_kept.jpg').writeAsBytesSync([5]);
    final service = serviceWithSeries(
      accounts: FailOnceAccountRepository(const []),
    );
    final backup = jsonEncode({
      'format': BackupService.format,
      'version': BackupService.version,
      'memoryItems': const [],
      'shiftSchedules': const [],
      'accounts': const [],
      'mediaFiles': [
        {
          'fileName': 'image_kept.jpg',
          'bytesBase64': base64Encode([5])
        },
      ],
    });

    await expectLater(
      service.restore(await service.parseBackupJson(backup)),
      throwsStateError,
    );

    expect(onDisk('image_kept.jpg').readAsBytesSync(), [5]);
  });
}
