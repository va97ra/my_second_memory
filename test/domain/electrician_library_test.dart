import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('идентификаторы карточек не повторяются', () {
    final ids = electricianCards.map((card) => card.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('у каждой карточки назван документ', () {
    for (final card in electricianCards) {
      expect(card.source, isNotEmpty, reason: card.id);
      expect(card.purpose, isNotEmpty, reason: card.id);
      expect(card.caution, isNotEmpty, reason: card.id);
    }
  });

  test('словарь закрывает список терминов из задания', () {
    final titles = cardsOfSection(ElectricianSection.glossary)
        .map((card) => card.titleRu)
        .toSet();
    expect(
      titles,
      containsAll([
        'Ампер',
        'Автоматический выключатель',
        'Ватт',
        'Вольт',
        'Герц',
        'Дифавтомат',
        'Заземление',
        'Короткое замыкание',
        'Мощность',
        'Напряжение',
        'Нейтраль',
        'Ом',
        'Переменный ток',
        'Проводник',
        'Сопротивление',
        'Ток',
        'УЗО',
        'Фаза',
        'Частота',
      ]),
    );
  });

  test('статьи справочника сохранили отрасль после переноса', () {
    final reference = cardsOfSection(ElectricianSection.reference);
    expect(reference, hasLength(15));
    for (final card in reference) {
      expect(card.trade, isNotNull, reason: card.id);
    }
    expect(
      reference.where((card) => card.trade == ElectricianTrade.electrical),
      hasLength(8),
    );
  });

  test('порядок действий по безопасности не помечен сверенным', () {
    for (final card in cardsOfSection(ElectricianSection.safety)) {
      expect(card.checkedAgainstSource, isFalse, reason: card.id);
      expect(card.source, contains('903н'));
    }
  });

  test('поиск идёт по синонимам, а не только по заголовку', () {
    List<String> found(String query) => [
          for (final card in searchElectricianCards(query, ru: true)) card.id,
        ];
    expect(found('утечка'), contains('glossary_rcd'));
    expect(found('30 мА'), contains('glossary_rcd'));
    expect(found('зануление'), contains('glossary_earthing'));
    expect(found('квт·ч'), contains('glossary_watt'));
  });

  test('поиск сужается разделом, отраслью и избранным', () {
    expect(
      searchElectricianCards('', ru: true, section: ElectricianSection.safety),
      hasLength(sectionCardCount(ElectricianSection.safety)),
    );
    expect(
      searchElectricianCards(
        '',
        ru: true,
        section: ElectricianSection.reference,
        trade: ElectricianTrade.ventilation,
      ),
      hasLength(2),
    );
    expect(
      searchElectricianCards(
        '',
        ru: true,
        onlyIds: const {'glossary_ohm'},
        favouritesOnly: true,
      ).single.id,
      'glossary_ohm',
    );
  });

  test('пустых разделов не осталось', () {
    for (final section in ElectricianSection.values) {
      expect(sectionCardCount(section), greaterThan(0), reason: section.name);
    }
  });

  test('обучение считается темами, а не карточками', () {
    expect(sectionCardCount(ElectricianSection.learning), learningTopics.length);
    expect(cardsOfSection(ElectricianSection.learning), isEmpty);
  });

  test('у каждого вопроса теста верный ответ существует', () {
    for (final topic in learningTopics) {
      expect(topic.quiz, isNotEmpty, reason: topic.id);
      for (final question in topic.quiz) {
        expect(question.optionsRu, hasLength(question.optionsEn.length));
        expect(question.correctIndex, greaterThanOrEqualTo(0));
        expect(
          question.correctIndex,
          lessThan(question.optionsRu.length),
          reason: topic.id,
        );
        expect(question.explanationRu, isNotEmpty, reason: topic.id);
      }
    }
  });

  test('прогресс считается по числу пройденных тем', () {
    expect(learningProgress(const {}), 0);
    expect(
      learningProgress({learningTopics.first.id}),
      closeTo(1 / learningTopics.length, 1e-12),
    );
    // Чужой идентификатор прогресса не добавляет.
    expect(learningProgress(const {'нет такой темы'}), 0);
  });

  test('у каждого инструмента есть рисунок', () {
    for (final card in cardsOfSection(ElectricianSection.tools)) {
      expect(card.symbol, isNotEmpty, reason: card.id);
    }
  });

  test('обозначения схем названы именем рисунка', () {
    final schematics = cardsOfSection(ElectricianSection.schematics);
    expect(schematics, hasLength(12));
    for (final card in schematics) {
      expect(card.symbol, isNotEmpty, reason: card.id);
    }
  });

  // Прибор описан в словаре, его обозначение — в схемах. Это разные
  // карточки об одном предмете, и совпадение заголовков здесь ожидаемо.
  test('прибор и его условное обозначение — две карточки, не больше', () {
    final titles = [
      for (final card in electricianCards) card.titleRu.toLowerCase(),
    ];
    expect(titles.where((title) => title == 'узо'), hasLength(2));
    expect(
      titles.where((title) => title == 'автоматический выключатель'),
      hasLength(2),
    );
  });
}
