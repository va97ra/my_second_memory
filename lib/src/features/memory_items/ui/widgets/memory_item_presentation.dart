import 'package:flutter/material.dart';

import '../../domain/memory_type.dart';

const memoryAttachmentPreviewHeight = 210.0;
const memoryAttachmentPreviewMaxWidth = 320.0;

IconData memoryTypeIcon(MemoryType type) => switch (type) {
      MemoryType.task => Icons.check_circle_outline,
      MemoryType.note => Icons.notes,
      MemoryType.voiceNote => Icons.mic_none,
      MemoryType.event => Icons.event,
      MemoryType.person => Icons.person_outline,
      MemoryType.habit => Icons.repeat,
      MemoryType.goal => Icons.flag_outlined,
      MemoryType.project => Icons.folder_outlined,
      MemoryType.purchase => Icons.shopping_bag_outlined,
      MemoryType.document => Icons.description_outlined,
      MemoryType.place => Icons.place_outlined,
      MemoryType.birthday => Icons.cake_outlined,
      MemoryType.payment => Icons.payments_outlined,
    };

Color memoryTypeColor(MemoryType type) => switch (type) {
      MemoryType.task => const Color(0xFF16A34A),
      MemoryType.note => const Color(0xFF5B7FA3),
      MemoryType.voiceNote => const Color(0xFFDB2777),
      MemoryType.event => const Color(0xFF7C3AED),
      MemoryType.person => const Color(0xFF0891B2),
      MemoryType.habit => const Color(0xFF059669),
      MemoryType.goal => const Color(0xFFEA580C),
      MemoryType.project => const Color(0xFF4F46E5),
      MemoryType.purchase => const Color(0xFFCA8A04),
      MemoryType.document => const Color(0xFFC2BFB6),
      MemoryType.place => const Color(0xFFDC2626),
      MemoryType.birthday => const Color(0xFFDB2777),
      MemoryType.payment => const Color(0xFF0F766E),
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
