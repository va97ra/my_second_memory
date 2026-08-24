import 'package:flutter/material.dart';

/// Спрашивает время суток и возвращает его в минутах от полуночи.
///
/// Открывается сразу с клавиатурой: время записи чаще набирают, чем крутят по
/// циферблату.
Future<int?> askTimeOfDay(BuildContext context, {int? initialMinutes}) async {
  final picked = await showTimePicker(
    context: context,
    initialEntryMode: TimePickerEntryMode.inputOnly,
    initialTime: initialMinutes == null
        ? TimeOfDay.now()
        : TimeOfDay(
            hour: initialMinutes ~/ 60,
            minute: initialMinutes % 60,
          ),
  );
  if (picked == null) return null;
  return picked.hour * 60 + picked.minute;
}
