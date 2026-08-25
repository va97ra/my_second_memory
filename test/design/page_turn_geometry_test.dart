import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:ez_design/ez_design.dart';

void main() {
  test('page geometry keeps the left-bound sheet length while curling', () {
    const width = 400.0;
    const geometry = PageTurnGeometry(width: width, progress: 0.52);
    const samples = 800;
    for (final verticalT in [0.0, 0.5, 1.0]) {
      var previous = geometry.project(0, verticalT: verticalT);
      var measuredLength = 0.0;
      for (var sample = 1; sample <= samples; sample++) {
        final point = geometry.project(
          width * sample / samples,
          verticalT: verticalT,
        );
        measuredLength += math.sqrt(
          math.pow(point.x - previous.x, 2) +
              math.pow(point.depth - previous.depth, 2),
        );
        previous = point;
      }

      expect(measuredLength, closeTo(width, 0.8));
    }
  });

  test('page fold becomes gently diagonal only while the sheet is moving', () {
    const flat = PageTurnGeometry(width: 360, progress: 0);
    const moving = PageTurnGeometry(width: 360, progress: 0.5);
    const finished = PageTurnGeometry(width: 360, progress: 1);

    expect(flat.foldXAt(0), flat.foldXAt(1));
    expect(moving.foldXAt(0), isNot(moving.foldXAt(1)));
    expect(
      (moving.foldXAt(1) - moving.foldXAt(0)).abs(),
      inInclusiveRange(8, 24),
    );
    expect(finished.foldXAt(0), closeTo(finished.foldXAt(1), 0.001));
  });

  test('page geometry starts flat and finishes beyond the left binding', () {
    const width = 360.0;
    const flat = PageTurnGeometry(width: width, progress: 0);
    const turned = PageTurnGeometry(width: width, progress: 1);

    expect(flat.foldX, width);
    expect(flat.project(0).x, 0);
    expect(flat.project(width).x, width);
    expect(turned.foldX, lessThan(0));
    expect(turned.project(0).x, lessThan(0));
    expect(turned.project(width).x, lessThan(0));
  });
}
