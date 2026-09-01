import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('electrical reference distinguishes sizing and protection devices', () {
    final sizing = electricianReference.singleWhere(
      (entry) => entry.id == 'wire_section_selection',
    );
    final devices = electricianReference.singleWhere(
      (entry) => entry.id == 'breaker_rcd_rcbo',
    );
    final marking = electricianReference.singleWhere(
      (entry) => entry.id == 'protective_device_marking',
    );

    expect(sizing.whatRu, contains('Одного значения тока недостаточно'));
    expect(sizing.whatRu, contains('32 А'));
    expect(devices.whatRu, contains('УЗО'));
    expect(devices.whatRu, contains('не заменяет автомат'));
    expect(marking.whatRu, contains('6 кА'));
    expect(marking.whatRu, contains('IΔn'));
  });
}
