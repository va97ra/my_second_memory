import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

/// Удаление вложения: долгое нажатие вызывает меню на месте касания.
///
/// Отдельной кнопки удаления у фотографии и голоса нет намеренно — она
/// стояла бы поверх содержимого и нажималась бы случайно.
Future<void> showMediaDeleteMenu(
  BuildContext context,
  Offset position, {
  required VoidCallback onDelete,
}) async {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final colors = Theme.of(context).colorScheme;
  final selected = await showMenu<bool>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromLTWH(position.dx, position.dy, 1, 1),
      Offset.zero & overlay.size,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    items: [
      PopupMenuItem<bool>(
        value: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: colors.error),
            const SizedBox(width: 10),
            Text(
              AppStrings.of(context).delete,
              style: TextStyle(color: colors.error),
            ),
          ],
        ),
      ),
    ],
  );
  if (selected == true && context.mounted) onDelete();
}
