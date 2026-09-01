import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('каждая ветка ведёт к существующему узлу', () {
    for (final tree in diagnosisTrees) {
      final ids = {for (final node in tree.nodes) node.id};
      expect(ids.length, tree.nodes.length, reason: '${tree.id}: повтор id');
      for (final node in tree.nodes) {
        if (node is DiagnosisQuestion) {
          expect(ids, contains(node.yes), reason: '${tree.id}/${node.id} да');
          expect(ids, contains(node.no), reason: '${tree.id}/${node.id} нет');
          expect(node.actionRu, isNotEmpty, reason: node.id);
          expect(node.yesLabelRu, isNotEmpty, reason: node.id);
          expect(node.noLabelRu, isNotEmpty, reason: node.id);
          // Исход назван словами: «да» и «нет» ничего не сообщают.
          expect(node.yesLabelRu.toLowerCase(), isNot('да'), reason: node.id);
          expect(node.noLabelRu.toLowerCase(), isNot('нет'), reason: node.id);
        }
      }
    }
  });

  test('любой путь заканчивается выводом, а не крутится по кругу', () {
    for (final tree in diagnosisTrees) {
      final visited = <String>{};
      void walk(String id, List<String> path) {
        expect(
          path.contains(id),
          isFalse,
          reason: '${tree.id}: путь зациклился на $id',
        );
        visited.add(id);
        final node = tree.nodeById(id);
        if (node is DiagnosisQuestion) {
          walk(node.yes, [...path, id]);
          walk(node.no, [...path, id]);
        }
      }

      walk(tree.root.id, const []);
      // Недостижимых узлов в дереве нет: каждый либо вопрос по пути, либо
      // вывод, к которому этот путь приводит.
      expect(
        visited,
        containsAll([for (final node in tree.nodes) node.id]),
        reason: tree.id,
      );
    }
  });

  test('корень каждого дерева — вопрос, а не готовый ответ', () {
    for (final tree in diagnosisTrees) {
      expect(tree.root, isA<DiagnosisQuestion>(), reason: tree.id);
      expect(tree.titleRu, isNotEmpty);
    }
  });

  test('вывод, требующий обесточивания, помечен и объясняет, что дальше', () {
    final answers = [
      for (final tree in diagnosisTrees)
        for (final node in tree.nodes)
          if (node is DiagnosisAnswer) node,
    ];
    expect(answers, isNotEmpty);
    for (final answer in answers) {
      expect(answer.adviceRu, isNotEmpty, reason: answer.id);
    }
    // Короткое замыкание и утечка в проводке — всегда к специалисту.
    final wiringFaults = answers.where(
      (answer) =>
          answer.id == 'breaker_answer_short' ||
          answer.id == 'rcd_answer_wiring',
    );
    expect(wiringFaults, hasLength(2));
    for (final answer in wiringFaults) {
      expect(answer.callSpecialist, isTrue, reason: answer.id);
    }
  });

  test('раздел диагностики считается деревьями', () {
    expect(
      sectionCardCount(ElectricianSection.diagnostics),
      diagnosisTrees.length,
    );
    expect(cardsOfSection(ElectricianSection.diagnostics), isEmpty);
  });
}
