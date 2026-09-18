import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Refreshes after midnight, including when an open app resumes from sleep.
final calendarTodayProvider = Provider.autoDispose<DateTime>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final timer = Timer.periodic(const Duration(minutes: 1), (_) {
    final current = DateTime.now();
    if (DateTime(current.year, current.month, current.day) != today) {
      ref.invalidateSelf();
    }
  });
  ref.onDispose(timer.cancel);
  return today;
});
