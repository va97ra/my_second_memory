import 'dart:ui' show FrameTiming;

import 'package:ezhednevnik_v2/src/core/theme/notebook/notebook_theme.dart';
import 'package:ezhednevnik_v2/src/shared/ui/page_turn_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('page turn stays inside the warmed 60 Hz frame budget',
      (tester) async {
    final frameKey = GlobalKey<PageTurnFrameState>();
    late StateSetter setHostState;
    var showAlternatePage = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildNotebookTheme(brightness: Brightness.light),
        home: StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return PageTurnFrame(
              key: frameKey,
              child: ColoredBox(
                color: showAlternatePage
                    ? const Color(0xFF315B8A)
                    : const Color(0xFFF1E4C8),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> turn(PageTurnDirection direction) async {
      final completed = frameKey.currentState!.beginTurn(
        direction: direction,
        switchContent: () {
          setHostState(() => showAlternatePage = !showAlternatePage);
        },
      );
      for (var frame = 0; frame < 44; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(
        await completed.timeout(const Duration(seconds: 5)),
        isTrue,
      );
    }

    // Exclude shader compilation and the first image capture from the sample.
    await turn(PageTurnDirection.forward);
    await turn(PageTurnDirection.backward);

    final timings = <FrameTiming>[];
    void collectTimings(List<FrameTiming> batch) => timings.addAll(batch);
    binding.addTimingsCallback(collectTimings);
    try {
      for (var index = 0; index < 10; index++) {
        await turn(
          index.isEven ? PageTurnDirection.forward : PageTurnDirection.backward,
        );
      }
      // Engines batch timings, so allow the last batch to arrive without the
      // unbounded wait used by watchPerformance on unsupported runners.
      await Future<void>.delayed(const Duration(seconds: 2));
    } finally {
      binding.removeTimingsCallback(collectTimings);
    }

    if (timings.isEmpty) {
      binding.reportData = {
        'page_turn_performance': {
          'frame_count': 0,
          'timings_available': false,
        },
      };
      return;
    }

    final buildTimes = [
      for (final timing in timings) timing.buildDuration.inMicroseconds / 1000,
    ];
    final rasterTimes = [
      for (final timing in timings) timing.rasterDuration.inMicroseconds / 1000,
    ];
    final summary = <String, dynamic>{
      'frame_count': timings.length,
      'timings_available': true,
      '90th_percentile_frame_build_time_millis': _percentile(buildTimes, 0.90),
      '99th_percentile_frame_build_time_millis': _percentile(buildTimes, 0.99),
      '90th_percentile_frame_rasterizer_time_millis':
          _percentile(rasterTimes, 0.90),
      '99th_percentile_frame_rasterizer_time_millis':
          _percentile(rasterTimes, 0.99),
    };
    binding.reportData = {'page_turn_performance': summary};
    final limits = <String, double>{
      '90th_percentile_frame_build_time_millis': 16.7,
      '90th_percentile_frame_rasterizer_time_millis': 16.7,
      '99th_percentile_frame_build_time_millis': 33.3,
      '99th_percentile_frame_rasterizer_time_millis': 33.3,
    };
    final violations = <String>[
      for (final entry in limits.entries)
        if ((summary[entry.key] as num) > entry.value)
          '${entry.key}=${summary[entry.key]}ms (limit ${entry.value}ms)',
    ];
    expect(
      violations,
      isEmpty,
      reason: 'Measured page-turn timings: $summary',
    );
  });
}

double _percentile(List<double> values, double percentile) {
  values.sort();
  final index = (values.length * percentile).ceil().clamp(1, values.length) - 1;
  return values[index];
}
