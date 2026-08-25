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

  /// Официальный праздник: государственный, воинский, профессиональный,
  /// церковный или народный. Только такому положена лента в сетке месяца —
  /// прочих дней слишком много, и лента, зажжённая почти каждый день,
  /// перестала бы что-либо значить.
  ///
  /// Перечисление разобрано целиком нарочно: новая категория не проскочит
  /// молча, а потребует решения, положена ей лента или нет.
  bool get isOfficial => switch (category) {
        HolidayCategory.general ||
        HolidayCategory.stateAndMemorial ||
        HolidayCategory.military ||
        HolidayCategory.professional ||
        HolidayCategory.orthodox ||
        HolidayCategory.folk =>
          true,
        HolidayCategory.observance || HolidayCategory.russianDay => false,
      };

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
  folk,
  observance,
  russianDay;

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
      HolidayCategory.observance =>
        isRu ? 'Международный день' : 'International observance',
      HolidayCategory.russianDay =>
        isRu ? 'Праздник России' : 'Russian observance',
    };
  }
}
