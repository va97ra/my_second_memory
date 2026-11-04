import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'package:ez_domain/ez_domain.dart';

const memoryAttachmentPreviewHeight = 210.0;
const memoryAttachmentPreviewMaxWidth = 320.0;

IconData memoryTypeIcon(MemoryType type) => switch (type) {
      MemoryType.task => Icons.task_alt_rounded,
      MemoryType.note => Icons.sticky_note_2_rounded,
      MemoryType.voiceNote => Icons.mic_rounded,
      MemoryType.event => Icons.event_rounded,
      MemoryType.person => Icons.person_rounded,
      MemoryType.habit => Icons.autorenew_rounded,
      MemoryType.goal => Icons.flag_rounded,
      MemoryType.project => Icons.folder_rounded,
      MemoryType.purchase => Icons.shopping_bag_rounded,
      MemoryType.document => Icons.description_rounded,
      MemoryType.place => Icons.location_on_rounded,
      MemoryType.birthday => Icons.cake_rounded,
      MemoryType.payment => Icons.payments_rounded,
    };

Color memoryTypeColor(MemoryType type) => switch (type) {
      MemoryType.task => AppPalette.cyan,
      MemoryType.note => AppPalette.amber,
      MemoryType.voiceNote => AppPalette.magenta,
      MemoryType.event => AppPalette.violet,
      MemoryType.person => AppPalette.turquoise,
      MemoryType.habit => AppPalette.turquoise,
      MemoryType.goal => AppPalette.orange,
      MemoryType.project => AppPalette.indigo,
      MemoryType.purchase => AppPalette.magenta,
      // Крафтовая папка. Серым документ быть не может: серый означает
      // «выполнено» — см. [memoryDoneColor].
      MemoryType.document => AppPalette.amberDeep,
      MemoryType.place => AppPalette.danger,
      MemoryType.birthday => AppPalette.magentaLight,
      MemoryType.payment => AppPalette.turquoise,
    };

/// Цвет выполненной записи, один для всех видов.
///
/// Сделанное уходит в серый, и цветными на странице остаются только дела,
/// которые ещё ждут: среди десятка записей дня сразу видно, что осталось.
const memoryDoneColor = AppPalette.done;

/// Цвет, которым помечена запись: цвет её вида, пока она не выполнена.
Color memoryAccentColor(MemoryItem item) =>
    item.isDone ? memoryDoneColor : memoryTypeColor(item.type);

/// Цвет заголовка записи: выполненная пишется приглушённо, как и её цвет.
Color memoryTitleColor(ColorScheme colors, MemoryItem item) =>
    item.isDone ? colors.onSurfaceVariant : colors.onSurface;
