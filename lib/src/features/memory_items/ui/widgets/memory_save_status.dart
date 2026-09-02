import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

/// Подпись о ходе автосохранения под заголовком редактора.
///
/// Значка рядом с ней нет: цвет самой подписи и говорит, сохранено уже или
/// ещё нет, а два указателя на одно и то же — лишний.
String memorySaveStatusLabel(
  BuildContext context, {
  required bool isSaving,
  required bool hasError,
}) {
  final strings = AppStrings.of(context);
  if (hasError) return strings.saveFailed;
  return isSaving ? strings.saving : strings.saved;
}
