/// Всё содержимое учебника в одном месте.
///
/// Разделы собираются здесь, а не на экране: экран должен уметь показать
/// список и поиск, но не знать, из скольких файлов этот список сложен.
library;

import 'electrician_card.dart';
import 'electrician_components.dart';
import 'electrician_diagnostics.dart';
import 'electrician_glossary.dart';
import 'electrician_reference.dart';
import 'electrician_learning.dart';
import 'electrician_schematics.dart';
import 'electrician_tools.dart';
import 'electrician_safety.dart';

const electricianCards = <ElectricianCard>[
  ...electricianGlossary,
  ...electricianTools,
  ...electricianComponents,
  ...electricianDiagnostics,
  ...electricianSafety,
  ...electricianSchematics,
  ...electricianReference,
];

/// Карточки одного раздела в порядке их объявления.
List<ElectricianCard> cardsOfSection(ElectricianSection section) =>
    [for (final card in electricianCards) if (card.section == section) card];

/// Сколько карточек уже написано в разделе. Ноль означает, что раздел
/// объявлен, но пуст: экран говорит об этом прямо, а не показывает пустоту.
int sectionCardCount(ElectricianSection section) =>
    section == ElectricianSection.learning
        ? learningTopics.length
        : cardsOfSection(section).length;

/// Поиск по всем разделам сразу.
///
/// Ищет по заголовку, объяснению, назначению, предупреждению и синонимам:
/// человек ищет «утечка» или «30 мА», а не заголовок «УЗО».
List<ElectricianCard> searchElectricianCards(
  String query, {
  required bool ru,
  ElectricianSection? section,
  ElectricianTrade? trade,
  Set<String> onlyIds = const {},
  bool favouritesOnly = false,
}) {
  final needle = query.trim().toLowerCase();
  return [
    for (final card in electricianCards)
      if ((section == null || card.section == section) &&
          (trade == null || card.trade == trade) &&
          (!favouritesOnly || onlyIds.contains(card.id)) &&
          (needle.isEmpty || card.searchText(ru).contains(needle)))
        card,
  ];
}
