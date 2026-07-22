import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_type.dart';

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
      audioPath: '/local/voice.m4a',
      audioDurationSeconds: 12,
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
    expect(restored.audioPath, '/local/voice.m4a');
    expect(restored.audioDurationSeconds, 12);
    expect(restored.imagePaths, ['/local/photo.jpg']);
    expect(restored.seriesId, 'series-1');
    expect(restored.amountMinor, 129900);
    expect(restored.paymentCategory, 'subscription');
    expect(restored.birthYear, 1990);
    expect(restored.isGeneratedOccurrence, isTrue);
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
      audioPath: '/local/voice.m4a',
      audioDurationSeconds: 25,
    );

    final updated = item.copyWith(clearAudio: true);

    expect(updated.audioPath, isNull);
    expect(updated.audioDurationSeconds, isNull);
  });
}
