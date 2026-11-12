import 'package:flutter/material.dart';

import 'scope_choice_sheet.dart';

/// Спрашивает, правится одно вхождение серии или все будущие.
///
/// true — эта и будущие записи, false — только эта, null — человек ушёл, не
/// ответив.
Future<bool?> askEditScope(BuildContext context) {
  final ru = Localizations.localeOf(context).languageCode == 'ru';
  return askScopeChoice(context, [
    ScopeChoice(
      icon: Icons.event_note_rounded,
      label: ru ? 'Редактировать только эту запись' : 'Edit only this record',
      value: false,
    ),
    ScopeChoice(
      icon: Icons.event_repeat_rounded,
      label: ru ? 'Эту и будущие записи' : 'This and future records',
      value: true,
    ),
  ]);
}
