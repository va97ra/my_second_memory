import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saved calculations are versioned and round-trip as typed payloads', () {
    final date = DateTime.utc(2026, 8, 30);
    final original = ToolDataSnapshot(calculations: [
      SavedToolCalculation(
        id: '1',
        name: 'Щит',
        payload: const SavedConversionPayload(
          category: 'length',
          fromUnit: 'm',
          toUnit: 'cm',
          value: 3.6,
        ),
        createdAt: date,
        updatedAt: date,
      ),
    ]);

    final restored = ToolDataSnapshot.fromJson(original.toJson());

    expect(restored.calculations.single.version, 1);
    expect(
        restored.calculations.single.payload, isA<SavedConversionPayload>());
  });


}
