import 'holiday_occurrence.dart';

/// Праздник на постоянной дате.
class FixedHoliday {
  const FixedHoliday(
    this.id,
    this.month,
    this.day,
    this.titleRu,
    this.titleEn,
    this.shortRu,
    this.shortEn,
    this.descriptionRu,
    this.descriptionEn,
  ) : category = HolidayCategory.general;

  const FixedHoliday.professional(
    this.id,
    this.month,
    this.day,
    this.titleRu,
    this.titleEn,
    this.descriptionRu,
    this.descriptionEn,
  )   : shortRu = 'Профессиональный праздник.',
        shortEn = 'A professional observance.',
        category = HolidayCategory.professional;

  const FixedHoliday.military(
    this.id,
    this.month,
    this.day,
    this.titleRu,
    this.titleEn,
    this.descriptionRu,
    this.descriptionEn,
  )   : shortRu = 'Памятный день воинской службы.',
        shortEn = 'A military service observance.',
        category = HolidayCategory.military;

  const FixedHoliday.orthodox(
    this.id,
    this.month,
    this.day,
    this.titleRu,
    this.titleEn,
    this.descriptionRu,
    this.descriptionEn,
  )   : shortRu = 'Православный церковный праздник.',
        shortEn = 'An Orthodox Christian feast.',
        category = HolidayCategory.orthodox;

  const FixedHoliday.folk(
    this.id,
    this.month,
    this.day,
    this.titleRu,
    this.titleEn,
    this.descriptionRu,
    this.descriptionEn,
  )   : shortRu = 'Народный календарный праздник.',
        shortEn = 'A folk-calendar tradition.',
        category = HolidayCategory.folk;

  const FixedHoliday.observance(
    this.id,
    this.month,
    this.day,
    this.titleRu,
    this.titleEn,
    this.descriptionRu,
    this.descriptionEn,
  )   : shortRu = 'Международный день.',
        shortEn = 'An international observance.',
        category = HolidayCategory.observance;

  const FixedHoliday.memorial(
    this.id,
    this.month,
    this.day,
    this.titleRu,
    this.titleEn,
    this.descriptionRu,
    this.descriptionEn,
  )   : shortRu = 'Памятная дата России.',
        shortEn = 'A Russian memorial date.',
        category = HolidayCategory.stateAndMemorial;

  final String id;
  final int month;
  final int day;
  final String titleRu;
  final String titleEn;
  final String shortRu;
  final String shortEn;
  final String descriptionRu;
  final String descriptionEn;
  final HolidayCategory category;

  HolidayOccurrence occurrence(int year) => HolidayOccurrence(
        id: id,
        date: DateTime(year, month, day),
        titleRu: titleRu,
        titleEn: titleEn,
        shortRu: shortRu,
        shortEn: shortEn,
        descriptionRu: descriptionRu,
        descriptionEn: descriptionEn,
        category: category,
      );
}
