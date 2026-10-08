import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Просьба календарю показать день — например, от Джарвиса: «покажи
/// ноябрь».
///
/// Видимый месяц живёт в самом экране календаря, потому что листается его
/// анимацией. Снаружи его не меняют, а просят: экран слушает просьбу и
/// перелистывает себя сам тем же переходом, что и по кнопке «сегодня».
/// Каждая просьба — новый объект, поэтому повторная просьба о том же дне
/// тоже доходит.
class CalendarFocusRequest {
  CalendarFocusRequest(DateTime date)
      : date = DateTime(date.year, date.month, date.day);

  final DateTime date;
}

final calendarFocusRequestProvider =
    StateProvider<CalendarFocusRequest?>((ref) => null);
