import 'package:flutter/material.dart';

/// Один вариант в вопросе «к чему в серии это применить».
class ScopeChoice<T> {
  const ScopeChoice({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final T value;
}

/// Спрашивает, к какой части серии применить действие. Null — человек ушёл, не
/// ответив.
Future<T?> askScopeChoice<T>(
  BuildContext context,
  List<ScopeChoice<T>> choices,
) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final choice in choices)
            ListTile(
              leading: Icon(choice.icon),
              title: Text(choice.label),
              onTap: () => Navigator.of(sheet).pop(choice.value),
            ),
        ],
      ),
    ),
  );
}
