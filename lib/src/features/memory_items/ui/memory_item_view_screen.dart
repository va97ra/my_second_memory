import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../home_feed/ui/widgets/memory_image_preview.dart';
import '../../home_feed/ui/widgets/memory_image_viewer.dart';
import '../../voice_notes/ui/widgets/voice_note_player.dart';
import '../domain/memory_item.dart';
import '../domain/memory_type.dart';
import '../state/memory_items_controller.dart';

class MemoryItemViewScreen extends ConsumerWidget {
  const MemoryItemViewScreen({
    required this.itemId,
    super.key,
  });

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final item = _findItem(ref);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => _goBack(context),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(strings.recordNotFound),
        ),
        body: Center(child: Text(strings.recordNotFound)),
      );
    }

    final locale = Localizations.localeOf(context).languageCode;
    final typeColor = _typeColor(item.type);
    final text = item.body.trim().isNotEmpty ? item.body.trim() : item.title;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => _goBack(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: const ValueKey('memory_readonly_view'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCF7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE7DCCB)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF92400E).withValues(alpha: 0.06),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: typeColor.withValues(alpha: 0.24),
                                ),
                              ),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(
                                  _iconFor(item.type),
                                  color: typeColor,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.type.label(locale),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: typeColor,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat.yMMMd(locale)
                                        .format(item.memoryDate),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: const Color(0xFF6B5B47),
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (text.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            text,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: const Color(0xFF241F1A),
                                      height: 1.36,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                        if (item.audioPath != null) ...[
                          const SizedBox(height: 16),
                          VoiceNotePlayer(
                            path: item.audioPath!,
                            recordedAt: item.memoryDate,
                            durationSeconds: item.audioDurationSeconds,
                          ),
                        ],
                        if (item.imagePaths.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _ReadonlyImageGrid(paths: item.imagePaths),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  MemoryItem? _findItem(WidgetRef ref) {
    final items = ref.watch(memoryItemsControllerProvider);
    for (final item in items) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }
}

class _ReadonlyImageGrid extends StatelessWidget {
  const _ReadonlyImageGrid({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final path in paths)
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('readonly_image_$path'),
              onTap: () => openMemoryImageViewer(context, path),
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                width: 156,
                height: 112,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0D3C0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: MemoryImagePreview(path: path),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

IconData _iconFor(MemoryType type) {
  return switch (type) {
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
  };
}

Color _typeColor(MemoryType type) {
  return switch (type) {
    MemoryType.task => const Color(0xFF16A34A),
    MemoryType.note => const Color(0xFF2563EB),
    MemoryType.voiceNote => const Color(0xFFDB2777),
    MemoryType.event => const Color(0xFF7C3AED),
    MemoryType.person => const Color(0xFF0891B2),
    MemoryType.habit => const Color(0xFF059669),
    MemoryType.goal => const Color(0xFFEA580C),
    MemoryType.project => const Color(0xFF4F46E5),
    MemoryType.purchase => const Color(0xFFCA8A04),
    MemoryType.document => const Color(0xFF475569),
    MemoryType.place => const Color(0xFFDC2626),
  };
}
