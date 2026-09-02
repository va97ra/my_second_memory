import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ez_data/ez_data_io.dart';

void main() {
  test('empty sqlite database returns empty records', () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    final repository = SqliteMemoryRepository(database: database);
    addTearDown(database.close);

    final items = await repository.loadAll();

    expect(items, isEmpty);
  });

  test('database upgrade from schema 11 keeps the end of a record', () async {
    SharedPreferences.setMockInitialValues({});
    final directory = await Directory.systemTemp.createTemp('memory_v11_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/v11.sqlite');

    // База без конца записи — такая уезжала в 1.0.8.
    final oldDatabase = AppDatabase(NativeDatabase(file));
    await oldDatabase
        .customStatement('ALTER TABLE memory_items DROP COLUMN end_minutes');
    await oldDatabase.customStatement('PRAGMA user_version = 11');
    await oldDatabase.close();

    final database = AppDatabase(NativeDatabase(file));
    addTearDown(database.close);
    expect(database.schemaVersion, 12);
    final repository = SqliteMemoryRepository(database: database);
    final date = DateTime(2026, 9, 2);
    await repository.replaceAll([
      MemoryItem(
        id: 'shift',
        type: MemoryType.task,
        title: 'Смена',
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
        timeMinutes: 9 * 60 + 30,
        endMinutes: 15 * 60 + 15,
      ),
    ]);

    final loaded = (await repository.loadAll()).single;
    expect(loaded.timeMinutes, 9 * 60 + 30);
    expect(loaded.endMinutes, 15 * 60 + 15);
  });

  test('the end of a record survives the trip through json', () {
    final date = DateTime(2026, 9, 2);
    final item = MemoryItem(
      id: 'framed',
      type: MemoryType.task,
      title: 'Дело с рамкой',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
      timeMinutes: 11 * 60,
      endMinutes: 16 * 60,
    );

    final restored = MemoryItem.fromJson(jsonDecode(jsonEncode(item.toJson()))
        as Map<String, Object?>);

    expect(restored.endMinutes, 16 * 60);
  });

  test('clearing the time clears the end as well', () {
    final date = DateTime(2026, 9, 2);
    final item = MemoryItem(
      id: 'framed',
      type: MemoryType.task,
      title: 'Дело с рамкой',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
      timeMinutes: 11 * 60,
      endMinutes: 16 * 60,
    );

    // Конца без начала не бывает: снятие времени убирает оба.
    expect(item.copyWith(clearTime: true).endMinutes, isNull);
  });

  test('saved records survive database reopen with media fields', () async {
    SharedPreferences.setMockInitialValues({});
    final directory = await Directory.systemTemp.createTemp('memory_sqlite_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/memory.sqlite');
    final date = DateTime(2026, 7, 3, 10, 15);
    final item = MemoryItem(
      id: 'saved-note',
      type: MemoryType.purchase,
      title: 'Покупка',
      body: 'Молоко',
      timeMinutes: 18 * 60,
      memoryDate: DateTime(2026, 7, 3),
      createdAt: date,
      updatedAt: date,
      status: MemoryStatus.done,
      priority: 3,
      tags: const ['дом'],
      remindAt: DateTime(2026, 7, 4, 9),
      reminderSoundUri: 'content://media/alarm/9',
      reminderSoundName: 'Будильник',
      repeatRule: 'weekly',
      projectId: 'project-1',
      personIds: const ['person-1'],
      placeId: 'shop',
      audioPath: '/local/voice.m4a',
      audioDurationSeconds: 42,
      imagePaths: const ['/local/photo.jpg'],
      transcript: 'текст голоса',
      isUndated: true,
    );

    final firstDatabase = AppDatabase(NativeDatabase(file));
    final firstRepository = SqliteMemoryRepository(database: firstDatabase);
    await firstRepository.upsert(item);
    await firstDatabase.close();

    final secondDatabase = AppDatabase(NativeDatabase(file));
    final secondRepository = SqliteMemoryRepository(database: secondDatabase);
    addTearDown(secondDatabase.close);
    final restored = await secondRepository.loadAll();

    expect(restored, hasLength(1));
    expect(restored.single.id, 'saved-note');
    expect(restored.single.timeMinutes, 18 * 60);
    expect(restored.single.status, MemoryStatus.done);
    expect(restored.single.audioPath, '/local/voice.m4a');
    expect(restored.single.audioDurationSeconds, 42);
    expect(restored.single.imagePaths, ['/local/photo.jpg']);
    expect(restored.single.tags, ['дом']);
    expect(restored.single.personIds, ['person-1']);
    expect(restored.single.remindAt, DateTime(2026, 7, 4, 9));
    expect(restored.single.reminderSoundUri, 'content://media/alarm/9');
    expect(restored.single.reminderSoundName, 'Будильник');
    expect(restored.single.isUndated, isTrue);
  });

  test('replaceAll removes records missing from the provided list', () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    final repository = SqliteMemoryRepository(database: database);
    addTearDown(database.close);
    final date = DateTime(2026, 7, 3);
    final first = MemoryItem(
      id: 'first',
      type: MemoryType.note,
      title: 'Первая',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
    );
    final second = MemoryItem(
      id: 'second',
      type: MemoryType.note,
      title: 'Вторая',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
    );

    await repository.replaceAll([first, second]);
    await repository.replaceAll([second]);

    final restored = await repository.loadAll();
    expect(restored.map((item) => item.id), ['second']);
  });

  test('migrates real SharedPreferences records and skips starter records',
      () async {
    final date = DateTime(2026, 7, 3);
    final starter = MemoryItem(
      id: 'starter-event',
      type: MemoryType.event,
      title: 'План на сегодня',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
    );
    final realItem = MemoryItem(
      id: 'real-note',
      type: MemoryType.note,
      title: 'Настоящая запись',
      body: 'Не потерять',
      timeMinutes: 9 * 60 + 15,
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
      imagePaths: const ['/local/photo.jpg'],
    );
    SharedPreferences.setMockInitialValues({
      SqliteMemoryRepository.legacyStorageKey: jsonEncode([
        starter.toJson(),
        realItem.toJson(),
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final database = AppDatabase(NativeDatabase.memory());
    final repository = SqliteMemoryRepository(
      database: database,
      legacyPreferences: prefs,
    );
    addTearDown(database.close);

    final firstLoad = await repository.loadAll();
    final secondLoad = await repository.loadAll();

    expect(firstLoad, hasLength(1));
    expect(firstLoad.single.id, 'real-note');
    expect(firstLoad.single.timeMinutes, 9 * 60 + 15);
    expect(firstLoad.single.imagePaths, ['/local/photo.jpg']);
    expect(secondLoad, hasLength(1));
    expect(secondLoad.single.id, 'real-note');
    expect(prefs.getBool(SqliteMemoryRepository.legacyMigrationKey), isTrue);
  });

  test('upsert changes one record without replacing other records', () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase(NativeDatabase.memory());
    final repository = SqliteMemoryRepository(database: database);
    addTearDown(database.close);
    final date = DateTime(2026, 7, 3);
    final first = MemoryItem(
      id: 'first',
      type: MemoryType.note,
      title: 'Первая',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
    );
    final second = MemoryItem(
      id: 'second',
      type: MemoryType.note,
      title: 'Вторая',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
    );

    await repository.replaceAll([first, second]);
    await repository.upsert(first.copyWith(body: 'Изменена'));

    final restored = await repository.loadAll();
    expect(restored, hasLength(2));
    expect(restored.singleWhere((item) => item.id == 'first').body, 'Изменена');
    expect(restored.singleWhere((item) => item.id == 'second').title, 'Вторая');
  });
}
