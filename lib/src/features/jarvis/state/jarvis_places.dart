import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calendar/calendar.dart';
import '../../home_feed/home_feed.dart';

/// Готовит страницу к показу до перехода на неё.
///
/// Адрес говорит только «куда». Какая закладка ленты открыта и какой месяц
/// листает календарь, страницы держат в своём состоянии, — его Джарвис
/// выставляет заранее, и страница открывается уже нужной.
void preparePlace(Ref ref, OpenPlace target) {
  switch (target.place) {
    case JarvisPlace.notes:
      ref.read(feedViewProvider.notifier).selectSection(FeedSection.notes);
    case JarvisPlace.feed:
      final view = ref.read(feedViewProvider);
      // Поиск, открытый Джарвисом, — тоже лента; его не закрываем.
      if (!view.searching) {
        ref.read(feedViewProvider.notifier).selectSection(FeedSection.day);
      }
    case JarvisPlace.calendar:
      final date = target.date;
      if (date != null) {
        ref.read(calendarFocusRequestProvider.notifier).state =
            CalendarFocusRequest(date);
      }
    default:
      break;
  }
}
