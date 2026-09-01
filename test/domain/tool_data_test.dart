import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saved calculations are versioned and round-trip as typed payloads', () {
    final date = DateTime.utc(2026, 8, 30);
    final original = ToolDataSnapshot(calculations: [
      SavedToolCalculation(
        id: '1',
        name: 'Щит',
        payload: SavedEngineeringPayload(
          discipline: 'electrical',
          calculator: 'power',
          values: const {
            'voltageV': 400,
            'currentA': 10,
            'powerFactor': 0.9,
            'efficiency': 0.95,
            'threePhase': 1,
          },
        ),
        createdAt: date,
        updatedAt: date,
      ),
    ]);

    final restored = ToolDataSnapshot.fromJson(original.toJson());

    expect(restored.calculations.single.version, 1);
    expect(
        restored.calculations.single.payload, isA<SavedEngineeringPayload>());
  });

  test('engineering payload rejects unknown schemas and non-finite input', () {
    expect(
      () => SavedEngineeringPayload(
        discipline: 'electrical',
        calculator: 'unknown',
        values: const {'x': 1},
      ),
      throwsFormatException,
    );
    expect(
      () => SavedEngineeringPayload(
        discipline: 'plumbing',
        calculator: 'flow',
        values: const {
          'flowLMin': double.nan,
          'diameterMm': 25,
          'targetVelocityMs': 1,
        },
      ),
      throwsFormatException,
    );
  });

  group('запись о пройденной теме', () {
    test('переживает запись и чтение json', () {
      final record = LearningRecord(
        topicId: 'learn_ohm',
        updatedAt: DateTime.utc(2026, 9, 1, 10),
      );
      final restored = LearningRecord.fromJson(record.toJson());
      expect(restored.topicId, 'learn_ohm');
      expect(restored.updatedAt.toUtc(), record.updatedAt);
    });

    test('снимок по умолчанию пуст, а не null', () {
      expect(const ToolDataSnapshot().learning, isEmpty);
    });
  });
}
