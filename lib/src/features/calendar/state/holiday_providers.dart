import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Доставка доменного сервиса праздников в дерево виджетов.
final holidayCalendarServiceProvider = Provider<HolidayCalendarService>(
  (ref) => HolidayCalendarService(),
);
