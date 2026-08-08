import 'package:flutter/material.dart';

import '../../domain/memory_type.dart';

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
      MemoryType.task => const Color(0xFF20B26B),
      MemoryType.note => const Color(0xFF2F7DD1),
      MemoryType.voiceNote => const Color(0xFFD9467B),
      MemoryType.event => const Color(0xFF7A5AF8),
      MemoryType.person => const Color(0xFF0FA3B1),
      MemoryType.habit => const Color(0xFF109B78),
      MemoryType.goal => const Color(0xFFF26B38),
      MemoryType.project => const Color(0xFF4D63D2),
      MemoryType.purchase => const Color(0xFFD69A00),
      MemoryType.document => const Color(0xFF64748B),
      MemoryType.place => const Color(0xFFE04444),
      MemoryType.birthday => const Color(0xFFE03E8C),
      MemoryType.payment => const Color(0xFF008C85),
    };

String formatMemoryTime(int minutes) {
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${mins.toString().padLeft(2, '0')}';
}

String memoryTitleFromRecord(
  String body,
  MemoryType type,
  String languageCode,
) {
  final compact = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.isEmpty) return type.label(languageCode);
  if (compact.length <= 48) return compact;
  return '${compact.substring(0, 48)}...';
}
