import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ez_design/ez_design.dart';
import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import '../../../memory_items/ui/widgets/memory_item_presentation.dart';
import '../../../voice_notes/ui/widgets/voice_note_player.dart';
import 'memory_image_preview.dart';
import 'memory_image_viewer.dart';

part 'memory_item_card_content.dart';
part 'memory_item_card_rails.dart';
part 'memory_item_card_shape.dart';

class MemoryItemCard extends StatelessWidget {
  const MemoryItemCard({
    required this.item,
    required this.onOpen,
    this.onToggleDone,
    this.onArchive,
    this.onRestore,
    this.showDate = true,
    this.compact = false,
    this.denseFeedLayout = false,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    super.key,
  });

  final MemoryItem item;
  final VoidCallback onOpen;
  final VoidCallback? onToggleDone;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final bool showDate;
  final bool compact;
  final bool denseFeedLayout;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final typeColor = memoryTypeColor(item.type);
    final colors = Theme.of(context).colorScheme;
    final textures = AppSurfaceTextures.maybeOf(context);
    final notebook = NotebookVisuals.maybeOf(context);
    final palette = AppSurfacePalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = item.isDone
        ? Color.alphaBlend(
            const Color(0xFF16A34A).withValues(alpha: isDark ? 0.14 : 0.08),
            colors.surface,
          )
        : colors.surface;
    final borderColor = item.isDone
        ? const Color(0xFF86EFAC)
        : typeColor.withValues(alpha: 0.34);
    final cardShadowColor = notebook != null
        ? const Color(0xFF3B1D0E).withValues(alpha: 0.45)
        : isDark
            ? Colors.black.withValues(alpha: 0.68)
            : const Color(0xFF536575).withValues(alpha: 0.34);
    final roundedBorder = BorderRadius.circular(8);
    final cardShape = notebook == null
        ? RoundedRectangleBorder(borderRadius: roundedBorder)
        : _TornPaperShapeBorder(
            variant: _stablePaperVariant(item.id),
            side: BorderSide(color: borderColor, width: 1),
          );

    // A card is loose paper: it stays light even on the dark notebook.
    return NotebookPaperIsland(
      child: Padding(
        padding: margin,
        child: Material(
          color: cardColor,
          elevation: 6,
          shadowColor: cardShadowColor,
          surfaceTintColor: Colors.transparent,
          shape: cardShape,
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            key: ValueKey('memory_card_${item.id}'),
            height: denseFeedLayout
                ? _denseFeedCardHeight(context) + (showDate ? 8 : 0)
                : compact
                    ? 108
                    : 118,
            child: Ink(
              decoration: BoxDecoration(
                color: notebook == null ? null : cardColor,
                gradient: notebook == null
                    ? palette.surfaceGradient(base: cardColor)
                    : null,
                image: notebook != null
                    // Loose paper keeps its own light grain in either notebook.
                    ? const DecorationImage(
                        image: AssetImage(NotebookAssets.paper),
                        fit: BoxFit.cover,
                        opacity: 0.5,
                      )
                    : textures == null
                        ? null
                        : DecorationImage(
                            image: AssetImage(textures.surfaceAsset),
                            fit: BoxFit.cover,
                            opacity: textures.surfaceOpacity,
                            filterQuality: FilterQuality.low,
                          ),
                borderRadius: notebook == null ? roundedBorder : null,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Paper does not ripple. Pressing the sheet presses the
                      // whole sheet; the action rail stays its own target.
                      Expanded(
                        child: NotebookPressable(
                          onTap: onOpen,
                          borderRadius: BorderRadius.zero,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _TypeRail(
                                key: ValueKey('memory_card_type_${item.id}'),
                                item: item,
                                color: typeColor,
                                showDate: showDate,
                                compact: compact,
                                denseFeedLayout: denseFeedLayout,
                              ),
                              Expanded(
                                child: _CardContent(
                                  key: ValueKey(
                                      'memory_card_content_${item.id}'),
                                  item: item,
                                  compact: compact,
                                  denseFeedLayout: denseFeedLayout,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _ActionRail(
                        key: ValueKey('memory_card_actions_${item.id}'),
                        item: item,
                        compact: compact,
                        denseFeedLayout: denseFeedLayout,
                        onToggleDone: onToggleDone,
                        onArchive: onArchive,
                        onRestore: onRestore,
                      ),
                    ],
                  ),
                  if (notebook == null)
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: roundedBorder,
                          border: Border.all(color: borderColor),
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
  }
}

double _denseFeedCardHeight(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(1);
  if (scale <= 1.3) {
    return 76 + ((scale - 1).clamp(0.0, 0.3) * 40);
  }
  final largeTextProgress = ((scale - 1.3) / 0.7).clamp(0.0, 1.0);
  return 88 + largeTextProgress * 64;
}
