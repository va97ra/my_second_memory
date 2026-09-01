/// Обучение: темы по уровням и короткий тест после каждой.
///
/// Единицы измерения отдельными темами не заводятся: ампер, вольт, ом, ватт
/// и герц определены в словаре, и второй раз то же самое здесь писать
/// нельзя. Тема ссылается на словарь словами, а поиск находит карточку.
///
/// Содержание разложено по уровням: `learning_level_1.dart` и дальше.
/// Здесь остаются модель темы, модель вопроса и сборка уровней в один
/// список — чтобы файл содержания не рос вместе с курсом.
library;

import 'learning_level_1.dart';
import 'learning_level_2.dart';
import 'learning_level_3.dart';
import 'learning_level_4.dart';
import 'learning_level_5.dart';

/// Вопрос теста: четыре варианта, один верный и объяснение после ответа.
class QuizQuestion {
  const QuizQuestion({
    required this.questionRu,
    required this.questionEn,
    required this.optionsRu,
    required this.optionsEn,
    required this.correctIndex,
    required this.explanationRu,
    required this.explanationEn,
  });

  final String questionRu;
  final String questionEn;
  final List<String> optionsRu;
  final List<String> optionsEn;
  final int correctIndex;
  final String explanationRu;
  final String explanationEn;

  String question(bool ru) => ru ? questionRu : questionEn;
  List<String> options(bool ru) => ru ? optionsRu : optionsEn;
  String explanation(bool ru) => ru ? explanationRu : explanationEn;
}

class LearningTopic {
  const LearningTopic({
    required this.id,
    required this.level,
    required this.titleRu,
    required this.titleEn,
    required this.explanationRu,
    required this.explanationEn,
    required this.exampleRu,
    required this.exampleEn,
    required this.quiz,
  });

  final String id;

  /// Номер уровня: темы идут по возрастанию сложности.
  final int level;
  final String titleRu;
  final String titleEn;
  final String explanationRu;
  final String explanationEn;

  /// Пример из работы, а не из учебника.
  final String exampleRu;
  final String exampleEn;
  final List<QuizQuestion> quiz;

  String title(bool ru) => ru ? titleRu : titleEn;
  String explanation(bool ru) => ru ? explanationRu : explanationEn;
  String example(bool ru) => ru ? exampleRu : exampleEn;
}

/// Все темы обучения по возрастанию уровня.
const learningTopics = <LearningTopic>[
  ...learningLevel1,
  ...learningLevel2,
  ...learningLevel3,
  ...learningLevel4,
  ...learningLevel5,
];

/// Номера уровней по возрастанию.
List<int> get learningLevels =>
    (learningTopics.map((topic) => topic.level).toSet().toList()..sort());

/// Темы одного уровня.
List<LearningTopic> topicsOfLevel(int level) =>
    [for (final topic in learningTopics) if (topic.level == level) topic];

/// Доля изученного, от 0 до 1.
double learningProgress(Set<String> passedIds) => learningTopics.isEmpty
    ? 0
    : passedIds.where(_isKnownTopic).length / learningTopics.length;

bool _isKnownTopic(String id) =>
    learningTopics.any((topic) => topic.id == id);
