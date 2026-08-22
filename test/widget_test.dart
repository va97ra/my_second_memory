import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezhednevnik_v2/src/app.dart';
import 'package:ezhednevnik_v2/src/core/routing/app_router.dart';
import 'package:ezhednevnik_v2/src/data/local_storage/local_storage_scope.dart';
import 'package:ezhednevnik_v2/src/data/local_storage/local_storage_scope_provider.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/data/local_memory_repository.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/data/memory_repository.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_status.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_type.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/ui/widgets/memory_item_card.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/data/local_recurrence_exception_repository.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/data/local_recurrence_repository.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/domain/recurrence_series.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/domain/recurrence_projection_service.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_controller.dart';
import 'package:ezhednevnik_v2/src/core/theme/app_theme_controller.dart';
import 'package:ezhednevnik_v2/src/core/theme/notebook/notebook_background.dart';
import 'package:ezhednevnik_v2/src/core/theme/app_theme_style.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/holiday_detail_screen.dart';
import 'package:ezhednevnik_v2/src/features/security/data/app_cipher.dart';
import 'package:ezhednevnik_v2/src/features/security/data/security_service.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/security/data/secure_entity_backend.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/data/shift_schedule_repository.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/domain/shift_schedule.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';

part 'support/widget_test_harness.dart';
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

  registerMemoryCardWidgetTests();
  registerSecurityWidgetTests();
  registerHomeFeedWidgetTests();
  registerMemoryFlowWidgetTests();
  registerCalendarWidgetTests();
  registerSettingsWidgetTests();
  registerCalendarShiftWidgetTests();
  registerResponsiveWidgetTests();
}
