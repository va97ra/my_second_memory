import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/widgets.dart';

import 'calendar_locations.dart';
import 'page_turn_navigation.dart';

/// Адрес страницы, которую назвал Джарвис.
String jarvisLocation(OpenPlace target) {
  final date = target.date ?? DateTime.now();
  return switch (target.place) {
    JarvisPlace.calendar => '/calendar',
    JarvisPlace.day => calendarDayLocation(date),
    JarvisPlace.holidays => holidaysLocation(date),
    JarvisPlace.feed || JarvisPlace.notes => '/',
    JarvisPlace.archive => '/memory',
    JarvisPlace.accounts => '/accounts',
    JarvisPlace.calculator => '/tools/calculator',
    JarvisPlace.finance => '/tools/finance',
    JarvisPlace.converter => '/tools/converter',
    JarvisPlace.shifts => '/settings/shifts',
    JarvisPlace.productionCalendar => '/calendar/preferences',
    JarvisPlace.settings => '/settings',
    JarvisPlace.backup => '/settings/backup',
    JarvisPlace.sync => '/settings/sync',
  };
}

/// Вкладки нижней панели меняют адрес целиком: они помнят себя сами. Всё
/// остальное открывается поверх страницы, чтобы «назад» вернуло к разговору.
const _branches = {'/calendar', '/', '/accounts', '/settings'};

/// Открывает страницу тем же переворотом листа, что и кнопки приложения.
Future<void> openJarvisPlace(BuildContext context, OpenPlace target) {
  final location = jarvisLocation(target);
  return _branches.contains(location)
      ? context.pageTurnGo(location)
      : context.pageTurnPush<void>(location);
}
