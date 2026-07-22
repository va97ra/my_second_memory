class HolidayOccurrence {
  const HolidayOccurrence({
    required this.id,
    required this.date,
    required this.titleRu,
    required this.titleEn,
    required this.shortRu,
    required this.shortEn,
    required this.descriptionRu,
    required this.descriptionEn,
  });

  final String id;
  final DateTime date;
  final String titleRu;
  final String titleEn;
  final String shortRu;
  final String shortEn;
  final String descriptionRu;
  final String descriptionEn;

  String title(String locale) => locale == 'ru' ? titleRu : titleEn;
  String shortDescription(String locale) => locale == 'ru' ? shortRu : shortEn;
  String description(String locale) =>
      locale == 'ru' ? descriptionRu : descriptionEn;
}
