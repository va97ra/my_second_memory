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
        date: easter.subtract(const Duration(days: 55)),
        titleRu: 'Масленица',
        titleEn: 'Maslenitsa',
        shortRu: 'Начало масленичной недели.',
        shortEn: 'The beginning of Maslenitsa week.',
        descriptionRu:
            'Начинается масленичная неделя — время проводов зимы и подготовки к Великому посту.',
        descriptionEn:
            'Maslenitsa week begins, marking the farewell to winter before Great Lent.',
        category: HolidayCategory.folk,
      ),
      _movable(
        id: 'forgiveness_sunday',
        date: easter.subtract(const Duration(days: 49)),
        titleRu: 'Прощёное воскресенье',
        titleEn: 'Forgiveness Sunday',
        shortRu: 'Последний день Масленицы перед Великим постом.',
        shortEn: 'The final day of Maslenitsa before Great Lent.',
        descriptionRu:
            'Последнее воскресенье перед Великим постом завершает масленичную неделю. По православной традиции в этот день люди просят друг у друга прощения, чтобы вступить в пост без обид и с примирённым сердцем.',
        descriptionEn:
            'The final Sunday before Great Lent closes Maslenitsa week. Orthodox tradition calls people to ask one another for forgiveness before entering the fast.',
        category: HolidayCategory.orthodox,
      ),
      _movable(
        id: 'palm_sunday',
        date: easter.subtract(const Duration(days: 7)),
        titleRu: 'Вербное воскресенье',
        titleEn: 'Palm Sunday',
        shortRu: 'Вход Господень в Иерусалим.',
        shortEn: "The Lord's Entry into Jerusalem.",
        descriptionRu:
            'Праздник отмечается в последнее воскресенье перед Пасхой и напоминает о торжественном входе Иисуса Христа в Иерусалим. В русской традиции пальмовые ветви заменили веточками вербы, которая одной из первых распускается весной.',
        descriptionEn:
            "Observed on the Sunday before Easter, the feast recalls Christ's entry into Jerusalem. Russian custom uses pussy-willow branches in place of palms.",
        category: HolidayCategory.orthodox,
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
        category: HolidayCategory.orthodox,
      ),
      _movable(
        id: 'radonitsa',
        date: easter.add(const Duration(days: 9)),
        titleRu: 'Радоница',
        titleEn: 'Radonitsa',
        shortRu: 'День пасхального поминовения усопших.',
        shortEn: 'The Paschal day of remembrance of the departed.',
        descriptionRu:
            'Радоница приходится на второй вторник после Пасхи. Традиция соединяет пасхальную радость с поминовением умерших: верующие посещают храмы и кладбища, вспоминая близких.',
        descriptionEn:
            'Radonitsa falls on the second Tuesday after Easter and joins Paschal joy with remembrance of departed relatives.',
        category: HolidayCategory.orthodox,
      ),
      _movable(
        id: 'ascension',
        date: easter.add(const Duration(days: 39)),
        titleRu: 'Вознесение Господне',
        titleEn: 'Ascension of the Lord',
        shortRu: 'Сороковой день после Пасхи.',
        shortEn: 'The fortieth day after Easter.',
        descriptionRu:
            'Вознесение празднуют на сороковой день после Пасхи, всегда в четверг. Праздник посвящён евангельскому событию Вознесения Иисуса Христа и относится к двунадесятым праздникам Православной церкви.',
        descriptionEn:
            "Celebrated on the fortieth day after Easter, the feast commemorates Christ's Ascension and is one of the Twelve Great Feasts.",
        category: HolidayCategory.orthodox,
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
        category: HolidayCategory.orthodox,
      ),
      _professionalMovable(
        id: 'housing_utilities_day',
        date: _nthWeekday(year, DateTime.march, DateTime.sunday, 3),
        titleRu: 'День работников ЖКХ',
        titleEn: 'Housing and Utilities Workers Day',
        descriptionRu:
            'Профессиональный день работников бытового обслуживания и жилищно-коммунального хозяйства отмечается в третье воскресенье марта. Дата закрепилась в советском календаре в 1980 году и объединяет специалистов, обеспечивающих работу домов и городской инфраструктуры.',
        descriptionEn:
            'Observed on the third Sunday of March, the day honors workers who maintain homes and municipal infrastructure.',
      ),
      _professionalMovable(
        id: 'geologists_day',
        date: _nthWeekday(year, DateTime.april, DateTime.sunday, 1),
        titleRu: 'День геолога',
        titleEn: "Geologists' Day",
        descriptionRu:
            'Праздник учреждён в СССР в 1966 году после крупных геологических открытий и отмечается в первое воскресенье апреля — перед началом летнего полевого сезона.',
        descriptionEn:
            'Established in 1966 after major geological discoveries, it is observed before the summer field season.',
      ),
      _professionalMovable(
        id: 'medical_workers_day',
        date: _nthWeekday(year, DateTime.june, DateTime.sunday, 3),
        titleRu: 'День медицинского работника',
        titleEn: 'Medical Workers Day',
        descriptionRu:
            'Профессиональный праздник врачей, фельдшеров, медсестёр и других работников здравоохранения отмечается в третье воскресенье июня. Современная дата закреплена указом Президиума Верховного Совета СССР 1980 года.',
        descriptionEn:
            'Observed on the third Sunday of June, the day honors physicians, nurses, paramedics, and other healthcare workers.',
      ),
      _professionalMovable(
        id: 'youth_day',
        date: _lastWeekday(year, DateTime.june, DateTime.saturday),
        titleRu: 'День молодёжи',
        titleEn: 'Youth Day',
        descriptionRu:
            'Российский День молодёжи ведёт историю от советского праздника 1958 года. С 2023 года его отмечают в последнюю субботу июня, чтобы молодёжные мероприятия было удобнее проводить в выходной.',
        descriptionEn:
            'Originating in a Soviet observance established in 1958, Russian Youth Day has been held on the last Saturday of June since 2023.',
      ),
      _professionalMovable(
        id: 'fishermens_day',
        date: _nthWeekday(year, DateTime.july, DateTime.sunday, 2),
        titleRu: 'День рыбака',
        titleEn: "Fishermen's Day",
        descriptionRu:
            'Профессиональный праздник работников рыбного хозяйства учреждён в СССР в 1965 году. Его отмечают во второе воскресенье июля, и со временем он стал также народным праздником любителей рыбалки.',
        descriptionEn:
            'Established in 1965 for fishing-industry workers, the day also became popular among recreational anglers.',
      ),
      _professionalMovable(
        id: 'navy_day',
        date: _lastWeekday(year, DateTime.july, DateTime.sunday),
        titleRu: 'День Военно-Морского Флота',
        titleEn: 'Russian Navy Day',
        descriptionRu:
            'Праздник военных моряков появился в СССР в 1939 году по инициативе адмирала Николая Кузнецова. Сейчас День ВМФ отмечают в последнее воскресенье июля военно-морскими парадами и памятными церемониями.',
        descriptionEn:
            'Created in 1939 at Admiral Nikolai Kuznetsov’s initiative, Navy Day is marked on the final Sunday of July.',
        category: HolidayCategory.military,
      ),
      _professionalMovable(
        id: 'railway_workers_day',
        date: _nthWeekday(year, DateTime.august, DateTime.sunday, 1),
        titleRu: 'День железнодорожника',
        titleEn: "Railway Workers' Day",
        descriptionRu:
            'Один из старейших профессиональных праздников России впервые появился в 1896 году. После восстановления традиции в СССР его стали отмечать в первое воскресенье августа.',
        descriptionEn:
            'First introduced in 1896, one of Russia’s oldest professional observances is now held on the first Sunday of August.',
      ),
      _professionalMovable(
        id: 'builders_day',
        date: _nthWeekday(year, DateTime.august, DateTime.sunday, 2),
        titleRu: 'День строителя',
        titleEn: "Builders' Day",
        descriptionRu:
            'День строителя учреждён в СССР в 1955 году, а впервые отмечался 12 августа 1956 года. Праздник приходится на второе воскресенье августа и объединяет строителей, проектировщиков и работников отрасли.',
        descriptionEn:
            'Established in 1955 and first celebrated in 1956, the holiday falls on the second Sunday of August.',
      ),
      _professionalMovable(
        id: 'miners_day',
        date: _lastWeekday(year, DateTime.august, DateTime.sunday),
        titleRu: 'День шахтёра',
        titleEn: "Miners' Day",
        descriptionRu:
            'Праздник учреждён в 1947 году в память о трудовом достижении шахтёра Алексея Стаханова. Его отмечают в последнее воскресенье августа в шахтёрских городах России.',
        descriptionEn:
            'Established in 1947 in memory of miner Alexey Stakhanov’s labor achievement, it is observed on the final Sunday of August.',
      ),
      _professionalMovable(
        id: 'tankers_day',
        date: _nthWeekday(year, DateTime.september, DateTime.sunday, 2),
        titleRu: 'День танкиста',
        titleEn: 'Tank Forces Day',
        descriptionRu:
            'День танкиста учреждён в 1946 году в честь заслуг бронетанковых войск и танкостроителей в Великой Отечественной войне. Сейчас его отмечают во второе воскресенье сентября.',
        descriptionEn:
            'Created in 1946 to honor armored forces and tank builders, the day falls on the second Sunday of September.',
        category: HolidayCategory.military,
      ),
      _professionalMovable(
        id: 'programmers_day',
        date: DateTime(year, DateTime.january, 1).add(
          const Duration(days: 255),
        ),
        titleRu: 'День программиста',
        titleEn: "Programmers' Day",
        descriptionRu:
            'Праздник отмечается в 256-й день года: обычно 13 сентября, а в високосный год — 12 сентября. Число 256 выбрано потому, что это количество значений, представимых одним байтом; официальный статус в России дата получила в 2009 году.',
        descriptionEn:
            'Observed on the 256th day of the year, the date refers to the number of values representable by one byte and became official in Russia in 2009.',
      ),
      _professionalMovable(
        id: 'drivers_day',
        date: _lastWeekday(year, DateTime.october, DateTime.sunday),
        titleRu: 'День автомобилиста',
        titleEn: "Motor Transport Workers' Day",
        descriptionRu:
            'Профессиональный праздник водителей и работников автотранспорта появился в СССР в 1976 году. Его отмечают в последнее воскресенье октября.',
        descriptionEn:
            'Established in 1976, the professional day for drivers and motor-transport workers falls on the final Sunday of October.',
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
    HolidayCategory category = HolidayCategory.general,
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
      category: category,
    );
  }

  HolidayOccurrence _professionalMovable({
    required String id,
    required DateTime date,
    required String titleRu,
    required String titleEn,
    required String descriptionRu,
    required String descriptionEn,
    HolidayCategory category = HolidayCategory.professional,
  }) {
    return _movable(
      id: id,
      date: date,
      titleRu: titleRu,
      titleEn: titleEn,
      shortRu: category == HolidayCategory.military
          ? 'Памятный день воинской службы.'
          : 'Профессиональный праздник.',
      shortEn: category == HolidayCategory.military
          ? 'A military service observance.'
          : 'A professional observance.',
      descriptionRu: descriptionRu,
      descriptionEn: descriptionEn,
      category: category,
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
  ) : category = HolidayCategory.general;

  const _FixedHoliday.professional(
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

  const _FixedHoliday.military(
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

  const _FixedHoliday.orthodox(
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

  const _FixedHoliday.folk(
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

  const _FixedHoliday.memorial(
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
  _FixedHoliday.folk(
    'old_new_year',
    1,
    14,
    'Старый Новый год',
    'Old New Year',
    'Традиция появилась после перехода России с юлианского на григорианский календарь в 1918 году. Разница между календарями оставила в народной культуре ещё одну новогоднюю ночь — с 13 на 14 января.',
    'The tradition arose after Russia adopted the Gregorian calendar in 1918, leaving a second New Year night on 13–14 January.',
  ),
  _FixedHoliday.orthodox(
    'epiphany',
    1,
    19,
    'Крещение Господне',
    'Theophany',
    'Один из двунадесятых праздников посвящён Крещению Иисуса Христа в реке Иордан. В русской традиции с праздником связаны великое освящение воды и крещенские купания.',
    "One of the Twelve Great Feasts commemorates Christ's baptism in the Jordan and is associated with the blessing of water.",
  ),
  _FixedHoliday.professional(
    'russian_science_day',
    2,
    8,
    'День российской науки',
    'Russian Science Day',
    'Дата связана с учреждением Петром I Академии наук в 1724 году. Современный праздник установлен в 1999 году к 275-летию Российской академии наук.',
    'The date recalls Peter the Great’s establishment of the Academy of Sciences in 1724; the modern observance was introduced in 1999.',
  ),
  _FixedHoliday.professional(
    'diplomats_day',
    2,
    10,
    'День дипломатического работника',
    'Diplomatic Service Day',
    'Праздник установлен в 2002 году. Дата связана с самым ранним упоминанием Посольского приказа в 1549 году — первого постоянного внешнеполитического ведомства Российского государства.',
    'Established in 2002, the date recalls the earliest 1549 reference to the Posolsky Prikaz, Russia’s first permanent foreign-affairs office.',
  ),
  _FixedHoliday.orthodox(
    'presentation_of_jesus',
    2,
    15,
    'Сретение Господне',
    'Presentation of Jesus',
    'Двунадесятый праздник вспоминает встречу младенца Иисуса с праведным Симеоном в Иерусалимском храме. Слово «сретение» в церковнославянском языке означает «встреча».',
    'The feast recalls the infant Jesus meeting Simeon in the Temple; the Slavic name literally means “meeting.”',
  ),
  _FixedHoliday.military(
    'special_operations_forces_day',
    2,
    27,
    'День Сил специальных операций',
    'Special Operations Forces Day',
    'Памятный день российских Сил специальных операций учреждён указом Президента в 2015 году. Он посвящён военнослужащим подразделений, выполняющих особо сложные задачи.',
    'The Russian military observance was established by presidential decree in 2015 to honor special-operations personnel.',
  ),
  _FixedHoliday.professional(
    'world_plumbing_day',
    3,
    11,
    'Всемирный день сантехника',
    'World Plumbing Day',
    'Всемирный совет по сантехнике учредил эту дату в 2010 году. Праздник напоминает о роли сантехников, водоснабжения и канализации в здоровье людей, безопасности городов и сохранении чистой воды.',
    'Created by the World Plumbing Council in 2010, the day highlights plumbing’s role in public health, safe water, and sanitation.',
  ),
  _FixedHoliday.military(
    'submariners_day',
    3,
    19,
    'День моряка-подводника',
    'Submariners Day',
    '19 марта 1906 года подводные лодки были выделены в самостоятельный класс кораблей Российского флота. Профессиональный день восстановлен приказом главнокомандующего ВМФ в 1996 году.',
    'On 19 March 1906 submarines became a distinct class of the Russian fleet; the observance was restored in 1996.',
  ),
  _FixedHoliday.professional(
    'culture_workers_day',
    3,
    25,
    'День работника культуры',
    'Culture Workers Day',
    'Единый профессиональный день работников музеев, библиотек, театров, домов культуры и других учреждений установлен указом Президента в 2007 году.',
    'The unified professional day for museum, library, theater, and cultural-center workers was established in 2007.',
  ),
  _FixedHoliday.military(
    'national_guard_day',
    3,
    27,
    'День войск национальной гвардии',
    'National Guard Troops Day',
    'Дата восходит к созданию в 1811 году внутренней стражи Российской империи. Современное название праздник получил после образования Росгвардии в 2016 году.',
    'The date traces its history to the Imperial Russian Internal Guard created in 1811 and received its current name in 2016.',
  ),
  _FixedHoliday.orthodox(
    'annunciation',
    4,
    7,
    'Благовещение Пресвятой Богородицы',
    'Annunciation',
    'Праздник посвящён евангельской вести архангела Гавриила Деве Марии о будущем рождении Иисуса Христа. Он относится к двунадесятым и неизменно отмечается 7 апреля по гражданскому календарю.',
    'The feast commemorates Gabriel’s announcement to Mary that she would give birth to Jesus Christ.',
  ),
  _FixedHoliday.professional(
    'fire_service_day',
    4,
    30,
    'День пожарной охраны',
    'Fire Service Day',
    '30 апреля 1649 года царь Алексей Михайлович издал «Наказ о градском благочинии», заложивший основы постоянной противопожарной службы в России. Профессиональный праздник установлен в 1999 году.',
    'The date recalls a 1649 decree by Tsar Alexei Mikhailovich that laid the foundations of Russia’s permanent fire service.',
  ),
  _FixedHoliday.professional(
    'radio_day',
    5,
    7,
    'День радио',
    'Radio Day',
    '7 мая 1895 года Александр Попов продемонстрировал в Петербурге прибор для регистрации электромагнитных волн. С 1945 года дата стала праздником работников связи, радио и электронной техники.',
    'The date marks Alexander Popov’s 1895 demonstration of a radio-wave receiver and has honored communications workers since 1945.',
  ),
  _FixedHoliday.professional(
    'nurses_day',
    5,
    12,
    'Международный день медицинской сестры',
    'International Nurses Day',
    'Праздник отмечают в день рождения Флоренс Найтингейл, реформатора сестринского дела XIX века. Международный совет медсестёр закрепил современную традицию в 1970-х годах.',
    'Observed on Florence Nightingale’s birthday, the day recognizes the nursing profession and its modern foundations.',
  ),
  _FixedHoliday.memorial(
    'slavic_writing_day',
    5,
    24,
    'День славянской письменности и культуры',
    'Day of Slavic Writing and Culture',
    'Дата посвящена равноапостольным Кириллу и Мефодию, создателям славянской письменной традиции IX века. В России государственное празднование было восстановлено в 1991 году.',
    'The date honors Saints Cyril and Methodius, whose ninth-century mission shaped the Slavic written tradition.',
  ),
  _FixedHoliday.military(
    'border_guards_day',
    5,
    28,
    'День пограничника',
    'Border Guards Day',
    '28 мая 1918 года была учреждена пограничная охрана РСФСР. Праздник сохраняет память о разных поколениях военнослужащих, охранявших государственную границу.',
    'The date recalls the establishment of the RSFSR border guard on 28 May 1918.',
  ),
  _FixedHoliday.memorial(
    'russian_language_day',
    6,
    6,
    'День русского языка',
    'Russian Language Day',
    'Праздник приходится на день рождения Александра Пушкина — 6 июня 1799 года. В России он официально установлен в 2011 году и посвящён русскому языку и литературному наследию.',
    'Observed on Alexander Pushkin’s birthday, the official day was established in 2011 to celebrate the Russian language.',
  ),
  _FixedHoliday.professional(
    'social_workers_day',
    6,
    8,
    'День социального работника',
    'Social Workers Day',
    'Дата связана с указом Петра I от 8 июня 1701 года о богадельнях для нуждающихся. Современный профессиональный праздник установлен в 2000 году.',
    'The date recalls Peter the Great’s 1701 decree on care institutions; the modern professional day was established in 2000.',
  ),
  _FixedHoliday.memorial(
    'remembrance_and_sorrow_day',
    6,
    22,
    'День памяти и скорби',
    'Day of Remembrance and Sorrow',
    '22 июня 1941 года началась Великая Отечественная война. Памятная дата установлена в 1996 году в честь погибших и всех, кто пережил войну.',
    'The date marks the beginning of the Great Patriotic War on 22 June 1941 and honors its victims and survivors.',
  ),
  _FixedHoliday.professional(
    'traffic_police_day',
    7,
    3,
    'День ГАИ',
    'Traffic Police Day',
    '3 июля 1936 года была создана Государственная автомобильная инспекция СССР. Профессиональный день сотрудников дорожной полиции официально закреплён МВД России.',
    'The date marks the creation of the Soviet State Automobile Inspectorate on 3 July 1936.',
  ),
  _FixedHoliday.folk(
    'ivan_kupala',
    7,
    7,
    'Иван Купала',
    'Ivan Kupala Day',
    'Народный праздник соединил древние обряды летнего солнцеворота и церковный день Рождества Иоанна Крестителя. С ним связаны костры, вода, травы и легенда о цветке папоротника.',
    'The folk celebration blends midsummer rites with the feast of the Nativity of John the Baptist.',
  ),
  _FixedHoliday.memorial(
    'baptism_of_rus',
    7,
    28,
    'День Крещения Руси',
    'Baptism of Rus Day',
    'Памятная дата связана с князем Владимиром и принятием христианства Древней Русью в 988 году. В российский календарь памятных дат она внесена в 2010 году.',
    'The memorial day recalls Prince Vladimir and the Christianization of Kievan Rus in 988.',
  ),
  _FixedHoliday.military(
    'airborne_forces_day',
    8,
    2,
    'День ВДВ',
    'Airborne Forces Day',
    '2 августа 1930 года на учениях под Воронежем впервые высадили парашютный десант из двенадцати человек. Этот эпизод принято считать началом отечественных воздушно-десантных войск.',
    'On 2 August 1930 a twelve-man parachute unit landed during exercises near Voronezh, an event regarded as the beginning of Soviet airborne forces.',
  ),
  _FixedHoliday.military(
    'air_force_day',
    8,
    12,
    'День Военно-воздушных сил',
    'Air Force Day',
    '12 августа 1912 года был подписан приказ о создании воздухоплавательной части Главного управления Генерального штаба. Эта дата считается отправной точкой российской военной авиации.',
    'The date recalls a 1912 order that created an aeronautical branch of the Russian General Staff.',
  ),
  _FixedHoliday.folk(
    'honey_spas',
    8,
    14,
    'Медовый Спас',
    'Honey Spas',
    'Первый из трёх августовских Спасов совпадает с началом Успенского поста. Народная традиция связывает его с окончанием сбора мёда и освящением мёда нового урожая.',
    'The first August “Spas” coincides with the Dormition Fast and is traditionally associated with the new honey harvest.',
  ),
  _FixedHoliday.orthodox(
    'transfiguration_apple_spas',
    8,
    19,
    'Преображение Господне · Яблочный Спас',
    'Transfiguration · Apple Spas',
    'Двунадесятый праздник посвящён Преображению Иисуса Христа на горе Фавор. В русской народной традиции к этому дню созревали яблоки нового урожая, которые приносили в храм для освящения.',
    'The Orthodox feast of the Transfiguration became associated in Russian folk tradition with blessing the new apple harvest.',
  ),
  _FixedHoliday.memorial(
    'russian_flag_day',
    8,
    22,
    'День Государственного флага России',
    'Russian National Flag Day',
    '22 августа 1991 года российский триколор был восстановлен как национальный флаг. Праздник официально установлен указом Президента в 1994 году.',
    'The date recalls the restoration of the Russian tricolor in 1991; the official observance was established in 1994.',
  ),
  _FixedHoliday.orthodox(
    'dormition',
    8,
    28,
    'Успение Пресвятой Богородицы',
    'Dormition of the Mother of God',
    'Двунадесятый праздник завершает двухнедельный Успенский пост и посвящён окончанию земной жизни Богородицы. На Руси этот день издавна был одним из важных рубежей земледельческого года.',
    'The feast concludes the Dormition Fast and commemorates the end of the earthly life of the Mother of God.',
  ),
  _FixedHoliday.folk(
    'nut_spas',
    8,
    29,
    'Ореховый Спас',
    'Nut Spas',
    'Третий Спас следует сразу за Успением Богородицы. В народном календаре он совпадал со сбором орехов и завершением жатвы, поэтому его также называли Хлебным Спасом.',
    'The third August “Spas” was associated with gathering nuts and completing the grain harvest.',
  ),
  _FixedHoliday.memorial(
    'solidarity_against_terrorism_day',
    9,
    3,
    'День солидарности в борьбе с терроризмом',
    'Day of Solidarity against Terrorism',
    'Памятная дата установлена после трагедии в Беслане 1–3 сентября 2004 года. В этот день вспоминают жертв террористических актов и сотрудников, погибших при спасении людей.',
    'Established after the 2004 Beslan school tragedy, the day remembers victims of terrorism and fallen rescuers.',
  ),
  _FixedHoliday.professional(
    'financiers_day',
    9,
    8,
    'День финансиста',
    'Financiers Day',
    '8 сентября 1802 года император Александр I учредил Министерство финансов Российской империи. Современный профессиональный праздник установлен в 2011 году.',
    'The date recalls the establishment of the Russian Empire’s Ministry of Finance in 1802; the modern observance began in 2011.',
  ),
  _FixedHoliday.orthodox(
    'nativity_of_theotokos',
    9,
    21,
    'Рождество Пресвятой Богородицы',
    'Nativity of the Mother of God',
    'Первый двунадесятый праздник церковного года посвящён рождению Девы Марии. Он открывает последовательность главных событий православного богослужебного календаря.',
    'The first Great Feast of the liturgical year commemorates the birth of the Virgin Mary.',
  ),
  _FixedHoliday.orthodox(
    'exaltation_of_cross',
    9,
    27,
    'Воздвижение Креста Господня',
    'Exaltation of the Holy Cross',
    'Праздник связан с обретением в IV веке Креста, на котором, по церковному преданию, был распят Иисус Христос. В этот день православные соблюдают строгий пост.',
    'The feast recalls the fourth-century finding and exaltation of the Cross of Christ.',
  ),
  _FixedHoliday.professional(
    'preschool_workers_day',
    9,
    27,
    'День воспитателя',
    'Preschool Workers Day',
    'Дата выбрана в память об открытии первого детского сада в Санкт-Петербурге в 1863 году. Праздник посвящён воспитателям и всем работникам дошкольного образования.',
    'The date recalls the opening of the first kindergarten in Saint Petersburg in 1863.',
  ),
  _FixedHoliday.orthodox(
    'intercession',
    10,
    14,
    'Покров Пресвятой Богородицы',
    'Intercession of the Mother of God',
    'Праздник основан на предании о явлении Богородицы во Влахернском храме Константинополя в X веке. На Руси Покров стал особенно почитаемым и воспринимался как рубеж между осенью и зимой.',
    'The feast recalls a tenth-century apparition in Constantinople and became especially beloved in medieval Rus.',
  ),
  _FixedHoliday.professional(
    'police_day',
    11,
    10,
    'День сотрудника органов внутренних дел',
    'Police and Internal Affairs Officers Day',
    'Дата восходит к постановлению о рабочей милиции от 10 ноября 1917 года. После реформы 2011 года привычный День милиции получил современное официальное название.',
    'The date traces back to the establishment of the workers’ militia on 10 November 1917 and received its current name in 2011.',
  ),
  _FixedHoliday.professional(
    'accountants_day',
    11,
    21,
    'День бухгалтера',
    'Accountants Day',
    'Неофициальная, но широко распространённая российская дата связана с подписанием 21 ноября 1996 года закона «О бухгалтерском учёте».',
    'The widely observed unofficial Russian date recalls the signing of the 1996 federal accounting law.',
  ),
  _FixedHoliday.military(
    'marines_day',
    11,
    27,
    'День морской пехоты',
    'Naval Infantry Day',
    '27 ноября 1705 года Пётр I распорядился сформировать первый в России морской полк. Дата стала профессиональным праздником морских пехотинцев.',
    'The date recalls Peter the Great’s 1705 order to form Russia’s first naval regiment.',
  ),
  _FixedHoliday.memorial(
    'unknown_soldier_day',
    12,
    3,
    'День Неизвестного Солдата',
    'Unknown Soldier Day',
    '3 декабря 1966 года прах неизвестного солдата перенесли из братской могилы под Москвой к Кремлёвской стене. Памятная дата учреждена в 2014 году в честь всех безымянных защитников Отечества.',
    'The date recalls the 1966 transfer of an unknown soldier’s remains to the Kremlin Wall and honors all unidentified defenders.',
  ),
  _FixedHoliday.professional(
    'lawyers_day',
    12,
    3,
    'День юриста',
    'Lawyers Day',
    'Профессиональный праздник установлен в 2008 году. Дата связана с судебной реформой 1864 года, заложившей основы современного российского судопроизводства и адвокатуры.',
    'Established in 2008, the day is associated with the landmark Russian judicial reform of 1864.',
  ),
  _FixedHoliday.orthodox(
    'entry_into_temple',
    12,
    4,
    'Введение во храм Пресвятой Богородицы',
    'Entry of the Mother of God into the Temple',
    'Двунадесятый праздник основан на церковном предании о том, как родители привели трёхлетнюю Марию в Иерусалимский храм и посвятили её Богу.',
    'The feast recalls the tradition of the young Mary being brought to the Temple and dedicated to God.',
  ),
  _FixedHoliday.memorial(
    'volunteer_day',
    12,
    5,
    'День добровольца',
    'Volunteer Day',
    'Российский День добровольца учреждён в 2017 году и совпадает с Международным днём добровольцев ООН, который отмечается 5 декабря с 1985 года.',
    'Russia established the observance in 2017 on the same date as the UN International Volunteer Day introduced in 1985.',
  ),
  _FixedHoliday.memorial(
    'heroes_of_fatherland_day',
    12,
    9,
    'День Героев Отечества',
    'Heroes of the Fatherland Day',
    'Дата продолжает дореволюционную традицию чествования георгиевских кавалеров 9 декабря. Памятный день восстановлен в 2007 году и посвящён Героям России, СССР и кавалерам высших наград.',
    'Restored in 2007, the day continues the older tradition of honoring recipients of the Order of Saint George.',
  ),
  _FixedHoliday.memorial(
    'constitution_day',
    12,
    12,
    'День Конституции России',
    'Russian Constitution Day',
    '12 декабря 1993 года Конституция Российской Федерации была принята всенародным голосованием. Праздник напоминает об основах государственного устройства, правах и свободах граждан.',
    'The Constitution of the Russian Federation was adopted by nationwide vote on 12 December 1993.',
  ),
  _FixedHoliday.military(
    'strategic_missile_forces_day',
    12,
    17,
    'День Ракетных войск стратегического назначения',
    'Strategic Missile Forces Day',
    '17 декабря 1959 года в Вооружённых силах СССР был создан новый вид войск — Ракетные войска стратегического назначения. Памятный день посвящён военнослужащим и ветеранам РВСН.',
    'The date recalls the establishment of the Soviet Strategic Missile Forces on 17 December 1959.',
  ),
  _FixedHoliday.professional(
    'power_engineers_day',
    12,
    22,
    'День энергетика и электрика',
    'Power Engineers and Electricians Day',
    '22 декабря 1920 года был принят план ГОЭЛРО — первая общегосударственная программа электрификации России. Дата стала профессиональным праздником энергетиков и широко отмечается электриками.',
    'The date marks the adoption of the GOELRO national electrification plan on 22 December 1920 and honors power-industry workers and electricians.',
  ),
  _FixedHoliday.professional(
    'rescuers_day',
    12,
    27,
    'День спасателя',
    'Rescuers Day',
    '27 декабря 1990 года был образован Российский корпус спасателей, из которого позднее выросло МЧС России. Профессиональный праздник установлен в 1995 году.',
    'The date marks the creation of the Russian Rescue Corps in 1990, the predecessor of EMERCOM; the observance began in 1995.',
  ),
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
