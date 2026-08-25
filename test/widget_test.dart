import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/navigation/app_router.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/shared/ui/memory_card/memory_item_card.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/holiday_detail_screen.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/recurrence.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import 'package:ezhednevnik_v2/src/app/theme/app_theme_controller.dart';
import 'package:ezhednevnik_v2/src/app/local_storage_scope_provider.dart';

part 'support/widget_test_harness.dart';
part 'widget_suites/app_shell_widget_tests.dart';
part 'widget_suites/memory_card_widget_tests.dart';
part 'widget_suites/security_widget_tests.dart';
part 'widget_suites/home_feed_widget_tests.dart';
part 'widget_suites/memory_flow_widget_tests.dart';
part 'widget_suites/calendar_widget_tests.dart';
part 'widget_suites/settings_widget_tests.dart';
part 'widget_suites/calendar_shift_widget_tests.dart';
part 'widget_suites/responsive_widget_tests.dart';

const _pixelImageDataUrl =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
    'AAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ru');
  });

  setUp(() {
    // Без этого обращения к SharedPreferences в тестовой среде не отвечают, и
    // загрузка повторов повисает: экраны, которые её дожидаются, показывают
    // вечный индикатор вместо содержимого.
    SharedPreferences.setMockInitialValues({});
  });

  registerAppShellWidgetTests();
  registerMemoryCardWidgetTests();
  registerSecurityWidgetTests();
  registerHomeFeedWidgetTests();
  registerMemoryFlowWidgetTests();
  registerCalendarWidgetTests();
  registerSettingsWidgetTests();
  registerCalendarShiftWidgetTests();
  registerResponsiveWidgetTests();
}
