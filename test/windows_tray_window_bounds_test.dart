import 'dart:ui';

import 'package:ezhednevnik_v2/src/platform/windows/windows_tray_window_bounds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('anchors a compact window to the bottom-right of the work area', () {
    const workArea = Rect.fromLTWH(0, 0, 1920, 1040);

    final bounds = calculateWindowsTrayWindowBounds(workArea);

    expect(bounds, const Rect.fromLTWH(1492, 132, 420, 900));
  });

  test('fits the window inside a small work area with an 8px margin', () {
    const workArea = Rect.fromLTWH(-1280, 24, 320, 600);

    final bounds = calculateWindowsTrayWindowBounds(workArea);

    expect(bounds, const Rect.fromLTWH(-1272, 32, 304, 584));
  });

  test('selects the work area nearest to the tray cursor', () {
    const primary = Rect.fromLTWH(0, 0, 1920, 1040);
    const secondary = Rect.fromLTWH(-1280, 0, 1280, 984);

    final selected = nearestWorkArea(
      const Offset(-20, 1000),
      const [primary, secondary],
    );

    expect(selected, secondary);
  });
}
