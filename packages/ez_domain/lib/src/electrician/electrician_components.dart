/// Компоненты электроустановки.
///
/// Аппараты защиты — автомат, УЗО и дифавтомат — описаны в словаре и здесь
/// не повторяются: одно понятие живёт в одном месте, а карточка словаря
/// находится тем же поиском.
///
/// Источники названы у каждой карточки; ни одна не сверена по тексту.
library;

import 'electrician_card.dart';

const _practice = 'Практика электромонтажных работ';
const _pue = 'ПУЭ, 7-е издание';
const _socketStandard = 'ГОСТ 7396.1-2019';
const _cableStandard = 'ГОСТ 31996-2012';
const _conductorStandard = 'ГОСТ 22483-2021';

const electricianComponents = <ElectricianCard>[
  ElectricianCard(
    id: 'component_socket',
    section: ElectricianSection.components,
    symbol: 'socket',
    titleRu: 'Розетка',
    titleEn: 'Socket outlet',
    whatRu: 'Точка подключения переносного оборудования. В бытовой сети — с '
        'защитным контактом, на 16 А.',
    whatEn: 'A connection point for portable equipment; in domestic wiring '
        'with an earthing contact, rated 16 A.',
    purpose: 'Разъёмное соединение вместо постоянного: прибор включают и '
        'выключают, не трогая проводку.',
    caution: 'Розетка без защитного контакта не заземляет корпус прибора. '
        'Ставить её взамен исправной с контактом — снимать защиту, которая '
        'была.',
    source: _socketStandard,
    edition: _socketStandard,
    aliases: ['розетка', '16 А', 'евророзетка', 'заземляющий контакт'],
  ),
  ElectricianCard(
    id: 'component_switch',
    section: ElectricianSection.components,
    symbol: 'switchOne',
    titleRu: 'Выключатель',
    titleEn: 'Wall switch',
    whatRu: 'Аппарат ручного управления освещением. Бывает одно- и '
        'двухклавишный, проходной, перекрёстный.',
    whatEn: 'A manual lighting control: one- or two-gang, two-way or '
        'intermediate.',
    purpose: 'Разрывает цепь светильника в удобном месте помещения.',
    caution: 'Разрывать нужно фазный проводник. Если разорван ноль, патрон '
        'остаётся под напряжением при выключенном свете — замена лампы '
        'становится опасной.',
    source: _pue,
    edition: _pue,
    aliases: ['выключатель', 'клавиша', 'проходной'],
  ),
  ElectricianCard(
    id: 'component_luminaire',
    section: ElectricianSection.components,
    symbol: 'lamp',
    titleRu: 'Светильник',
    titleEn: 'Luminaire',
    whatRu: 'Прибор, в котором стоит источник света вместе с патроном и '
        'пускорегулирующей частью.',
    whatEn: 'A device holding the light source together with its holder and '
        'control gear.',
    purpose: 'Даёт свет и защищает лампу и контакты от пыли и влаги — в меру '
        'своей степени защиты IP.',
    caution: 'Светильник с электронным блоком боится диммера и выключателя с '
        'подсветкой: лампа начинает мигать в выключенном состоянии.',
    source: _practice,
    aliases: ['светильник', 'лампа', 'люстра'],
  ),
  ElectricianCard(
    id: 'component_contactor',
    section: ElectricianSection.components,
    titleRu: 'Контактор',
    titleEn: 'Contactor',
    whatRu: 'Аппарат с электромагнитным приводом: катушка притягивает '
        'контакты и замыкает силовую цепь.',
    whatEn: 'A device with an electromagnetic drive: the coil pulls the '
        'contacts and closes the power circuit.',
    purpose: 'Управлять мощной нагрузкой слабым сигналом — кнопкой, '
        'термостатом, таймером.',
    caution: 'Контактор — не аппарат защиты. Он коммутирует, но не '
        'отключает при перегрузке: защиту ставят отдельно.',
    source: _practice,
    aliases: ['контактор', 'катушка', 'пускатель'],
  ),
  ElectricianCard(
    id: 'component_relay',
    section: ElectricianSection.components,
    titleRu: 'Промежуточное реле',
    titleEn: 'Interposing relay',
    whatRu: 'Малый аппарат с катушкой и переключающими контактами.',
    whatEn: 'A small device with a coil and change-over contacts.',
    purpose: 'Развязывает цепи управления и силовые, размножает один сигнал '
        'на несколько цепей.',
    caution: 'Контакты реле рассчитаны на небольшой ток. Подключать через '
        'них нагрузку напрямую — путь к подгоранию контактов.',
    source: _practice,
    aliases: ['реле', 'контакты', 'управление'],
  ),
  ElectricianCard(
    id: 'component_terminal',
    section: ElectricianSection.components,
    titleRu: 'Клеммник',
    titleEn: 'Terminal block',
    whatRu: 'Зажим для соединения проводников: винтовой, пружинный или '
        'самозажимной.',
    whatEn: 'A terminal joining conductors: screw, spring or push-in.',
    purpose: 'Даёт разборное соединение, которое можно осмотреть и '
        'подтянуть.',
    caution: 'Зажим рассчитан на определённое сечение и на определённый '
        'металл. Медь и алюминий в одном обычном зажиме окисляются и '
        'греются — для них есть отдельные клеммы.',
    source: _practice,
    aliases: ['клемма', 'зажим', 'ваго', 'соединение'],
  ),
  ElectricianCard(
    id: 'component_junction_box',
    section: ElectricianSection.components,
    symbol: 'junctionBox',
    titleRu: 'Распределительная коробка',
    titleEn: 'Junction box',
    whatRu: 'Коробка, в которой сходятся и соединяются линии проводки.',
    whatEn: 'A box where wiring runs meet and are joined.',
    purpose: 'Собирает соединения в одном доступном месте вместо разбросанных '
        'по стенам скруток.',
    caution: 'Коробку нельзя замуровывать: соединение — самое горячее место '
        'проводки, и к нему нужен доступ.',
    source: _pue,
    edition: _pue,
    aliases: ['коробка', 'распайка'],
  ),
  ElectricianCard(
    id: 'component_cable',
    section: ElectricianSection.components,
    titleRu: 'Кабель',
    titleEn: 'Cable',
    whatRu: 'Несколько изолированных жил в общей оболочке. Провод — одна или '
        'несколько жил без общей оболочки.',
    whatEn: 'Several insulated cores in a common sheath; a wire has no '
        'common sheath.',
    purpose: 'Оболочка защищает изоляцию жил от повреждения и влаги, поэтому '
        'кабель кладут там, где провод не выдержит.',
    caution: 'Марка кабеля говорит о материале изоляции и поведении в огне. '
        'Индекс «нг» и буквы после него — не украшение: они определяют, где '
        'кабель разрешено прокладывать.',
    source: _cableStandard,
    edition: _cableStandard,
    aliases: ['ВВГ', 'нг', 'марка', 'провод', 'оболочка'],
  ),
  ElectricianCard(
    id: 'component_conductor_class',
    section: ElectricianSection.components,
    titleRu: 'Жила и её класс гибкости',
    titleEn: 'Conductor and its flexibility class',
    whatRu: 'Жила бывает однопроволочной и многопроволочной. Класс гибкости '
        'обозначают номером — чем он выше, тем мягче жила.',
    whatEn: 'A core may be solid or stranded; the flexibility class number '
        'grows as the core gets softer.',
    purpose: 'Жёсткая жила держит форму в щите, мягкая переживает изгибы и '
        'вибрацию.',
    caution: 'Мягкую многопроволочную жилу зажимают только через наконечник: '
        'без него проволоки расползаются под винтом и контакт греется.',
    source: _conductorStandard,
    edition: _conductorStandard,
    aliases: ['жила', 'многопроволочная', 'гибкость', 'класс'],
  ),
  ElectricianCard(
    id: 'component_ferrule',
    section: ElectricianSection.components,
    titleRu: 'Наконечник',
    titleEn: 'Ferrule',
    whatRu: 'Гильза, надеваемая на зачищённую жилу и обжимаемая кримпером.',
    whatEn: 'A sleeve fitted over the stripped core and crimped in place.',
    purpose: 'Собирает проволоки многопроволочной жилы в монолит, годный для '
        'винтового зажима.',
    caution: 'Наконечник подбирают по сечению и обжимают инструментом, а не '
        'пассатижами: неполный обжим оставляет контакт подвижным.',
    source: _practice,
    aliases: ['НШВИ', 'гильза', 'обжим', 'опрессовка'],
  ),
  ElectricianCard(
    id: 'component_busbar',
    section: ElectricianSection.components,
    titleRu: 'Шина',
    titleEn: 'Busbar',
    whatRu: 'Планка с рядом зажимов, соединяющая много проводников с одной '
        'точкой. В щите их две: нулевая N и защитная PE.',
    whatEn: 'A bar with a row of terminals joining many conductors to one '
        'point; a board has an N bar and a PE bar.',
    purpose: 'Собирает нулевые и защитные проводники линий без гирлянды '
        'скруток.',
    caution: 'Смешивать N и PE на одной шине нельзя там, где система '
        'заземления их разделяет. Разделение задаётся проектом, а не '
        'удобством монтажа.',
    source: _pue,
    edition: 'ПУЭ, 7-е издание, глава 1.7',
    aliases: ['шина', 'нулевая', 'PE', 'N'],
  ),
  ElectricianCard(
    id: 'component_board',
    section: ElectricianSection.components,
    symbol: 'distributionBoard',
    titleRu: 'Электрический щит',
    titleEn: 'Distribution board',
    whatRu: 'Корпус, в котором стоят вводной аппарат, аппараты защиты линий, '
        'шины и счётчик.',
    whatEn: 'An enclosure holding the incoming device, the protective '
        'devices, the busbars and the meter.',
    purpose: 'Собирает управление и защиту установки в одном месте с '
        'понятной маркировкой.',
    caution: 'Щит без маркировки линий — щит, в котором при аварии ищут '
        'нужный автомат наугад. Подписи делают сразу, а не потом.',
    source: _practice,
    aliases: ['щит', 'щиток', 'ВРУ', 'маркировка'],
  ),
  ElectricianCard(
    id: 'component_conduit',
    section: ElectricianSection.components,
    titleRu: 'Гофра и кабельный лоток',
    titleEn: 'Conduit and cable tray',
    whatRu: 'Труба или открытый лоток, в которых прокладывают кабель.',
    whatEn: 'A pipe or an open tray carrying the cable.',
    purpose: 'Защищают кабель от повреждения и позволяют заменить его без '
        'вскрытия стены.',
    caution: 'Чем теснее жилам, тем хуже они остывают: тот же кабель в трубе '
        'выдерживает меньший ток, чем проложенный открыто.',
    source: _pue,
    edition: _pue,
    aliases: ['гофра', 'лоток', 'труба', 'прокладка'],
  ),
  ElectricianCard(
    id: 'component_plug',
    section: ElectricianSection.components,
    titleRu: 'Вилка и патрон',
    titleEn: 'Plug and lamp holder',
    whatRu: 'Вилка — ответная часть розетки, патрон — держатель лампы с '
        'контактами.',
    whatEn: 'A plug mates with the socket; a lamp holder carries the lamp '
        'and its contacts.',
    purpose: 'Разъёмные части установки, которые чаще всего заменяют.',
    caution: 'В патроне фазу подают на центральный контакт, а не на резьбу: '
        'иначе резьба цоколя оказывается под напряжением при замене лампы.',
    source: _pue,
    edition: _pue,
    aliases: ['вилка', 'патрон', 'цоколь', 'E27'],
  ),
];
