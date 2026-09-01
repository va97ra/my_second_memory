import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';
import 'electrician_art_view.dart';

/// Карточка целиком: три вопроса, документ, пометка о сверке и своя заметка.
Future<void> showElectricianCardSheet(
  BuildContext context,
  WidgetRef ref,
  ElectricianCard card,
) async {
  final snapshot = ref.read(toolDataControllerProvider).valueOrNull ??
      const ToolDataSnapshot();
  final existing =
      snapshot.bookmarks.where((item) => item.entryId == card.id).firstOrNull;
  final note = TextEditingController(text: existing?.note ?? '');
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final strings = AppStrings.of(context);
      final ru = strings.isRu;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  card.title(ru),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (hasElectricianArt(card.symbol))
                  Center(child: _ZoomableArt(name: card.symbol)),
                _Block(label: strings.cardWhat, value: card.what(ru)),
                _Block(label: strings.cardPurpose, value: card.purpose),
                _Block(
                  label: strings.cardCaution,
                  value: card.caution,
                  tone: _Tone.caution,
                ),
                _Block(
                  label: strings.source,
                  value: card.edition.isEmpty
                      ? card.source
                      : '${card.source} · ${card.edition}',
                  tone: card.checkedAgainstSource
                      ? _Tone.plain
                      : _Tone.unchecked,
                  footnote: card.checkedAgainstSource
                      ? null
                      : strings.notCheckedAgainstSource,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: strings.personalNote,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    await ref
                        .read(toolDataControllerProvider.notifier)
                        .saveBookmark(entryId: card.id, note: note.text);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.star_rounded),
                  label: Text(strings.save),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  note.dispose();
}

enum _Tone { plain, caution, unchecked }

class _Block extends StatelessWidget {
  const _Block({
    required this.label,
    required this.value,
    this.tone = _Tone.plain,
    this.footnote,
  });

  final String label;
  final String value;
  final _Tone tone;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: switch (tone) {
        _Tone.plain => null,
        _Tone.caution => scheme.tertiaryContainer,
        _Tone.unchecked => scheme.errorContainer,
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            SelectableText(value),
            if (footnote != null) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.help_outline_rounded, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      footnote!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Обозначение, которое можно рассмотреть: нажатие открывает его во весь
/// экран с масштабированием — на схеме важны детали начертания.
class _ZoomableArt extends StatelessWidget {
  const _ZoomableArt({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => Dialog(
              insetPadding: const EdgeInsets.all(24),
              child: InteractiveViewer(
                maxScale: 6,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElectricianArtView(name: name, size: 280),
                ),
              ),
            ),
          ),
          child: ElectricianArtView(name: name, size: 120),
        ),
      );
}
