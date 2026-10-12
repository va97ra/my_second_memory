import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calculator/state/calculator_controller.dart';
import '../../converter/state/converter_controller.dart';
import '../../memory_items/memory_items.dart';
import 'jarvis_answers.dart';
import 'jarvis_converter.dart';
import 'jarvis_outcome.dart';
import 'jarvis_page.dart';

/// Глаза Джарвиса: «посмотри на календарь», «что в финансах», «что здесь».
///
/// Решение владельца 12 октября 2026: Джарвис полноценен на каждой странице
/// Ежедневника — смотрит, читает и объясняет, кроме «Аккаунтов». Рассказ
/// собирается из тех же ответов, что и на прямой вопрос («что у меня
/// завтра», «сколько я потратил»), — второго описания страниц нет. Страницу
/// при этом видно: «видите, сэр» — хост Джарвиса сворачивает лист, а если
/// названа другая страница, переходит на неё.
class JarvisLook {
  JarvisLook(this._ref, this._answers);

  final Ref _ref;
  final JarvisAnswers _answers;

  JarvisOutcome look(LookAtPage command, DateTime now) {
    final screen = _ref.read(jarvisPageProvider);
    final asked = command.place;
    final target =
        asked == null ? screen : OpenPlace(asked, date: command.date);
    if (target == null) return const JarvisOutcome(JarvisReplies.lookNowhere);
    final told = _tell(target, now);
    return JarvisOutcome(
      told.say,
      open: target,
      mentioned: told.mentioned,
      followUp: told.followUp,
    );
  }

  JarvisOutcome _tell(OpenPlace target, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final day = target.date ?? today;
    return switch (target.place) {
      JarvisPlace.calendar => _plan(_answers.agenda(
          AskAgenda(
            from: today,
            to: DateTime(today.year, today.month, today.day + 6),
            label: 'В ближайшие семь дней',
          ),
          now)),
      JarvisPlace.day => _plan(_answers.agenda(
          AskAgenda(from: day, to: day, label: spokenDay(day, now)), now)),
      JarvisPlace.feed => _plan(_answers.agenda(
          AskAgenda(from: today, to: today, label: spokenDay(today, now)),
          now)),
      JarvisPlace.notes => _answers.undated(),
      JarvisPlace.finance => _answers.finance(
          AskFinance(kind: FinanceEntryKind.expense, month: today), now),
      JarvisPlace.shifts =>
        _answers.shift(AskShift(today, findNext: true), now),
      JarvisPlace.holidays => _answers.holidays(AskHolidays(day), now),
      JarvisPlace.calculator => _calculator(),
      JarvisPlace.converter => _converter(),
      JarvisPlace.archive => _archive(),
      JarvisPlace.accounts => const JarvisOutcome(JarvisReplies.lookAccounts),
      _ => JarvisOutcome(JarvisReplies.lookAbout(target.place)),
    };
  }

  /// После рассказа о делах — предложить записать ещё; «да» — «Что
  /// записать?».
  JarvisOutcome _plan(JarvisOutcome told) => JarvisOutcome(
        '${told.say} ${JarvisReplies.planMore}',
        link: told.link,
        mentioned: told.mentioned,
        followUp: (said, _) async => SmallTalk.agrees(said)
            ? const JarvisOutcome(JarvisReplies.whatToPlan)
            : null,
      );

  JarvisOutcome _calculator() {
    final shown = _ref.read(calculatorControllerProvider);
    return JarvisOutcome(calculatorReply(
      CalculatorMove.result,
      value: shown.evaluation.value,
      empty: shown.expression.isEmpty,
    ));
  }

  JarvisOutcome _converter() {
    final reading = converterReading(_ref.read(converterControllerProvider));
    return JarvisOutcome(reading == null
        ? JarvisReplies.lookAbout(JarvisPlace.converter)
        : unitReply(reading.asked, reading.result));
  }

  JarvisOutcome _archive() {
    final archived = [
      for (final item in _ref.read(memoryItemsControllerProvider))
        if (item.status == MemoryStatus.archived) item,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return JarvisOutcome(JarvisReplies.lookArchive(
      archived.length,
      archived.isEmpty ? null : archived.first.title,
    ));
  }
}
