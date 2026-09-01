import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DN uses the current Russian standards term', () {
    final definition = electricianReference.singleWhere(
      (entry) => entry.id == 'pipe_dn',
    );
    final comparison = electricianReference.singleWhere(
      (entry) => entry.id == 'pipe_dn_dy_table',
    );

    expect(definition.titleRu, 'DN — номинальный диаметр');
    expect(definition.whatRu, contains('безразмерное обозначение'));
    expect(definition.whatRu, isNot(contains('DN — условный проход')));
    expect(comparison.titleRu, 'DN, наружный диаметр и дюймы: соответствие');
    expect(comparison.whatRu, contains('старое обозначение — Ду'));
  });
}
