import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/features/tool_data/tool_data.dart';

void main() {
  test('calculations and bookmarks can be saved, changed and deleted',
      () async {
    final repository = _ToolRepository();
    final controller = ToolDataController(repository);
    final date = DateTime.utc(2026, 8, 30);
    final calculation = SavedToolCalculation(
      id: 'conversion-1',
      name: 'Черновик',
      payload: const SavedConversionPayload(
        category: 'length',
        fromUnit: 'm',
        toUnit: 'cm',
        value: 1,
      ),
      createdAt: date,
      updatedAt: date,
    );

    await controller.saveCalculation(calculation);
    await controller.renameCalculation(calculation.id, 'Замер');
    expect(repository.snapshot.calculations.single.name, 'Замер');

    await controller.saveBookmark(entryId: 'ip_code', note: 'Шкаф на улице');
    await controller.saveBookmark(entryId: 'ip_code', note: 'Шкаф под навесом');
    expect(repository.snapshot.bookmarks, hasLength(1));
    expect(repository.snapshot.bookmarks.single.note, 'Шкаф под навесом');

    await controller.deleteCalculation(calculation.id);
    await controller.deleteBookmark('ip_code');
    expect(repository.snapshot.calculations, isEmpty);
    expect(repository.snapshot.bookmarks, isEmpty);
  });
}

class _ToolRepository implements ToolDataRepository {
  ToolDataSnapshot snapshot = const ToolDataSnapshot();

  @override
  Future<ToolDataSnapshot> load() async => snapshot;

  @override
  Future<void> replaceAll(ToolDataSnapshot snapshot) async {
    this.snapshot = snapshot;
  }
}
