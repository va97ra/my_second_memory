import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../navigation/page_turn_navigation.dart';
import '../../../../shared/ui/memory_card/memory_card_attachment_icons.dart';
import '../../../../shared/ui/memory_card/memory_card_paper.dart';
import '../../../../shared/ui/memory_card/memory_item_presentation.dart';
import '../../../../shared/ui/styled_text_span.dart';
import '../../../memory_items/memory_items.dart';
import 'note_card_done_box.dart';
import 'note_card_strip.dart';

/// Карточка записки: ровный квадрат с полосой вида сверху и квадратиком
/// выполнения в углу.
///
/// Нажатие открывает редактор, долгое нажатие — меню записки. Подписка идёт
/// по идентификатору: правка одной записки перестраивает одну карточку.
class NoteGridCard extends ConsumerWidget {
  const NoteGridCard({super.key, required this.itemId});

  static const _radius = BorderRadius.all(Radius.circular(8));

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(memoryItemByIdProvider(itemId));
    if (item == null) return const SizedBox.shrink();
    final accent = memoryAccentColor(item);

    return PaperSheet(
      child: GestureDetector(
        onLongPress: () => _showMenu(context, ref, item),
        child: Material(
          key: ValueKey('note_card_$itemId'),
          color: notebookCardSurface,
          elevation: 3,
          shadowColor: MemoryCardPaper.shadowColor(context),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: _radius,
            side: BorderSide(color: accent.withValues(alpha: 0.34)),
          ),
          clipBehavior: Clip.antiAlias,
          child: NotebookPressable(
            onTap: () => context.pageTurnPush(
              '/memory/item/${Uri.encodeComponent(itemId)}?panel=notes',
            ),
            borderRadius: _radius,
            pressedOffset: 0,
            child: Ink(
              decoration: MemoryCardPaper.surface(_radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      NoteCardStrip(
                        key: ValueKey('note_card_strip_$itemId'),
                        item: item,
                      ),
                      Expanded(child: _NoteCardContent(item: item)),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: NoteCardDoneBox(
                      key: ValueKey('note_card_done_$itemId'),
                      isDone: item.isDone,
                      onToggle: () => toggleMemoryDone(ref, item),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMenu(
    BuildContext context,
    WidgetRef ref,
    MemoryItem item,
  ) async {
    final strings = AppStrings.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: ValueKey('note_card_archive_$itemId'),
              leading: const Icon(Icons.archive_rounded),
              title: Text(strings.archiveRecord),
              onTap: () {
                Navigator.of(sheet).pop();
                archiveMemory(ref, item);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteCardContent extends StatelessWidget {
  const _NoteCardContent({required this.item});

  final MemoryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final typography = AppContentTypography.of(context);
    final style = typography.apply(
      Theme.of(context).textTheme.bodySmall?.copyWith(
            color: memoryTitleColor(colors, item),
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
      manropeWeight: FontWeight.w600,
    );
    final styled = StyledText.parse(item.body.trim());
    final text = styled.plain.isNotEmpty ? styled : styledMemoryTitle(item);
    final hasAudio = item.voiceNotes.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              // Сколько строк влезает, столько и показываем: многоточие
              // лучше, чем буквы, обрезанные по краю карточки.
              builder: (context, constraints) => ClipRect(
                child: Text.rich(
                  styledTextSpan(text, style),
                  maxLines: (constraints.maxHeight /
                          typography.measuredLineHeight(style))
                      .floor()
                      .clamp(1, 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          // Ряд вложений и место под квадратик выполнения в углу.
          SizedBox(
            height: NoteCardDoneBox.boxSize,
            child: hasAudio || item.imagePaths.isNotEmpty
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: MemoryCardAttachmentIcons(
                      imageCount: item.imagePaths.length,
                      hasAudio: hasAudio,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
