import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/features/tool_data/tool_data.dart';

void main() {
  test('calculations can be saved, changed and deleted',
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


    await controller.deleteCalculation(calculation.id);
    expect(repository.snapshot.calculations, isEmpty);
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
