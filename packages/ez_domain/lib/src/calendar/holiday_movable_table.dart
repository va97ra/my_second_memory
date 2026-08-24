import 'holiday_occurrence.dart';

/// Праздники, дату которых нужно вычислить: от Пасхи или по дню недели месяца.
///
/// Тексты лежат рядом с правилом даты, потому что здесь дата — такая же часть
/// описания праздника, как его название.
List<HolidayOccurrence> movableHolidays(int year, DateTime easter) {
  return [
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

DateTime _nthWeekday(int year, int month, int weekday, int occurrence) {
  final first = DateTime(year, month);
  final offset = (weekday - first.weekday + 7) % 7;
  return DateTime(year, month, 1 + offset + (occurrence - 1) * 7);
}

DateTime _lastWeekday(int year, int month, int weekday) {
  final last = DateTime(year, month + 1, 0);
  return last.subtract(Duration(days: (last.weekday - weekday + 7) % 7));
}
