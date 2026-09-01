/// Справочные статьи: коды, степени защиты, маркировка, соответствия.
///
/// Статьи перенесены из прежнего технического справочника без изменения
/// текста: у каждой назван документ и его редакция. Они служат трём
/// специальностям сразу, поэтому у них есть отрасль — единственный раздел
/// учебника, где она нужна.
///
/// Ни одна статья не сверена человеком по тексту документа.
library;

import 'electrician_card.dart';

const electricianReference = <ElectricianCard>[
  ElectricianCard(
    id: 'ip_code',
    section: ElectricianSection.reference,
    trade: ElectricianTrade.electrical,
    titleRu: 'Степень защиты IP',
    titleEn: 'IP protection code',
    whatRu:
        'Первая цифра показывает защиту от твёрдых частиц (0–6), вторая — от воды (0–9). Буква X означает, что характеристика не заявлена.',
    whatEn:
        'The first digit describes protection from solids (0–6), the second from water (0–9). X means the characteristic is not declared.',
    source: 'ГОСТ 14254 / IEC 60529',
    edition: 'ГОСТ 14254-2015, IEC 60529:2013',
    purpose: 'Оболочки электрооборудования',
    caution:
        'IP не описывает стойкость к ударам, коррозии и взрывоопасной среде.',
    aliases: ['IP44', 'IP54', 'IP65', 'пыль', 'вода'],
  ),
  ElectricianCard(
    id: 'ik_code',
    section: ElectricianSection.reference,
    trade: ElectricianTrade.electrical,
    titleRu: 'Ударопрочность IK',
    titleEn: 'IK impact protection',
    whatRu:
        'Код IK00–IK10 задаёт энергию механического удара, которую выдерживает оболочка. Например, IK08 соответствует 5 Дж, IK10 — 20 Дж.',
    whatEn:
        'IK00–IK10 describes the impact energy tolerated by an enclosure. IK08 is 5 J and IK10 is 20 J.',
    source: 'ГОСТ IEC 62262 / IEC 62262',
    edition: 'ГОСТ IEC 62262-2015',
    purpose: 'Оболочки электрооборудования',
    caution:
        'Результат испытания относится к конкретной оболочке и способу её монтажа.',
    aliases: ['IK08', 'IK10', 'удар', 'джоуль'],
  ),
  ElectricianCard(
    id: 'cable_marking',
    section: ElectricianSection.reference,
    trade: ElectricianTrade.electrical,
    titleRu: 'Базовая маркировка кабеля',
    titleEn: 'Basic cable marking',
    whatRu:
        'А — алюминиевая жила (отсутствие А обычно означает медь); В — ПВХ; П — полиэтилен; нг — не распространяет горение; LS — пониженное дымо- и газовыделение.',
    whatEn:
        'Common Russian marking: A indicates aluminium conductor; V is PVC; P is polyethylene; ng limits flame propagation; LS means low smoke.',
    source: 'ГОСТ 31996 и документация изготовителя',
    edition: 'ГОСТ 31996-2012',
    purpose: 'Силовые кабели до 3 кВ',
    caution:
        'Одинаковые буквы могут иметь другой смысл в кабелях иного назначения; сверяйте паспорт изготовителя.',
    aliases: ['ВВГ', 'ВВГнг', 'LS', 'алюминий', 'медь'],
  ),
  ElectricianCard(
    id: 'awg_section',
    section: ElectricianSection.reference,
    trade: ElectricianTrade.electrical,
    titleRu: 'AWG и площадь жилы',
    titleEn: 'AWG and conductor area',
    whatRu:
        'Ориентиры: AWG 14 ≈ 2,08 мм²; AWG 12 ≈ 3,31 мм²; AWG 10 ≈ 5,26 мм²; AWG 8 ≈ 8,37 мм²; AWG 6 ≈ 13,3 мм².',
    whatEn:
        'Reference values: AWG 14 ≈ 2.08 mm²; AWG 12 ≈ 3.31 mm²; AWG 10 ≈ 5.26 mm²; AWG 8 ≈ 8.37 mm²; AWG 6 ≈ 13.3 mm².',
    source: 'ASTM B258 / IEC conductor practice',
    edition: 'ASTM B258-18',
    purpose: 'Геометрическое соответствие размеров проводника',
    caution: 'Эквивалентная площадь не означает одинаковый допустимый ток.',
    aliases: ['AWG', 'мм2', 'сечение'],
  ),
  ElectricianCard(
    id: 'preferred_cable_sections',
    section: ElectricianSection.reference,
    trade: ElectricianTrade.electrical,
    titleRu: 'Стандартные сечения жил',
    titleEn: 'Preferred conductor sections',
    whatRu:
        'Распространённый ряд номинальных сечений, мм²: 0,5; 0,75; 1; 1,5; 2,5; 4; 6; 10; 16; 25; 35; 50; 70; 95; 120; 150; 185; 240. Пересечение с AWG является только геометрическим приближением.',
    whatEn:
        'Common nominal conductor sections, mm²: 0.5; 0.75; 1; 1.5; 2.5; 4; 6; 10; 16; 25; 35; 50; 70; 95; 120; 150; 185; 240. AWG matching is geometric only.',
    source: 'ГОСТ 22483 / IEC 60228',
    edition: 'ГОСТ 22483-2021, IEC 60228:2004',
    purpose: 'Токопроводящие жилы кабелей и изолированных проводов',
    caution:
        'Допустимый ток выбирают по конструкции кабеля, способу прокладки, температуре и требованиям проекта.',
    aliases: ['1.5', '2.5', '4 мм2', 'IEC 60228', 'сечение'],
  ),
  ElectricianCard(
    id: 'wire_section_selection',
    section: ElectricianSection.reference,
    trade: ElectricianTrade.electrical,
    titleRu: 'Как выбирают сечение провода',
    titleEn: 'How conductor size is selected',
    whatRu:
        'Одного значения тока недостаточно. Для выбора нужны материал жилы, тип изоляции, способ прокладки, число нагруженных жил, температура, соседние кабели и длина линии. Сначала сечение проверяют по допустимому длительному току, затем — по падению напряжения и работе защиты. Поэтому для 32 А ответ может различаться у меди и алюминия, при открытой прокладке и в трубе.',
    whatEn:
        'Current alone is not enough. Conductor material, insulation, installation method, loaded conductors, temperature, grouped cables and run length all matter. The section is checked for continuous current, voltage drop and protective-device operation.',
    source: 'ПУЭ, гл. 1.3 / ГОСТ Р 50571.5.52',
    edition: 'ПУЭ, 6-е/7-е изд.; ГОСТ Р 50571.5.52-2011',
    purpose: 'Предварительный выбор проводников низковольтной линии',
    checkedAgainstSource: true,
    caution:
        'Таблицы допустимого тока в калькуляторе подтверждены электриком 1 сентября 2026 года. Кабеля с двумя и тремя жилами в них пока нет — есть только одножильные провода. Даже подтверждённый ответ не заменяет проект, паспорт кабеля и условия трассы.',
    aliases: ['сечение', 'провод', 'кабель', '32 А', 'медь', 'алюминий'],
  ),
  ElectricianCard(
    id: 'breaker_rcd_rcbo',
    section: ElectricianSection.reference,
    trade: ElectricianTrade.electrical,
    titleRu: 'Автомат, УЗО и дифавтомат',
    titleEn: 'Circuit breaker, RCD and RCBO',
    whatRu:
        'Автоматический выключатель защищает проводку от перегрузки и короткого замыкания. УЗО реагирует на дифференциальный ток утечки, но не заменяет автомат: встроенной защиты от сверхтока у него нет. Дифавтомат, или АВДТ, объединяет обе функции в одном аппарате. Номиналы выбирают вместе с кабелем, заземлением, ожидаемым током короткого замыкания и назначением линии.',
    whatEn:
        'A circuit breaker protects wiring against overload and short circuit. An RCD responds to residual current but has no integral overcurrent protection. An RCBO combines both functions. Ratings must be coordinated with the cable and installation.',
    source: 'ГОСТ IEC 60898-1, ГОСТ IEC 61008-1, ГОСТ IEC 61009-1',
    edition:
        'ГОСТ IEC 60898-1-2020, ГОСТ IEC 61008-1-2020, ГОСТ IEC 61009-1-2020',
    purpose: 'Бытовые и аналогичные низковольтные электроустановки',
    caution:
        'УЗО не ограничивает ток перегрузки и короткого замыкания. Его применяют с защитой от сверхтока либо используют дифавтомат.',
    aliases: ['автомат', 'АВ', 'УЗО', 'дифавтомат', 'АВДТ', 'утечка'],
  ),
  ElectricianCard(
    id: 'protective_device_marking',
    section: ElectricianSection.reference,
    trade: ElectricianTrade.electrical,
    titleRu: 'Как читать маркировку защиты',
    titleEn: 'Reading protective-device markings',
    whatRu:
        'В обозначении C16 буква C задаёт характеристику мгновенного расцепления, а 16 А — номинальный ток автомата. Значение 6 кА — отключающая способность, а не допустимый ток линии. На УЗО и дифавтомате In обозначает номинальный ток, IΔn — номинальный отключающий дифференциальный ток. Тип AC, A, F или B описывает форму тока утечки, которую распознаёт аппарат.',
    whatEn:
        'In C16, C is the instantaneous-tripping characteristic and 16 A is rated current. 6 kA is breaking capacity, not line current. On an RCD or RCBO, In is rated current and IΔn is rated residual operating current; AC, A, F and B describe detected residual-current waveforms.',
    source: 'ГОСТ IEC 60898-1, ГОСТ IEC 60755',
    edition: 'ГОСТ IEC 60898-1-2020, ГОСТ IEC/TR 60755-2017',
    purpose: 'Маркировка модульных аппаратов защиты',
    caution:
        'Одинаковый номинальный ток не делает аппараты взаимозаменяемыми: проверяют характеристику, полюсность, тип дифференциального тока, отключающую способность и схему сети.',
    aliases: ['C16', 'B16', 'D16', '6 кА', '30 мА', 'IΔn', 'тип A'],
  ),
  ElectricianCard(
    id: 'pipe_dn',
    section: ElectricianSection.reference,
    trade: ElectricianTrade.plumbing,
    titleRu: 'DN — номинальный диаметр',
    titleEn: 'DN nominal size',
    whatRu:
        'DN — безразмерное обозначение номинального диаметра компонента трубопровода. Число после DN лишь косвенно связано с внутренним или наружным диаметром присоединительного конца и не является измеренным размером. Фактические диаметры зависят от типа изделия и толщины стенки.',
    whatEn:
        'DN is a dimensionless nominal size. It is close to, but not equal to, the internal diameter, which depends on material and wall thickness.',
    source: 'ГОСТ 28338 / ISO 6708',
    edition: 'ГОСТ 28338-89, ISO 6708:1995',
    purpose: 'Трубопроводы и арматура',
    caution:
        'Для расчёта скорости используйте фактический внутренний диаметр из документации трубы.',
    aliases: ['DN15', 'DN20', 'DN25', 'диаметр'],
  ),
  ElectricianCard(
    id: 'pipe_dn_dy_table',
    section: ElectricianSection.reference,
    trade: ElectricianTrade.plumbing,
    titleRu: 'DN, наружный диаметр и дюймы: соответствие',
    titleEn: 'Nominal bore, outside diameter and inches',
    whatRu:
        'DN — номинальный диаметр (старое обозначение — Ду), а знак ⌀ в таблице означает наружный диаметр трубы. Стальные и чугунные трубы и арматуру подбирают по DN, полимерные и медные трубы — по наружному диаметру, поэтому один и тот же участок описывают разными числами.\n\nDN 15 · G½ · сталь ВГП ⌀ 21,3 · ППР ⌀ 20 · медь ⌀ 15\nDN 20 · G¾ · сталь ВГП ⌀ 26,8 · ППР ⌀ 25 · медь ⌀ 22\nDN 25 · G1 · сталь ВГП ⌀ 33,5 · ППР ⌀ 32 · медь ⌀ 28\nDN 32 · G1¼ · сталь ВГП ⌀ 42,3 · ППР ⌀ 40 · медь ⌀ 35\nDN 40 · G1½ · сталь ВГП ⌀ 48,0 · ППР ⌀ 50 · медь ⌀ 42\nDN 50 · G2 · сталь ВГП ⌀ 60,0 · ППР ⌀ 63 · медь ⌀ 54',
    whatEn:
        'Nominal bore sizes steel and cast iron fittings; polymer and copper pipes are sized by outside diameter, so one run is described by different numbers.\n\nDN 15 · G1/2 · steel OD 21.3 · PPR OD 20 · copper OD 15\nDN 20 · G3/4 · steel OD 26.8 · PPR OD 25 · copper OD 22\nDN 25 · G1 · steel OD 33.5 · PPR OD 32 · copper OD 28\nDN 32 · G1 1/4 · steel OD 42.3 · PPR OD 40 · copper OD 35\nDN 40 · G1 1/2 · steel OD 48.0 · PPR OD 50 · copper OD 42\nDN 50 · G2 · steel OD 60.0 · PPR OD 63 · copper OD 54',
    source: 'ГОСТ 3262, ГОСТ 28338, ГОСТ 617',
    edition: 'ГОСТ 3262-75, ГОСТ 28338-89, ГОСТ 617-2006',
    purpose: 'Подбор труб и арматуры одного участка из разных материалов',
    caution:
        'Строка — практическое соответствие, а не равенство: проход у стали, полипропилена и меди одного ряда разный, и для гидравлики берут фактический внутренний диаметр.',
    aliases: ['Ду', 'Дн', 'DN', 'дюйм', 'ППР', 'медь', 'ВГП'],
  ),
  ElectricianCard(
    id: 'drain_slope',
    section: ElectricianSection.reference,
    trade: ElectricianTrade.plumbing,
    titleRu: 'Уклон безнапорной канализации',
    titleEn: 'Gravity drain slope',
    whatRu:
        'Уклон задают так, чтобы поток уносил взвесь, но не убегал от неё вперёд.\n\nДн 40–50 — 0,03 (три сантиметра на метр)\nДн 110 — 0,02 (два сантиметра на метр)\nДн 160 — 0,008\nДн 200 — 0,007\n\nСамоочищение начинается со скорости 0,7 м/с при наполнении 0,5–0,6 диаметра.',
    whatEn:
        'The slope must carry solids without outrunning them.\n\nOD 40-50 — 0.03\nOD 110 — 0.02\nOD 160 — 0.008\nOD 200 — 0.007\n\nSelf-cleaning starts at 0.7 m/s with filling of 0.5-0.6 of the diameter.',
    source: 'СП 30.13330, СП 32.13330',
    edition: 'СП 30.13330.2020, СП 32.13330.2018',
    purpose: 'Внутренняя и наружная безнапорная канализация',
    caution:
        'Слишком большой уклон так же плох, как малый: вода уходит вперёд, твёрдое остаётся в трубе.',
    aliases: ['уклон', 'канализация', 'слив', '110', 'самотёк'],
  ),
  ElectricianCard(
    id: 'pipe_thread_g',
    section: ElectricianSection.reference,
    trade: ElectricianTrade.plumbing,
    titleRu: 'Трубная резьба G',
    titleEn: 'G pipe thread',
    whatRu:
        'G обозначает цилиндрическую трубную резьбу BSPP. Размер в дюймах является условным: наружный диаметр G 1/2 около 20,96 мм, G 3/4 — 26,44 мм, G 1 — 33,25 мм.',
    whatEn:
        'G denotes a BSPP parallel pipe thread. Inch labels are nominal: G 1/2 major diameter is about 20.96 mm, G 3/4 is 26.44 mm and G 1 is 33.25 mm.',
    source: 'ГОСТ 6357 / ISO 228-1',
    edition: 'ГОСТ 6357-81, ISO 228-1:2000',
    purpose: 'Цилиндрические трубные соединения',
    caution:
        'G и конические R/Rc имеют разные правила уплотнения и не взаимозаменяются автоматически.',
    aliases: ['G1/2', 'G3/4', 'BSPP', 'резьба'],
  ),
  ElectricianCard(
    id: 'pipe_standards',
    section: ElectricianSection.reference,
    trade: ElectricianTrade.plumbing,
    titleRu: 'Размер трубы и стандарт',
    titleEn: 'Pipe size and product standard',
    whatRu:
        'Одинаковый DN не задаёт один наружный или внутренний диаметр. Например, водогазопроводные стальные трубы описывает ГОСТ 3262, электросварные — ГОСТ 10704, полимерные напорные трубы имеют собственные ряды SDR по профильным стандартам.',
    whatEn:
        'The same DN does not define one outside or inside diameter. Steel water and gas, welded steel and polymer pressure pipes use different product standards and SDR series.',
    source: 'ГОСТ 3262, ГОСТ 10704 и профильные стандарты материала',
    edition: 'ГОСТ 3262-75, ГОСТ 10704-91',
    purpose: 'Идентификация типоразмера трубы перед расчётом',
    caution:
        'Для гидравлики берите фактический внутренний диаметр и шероховатость из актуального паспорта конкретной трубы.',
    aliases: ['ГОСТ 3262', 'ГОСТ 10704', 'SDR', 'стальная', 'полимерная'],
  ),
  ElectricianCard(
    id: 'duct_sizes',
    section: ElectricianSection.reference,
    trade: ElectricianTrade.ventilation,
    titleRu: 'Предпочтительные круглые воздуховоды',
    titleEn: 'Preferred circular duct sizes',
    whatRu:
        'Распространённый ряд диаметров, мм: 80, 100, 125, 140, 160, 180, 200, 224, 250, 280, 315, 355, 400, 450, 500, 560, 630.',
    whatEn:
        'Common preferred diameters, mm: 80, 100, 125, 140, 160, 180, 200, 224, 250, 280, 315, 355, 400, 450, 500, 560, 630.',
    source: 'ГОСТ 24751 и отраслевые каталоги',
    edition: 'ГОСТ 24751-81',
    purpose: 'Металлические вентиляционные воздуховоды',
    caution:
        'Фактический ряд и толщина металла зависят от изготовителя и давления системы.',
    aliases: ['воздуховод', 'диаметр', 'круглый'],
  ),
  ElectricianCard(
    id: 'air_exchange',
    section: ElectricianSection.reference,
    trade: ElectricianTrade.ventilation,
    titleRu: 'Кратность воздухообмена',
    titleEn: 'Air changes per hour',
    whatRu:
        'Расход по кратности: L = n × V, где L — м³/ч, n — 1/ч, V — объём помещения в м³. Нормативную кратность выбирают по назначению помещения и действующему СП.',
    whatEn:
        'Airflow by air changes: L = n × V, where L is m³/h, n is 1/h and V is room volume in m³.',
    source: 'СП 60.13330 и профильные санитарные нормы',
    edition: 'СП 60.13330.2020',
    purpose: 'Расчётный воздухообмен помещений',
    caution:
        'Расчёт по кратности не заменяет проверку по людям, вредностям, влаге и тепловыделениям.',
    aliases: ['ACH', 'кратность', 'м3/ч', 'помещение'],
  ),
];
