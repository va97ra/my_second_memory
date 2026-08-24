import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

/// Ответ на вопрос о повторе.
///
/// Сам объект отличает выбор «не повторять» ([frequency] == null) от ухода без
/// ответа, когда не приходит ничего.
class RecurrenceChoice {
  const RecurrenceChoice(this.frequency);

  final RecurrenceFrequency? frequency;
}

/// Спрашивает, как запись повторяется.
Future<RecurrenceChoice?> askRecurrence(
  BuildContext context, {
  required RecurrenceFrequency? current,
}) {
  return showModalBottomSheet<RecurrenceChoice>(
    context: context,
    showDragHandle: true,
    builder: (context) => RecurrencePickerSheet(current: current),
  );
}

/// Выбор повтора записи.
class RecurrencePickerSheet extends StatelessWidget {
  const RecurrencePickerSheet({super.key, required this.current});

  final RecurrenceFrequency? current;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.event_busy_rounded),
            title: Text(locale == 'ru' ? 'Не повторять' : 'Do not repeat'),
            trailing: current == null ? const Icon(Icons.check_rounded) : null,
            onTap: () =>
                Navigator.of(context).pop(const RecurrenceChoice(null)),
          ),
          for (final frequency in RecurrenceFrequency.values)
            ListTile(
              leading: Icon(
                frequency == RecurrenceFrequency.monthly
                    ? Icons.sync_rounded
                    : Icons.event_repeat_rounded,
              ),
              title: Text(frequency.label(locale)),
              trailing:
                  current == frequency ? const Icon(Icons.check_rounded) : null,
              onTap: () =>
                  Navigator.of(context).pop(RecurrenceChoice(frequency)),
            ),
        ],
      ),
    );
  }
}
