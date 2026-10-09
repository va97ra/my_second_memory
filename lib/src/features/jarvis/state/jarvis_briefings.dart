import 'dart:async';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/state/bool_setting_controller.dart';
import '../../../shared/state/notification_providers.dart';
import '../../finance/finance.dart';
import '../../memory_items/memory_items.dart';
import '../../recurrence/recurrence.dart';
import '../../shift_schedules/shift_schedules.dart';

/// «Говорить напоминания вслух» — включено, пока владелец не выключит.
final jarvisSpeakRemindersProvider = boolSettingProvider(
  storageKey: 'jarvis_speak_reminders_v1',
  initial: true,
);

/// Когда приходят сводки: время — в минутах от полуночи.
class JarvisBriefingSettings {
  const JarvisBriefingSettings({
    this.morning = true,
    this.morningAt = 9 * 60,
    this.evening = true,
    this.eveningAt = 20 * 60,
  });

  final bool morning;
  final int morningAt;
  final bool evening;
  final int eveningAt;

  JarvisBriefingSettings copyWith({
    bool? morning,
    int? morningAt,
    bool? evening,
    int? eveningAt,
  }) =>
      JarvisBriefingSettings(
        morning: morning ?? this.morning,
        morningAt: morningAt ?? this.morningAt,
        evening: evening ?? this.evening,
        eveningAt: eveningAt ?? this.eveningAt,
      );
}

final jarvisBriefingSettingsProvider = StateNotifierProvider<
    JarvisBriefingSettingsController, JarvisBriefingSettings>(
  (ref) => JarvisBriefingSettingsController(),
);

/// Сводки по умолчанию включены — в 9 утра и в 8 вечера, как в MemoryVoice.
class JarvisBriefingSettingsController
    extends StateNotifier<JarvisBriefingSettings> {
  JarvisBriefingSettingsController() : super(const JarvisBriefingSettings()) {
    unawaited(_load());
  }

  static const _morning = 'jarvis_briefing_morning_v1';
  static const _morningAt = 'jarvis_briefing_morning_at_v1';
  static const _evening = 'jarvis_briefing_evening_v1';
  static const _eveningAt = 'jarvis_briefing_evening_at_v1';

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    state = state.copyWith(
      morning: preferences.getBool(_morning),
      morningAt: preferences.getInt(_morningAt),
      evening: preferences.getBool(_evening),
      eveningAt: preferences.getInt(_eveningAt),
    );
  }

  Future<void> setMorning({bool? enabled, int? at}) async {
    state = state.copyWith(morning: enabled, morningAt: at);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_morning, state.morning);
    await preferences.setInt(_morningAt, state.morningAt);
  }

  Future<void> setEvening({bool? enabled, int? at}) async {
    state = state.copyWith(evening: enabled, eveningAt: at);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_evening, state.evening);
    await preferences.setInt(_eveningAt, state.eveningAt);
  }
}

/// Джарвис вне приложения: сводки утром и вечером и голос напоминаний.
///
/// Сводки ставятся на неделю вперёд — так они приходят, даже если
/// приложение неделю не открывать. Текст каждой собран заранее, поэтому
/// после любой правки дел, повторов или настроек вся неделя ставится
/// заново. Дней без дел в сводках нет: беспокоить незачем.
final jarvisBriefingsProvider = Provider<JarvisBriefings>((ref) {
  final briefings = JarvisBriefings(ref);
  ref
    ..listen(memoryItemsControllerProvider, (_, __) => briefings.plan())
    ..listen(recurrenceSeriesControllerProvider, (_, __) => briefings.plan())
    ..listen(jarvisBriefingSettingsProvider, (_, __) => briefings.plan())
    // Подсказки сводки — смены и деньги — тоже меняют её текст.
    ..listen(shiftSchedulesControllerProvider, (_, __) => briefings.plan())
    ..listen(financeControllerProvider, (_, __) => briefings.plan())
    ..listen(
      jarvisSpeakRemindersProvider,
      (_, speak) =>
          unawaited(ref.read(spokenRemindersProvider).setEnabled(speak)),
      fireImmediately: true,
    )
    ..onDispose(briefings.dispose);
  briefings.plan();
  return briefings;
});

class JarvisBriefings {
  JarvisBriefings(this._ref, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final Ref _ref;
  final DateTime Function() _clock;
  Timer? _pending;

  /// На сколько дней вперёд ставятся сводки.
  static const days = 7;

  /// Пачка правок — одна перестановка: записи сохраняются по одной.
  void plan() {
    _pending?.cancel();
    _pending = Timer(const Duration(seconds: 1), () => unawaited(_plan()));
  }

  /// Сводки на [days] дней вперёд от [now].
  List<Briefing> briefings(DateTime now) {
    final settings = _ref.read(jarvisBriefingSettingsProvider);
    final schedules = _ref.read(shiftSchedulesControllerProvider);
    final finance = _ref.read(financeControllerProvider);
    final currency = _ref.read(financeCurrencyProvider);
    List<MemoryItem> itemsOn(DateTime day, [int offset = 0]) =>
        _ref.read(memoryItemsForDayProvider(
            DateTime(day.year, day.month, day.day + offset)));
    final result = <Briefing>[];
    void add(DateTime on, int minutes, DateTime about) {
      final at =
          DateTime(on.year, on.month, on.day, minutes ~/ 60, minutes % 60);
      if (!at.isAfter(now)) return;
      final morning = on == about;
      final items = itemsOn(about);
      final text = AgendaSpeech.briefing(
        items,
        day: about,
        at: at,
        address: jarvisAddress,
        notes: briefingNotes(
          day: about,
          at: now,
          morning: morning,
          shifts: workingShifts(schedules, about),
          dayItems: items,
          overdue: morning ? itemsOn(about, -1) : const [],
          ahead: morning
              ? [for (var d = 1; d <= 3; d++) ...itemsOn(about, d)]
              : const [],
          finance: finance,
          currency: currency,
        ),
      );
      if (text != null) {
        result.add((at: at, day: about, title: text.title, body: text.body));
      }
    }

    for (var offset = 0; offset < days; offset++) {
      final day = DateTime(now.year, now.month, now.day + offset);
      if (settings.morning) add(day, settings.morningAt, day);
      if (settings.evening) {
        add(day, settings.eveningAt,
            DateTime(day.year, day.month, day.day + 1));
      }
    }
    return result;
  }

  Future<void> _plan() async {
    try {
      await _ref
          .read(briefingSchedulerProvider)
          .reconcileBriefings(briefings(_clock()));
    } catch (_) {
      // Android вправе отказать в уведомлении; следующая правка повторит.
    }
  }

  void dispose() => _pending?.cancel();
}
