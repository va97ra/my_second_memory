import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/domain/memory_status.dart';

const _notificationChannel = MethodChannel('ezhednevnik_v2/notifications');
const _openAction = 'open_record';
const _stopAction = 'stop_sound';
const _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

class ReminderSoundSelection {
  const ReminderSoundSelection({required this.uri, required this.name});

  final String uri;
  final String name;
}

abstract class ReminderScheduler {
  Stream<String> get openedItemIds;

  bool get isSupported;

  Future<void> initialize();

  Future<bool> requestPermissions();

  Future<ReminderSoundSelection?> selectSound({String? currentUri});

  Future<void> schedule(MemoryItem item);

  Future<void> cancel(String itemId);

  Future<void> reconcile(List<MemoryItem> items);
}

final notificationServiceProvider = Provider<ReminderScheduler>((ref) {
  final service = NotificationService();
  ref.onDispose(service.dispose);
  return service;
});

class NotificationService implements ReminderScheduler {
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
  Future<ReminderSoundSelection?> selectSound({String? currentUri}) async {
    if (!isSupported) {
      return null;
    }
    final result = await _notificationChannel.invokeMapMethod<String, Object?>(
      'selectReminderSound',
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

    final selectedUri = item.reminderSoundUri;
    final defaultUri = selectedUri == null
        ? await _notificationChannel.invokeMethod<String>(
            'getDefaultAlarmSound',
          )
        : null;
    final soundUri = selectedUri ?? defaultUri;

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
    final channelId = soundUri == null
        ? 'memory_reminders_default_v1'
        : 'memory_reminders_${stableNotificationId(soundUri)}_v1';
    final sound =
        soundUri == null ? null : UriAndroidNotificationSound(soundUri);
    final details = AndroidNotificationDetails(
      channelId,
      item.reminderSoundName ?? 'Напоминания',
      channelDescription: 'Звуковые напоминания Ежедневника V2',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: sound,
      playSound: true,
      enableVibration: true,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      additionalFlags: Int32List.fromList(const [4]),
      actions: const [
        AndroidNotificationAction(
          _openAction,
          'Открыть',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          _stopAction,
          'Выключить звук',
          cancelNotification: true,
        ),
      ],
    );
    final payload = jsonEncode({
      'source': 'memory_reminder',
      'itemId': item.id,
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
  Future<void> reconcile(List<MemoryItem> items) async {
    if (!isSupported) {
      return;
    }
    await initialize();
    final desired = {
      for (final item in items)
        if (item.status == MemoryStatus.active &&
            item.remindAt?.isAfter(DateTime.now()) == true)
          stableNotificationId(item.id),
    };
    final pending = await _plugin.pendingNotificationRequests();
    for (final notification in pending) {
      final data = decodeReminderPayload(notification.payload);
      if (data?['source'] == 'memory_reminder' &&
          !desired.contains(notification.id)) {
        await _plugin.cancel(notification.id);
      }
    }
    for (final item in items) {
      if (item.status == MemoryStatus.active &&
          item.remindAt?.isAfter(DateTime.now()) == true) {
        await schedule(item);
      }
    }
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
