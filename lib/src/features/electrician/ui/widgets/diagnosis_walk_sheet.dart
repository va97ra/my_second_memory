import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

/// Проход по дереву вопросов.
///
/// Один вопрос на экране: человек, который ищет неисправность, не должен
/// держать в голове ветку. Назад можно вернуться — ответ бывает неверным, и
/// начинать заново из-за этого не нужно.
Future<void> showDiagnosisWalkSheet(
  BuildContext context,
  DiagnosisTree tree,
) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _WalkSheet(tree: tree),
    );

class _WalkSheet extends StatefulWidget {
  const _WalkSheet({required this.tree});

  final DiagnosisTree tree;

  @override
  State<_WalkSheet> createState() => _WalkSheetState();
}

class _WalkSheetState extends State<_WalkSheet> {
  late final List<String> _path = [widget.tree.root.id];

  DiagnosisNode get _node => widget.tree.nodeById(_path.last);

  void _answer(String nextId) => setState(() => _path.add(nextId));

  void _back() => setState(() {
        if (_path.length > 1) _path.removeLast();
      });

  void _restart() => setState(() {
        _path
          ..clear()
          ..add(widget.tree.root.id);
      });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final ru = strings.isRu;
    final theme = Theme.of(context);
    final node = _node;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.tree.title(ru),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (_path.length > 1)
                    IconButton(
                      onPressed: _back,
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      icon: const Icon(Icons.undo_rounded),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (node case final DiagnosisQuestion question) ...[
                Card(
                  margin: EdgeInsets.zero,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.whatToDo,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question.action(ru),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(question.text(ru), style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                // Кнопки в столбец: исход назван словами, и такая подпись в
                // половину ширины не помещается.
                FilledButton(
                  onPressed: () => _answer(question.yes),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      question.yesLabel(ru),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _answer(question.no),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      question.noLabel(ru),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
              if (node case final DiagnosisAnswer answer) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: answer.callSpecialist
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        answer.title(ru),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(answer.advice(ru)),
                      if (answer.callSpecialist) ...[
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                strings.callSpecialist,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(strings.startOver),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
