import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../home_feed/ui/widgets/memory_image_preview.dart';
import '../../home_feed/ui/widgets/memory_image_viewer.dart';
import '../../voice_notes/ui/widgets/voice_note_player.dart';
import '../domain/memory_type.dart';
import '../state/memory_items_controller.dart';
import '../state/memory_item_selectors.dart';

class MemoryItemViewScreen extends ConsumerWidget {
  const MemoryItemViewScreen({
    required this.itemId,
    super.key,
  });

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final loadState = ref.watch(memoryItemsLoadProvider);
    final item = ref.watch(memoryItemByIdProvider(itemId));

    if (loadState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (loadState.hasError) {
      return Scaffold(body: Center(child: Text(strings.loadFailed)));
    }

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
    final timeText = item.timeMinutes == null
        ? null
        : '${(item.timeMinutes! ~/ 60).toString().padLeft(2, '0')}:'
            '${(item.timeMinutes! % 60).toString().padLeft(2, '0')}';

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
        child: LayoutBuilder(
          key: const ValueKey('memory_readonly_view'),
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SizedBox(
                    key: const ValueKey('memory_readonly_panel'),
                    width: double.infinity,
                    height: constraints.maxHeight - 18,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFDF8).withValues(alpha: 0.97),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD8C8B4)),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF6B4F35).withValues(alpha: 0.09),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _iconFor(item.type),
                                    color: typeColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.type.label(locale),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: typeColor,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                                Text(
                                  DateFormat('d MMM y', locale)
                                      .format(item.memoryDate),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: const Color(0xFF6B5B47),
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                if (timeText != null) ...[
                                  const SizedBox(width: 8),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: typeColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        timeText,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: typeColor,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Divider(),
                          Expanded(
                            child: SingleChildScrollView(
                              key: const ValueKey('memory_readonly_content'),
                              padding:
                                  const EdgeInsets.fromLTRB(14, 12, 14, 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (text.isNotEmpty) ...[
                                    Text(
                                      text,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
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
                                      durationSeconds:
                                          item.audioDurationSeconds,
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final single = paths.length == 1;
        final width =
            single ? constraints.maxWidth : (constraints.maxWidth - 10) / 2;
        final height =
            single ? (width * 0.62).clamp(180.0, 360.0) : width * 0.72;

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
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE0D3C0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: MemoryImagePreview(
                        path: path,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
