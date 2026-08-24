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
    this.category = HolidayCategory.general,
  });

  final String id;
  final DateTime date;
  final String titleRu;
  final String titleEn;
  final String shortRu;
  final String shortEn;
  final String descriptionRu;
  final String descriptionEn;
  final HolidayCategory category;

  String title(String locale) => locale == 'ru' ? titleRu : titleEn;
  String shortDescription(String locale) => locale == 'ru' ? shortRu : shortEn;
  String description(String locale) =>
      locale == 'ru' ? descriptionRu : descriptionEn;
}

enum HolidayCategory {
  general,
  stateAndMemorial,
  military,
  professional,
  orthodox,
  folk;

  String label(String locale) {
    final isRu = locale == 'ru';
    return switch (this) {
      HolidayCategory.general => isRu ? 'Праздник' : 'Holiday',
      HolidayCategory.stateAndMemorial =>
        isRu ? 'Памятная дата' : 'State and memorial day',
      HolidayCategory.military =>
        isRu ? 'Воинский праздник' : 'Military observance',
      HolidayCategory.professional =>
        isRu ? 'Профессиональный праздник' : 'Professional observance',
      HolidayCategory.orthodox =>
        isRu ? 'Православный праздник' : 'Orthodox feast',
      HolidayCategory.folk => isRu ? 'Народная традиция' : 'Folk tradition',
    };
  }
}
