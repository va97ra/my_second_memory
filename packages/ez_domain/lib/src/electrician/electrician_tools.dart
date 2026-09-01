/// Инструмент электрика.
///
/// Про ручной инструмент документов нет — есть практика, и источник у таких
/// карточек назван прямо: «Практика электромонтажных работ». Там, где
/// документ есть, он назван: изолированный инструмент — ГОСТ IEC 60900,
/// указатели напряжения — ГОСТ IEC 61243-3, средства защиты — Инструкция по
/// применению и испытанию средств защиты СО 153-34.03.603-2003.
///
/// Ни одна карточка не сверена по тексту документа.
library;

import 'electrician_card.dart';

const _practice = 'Практика электромонтажных работ';
const _insulatedTools = 'ГОСТ IEC 60900';
const _detectors = 'ГОСТ IEC 61243-3';
const _protectiveMeans = 'СО 153-34.03.603-2003';

const electricianTools = <ElectricianCard>[
  ElectricianCard(
    id: 'tool_screwdriver',
    section: ElectricianSection.tools,
    symbol: 'screwdriver',
    titleRu: 'Отвёртка',
    titleEn: 'Screwdriver',
    whatRu: 'Инструмент для винтовых зажимов. У электрика их несколько: '
        'шлицевые и крестовые разных размеров, отдельно — с изолированным '
        'стержнем.',
    whatEn: 'A tool for screw terminals: slotted and cross-head in several '
        'sizes, plus insulated-shaft versions.',
    purpose: 'Затягивать зажимы аппаратов и клемм. Момент затяжки задаёт '
        'изготовитель аппарата — для ответственных зажимов есть динамометрическая отвёртка.',
    caution: 'Отвёртка не по размеру шлица разбивает головку винта и не даёт '
        'дотянуть зажим. Слабый зажим греется, перетянутый — рвёт жилу.',
    source: _practice,
    aliases: ['шлиц', 'крест', 'PH', 'PZ'],
  ),
  ElectricianCard(
    id: 'tool_pliers',
    section: ElectricianSection.tools,
    symbol: 'pliers',
    titleRu: 'Пассатижи',
    titleEn: 'Combination pliers',
    whatRu: 'Губки с насечкой, кусачки у основания и площадка для захвата.',
    whatEn: 'Serrated jaws, a cutting edge near the pivot and a gripping '
        'area.',
    purpose: 'Держать, подгибать и откусывать. Основной хватательный '
        'инструмент в сумке.',
    caution: 'Насечка на губках оставляет следы на жиле и надрезает её. Для '
        'формовки жилы под зажим лучше подходят длинногубцы.',
    source: _practice,
    aliases: ['плоскогубцы', 'губки'],
  ),
  ElectricianCard(
    id: 'tool_side_cutters',
    section: ElectricianSection.tools,
    symbol: 'sideCutters',
    titleRu: 'Бокорезы',
    titleEn: 'Side cutters',
    whatRu: 'Кусачки с режущими кромками сбоку от оси.',
    whatEn: 'Cutters with the cutting edges to the side of the pivot.',
    purpose: 'Резать жилы и стяжки заподлицо, откусывать концы в тесноте '
        'щита.',
    caution: 'Бокорезы для меди не годятся для стальной проволоки и саморезов: '
        'кромка выкрашивается и инструмент перестаёт резать чисто.',
    source: _practice,
    aliases: ['кусачки', 'резать'],
  ),
  ElectricianCard(
    id: 'tool_long_nose',
    section: ElectricianSection.tools,
    symbol: 'longNose',
    titleRu: 'Длинногубцы',
    titleEn: 'Long-nose pliers',
    whatRu: 'Пассатижи с вытянутыми узкими губками.',
    whatEn: 'Pliers with elongated narrow jaws.',
    purpose: 'Достать и завести жилу в глубине коробки, сформовать колечко '
        'под винт.',
    caution: 'Узкие губки легко гнутся при усилии на излом: тянуть ими '
        'застрявший кабель — верный способ испортить инструмент.',
    source: _practice,
    aliases: ['утконосы', 'тонкогубцы'],
  ),
  ElectricianCard(
    id: 'tool_cable_knife',
    section: ElectricianSection.tools,
    symbol: 'knife',
    titleRu: 'Кабельный нож',
    titleEn: 'Cable knife',
    whatRu: 'Нож с изогнутым лезвием и пяткой, ограничивающей глубину реза.',
    whatEn: 'A knife with a hooked blade and a heel limiting the cut depth.',
    purpose: 'Снимать наружную оболочку кабеля, не задевая изоляцию жил.',
    caution: 'Прямой монтажный нож режет вдоль жилы и оставляет надрез на её '
        'изоляции. Надрез не виден после сборки, но становится местом '
        'пробоя.',
    source: _practice,
    aliases: ['нож', 'оболочка', 'разделка'],
  ),
  ElectricianCard(
    id: 'tool_stripper',
    section: ElectricianSection.tools,
    symbol: 'stripper',
    titleRu: 'Стриппер',
    titleEn: 'Wire stripper',
    whatRu: 'Клещи с калиброванными гнёздами или с самонастройкой, снимающие '
        'изоляцию на заданную длину.',
    whatEn: 'Pliers with calibrated slots or a self-adjusting jaw that strip '
        'insulation to a set length.',
    purpose: 'Снять изоляцию, не повредив жилу, и повторить это одинаково '
        'сотню раз подряд.',
    caution: 'Гнездо не по сечению либо не снимает изоляцию, либо срезает '
        'часть проволок. Ослабленная жила греется и ломается в зажиме.',
    source: _practice,
    aliases: ['зачистка', 'изоляция', 'съёмник'],
  ),
  ElectricianCard(
    id: 'tool_crimper',
    section: ElectricianSection.tools,
    symbol: 'crimper',
    titleRu: 'Кримпер',
    titleEn: 'Crimping tool',
    whatRu: 'Пресс-клещи с профильными матрицами для опрессовки наконечников '
        'и гильз.',
    whatEn: 'Crimping pliers with profiled dies for ferrules and lugs.',
    purpose: 'Делать соединение, которое не ослабнет: опрессовка сжимает '
        'проволоки в монолит.',
    caution: 'Матрица должна соответствовать сечению и типу наконечника. '
        'Опрессовка пассатижами — не опрессовка: контакт останется '
        'подвижным.',
    source: _practice,
    aliases: ['опрессовка', 'наконечник', 'гильза', 'НШВИ'],
  ),
  ElectricianCard(
    id: 'tool_multimeter',
    section: ElectricianSection.tools,
    symbol: 'meter',
    titleRu: 'Мультиметр',
    titleEn: 'Multimeter',
    whatRu: 'Прибор, измеряющий напряжение, ток, сопротивление и '
        'прозванивающий цепь.',
    whatEn: 'An instrument measuring voltage, current and resistance, and '
        'testing continuity.',
    purpose: 'Основной измерительный прибор: им проверяют наличие '
        'напряжения, целость жилы и сопротивление нагрузки.',
    caution: 'Категория измерений на приборе должна соответствовать цепи. '
        'Прибор, забытый в режиме измерения тока и подключённый к '
        'напряжению, — короткое замыкание через сам прибор.',
    source: _practice,
    aliases: ['тестер', 'прозвонка', 'измерение'],
  ),
  ElectricianCard(
    id: 'tool_voltage_detector',
    section: ElectricianSection.tools,
    symbol: 'detector',
    titleRu: 'Указатель напряжения',
    titleEn: 'Voltage detector',
    whatRu: 'Прибор, показывающий наличие напряжения между двумя точками. '
        'Двухполюсный — с двумя щупами.',
    whatEn: 'A device showing the presence of voltage between two points; '
        'the two-pole type has two probes.',
    purpose: 'Единственный правильный способ убедиться, что напряжение '
        'снято, перед началом работы.',
    caution: 'Однополюсная отвёртка-индикатор показывает фазу, но её '
        'молчание ничего не доказывает. Исправность указателя проверяют до '
        'и после проверки на заведомо живой части.',
    source: _detectors,
    edition: _detectors,
    aliases: ['индикатор', 'фазоискатель', 'проверка напряжения'],
  ),
  ElectricianCard(
    id: 'tool_clamp_meter',
    section: ElectricianSection.tools,
    symbol: 'clampMeter',
    titleRu: 'Токовые клещи',
    titleEn: 'Clamp meter',
    whatRu: 'Прибор с раскрывающимся магнитопроводом: измеряет ток, не '
        'разрывая цепь.',
    whatEn: 'An instrument with a split core that measures current without '
        'breaking the circuit.',
    purpose: 'Узнать реальный ток линии под нагрузкой — то, что не '
        'посчитаешь по паспорту.',
    caution: 'Клещи охватывают одну жилу. Если охватить кабель целиком, токи '
        'фазы и нуля скомпенсируются и прибор покажет около нуля — это не '
        'отсутствие тока.',
    source: _practice,
    aliases: ['клещи', 'ток', 'измерение тока'],
  ),
  ElectricianCard(
    id: 'tool_insulation_tester',
    section: ElectricianSection.tools,
    symbol: 'insulationTester',
    titleRu: 'Мегаомметр',
    titleEn: 'Insulation tester',
    whatRu: 'Прибор, подающий высокое испытательное напряжение и измеряющий '
        'сопротивление изоляции в мегаомах.',
    whatEn: 'An instrument applying a high test voltage and measuring '
        'insulation resistance in megohms.',
    purpose: 'Проверить состояние изоляции линии — то, чего мультиметр не '
        'умеет.',
    caution: 'Измерение ведут на отключённой и разряженной линии, отсоединив '
        'чувствительную технику: испытательное напряжение выводит её из '
        'строя.',
    source: _practice,
    aliases: ['изоляция', 'мегаом', 'испытание'],
  ),
  ElectricianCard(
    id: 'tool_rotary_hammer',
    section: ElectricianSection.tools,
    symbol: 'rotaryHammer',
    titleRu: 'Перфоратор',
    titleEn: 'Rotary hammer',
    whatRu: 'Инструмент с ударным механизмом для бетона и кирпича.',
    whatEn: 'A tool with a hammering mechanism for concrete and masonry.',
    purpose: 'Бурить отверстия под коробки и крепёж, штробить.',
    caution: 'До сверления надо знать, что в стене. Скрытая проводка и '
        'арматура находятся детектором, а не наугад.',
    source: _practice,
    aliases: ['бур', 'штроба', 'сверление'],
  ),
  ElectricianCard(
    id: 'tool_hole_saw',
    section: ElectricianSection.tools,
    symbol: 'holeSaw',
    titleRu: 'Коронка',
    titleEn: 'Hole saw',
    whatRu: 'Кольцевая насадка с зубьями или алмазным напылением.',
    whatEn: 'A ring-shaped bit with teeth or a diamond edge.',
    purpose: 'Делать посадочные отверстия под подрозетники — обычно 68 мм.',
    caution: 'Коронка по бетону и коронка по дереву не заменяют друг друга. '
        'Работа без пылеудаления в жилом помещении — пыль в лёгких.',
    source: _practice,
    aliases: ['подрозетник', '68 мм', 'отверстие'],
  ),
  ElectricianCard(
    id: 'tool_insulated_set',
    section: ElectricianSection.tools,
    symbol: 'insulatedSet',
    titleRu: 'Изолированный инструмент',
    titleEn: 'Insulated tools',
    whatRu: 'Инструмент с изоляцией, испытанной на 1000 В: отвёртки, '
        'пассатижи, ключи.',
    whatEn: 'Tools with insulation tested to 1000 V: screwdrivers, pliers, '
        'spanners.',
    purpose: 'Работа в щите, где рядом остаются части под напряжением.',
    caution: 'Значок 1000 В относится к целой изоляции. Трещина, потёртость '
        'или след оплавления делают инструмент обычным, а не '
        'изолированным.',
    source: _insulatedTools,
    edition: _insulatedTools,
    aliases: ['1000 В', 'VDE', 'диэлектрический инструмент'],
  ),
  ElectricianCard(
    id: 'tool_gloves',
    section: ElectricianSection.tools,
    symbol: 'gloves',
    titleRu: 'Диэлектрические перчатки',
    titleEn: 'Insulating gloves',
    whatRu: 'Перчатки из диэлектрической резины с отметкой об испытании.',
    whatEn: 'Gloves of insulating rubber carrying a test stamp.',
    purpose: 'Основное средство защиты рук при работах в электроустановках '
        'до 1000 В.',
    caution: 'Перед применением перчатки проверяют на прокол скручиванием и '
        'смотрят дату испытания. Просроченные равны их отсутствию.',
    source: _protectiveMeans,
    edition: _protectiveMeans,
    aliases: ['перчатки', 'СИЗ', 'резина'],
  ),
  ElectricianCard(
    id: 'tool_mat',
    section: ElectricianSection.tools,
    symbol: 'mat',
    titleRu: 'Диэлектрический коврик',
    titleEn: 'Insulating mat',
    whatRu: 'Резиновый коврик с рифлением, отделяющий человека от пола.',
    whatEn: 'A ribbed rubber mat separating the worker from the floor.',
    purpose: 'Разрывает путь тока через тело в землю при работе у щита.',
    caution: 'Трещины, вырывы и масляные пятна выводят коврик из строя. '
        'Мокрый пол под ковриком сводит защиту на нет.',
    source: _protectiveMeans,
    edition: _protectiveMeans,
    aliases: ['коврик', 'резина', 'пол'],
  ),
  ElectricianCard(
    id: 'tool_goggles',
    section: ElectricianSection.tools,
    symbol: 'goggles',
    titleRu: 'Защитные очки',
    titleEn: 'Safety goggles',
    whatRu: 'Очки с ударопрочными стёклами и боковой защитой.',
    whatEn: 'Goggles with impact-resistant lenses and side protection.',
    purpose: 'Защита глаз при бурении, штроблении и от брызг металла при '
        'коротком замыкании.',
    caution: 'Обычные очки для зрения защитой не являются: осколок входит '
        'сбоку.',
    source: _protectiveMeans,
    edition: _protectiveMeans,
    aliases: ['очки', 'глаза', 'СИЗ'],
  ),
];
