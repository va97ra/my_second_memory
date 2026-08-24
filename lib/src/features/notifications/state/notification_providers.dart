import 'package:ez_data/ez_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Планировщик напоминаний живёт столько же, сколько корневой контейнер, и
/// закрывается вместе с ним.
final notificationServiceProvider = Provider<ReminderScheduler>((ref) {
  final service = NotificationService();
  ref.onDispose(service.dispose);
  return service;
});

/// Будильники смен умеет ставить не всякая платформа: там, где нельзя,
/// подставляется молчаливая заглушка вместо отказа приложения.
final shiftAlarmSchedulerProvider = Provider<ShiftAlarmScheduler>((ref) {
  final scheduler = ref.watch(notificationServiceProvider);
  return scheduler is ShiftAlarmScheduler
      ? scheduler as ShiftAlarmScheduler
      : const NoopShiftAlarmScheduler();
});
