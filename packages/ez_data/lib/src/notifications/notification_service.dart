import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import 'package:ez_domain/ez_domain.dart';

const _notificationChannel = MethodChannel('ezhednevnik_v2/notifications');
const _openAction = 'open_record';
const _stopAction = 'stop_sound';
const _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

class ReminderSoundSelection {
  const ReminderSoundSelection({required this.uri, required this.name});

  final String uri;
  final String name;
}

enum ReminderSoundSource { system, audioFile }

abstract class ReminderScheduler {
  Stream<String> get openedItemIds;

  bool get isSupported;

  Future<void> initialize();

  Future<bool> requestPermissions();

  Future<List<ReminderSoundSelection>> systemSounds();

  Future<ReminderSoundSelection?> selectSound({
    String? currentUri,
    ReminderSoundSource source = ReminderSoundSource.system,
  });

  Future<void> schedule(MemoryItem item);

  Future<void> cancel(String itemId);

  Future<void> reconcile(List<MemoryItem> items);

  Future<void> reconcileRecurring(List<MemoryItem> items);
}

abstract class ShiftAlarmScheduler {
  Future<void> reconcileShiftAlarms(
    List<ShiftSchedule> schedules, {
    bool force = false,
  });
}

class NotificationService implements ReminderScheduler, ShiftAlarmScheduler {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _openedItems = StreamController<String>.broadcast();
  bool _initialized = false;

  @override
  Stream<String> get openedItemIds => _openedItems.stream;

  @override
  bool get isSupported =>
      !_isFlutterTest &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> initialize() async {
    if (_initialized || !isSupported) {
      return;
    }
    _initialized = true;

    timezone_data.initializeTimeZones();
    try {
      final zoneName = await _notificationChannel.invokeMethod<String>(
        'getTimeZone',
      );
      if (zoneName != null && zoneName.isNotEmpty) {
        timezone.setLocalLocation(timezone.getLocation(zoneName));
      }
    } catch (_) {
      // UTC is a safe fallback; Android normally supplies the device zone.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationResponseBackground,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchResponse != null) {
      await _handleResponse(launchResponse);
    }
  }

  @override
  Future<bool> requestPermissions() async {
    if (!isSupported) {
      return false;
    }
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final notificationPermission =
        await android?.requestNotificationsPermission();
    if (notificationPermission == false) {
      return false;
    }
    final exactAlarmPermission = await android?.requestExactAlarmsPermission();
    return exactAlarmPermission != false;
  }

  @override
  Future<List<ReminderSoundSelection>> systemSounds() async {
    if (!isSupported) return const [];
    final result = await _notificationChannel.invokeListMethod<Object?>(
      'listSystemAlarmSounds',
    );
    return [
      for (final entry in result ?? const [])
        if (entry is Map)
          ReminderSoundSelection(
            uri: entry['uri'] as String,
            name: entry['name'] as String? ?? 'Системный звук',
          ),
    ];
  }

  @override
  Future<ReminderSoundSelection?> selectSound({
    String? currentUri,
    ReminderSoundSource source = ReminderSoundSource.system,
  }) async {
    if (!isSupported) {
      return null;
    }
    final result = await _notificationChannel.invokeMapMethod<String, Object?>(
      source == ReminderSoundSource.audioFile
          ? 'selectReminderAudioFile'
          : 'selectReminderSound',
      {'currentUri': currentUri},
    );
    final uri = result?['uri'] as String?;
    if (uri == null || uri.isEmpty) {
      return null;
    }
    return ReminderSoundSelection(
      uri: uri,
      name: result?['name'] as String? ?? 'Системный звук',
    );
  }

  @override
  Future<void> schedule(MemoryItem item) async {
    if (!isSupported) {
      return;
    }
    await initialize();
    await cancel(item.id);

    final remindAt = item.remindAt;
    if (remindAt == null ||
        item.status != MemoryStatus.active ||
        !remindAt.isAfter(DateTime.now())) {
      return;
    }

    // Мелодия и есть согласие на будильник. Не выбрали — придёт обычное
    // уведомление: звук будильника без спроса приложение не включает.
    final soundUri = item.reminderSoundUri;

    try {
      await _scheduleWithSound(item, remindAt, soundUri);
    } catch (_) {
      if (soundUri != null) {
        await _scheduleWithSound(item, remindAt, null);
      }
    }
  }

  Future<void> _scheduleWithSound(
    MemoryItem item,
    DateTime remindAt,
    String? soundUri,
  ) async {
    // Будильник звонит, пока его не выключат, и сам не смахивается. Обычное
    // уведомление ведёт себя как все прочие: выпало, прочитали, убрали.
    final isAlarm = soundUri != null;
    final channelId = isAlarm
        ? 'memory_reminders_${stableNotificationId(soundUri)}_v1'
        : 'memory_reminders_plain_v1';
    final details = AndroidNotificationDetails(
      channelId,
      isAlarm ? (item.reminderSoundName ?? 'Будильники') : 'Напоминания',
      channelDescription: isAlarm
          ? 'Будильники Ежедневника V2 с выбранной мелодией'
          : 'Напоминания Ежедневника V2',
      importance: isAlarm ? Importance.max : Importance.high,
      priority: isAlarm ? Priority.max : Priority.high,
      category: isAlarm
          ? AndroidNotificationCategory.alarm
          : AndroidNotificationCategory.reminder,
      audioAttributesUsage: isAlarm
          ? AudioAttributesUsage.alarm
          : AudioAttributesUsage.notification,
      sound: isAlarm ? UriAndroidNotificationSound(soundUri) : null,
      playSound: true,
      enableVibration: true,
      ongoing: isAlarm,
      autoCancel: !isAlarm,
      visibility: NotificationVisibility.public,
      additionalFlags: isAlarm ? Int32List.fromList(const [4]) : null,
      actions: [
        const AndroidNotificationAction(
          _openAction,
          'Открыть',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        if (isAlarm)
          const AndroidNotificationAction(
            _stopAction,
            'Выключить звук',
            cancelNotification: true,
          ),
      ],
    );
    final recurring = item.isGeneratedOccurrence && item.seriesId != null;
    final payload = jsonEncode({
      'source': ReminderSource.of(item),
      'itemId': item.id,
      if (recurring) 'seriesId': item.seriesId,
      if (recurring)
        'occurrenceDate': DateTime(
          item.memoryDate.year,
          item.memoryDate.month,
          item.memoryDate.day,
        ).toIso8601String(),
      'notificationId': stableNotificationId(item.id),
    });
    final body = item.body.trim();

    await _plugin.zonedSchedule(
      stableNotificationId(item.id),
      item.title,
      body.isEmpty || body == item.title ? 'Запланированная запись' : body,
      timezone.TZDateTime.from(remindAt, timezone.local),
      NotificationDetails(android: details),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> cancel(String itemId) async {
    if (!isSupported) {
      return;
    }
    await _plugin.cancel(stableNotificationId(itemId));
  }

  @override
  Future<void> reconcile(List<MemoryItem> items) =>
      _reconcileSource(items, ReminderSource.memory);

  @override
  Future<void> reconcileRecurring(List<MemoryItem> items) =>
      _reconcileSource(items, ReminderSource.recurrence);

  /// Приводит запланированные напоминания одного источника в соответствие со
  /// списком: лишние снимает, недостающие ставит.
  ///
  /// Чужой источник не трогается: обычные записи и вхождения повторов
  /// согласуются отдельно и не должны отменять напоминания друг друга.
  Future<void> _reconcileSource(List<MemoryItem> items, String source) async {
    if (!isSupported) return;
    await initialize();

    final wanted = {
      for (final item in items)
        if (wantsReminder(item)) stableNotificationId(item.id),
    };
    final alive = <int>{};
    for (final notification in await _plugin.pendingNotificationRequests()) {
      final payload = decodeReminderPayload(notification.payload);
      if (payload?['source'] != source) continue;
      if (wanted.contains(notification.id)) {
        alive.add(notification.id);
      } else {
        await _plugin.cancel(notification.id);
      }
    }

    var scheduled = 0;
    for (final item in items) {
      if (!wantsReminder(item) ||
          alive.contains(stableNotificationId(item.id))) {
        continue;
      }
      await schedule(item);
      // Планирование ходит на платформу. Без пауз длинный список подвешивает
      // интерфейс, поэтому каждые восемь напоминаний уступаем кадр.
      if (++scheduled % 8 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
  }

  @override
  Future<void> reconcileShiftAlarms(
    List<ShiftSchedule> schedules, {
    bool force = false,
  }) async {
    if (!isSupported) return;
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    final pendingShiftIds = <int>{
      for (final notification in pending)
        if (decodeReminderPayload(notification.payload)?['source'] ==
            'shift_alarm')
          notification.id,
    };

    final now = DateTime.now();
    final desiredIds = <int>{};
    for (final schedule in schedules) {
      for (var slot = 0; slot < schedule.alarms.length; slot++) {
        final alarm = schedule.alarms[slot];
        final times = shiftAlarmTimes(schedule, alarm, slot, now: now);
        if (times.isEmpty) continue;
        // Звук берётся один раз на будильник: обращение за системным звуком
        // ходит на платформу, а дней у одного графика десятки.
        var soundUri = alarm.soundUri ??
            await _notificationChannel.invokeMethod<String>(
              'getDefaultAlarmSound',
            );
        for (final alarmAt in times) {
          final notificationId = _shiftAlarmId(schedule.id, slot, alarmAt);
          desiredIds.add(notificationId);
          if (!force && pendingShiftIds.contains(notificationId)) continue;
          try {
            await _scheduleShiftAlarm(
              schedule,
              alarm,
              slot,
              alarmAt,
              soundUri,
            );
          } catch (_) {
            // Свой звук может оказаться недоступен — тогда остальные дни этого
            // будильника ставятся уже со звуком по умолчанию.
            if (soundUri != null) {
              soundUri = null;
              await _scheduleShiftAlarm(schedule, alarm, slot, alarmAt, null);
            }
          }
        }
      }
    }
    for (final id in pendingShiftIds.difference(desiredIds)) {
      await _plugin.cancel(id);
    }
  }

  Future<void> _scheduleShiftAlarm(
    ShiftSchedule schedule,
    ShiftAlarm alarm,
    int alarmIndex,
    DateTime alarmAt,
    String? soundUri,
  ) async {
    final channelId = soundUri == null
        ? 'shift_alarms_default_v1'
        : 'shift_alarms_${stableNotificationId(soundUri)}_v1';
    final id = _shiftAlarmId(schedule.id, alarmIndex, alarmAt);
    final details = AndroidNotificationDetails(
      channelId,
      alarm.soundName ?? 'Будильники смен',
      channelDescription: 'Будильники рабочих смен Ежедневника V2',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: soundUri == null ? null : UriAndroidNotificationSound(soundUri),
      playSound: true,
      enableVibration: true,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      additionalFlags: Int32List.fromList(const [4]),
      actions: const [
        AndroidNotificationAction(
          _stopAction,
          'Выключить звук',
          cancelNotification: true,
        ),
      ],
    );
    await _plugin.zonedSchedule(
      id,
      schedule.organizationName,
      alarmIndex == 1 ? 'Утро после суточной смены' : 'Сегодня рабочая смена',
      timezone.TZDateTime.from(alarmAt, timezone.local),
      NotificationDetails(android: details),
      payload: jsonEncode({
        'source': 'shift_alarm',
        'scheduleId': schedule.id,
        'alarmIndex': alarmIndex,
        'notificationId': id,
      }),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _handleResponse(NotificationResponse response) async {
    final id = response.id;
    if (id != null) {
      await _plugin.cancel(id);
    }
    if (response.actionId == _stopAction) {
      return;
    }
    final data = decodeReminderPayload(response.payload);
    final itemId = data?['itemId'] as String?;
    if (itemId != null && itemId.isNotEmpty) {
      _openedItems.add(itemId);
    }
  }

  void dispose() {
    _openedItems.close();
  }
}

class NoopShiftAlarmScheduler implements ShiftAlarmScheduler {
  const NoopShiftAlarmScheduler();

  @override
  Future<void> reconcileShiftAlarms(
    List<ShiftSchedule> schedules, {
    bool force = false,
  }) async {}
}

int _shiftAlarmId(String scheduleId, int alarmIndex, DateTime alarmAt) {
  return stableNotificationId(
    'shift:$scheduleId:$alarmIndex:'
    '${alarmAt.year}-${alarmAt.month}-${alarmAt.day}',
  );
}

Map<String, Object?>? decodeReminderPayload(String? payload) {
  if (payload == null || payload.isEmpty) {
    return null;
  }
  try {
    return (jsonDecode(payload) as Map).cast<String, Object?>();
  } catch (_) {
    return null;
  }
}

int stableNotificationId(String value) {
  var hash = 0x811C9DC5;
  for (final byte in utf8.encode(value)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0x7FFFFFFF;
  }
  return hash;
}

@pragma('vm:entry-point')
Future<void> notificationResponseBackground(
  NotificationResponse response,
) async {
  final id = response.id;
  if (id != null) {
    await FlutterLocalNotificationsPlugin().cancel(id);
  }
}
