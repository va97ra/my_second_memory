import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'holiday_occurrence.dart';

final holidayCalendarServiceProvider = Provider<HolidayCalendarService>(
  (ref) => const HolidayCalendarService(),
);

class HolidayCalendarService {
  const HolidayCalendarService();

  List<HolidayOccurrence> holidaysForDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return holidaysForRange(normalized, normalized);
  }

  List<HolidayOccurrence> holidaysForRange(DateTime start, DateTime end) {
    final first = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    final result = <HolidayOccurrence>[];
    for (var year = first.year; year <= last.year; year++) {
      for (final holiday in _holidaysForYear(year)) {
        if (!holiday.date.isBefore(first) && !holiday.date.isAfter(last)) {
          result.add(holiday);
        }
      }
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  List<HolidayOccurrence> _holidaysForYear(int year) {
    final easter = _orthodoxEaster(year);
    return [
      ..._fixed.map((definition) => definition.occurrence(year)),
      _movable(
        id: 'maslenitsa',
        date: easter.subtract(const Duration(days: 49)),
        titleRu: 'Масленица',
        titleEn: 'Maslenitsa',
        shortRu: 'Начало масленичной недели.',
        shortEn: 'The beginning of Maslenitsa week.',
        descriptionRu:
            'Начинается масленичная неделя — время проводов зимы и подготовки к Великому посту.',
        descriptionEn:
            'Maslenitsa week begins, marking the farewell to winter before Great Lent.',
      ),
      _movable(
        id: 'orthodox_easter',
        date: easter,
        titleRu: 'Православная Пасха',
        titleEn: 'Orthodox Easter',
        shortRu: 'Светлое Христово Воскресение.',
        shortEn: 'The Resurrection of Christ.',
        descriptionRu:
            'Главный православный праздник — Светлое Христово Воскресение.',
        descriptionEn:
            'The principal Orthodox Christian feast celebrating the Resurrection of Christ.',
      ),
      _movable(
        id: 'trinity',
        date: easter.add(const Duration(days: 49)),
        titleRu: 'День Святой Троицы',
        titleEn: 'Trinity Sunday',
        shortRu: 'Православный праздник Святой Троицы.',
        shortEn: 'The Orthodox feast of the Holy Trinity.',
        descriptionRu:
            'Православный праздник в честь сошествия Святого Духа на апостолов.',
        descriptionEn:
            'An Orthodox feast commemorating the descent of the Holy Spirit upon the Apostles.',
      ),
      _movable(
        id: 'fathers_day',
        date: _nthWeekday(year, DateTime.october, DateTime.sunday, 3),
        titleRu: 'День отца',
        titleEn: "Father's Day",
        shortRu: 'Праздник отцов и семейных традиций.',
        shortEn: 'A celebration of fathers and family.',
        descriptionRu:
            'В России День отца отмечается в третье воскресенье октября.',
        descriptionEn:
            "Russia celebrates Father's Day on the third Sunday of October.",
      ),
      _movable(
        id: 'mothers_day',
        date: _lastWeekday(year, DateTime.november, DateTime.sunday),
        titleRu: 'День матери',
        titleEn: "Mother's Day",
        shortRu: 'Праздник мам и семейной заботы.',
        shortEn: 'A celebration of mothers and family care.',
        descriptionRu:
            'В России День матери отмечается в последнее воскресенье ноября.',
        descriptionEn:
            "Russia celebrates Mother's Day on the last Sunday of November.",
      ),
    ];
  }

  HolidayOccurrence _movable({
    required String id,
    required DateTime date,
    required String titleRu,
    required String titleEn,
    required String shortRu,
    required String shortEn,
    required String descriptionRu,
    required String descriptionEn,
  }) {
    return HolidayOccurrence(
      id: id,
      date: date,
      titleRu: titleRu,
      titleEn: titleEn,
      shortRu: shortRu,
      shortEn: shortEn,
      descriptionRu: descriptionRu,
      descriptionEn: descriptionEn,
    );
  }
}

class _FixedHoliday {
  const _FixedHoliday(
    this.id,
    this.month,
    this.day,
    this.titleRu,
    this.titleEn,
    this.shortRu,
    this.shortEn,
    this.descriptionRu,
    this.descriptionEn,
  );

  final String id;
  final int month;
  final int day;
  final String titleRu;
  final String titleEn;
  final String shortRu;
  final String shortEn;
  final String descriptionRu;
  final String descriptionEn;

  HolidayOccurrence occurrence(int year) => HolidayOccurrence(
        id: id,
        date: DateTime(year, month, day),
        titleRu: titleRu,
        titleEn: titleEn,
        shortRu: shortRu,
        shortEn: shortEn,
        descriptionRu: descriptionRu,
        descriptionEn: descriptionEn,
      );
}

const _fixed = <_FixedHoliday>[
  _FixedHoliday(
      'new_year',
      1,
      1,
      'Новый год',
      'New Year',
      'Первый день нового года.',
      'The first day of the new year.',
      'Государственный праздник и начало новогодних каникул.',
      'A public holiday and the start of the New Year holidays.'),
  _FixedHoliday(
      'new_year_holiday_2',
      1,
      2,
      'Новогодние каникулы',
      'New Year holidays',
      'Новогодний праздничный день.',
      'A New Year public holiday.',
      'Официальный день новогодних каникул.',
      'An official day of the New Year holidays.'),
  _FixedHoliday(
      'new_year_holiday_3',
      1,
      3,
      'Новогодние каникулы',
      'New Year holidays',
      'Новогодний праздничный день.',
      'A New Year public holiday.',
      'Официальный день новогодних каникул.',
      'An official day of the New Year holidays.'),
  _FixedHoliday(
      'new_year_holiday_4',
      1,
      4,
      'Новогодние каникулы',
      'New Year holidays',
      'Новогодний праздничный день.',
      'A New Year public holiday.',
      'Официальный день новогодних каникул.',
      'An official day of the New Year holidays.'),
  _FixedHoliday(
      'new_year_holiday_5',
      1,
      5,
      'Новогодние каникулы',
      'New Year holidays',
      'Новогодний праздничный день.',
      'A New Year public holiday.',
      'Официальный день новогодних каникул.',
      'An official day of the New Year holidays.'),
  _FixedHoliday(
      'new_year_holiday_6',
      1,
      6,
      'Новогодние каникулы',
      'New Year holidays',
      'Новогодний праздничный день.',
      'A New Year public holiday.',
      'Официальный день новогодних каникул.',
      'An official day of the New Year holidays.'),
  _FixedHoliday(
      'orthodox_christmas',
      1,
      7,
      'Рождество Христово',
      'Orthodox Christmas',
      'Православное Рождество.',
      'Orthodox Christmas Day.',
      'Православный праздник Рождества Иисуса Христа.',
      'The Orthodox celebration of the birth of Jesus Christ.'),
  _FixedHoliday(
      'new_year_holiday_8',
      1,
      8,
      'Новогодние каникулы',
      'New Year holidays',
      'Новогодний праздничный день.',
      'A New Year public holiday.',
      'Официальный день новогодних каникул.',
      'An official day of the New Year holidays.'),
  _FixedHoliday(
      'students_day',
      1,
      25,
      'Татьянин день',
      "Students' Day",
      'День российского студенчества.',
      'Russian Students’ Day.',
      'Праздник российского студенчества и именины Татьян.',
      'A celebration of Russian students and Saint Tatiana.'),
  _FixedHoliday(
      'valentines_day',
      2,
      14,
      'День всех влюблённых',
      "Valentine's Day",
      'Популярный праздник влюблённых.',
      'A popular celebration of love.',
      'День, когда близким людям дарят знаки внимания.',
      'A day for sharing affection with loved ones.'),
  _FixedHoliday(
      'defender_day',
      2,
      23,
      'День защитника Отечества',
      'Defender of the Fatherland Day',
      'Государственный праздник.',
      'A national public holiday.',
      'Праздник военнослужащих, ветеранов и защитников страны.',
      'A public holiday honoring service members, veterans, and defenders.'),
  _FixedHoliday(
      'womens_day',
      3,
      8,
      'Международный женский день',
      "International Women's Day",
      'Государственный праздник.',
      'A national public holiday.',
      'Праздник женщин, весны и уважения.',
      'A celebration of women, spring, and appreciation.'),
  _FixedHoliday(
      'april_fools',
      4,
      1,
      'День смеха',
      "April Fools' Day",
      'День добрых шуток.',
      'A day for friendly jokes.',
      'Популярный неофициальный день юмора и добрых розыгрышей.',
      'An informal day of humor and friendly pranks.'),
  _FixedHoliday(
      'cosmonautics_day',
      4,
      12,
      'День космонавтики',
      'Cosmonautics Day',
      'Годовщина первого полёта человека в космос.',
      'The anniversary of the first human spaceflight.',
      'Праздник в честь полёта Юрия Гагарина 12 апреля 1961 года.',
      'Celebrates Yuri Gagarin’s first human spaceflight on 12 April 1961.'),
  _FixedHoliday(
      'spring_labour_day',
      5,
      1,
      'Праздник Весны и Труда',
      'Spring and Labour Day',
      'Государственный праздник.',
      'A national public holiday.',
      'Праздник весны, мира и труда.',
      'A public celebration of spring, peace, and labour.'),
  _FixedHoliday(
      'victory_day',
      5,
      9,
      'День Победы',
      'Victory Day',
      'День Победы в Великой Отечественной войне.',
      'Victory in the Great Patriotic War.',
      'День памяти и празднования Победы 1945 года.',
      'A day of remembrance and celebration of the 1945 Victory.'),
  _FixedHoliday(
      'childrens_day',
      6,
      1,
      'День защиты детей',
      "Children's Day",
      'Международный день защиты детей.',
      "International Children's Day.",
      'Праздник, напоминающий о правах и благополучии детей.',
      'A day highlighting children’s rights and well-being.'),
  _FixedHoliday(
      'russia_day',
      6,
      12,
      'День России',
      'Russia Day',
      'Государственный праздник.',
      'A national public holiday.',
      'Праздник страны, гражданского мира и единства.',
      'A celebration of the country, civic peace, and unity.'),
  _FixedHoliday(
      'family_day',
      7,
      8,
      'День семьи, любви и верности',
      'Day of Family, Love and Fidelity',
      'Российский семейный праздник.',
      'A Russian family celebration.',
      'Праздник семьи, супружеской верности и заботы о близких.',
      'A celebration of family, marital fidelity, and care for loved ones.'),
  _FixedHoliday(
      'knowledge_day',
      9,
      1,
      'День знаний',
      'Knowledge Day',
      'Начало учебного года.',
      'The start of the school year.',
      'Традиционный первый день нового учебного года.',
      'The traditional first day of the new school year.'),
  _FixedHoliday(
      'teachers_day',
      10,
      5,
      'День учителя',
      "Teachers' Day",
      'Профессиональный праздник учителей.',
      'A professional holiday for teachers.',
      'День благодарности педагогам и наставникам.',
      'A day of appreciation for teachers and mentors.'),
  _FixedHoliday(
      'unity_day',
      11,
      4,
      'День народного единства',
      'National Unity Day',
      'Государственный праздник.',
      'A national public holiday.',
      'Праздник гражданской солидарности и единства народа России.',
      'A public holiday celebrating civic solidarity and national unity.'),
  _FixedHoliday(
      'new_year_eve',
      12,
      31,
      'Канун Нового года',
      "New Year's Eve",
      'Последний день года.',
      'The final day of the year.',
      'День подготовки к встрече Нового года.',
      'A day for preparing to welcome the new year.'),
];

DateTime _nthWeekday(int year, int month, int weekday, int occurrence) {
  final first = DateTime(year, month);
  final offset = (weekday - first.weekday + 7) % 7;
  return DateTime(year, month, 1 + offset + (occurrence - 1) * 7);
}

DateTime _lastWeekday(int year, int month, int weekday) {
  final last = DateTime(year, month + 1, 0);
  return last.subtract(Duration(days: (last.weekday - weekday + 7) % 7));
}

DateTime _orthodoxEaster(int year) {
  final a = year % 4;
  final b = year % 7;
  final c = year % 19;
  final d = (19 * c + 15) % 30;
  final e = (2 * a + 4 * b - d + 34) % 7;
  final month = (d + e + 114) ~/ 31;
  final day = (d + e + 114) % 31 + 1;
  return DateTime(year, month, day).add(const Duration(days: 13));
}
