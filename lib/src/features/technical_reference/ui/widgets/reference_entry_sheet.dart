import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';

Future<void> showReferenceEntrySheet(
  BuildContext context,
  WidgetRef ref,
  TechnicalReferenceEntry entry,
) async {
  final snapshot = ref.read(toolDataControllerProvider).valueOrNull ??
      const ToolDataSnapshot();
  final existing =
      snapshot.bookmarks.where((item) => item.entryId == entry.id).firstOrNull;
  final note = TextEditingController(text: existing?.note ?? '');
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final strings = AppStrings.of(context);
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
                Text(entry.title(strings.isRu),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                SelectableText(entry.body(strings.isRu)),
                const SizedBox(height: 16),
                _Metadata(
                    label: strings.source,
                    value: '${entry.source} · ${entry.edition}'),
                _Metadata(label: strings.scope, value: entry.scope),
                _Metadata(
                    label: strings.warning,
                    value: entry.warning,
                    warning: true),
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
                        .saveBookmark(entryId: entry.id, note: note.text);
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

class _Metadata extends StatelessWidget {
  const _Metadata(
      {required this.label, required this.value, this.warning = false});

  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) => Card(
        color: warning ? Theme.of(context).colorScheme.tertiaryContainer : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(value),
            ],
          ),
        ),
      );
}
