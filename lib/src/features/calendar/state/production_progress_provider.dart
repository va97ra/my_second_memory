import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'production_calendar_provider.dart';
import 'production_preferences.dart';
import 'calendar_today_provider.dart';

final productionProgressProvider =
    Provider.family<ProductionProgress?, DateTime>((ref, month) {
  final preferences = ref.watch(productionPreferencesProvider);
  final today = ref.watch(calendarTodayProvider);
  final calendar = ref.watch(productionCalendarProvider(month.year)).calendar;
  return calendar.progress(month,
      today: today, includeToday: preferences.includeToday);
});
