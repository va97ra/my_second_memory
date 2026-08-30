enum TechnicalDiscipline { electrical, plumbing, ventilation }

class TechnicalReferenceEntry {
  const TechnicalReferenceEntry({
    required this.id,
    required this.discipline,
    required this.titleRu,
    required this.titleEn,
    required this.bodyRu,
    required this.bodyEn,
    required this.source,
    required this.edition,
    required this.scope,
    required this.warning,
    this.aliases = const [],
  });

  final String id;
  final TechnicalDiscipline discipline;
  final String titleRu;
  final String titleEn;
  final String bodyRu;
  final String bodyEn;
  final String source;
  final String edition;
  final String scope;
  final String warning;
  final List<String> aliases;

  String title(bool ru) => ru ? titleRu : titleEn;
  String body(bool ru) => ru ? bodyRu : bodyEn;
}

const technicalReferenceEntries = <TechnicalReferenceEntry>[
  TechnicalReferenceEntry(
    id: 'ip_code',
    discipline: TechnicalDiscipline.electrical,
    titleRu: 'Степень защиты IP',
    titleEn: 'IP protection code',
    bodyRu:
        'Первая цифра показывает защиту от твёрдых частиц (0–6), вторая — от воды (0–9). Буква X означает, что характеристика не заявлена.',
    bodyEn:
        'The first digit describes protection from solids (0–6), the second from water (0–9). X means the characteristic is not declared.',
    source: 'ГОСТ 14254 / IEC 60529',
    edition: 'ГОСТ 14254-2015, IEC 60529:2013',
    scope: 'Оболочки электрооборудования',
    warning:
        'IP не описывает стойкость к ударам, коррозии и взрывоопасной среде.',
    aliases: ['IP44', 'IP54', 'IP65', 'пыль', 'вода'],
  ),
  TechnicalReferenceEntry(
    id: 'ik_code',
    discipline: TechnicalDiscipline.electrical,
    titleRu: 'Ударопрочность IK',
    titleEn: 'IK impact protection',
    bodyRu:
        'Код IK00–IK10 задаёт энергию механического удара, которую выдерживает оболочка. Например, IK08 соответствует 5 Дж, IK10 — 20 Дж.',
    bodyEn:
        'IK00–IK10 describes the impact energy tolerated by an enclosure. IK08 is 5 J and IK10 is 20 J.',
    source: 'ГОСТ IEC 62262 / IEC 62262',
    edition: 'ГОСТ IEC 62262-2015',
    scope: 'Оболочки электрооборудования',
    warning:
        'Результат испытания относится к конкретной оболочке и способу её монтажа.',
    aliases: ['IK08', 'IK10', 'удар', 'джоуль'],
  ),
  TechnicalReferenceEntry(
    id: 'cable_marking',
    discipline: TechnicalDiscipline.electrical,
    titleRu: 'Базовая маркировка кабеля',
    titleEn: 'Basic cable marking',
    bodyRu:
        'А — алюминиевая жила (отсутствие А обычно означает медь); В — ПВХ; П — полиэтилен; нг — не распространяет горение; LS — пониженное дымо- и газовыделение.',
    bodyEn:
        'Common Russian marking: A indicates aluminium conductor; V is PVC; P is polyethylene; ng limits flame propagation; LS means low smoke.',
    source: 'ГОСТ 31996 и документация изготовителя',
    edition: 'ГОСТ 31996-2012',
    scope: 'Силовые кабели до 3 кВ',
    warning:
        'Одинаковые буквы могут иметь другой смысл в кабелях иного назначения; сверяйте паспорт изготовителя.',
    aliases: ['ВВГ', 'ВВГнг', 'LS', 'алюминий', 'медь'],
  ),
  TechnicalReferenceEntry(
    id: 'awg_section',
    discipline: TechnicalDiscipline.electrical,
    titleRu: 'AWG и площадь жилы',
    titleEn: 'AWG and conductor area',
    bodyRu:
        'Ориентиры: AWG 14 ≈ 2,08 мм²; AWG 12 ≈ 3,31 мм²; AWG 10 ≈ 5,26 мм²; AWG 8 ≈ 8,37 мм²; AWG 6 ≈ 13,3 мм².',
    bodyEn:
        'Reference values: AWG 14 ≈ 2.08 mm²; AWG 12 ≈ 3.31 mm²; AWG 10 ≈ 5.26 mm²; AWG 8 ≈ 8.37 mm²; AWG 6 ≈ 13.3 mm².',
    source: 'ASTM B258 / IEC conductor practice',
    edition: 'ASTM B258-18',
    scope: 'Геометрическое соответствие размеров проводника',
    warning: 'Эквивалентная площадь не означает одинаковый допустимый ток.',
    aliases: ['AWG', 'мм2', 'сечение'],
  ),
  TechnicalReferenceEntry(
    id: 'preferred_cable_sections',
    discipline: TechnicalDiscipline.electrical,
    titleRu: 'Стандартные сечения жил',
    titleEn: 'Preferred conductor sections',
    bodyRu:
        'Распространённый ряд номинальных сечений, мм²: 0,5; 0,75; 1; 1,5; 2,5; 4; 6; 10; 16; 25; 35; 50; 70; 95; 120; 150; 185; 240. Пересечение с AWG является только геометрическим приближением.',
    bodyEn:
        'Common nominal conductor sections, mm²: 0.5; 0.75; 1; 1.5; 2.5; 4; 6; 10; 16; 25; 35; 50; 70; 95; 120; 150; 185; 240. AWG matching is geometric only.',
    source: 'ГОСТ 22483 / IEC 60228',
    edition: 'ГОСТ 22483-2021, IEC 60228:2004',
    scope: 'Токопроводящие жилы кабелей и изолированных проводов',
    warning:
        'Допустимый ток выбирают по конструкции кабеля, способу прокладки, температуре и требованиям проекта.',
    aliases: ['1.5', '2.5', '4 мм2', 'IEC 60228', 'сечение'],
  ),
  TechnicalReferenceEntry(
    id: 'pipe_dn',
    discipline: TechnicalDiscipline.plumbing,
    titleRu: 'DN — условный проход',
    titleEn: 'DN nominal size',
    bodyRu:
        'DN — безразмерное обозначение типоразмера. Оно близко к внутреннему диаметру, но не равно ему. Реальный проход зависит от материала, серии и толщины стенки.',
    bodyEn:
        'DN is a dimensionless nominal size. It is close to, but not equal to, the internal diameter, which depends on material and wall thickness.',
    source: 'ГОСТ 28338 / ISO 6708',
    edition: 'ГОСТ 28338-89, ISO 6708:1995',
    scope: 'Трубопроводы и арматура',
    warning:
        'Для расчёта скорости используйте фактический внутренний диаметр из документации трубы.',
    aliases: ['DN15', 'DN20', 'DN25', 'диаметр'],
  ),
  TechnicalReferenceEntry(
    id: 'pipe_dn_dy_table',
    discipline: TechnicalDiscipline.plumbing,
    titleRu: 'Ду, Дн и дюймы: соответствие',
    titleEn: 'Nominal bore, outside diameter and inches',
    bodyRu: 'Ду — условный проход, Дн — наружный диаметр. Стальные и чугунные трубы и арматуру подбирают по Ду, полимерные и медные — по Дн, поэтому один и тот же участок описывают разными числами.\n\nДу 15 · G½ · сталь ВГП Дн 21,3 · ППР Дн 20 · медь Дн 15\nДу 20 · G¾ · сталь ВГП Дн 26,8 · ППР Дн 25 · медь Дн 22\nДу 25 · G1 · сталь ВГП Дн 33,5 · ППР Дн 32 · медь Дн 28\nДу 32 · G1¼ · сталь ВГП Дн 42,3 · ППР Дн 40 · медь Дн 35\nДу 40 · G1½ · сталь ВГП Дн 48,0 · ППР Дн 50 · медь Дн 42\nДу 50 · G2 · сталь ВГП Дн 60,0 · ППР Дн 63 · медь Дн 54',
    bodyEn: 'Nominal bore sizes steel and cast iron fittings; polymer and copper pipes are sized by outside diameter, so one run is described by different numbers.\n\nDN 15 · G1/2 · steel OD 21.3 · PPR OD 20 · copper OD 15\nDN 20 · G3/4 · steel OD 26.8 · PPR OD 25 · copper OD 22\nDN 25 · G1 · steel OD 33.5 · PPR OD 32 · copper OD 28\nDN 32 · G1 1/4 · steel OD 42.3 · PPR OD 40 · copper OD 35\nDN 40 · G1 1/2 · steel OD 48.0 · PPR OD 50 · copper OD 42\nDN 50 · G2 · steel OD 60.0 · PPR OD 63 · copper OD 54',
    source: 'ГОСТ 3262, ГОСТ 28338, ГОСТ 617',
    edition: 'ГОСТ 3262-75, ГОСТ 28338-89, ГОСТ 617-2006',
    scope: 'Подбор труб и арматуры одного участка из разных материалов',
    warning:
        'Строка — практическое соответствие, а не равенство: проход у стали, полипропилена и меди одного ряда разный, и для гидравлики берут фактический внутренний диаметр.',
    aliases: ['Ду', 'Дн', 'DN', 'дюйм', 'ППР', 'медь', 'ВГП'],
  ),
  TechnicalReferenceEntry(
    id: 'drain_slope',
    discipline: TechnicalDiscipline.plumbing,
    titleRu: 'Уклон безнапорной канализации',
    titleEn: 'Gravity drain slope',
    bodyRu: 'Уклон задают так, чтобы поток уносил взвесь, но не убегал от неё вперёд.\n\nДн 40–50 — 0,03 (три сантиметра на метр)\nДн 110 — 0,02 (два сантиметра на метр)\nДн 160 — 0,008\nДн 200 — 0,007\n\nСамоочищение начинается со скорости 0,7 м/с при наполнении 0,5–0,6 диаметра.',
    bodyEn: 'The slope must carry solids without outrunning them.\n\nOD 40-50 — 0.03\nOD 110 — 0.02\nOD 160 — 0.008\nOD 200 — 0.007\n\nSelf-cleaning starts at 0.7 m/s with filling of 0.5-0.6 of the diameter.',
    source: 'СП 30.13330, СП 32.13330',
    edition: 'СП 30.13330.2020, СП 32.13330.2018',
    scope: 'Внутренняя и наружная безнапорная канализация',
    warning:
        'Слишком большой уклон так же плох, как малый: вода уходит вперёд, твёрдое остаётся в трубе.',
    aliases: ['уклон', 'канализация', 'слив', '110', 'самотёк'],
  ),
  TechnicalReferenceEntry(
    id: 'pipe_thread_g',
    discipline: TechnicalDiscipline.plumbing,
    titleRu: 'Трубная резьба G',
    titleEn: 'G pipe thread',
    bodyRu:
        'G обозначает цилиндрическую трубную резьбу BSPP. Размер в дюймах является условным: наружный диаметр G 1/2 около 20,96 мм, G 3/4 — 26,44 мм, G 1 — 33,25 мм.',
    bodyEn:
        'G denotes a BSPP parallel pipe thread. Inch labels are nominal: G 1/2 major diameter is about 20.96 mm, G 3/4 is 26.44 mm and G 1 is 33.25 mm.',
    source: 'ГОСТ 6357 / ISO 228-1',
    edition: 'ГОСТ 6357-81, ISO 228-1:2000',
    scope: 'Цилиндрические трубные соединения',
    warning:
        'G и конические R/Rc имеют разные правила уплотнения и не взаимозаменяются автоматически.',
    aliases: ['G1/2', 'G3/4', 'BSPP', 'резьба'],
  ),
  TechnicalReferenceEntry(
    id: 'pipe_standards',
    discipline: TechnicalDiscipline.plumbing,
    titleRu: 'Размер трубы и стандарт',
    titleEn: 'Pipe size and product standard',
    bodyRu:
        'Одинаковый DN не задаёт один наружный или внутренний диаметр. Например, водогазопроводные стальные трубы описывает ГОСТ 3262, электросварные — ГОСТ 10704, полимерные напорные трубы имеют собственные ряды SDR по профильным стандартам.',
    bodyEn:
        'The same DN does not define one outside or inside diameter. Steel water and gas, welded steel and polymer pressure pipes use different product standards and SDR series.',
    source: 'ГОСТ 3262, ГОСТ 10704 и профильные стандарты материала',
    edition: 'ГОСТ 3262-75, ГОСТ 10704-91',
    scope: 'Идентификация типоразмера трубы перед расчётом',
    warning:
        'Для гидравлики берите фактический внутренний диаметр и шероховатость из актуального паспорта конкретной трубы.',
    aliases: ['ГОСТ 3262', 'ГОСТ 10704', 'SDR', 'стальная', 'полимерная'],
  ),
  TechnicalReferenceEntry(
    id: 'duct_sizes',
    discipline: TechnicalDiscipline.ventilation,
    titleRu: 'Предпочтительные круглые воздуховоды',
    titleEn: 'Preferred circular duct sizes',
    bodyRu:
        'Распространённый ряд диаметров, мм: 80, 100, 125, 140, 160, 180, 200, 224, 250, 280, 315, 355, 400, 450, 500, 560, 630.',
    bodyEn:
        'Common preferred diameters, mm: 80, 100, 125, 140, 160, 180, 200, 224, 250, 280, 315, 355, 400, 450, 500, 560, 630.',
    source: 'ГОСТ 24751 и отраслевые каталоги',
    edition: 'ГОСТ 24751-81',
    scope: 'Металлические вентиляционные воздуховоды',
    warning:
        'Фактический ряд и толщина металла зависят от изготовителя и давления системы.',
    aliases: ['воздуховод', 'диаметр', 'круглый'],
  ),
  TechnicalReferenceEntry(
    id: 'air_exchange',
    discipline: TechnicalDiscipline.ventilation,
    titleRu: 'Кратность воздухообмена',
    titleEn: 'Air changes per hour',
    bodyRu:
        'Расход по кратности: L = n × V, где L — м³/ч, n — 1/ч, V — объём помещения в м³. Нормативную кратность выбирают по назначению помещения и действующему СП.',
    bodyEn:
        'Airflow by air changes: L = n × V, where L is m³/h, n is 1/h and V is room volume in m³.',
    source: 'СП 60.13330 и профильные санитарные нормы',
    edition: 'СП 60.13330.2020',
    scope: 'Расчётный воздухообмен помещений',
    warning:
        'Расчёт по кратности не заменяет проверку по людям, вредностям, влаге и тепловыделениям.',
    aliases: ['ACH', 'кратность', 'м3/ч', 'помещение'],
  ),
];
