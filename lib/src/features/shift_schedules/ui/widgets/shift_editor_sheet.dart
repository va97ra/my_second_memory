import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Настройка, которая открывается из карточки редактора.
///
/// [updates] перерисовывает содержимое: лист открыт поверх экрана и сам не
/// узнаёт, что в форме что-то поменялось.
Future<void> showShiftEditorSheet(
  BuildContext context, {
  required String title,
  required Listenable updates,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => KeyboardInsetPadding(
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(sheet).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: updates,
                builder: (context, _) => builder(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
