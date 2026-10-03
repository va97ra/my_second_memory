import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MemoryItem item({String title = '', String body = ''}) {
    final now = DateTime(2026, 10, 1);
    return MemoryItem(
      id: 'item',
      type: MemoryType.task,
      title: title,
      body: body,
      memoryDate: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('empty query finds every record', () {
    expect(MemorySearch('').isEmpty, isTrue);
    expect(MemorySearch('   ').matches(item(title: 'Что угодно')), isTrue);
  });

  test('search ignores case and finds part of a word', () {
    final record = item(title: 'Замена СЧЕТЧИКА');
    expect(MemorySearch('счетчик').matches(record), isTrue);
    expect(MemorySearch('ЗАМЕН').matches(record), isTrue);
  });

  test('ё and е are the same letter for search', () {
    expect(MemorySearch('счетчик').matches(item(title: 'Счётчик')), isTrue);
    expect(MemorySearch('счётчик').matches(item(title: 'Счетчик')), isTrue);
  });

  test('every word must be found, in any order, title or body', () {
    final record = item(title: 'Замена счётчика', body: 'ул. Ленина, 5');
    expect(MemorySearch('ленина  замена').matches(record), isTrue);
    expect(MemorySearch('замена гагарина').matches(record), isFalse);
  });

  test('words do not join across title and body', () {
    final record = item(title: 'Замена', body: 'счётчика');
    expect(MemorySearch('заменасчетчика').matches(record), isFalse);
  });
}
