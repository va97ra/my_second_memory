import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

/// Готовые ответы на вопрос Джарвиса — чтобы не набирать «завтра» руками.
///
/// Нажатие уходит Джарвису обычной фразой, той же, что можно сказать:
/// второго пути ответа у него нет.
class JarvisAnswerChips extends StatelessWidget {
  const JarvisAnswerChips({
    required this.asking,
    required this.onAnswer,
    super.key,
  });

  final ParsedTask asking;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final answers = asking.need == TaskNeed.date
        ? [
            (strings.today, 'сегодня'),
            (strings.tomorrow, 'завтра'),
            (strings.jarvisNoDate, 'без даты'),
            (strings.jarvisCancelAnswer, 'не надо'),
          ]
        : [
            (strings.jarvisMorning, 'в 9 утра'),
            (strings.jarvisAfternoon, 'в 13:00'),
            (strings.jarvisEvening, 'в 19:00'),
            (strings.jarvisAllDay, 'весь день'),
            (strings.jarvisCancelAnswer, 'не надо'),
          ];
    // Одна строка, которую листают пальцем, а не столбик: при крупном шрифте
    // перенесённые кнопки занимали пол-листа и выдавливали сам разговор.
    return SingleChildScrollView(
      key: const ValueKey('jarvis_answers'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (index, (label, said)) in answers.indexed) ...[
            if (index > 0) const SizedBox(width: 8),
            OutlinedButton(
              key: ValueKey('jarvis_answer_$said'),
              onPressed: () => onAnswer(said),
              child: Text(label),
            ),
          ],
        ],
      ),
    );
  }
}
