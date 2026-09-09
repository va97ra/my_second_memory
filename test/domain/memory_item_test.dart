import 'package:flutter_test/flutter_test.dart';
import 'package:ez_domain/ez_domain.dart';

void main() {
  test('memory item keeps required date and voice fields in json', () {
    final date = DateTime(2026, 6, 30);
    final item = MemoryItem(
      id: 'voice-1',
      type: MemoryType.voiceNote,
      title: 'Voice note',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
      timeMinutes: 9 * 60 + 30,
      remindAt: DateTime(2026, 6, 30, 9, 30),
      reminderSoundUri: 'content://media/alarm/7',
      reminderSoundName: 'Рассвет',
      voiceNotes: const [
        VoiceNote(reference: 'voice_1.m4a', durationSeconds: 12),
        VoiceNote(reference: 'voice_2.m4a', durationSeconds: 3),
      ],
      imagePaths: const ['/local/photo.jpg'],
      seriesId: 'series-1',
      amountMinor: 129900,
      paymentCategory: 'subscription',
      birthYear: 1990,
      isGeneratedOccurrence: true,
    );

    final restored = MemoryItem.fromJson(item.toJson());

    expect(restored.memoryDate, date);
    expect(restored.timeMinutes, 9 * 60 + 30);
    expect(restored.remindAt, DateTime(2026, 6, 30, 9, 30));
    expect(restored.reminderSoundUri, 'content://media/alarm/7');
    expect(restored.reminderSoundName, 'Рассвет');
    expect(restored.type, MemoryType.voiceNote);
    expect(restored.voiceNotes, const [
      VoiceNote(reference: 'voice_1.m4a', durationSeconds: 12),
      VoiceNote(reference: 'voice_2.m4a', durationSeconds: 3),
    ]);
    expect(restored.imagePaths, ['/local/photo.jpg']);
    expect(restored.seriesId, 'series-1');
    expect(restored.amountMinor, 129900);
    expect(restored.paymentCategory, 'subscription');
    expect(restored.birthYear, 1990);
    expect(restored.isGeneratedOccurrence, isTrue);
  });

  test('a record names every attachment it holds', () {
    final date = DateTime(2026, 9, 9);
    final item = MemoryItem(
      id: 'many',
      type: MemoryType.note,
      title: 'Вложения',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
      imagePaths: const ['image_1.jpg', 'image_2.jpg'],
      voiceNotes: const [
        VoiceNote(reference: 'voice_1.m4a', durationSeconds: 2),
        VoiceNote(reference: 'voice_2.m4a', durationSeconds: 3),
      ],
    );

    // По этому списку убирают файлы, кладут резервную копию и синхронизируют
    // вложения. Потеряется здесь — потеряется везде.
    expect(item.mediaReferences, [
      'image_1.jpg',
      'image_2.jpg',
      'voice_1.m4a',
      'voice_2.m4a',
    ]);
  });

  test('a record from an older build keeps its single voice note', () {
    final date = DateTime(2026, 9, 9);
    final legacy = {
      'id': 'legacy',
      'type': MemoryType.note.name,
      'title': 'Старая запись',
      'memoryDate': date.toIso8601String(),
      'createdAt': date.toUtc().toIso8601String(),
      'updatedAt': date.toUtc().toIso8601String(),
      'status': MemoryStatus.active.name,
      'audioPath': 'voice_old.m4a',
      'audioDurationSeconds': 11,
    };

    final restored = MemoryItem.fromJson(legacy);

    expect(restored.voiceNotes, const [
      VoiceNote(reference: 'voice_old.m4a', durationSeconds: 11),
    ]);
  });

  test('the payload still names the first note for older builds', () {
    final date = DateTime(2026, 9, 9);
    final item = MemoryItem(
      id: 'two-voices',
      type: MemoryType.note,
      title: 'Две заметки',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
      voiceNotes: const [
        VoiceNote(reference: 'voice_1.m4a', durationSeconds: 5),
        VoiceNote(reference: 'voice_2.m4a', durationSeconds: 6),
      ],
    );

    final json = item.toJson();

    expect(json['audioPath'], 'voice_1.m4a');
    expect(json['audioDurationSeconds'], 5);
    expect(MemoryItem.fromJson(json).voiceNotes, item.voiceNotes);
  });

  test('copyWith can remove an attached voice recording', () {
    final date = DateTime(2026, 7, 22);
    final item = MemoryItem(
      id: 'voice-2',
      type: MemoryType.note,
      title: 'Voice attachment',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
      voiceNotes: const [
        VoiceNote(reference: 'voice_1.m4a', durationSeconds: 25),
      ],
    );

    final updated = item.copyWith(voiceNotes: const []);

    expect(updated.voiceNotes, isEmpty);
  });

  test('undated note survives json and old json defaults to dated', () {
    final date = DateTime(2026, 8, 13);
    final note = MemoryItem(
      id: 'undated-note',
      type: MemoryType.note,
      title: 'Карта дочери',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
      isUndated: true,
    );

    expect(MemoryItem.fromJson(note.toJson()).isUndated, isTrue);
    final oldJson = note.toJson()..remove('isUndated');
    expect(MemoryItem.fromJson(oldJson).isUndated, isFalse);
  });
}
