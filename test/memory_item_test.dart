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
  });
}
