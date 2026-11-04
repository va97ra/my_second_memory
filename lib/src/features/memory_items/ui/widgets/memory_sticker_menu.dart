import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/memory_item_commands.dart';
import 'delete_scope_sheet.dart';

enum _StickerAction { move, archive, delete }

/// Меню карточки по долгому нажатию. Отметка о выполнении здесь не нужна: для неё
/// квадратик на самой карточке.
Future<void> showMemoryStickerMenu(
  BuildContext context,
  WidgetRef ref,
  MemoryItem item,
) async {
  final strings = AppStrings.of(context);
  final action = await showModalBottomSheet<_StickerAction>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!item.isUndated)
            ListTile(
              key: ValueKey('sticker_move_${item.id}'),
              leading: const Icon(Icons.event_rounded),
              title: Text(strings.moveToDay),
              onTap: () => Navigator.of(sheet).pop(_StickerAction.move),
            ),
          ListTile(
            key: ValueKey('sticker_archive_${item.id}'),
            leading: const Icon(Icons.archive_rounded),
            title: Text(strings.archiveRecord),
            onTap: () => Navigator.of(sheet).pop(_StickerAction.archive),
          ),
          ListTile(
            key: ValueKey('sticker_delete_${item.id}'),
            leading: const Icon(Icons.delete_rounded),
            title: Text(strings.delete),
            onTap: () => Navigator.of(sheet).pop(_StickerAction.delete),
          ),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case _StickerAction.move:
      final picked = await showDatePicker(
        context: context,
        initialDate: item.memoryDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) await moveMemoryToDay(ref, item, picked);
    case _StickerAction.archive:
      archiveMemory(ref, item);
    case _StickerAction.delete:
      final scope = await askMemoryDelete(context, item);
      if (scope != null) await deleteMemory(ref, item, scope);
  }
}
