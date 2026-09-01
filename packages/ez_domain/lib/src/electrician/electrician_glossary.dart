/// Словарь электрика.
///
/// Единицы и величины опираются на ГОСТ 8.417-2024 «ГСИ. Единицы величин»,
/// действующий с 30 сентября 2024 года вместо ГОСТ 8.417-2002. Аппараты
/// защиты — на ГОСТ IEC 60898-1-2020 (автоматические выключатели),
/// ГОСТ IEC 61008-1-2020 (УЗО) и ГОСТ IEC 61009-1-2014 (дифавтоматы).
/// Заземление, фаза и нейтраль — на ПУЭ, 7-е издание, глава 1.7.
///
/// `checkedAgainstSource: true` стоит там, где утверждение одинаково во всех
/// учебниках и не зависит от редакции документа: определения величин и связи
/// между ними. Всё, что описывает работу аппарата защиты или порядок
/// действий, помечено `false` — там нужна сверка по тексту документа.
library;

import 'electrician_card.dart';

const _si = 'ГОСТ 8.417-2024';
const _siEdition = 'ГОСТ 8.417-2024, действует с 30.09.2024';
const _pue = 'ПУЭ, 7-е издание';
const _pueEarthing = 'ПУЭ, 7-е издание, глава 1.7';

const electricianGlossary = <ElectricianCard>[
  ElectricianCard(
    id: 'glossary_current',
    section: ElectricianSection.glossary,
    titleRu: 'Ток',
    titleEn: 'Electric current',
    whatRu: 'Упорядоченное движение заряженных частиц по проводнику. '
        'Обозначается буквой I, измеряется в амперах.',
    whatEn: 'An ordered movement of charge along a conductor. '
        'Denoted I and measured in amperes.',
    purpose: 'Ток нагревает провод и приводит в движение оборудование. '
        'По нему выбирают сечение жилы и номинал защиты.',
    caution: 'Для человека опасно не напряжение само по себе, а ток через '
        'тело. Уже десятки миллиампер способны привести к тяжёлым последствиям.',
    source: _si,
    edition: _siEdition,
    checkedAgainstSource: true,
    aliases: ['сила тока', 'I', 'амперы'],
  ),
  ElectricianCard(
    id: 'glossary_voltage',
    section: ElectricianSection.glossary,
    titleRu: 'Напряжение',
    titleEn: 'Voltage',
    whatRu: 'Разность электрических потенциалов между двумя точками. '
        'Обозначается U, измеряется в вольтах.',
    whatEn: 'The difference of electric potential between two points. '
        'Denoted U and measured in volts.',
    purpose: 'Напряжение заставляет ток течь. В однофазной сети между фазой и '
        'нейтралью 230 В, в трёхфазной между фазами 400 В.',
    caution: 'Отсутствие напряжения проверяют указателем и на всех жилах. '
        'Однополюсный индикатор показывает наличие фазы, но не доказывает, '
        'что снято напряжение.',
    source: _si,
    edition: _siEdition,
    checkedAgainstSource: true,
    aliases: ['U', 'вольты', 'потенциал'],
  ),
  ElectricianCard(
    id: 'glossary_resistance',
    section: ElectricianSection.glossary,
    titleRu: 'Сопротивление',
    titleEn: 'Resistance',
    whatRu: 'Способность проводника мешать току. Обозначается R, измеряется '
        'в омах: R = U / I.',
    whatEn: 'How much a conductor opposes current. '
        'Denoted R and measured in ohms: R = U / I.',
    purpose: 'Сопротивление жилы определяет, сколько напряжения потеряется по '
        'дороге и сколько тепла выделится в проводе.',
    caution: 'Сопротивление растёт с нагревом: горячая жила сопротивляется '
        'примерно на пятую часть сильнее холодной. Измеряют его только на '
        'обесточенной цепи.',
    source: _si,
    edition: _siEdition,
    checkedAgainstSource: true,
    aliases: ['R', 'омы', 'закон Ома'],
  ),
  ElectricianCard(
    id: 'glossary_power',
    section: ElectricianSection.glossary,
    titleRu: 'Мощность',
    titleEn: 'Power',
    whatRu: 'Скорость передачи энергии. Обозначается P, измеряется в ваттах. '
        'В цепи постоянного тока P = U × I.',
    whatEn: 'The rate of energy transfer. Denoted P and measured in watts; '
        'in a DC circuit P = U × I.',
    purpose: 'По мощности потребителей считают ток линии, а по нему выбирают '
        'сечение и защиту.',
    caution: 'В цепи переменного тока часть мощности реактивная: '
        'P = U × I × cos φ. Перемножать напряжение и ток без cos φ можно '
        'только для активной нагрузки — обогревателя, лампы накаливания.',
    source: _si,
    edition: _siEdition,
    checkedAgainstSource: true,
    aliases: ['P', 'ватты', 'киловатты'],
  ),
  ElectricianCard(
    id: 'glossary_ampere',
    section: ElectricianSection.glossary,
    titleRu: 'Ампер',
    titleEn: 'Ampere',
    whatRu: 'Единица силы тока в СИ, обозначается А. Основная единица: через '
        'неё выражают остальные электрические величины.',
    whatEn: 'The SI unit of electric current, symbol A. A base unit from '
        'which the other electrical units follow.',
    purpose: 'В амперах указывают номинал автомата, допустимый ток жилы и '
        'потребление прибора.',
    caution: 'В отечественных документах обозначение пишут кириллицей — А. '
        'Уставки УЗО задают в миллиамперах: 10, 30, 100, 300 мА.',
    source: _si,
    edition: _siEdition,
    checkedAgainstSource: true,
    aliases: ['A', 'мА', 'миллиампер'],
  ),
  ElectricianCard(
    id: 'glossary_volt',
    section: ElectricianSection.glossary,
    titleRu: 'Вольт',
    titleEn: 'Volt',
    whatRu: 'Единица напряжения в СИ, обозначается В. Один вольт — это один '
        'ватт на один ампер.',
    whatEn: 'The SI unit of voltage, symbol V. One volt is one watt per '
        'ampere.',
    purpose: 'В вольтах указывают напряжение сети и рабочее напряжение '
        'оборудования.',
    caution: 'Номинал 230/400 В — не ровное число в розетке: напряжение '
        'плавает, и оборудование рассчитывают на допуск, а не на точное '
        'значение.',
    source: _si,
    edition: _siEdition,
    checkedAgainstSource: true,
    aliases: ['V', 'кВ'],
  ),
  ElectricianCard(
    id: 'glossary_ohm',
    section: ElectricianSection.glossary,
    titleRu: 'Ом',
    titleEn: 'Ohm',
    whatRu: 'Единица сопротивления в СИ, обозначается Ом. Один ом — это один '
        'вольт на один ампер.',
    whatEn: 'The SI unit of resistance, symbol Ω. One ohm is one volt per '
        'ampere.',
    purpose: 'В омах измеряют сопротивление жил, обмоток и нагревателей, в '
        'мегаомах — сопротивление изоляции.',
    caution: 'Прозвонка мультиметром показывает целость цепи, но ничего не '
        'говорит о состоянии изоляции: для неё нужен мегаомметр и своя '
        'методика.',
    source: _si,
    edition: _siEdition,
    checkedAgainstSource: true,
    aliases: ['Ω', 'МОм', 'мегаом'],
  ),
  ElectricianCard(
    id: 'glossary_watt',
    section: ElectricianSection.glossary,
    titleRu: 'Ватт',
    titleEn: 'Watt',
    whatRu: 'Единица мощности в СИ, обозначается Вт. Один ватт — это один '
        'джоуль в секунду.',
    whatEn: 'The SI unit of power, symbol W. One watt is one joule per '
        'second.',
    purpose: 'В ваттах указывают мощность приборов, в киловаттах — мощность '
        'ввода и крупного оборудования.',
    caution: 'Ватт — мощность, киловатт-час — количество энергии. Счётчик '
        'считает вторые.',
    source: _si,
    edition: _siEdition,
    checkedAgainstSource: true,
    aliases: ['W', 'кВт', 'кВт·ч'],
  ),
  ElectricianCard(
    id: 'glossary_hertz',
    section: ElectricianSection.glossary,
    titleRu: 'Герц',
    titleEn: 'Hertz',
    whatRu: 'Единица частоты в СИ, обозначается Гц. Один герц — одно '
        'колебание в секунду.',
    whatEn: 'The SI unit of frequency, symbol Hz. One hertz is one cycle per '
        'second.',
    purpose: 'Частота сети в России — 50 Гц. На неё рассчитаны двигатели, '
        'трансформаторы и бытовая техника.',
    caution: 'Оборудование на 60 Гц в сети 50 Гц ведёт себя иначе: двигатель '
        'вращается медленнее, трансформатор греется сильнее.',
    source: _si,
    edition: _siEdition,
    checkedAgainstSource: true,
    aliases: ['Hz', '50 Гц', 'частота сети'],
  ),
  ElectricianCard(
    id: 'glossary_frequency',
    section: ElectricianSection.glossary,
    titleRu: 'Частота',
    titleEn: 'Frequency',
    whatRu: 'Сколько раз за секунду переменный ток меняет направление. '
        'Обозначается f, измеряется в герцах.',
    whatEn: 'How many times per second alternating current reverses. '
        'Denoted f and measured in hertz.',
    purpose: 'Частота задаёт скорость вращения асинхронных двигателей и '
        'работу всего, что зависит от переменного поля.',
    caution: 'Частотный преобразователь меняет частоту нарочно: на выходе не '
        '50 Гц, и измерения там требуют подходящего прибора.',
    source: _si,
    edition: _siEdition,
    checkedAgainstSource: true,
    aliases: ['f', 'Гц'],
  ),
  ElectricianCard(
    id: 'glossary_ac',
    section: ElectricianSection.glossary,
    titleRu: 'Переменный ток',
    titleEn: 'Alternating current',
    whatRu: 'Ток, который периодически меняет направление. В бытовой сети — '
        'пятьдесят раз в секунду.',
    whatEn: 'Current that periodically reverses direction — fifty times a '
        'second in the domestic grid.',
    purpose: 'Переменным током питаются жилые и производственные сети: его '
        'удобно передавать и преобразовывать трансформатором.',
    caution: 'Постоянный ток измеряют и коммутируют иначе. Аппарат для '
        'переменного тока нельзя без оговорок ставить в цепь постоянного: '
        'дуга там гаснет хуже.',
    source: _si,
    edition: _siEdition,
    checkedAgainstSource: true,
    aliases: ['AC', 'переменка', 'постоянный ток', 'DC'],
  ),
  ElectricianCard(
    id: 'glossary_conductor',
    section: ElectricianSection.glossary,
    titleRu: 'Проводник',
    titleEn: 'Conductor',
    whatRu: 'Материал или изделие, по которому свободно течёт ток. В '
        'проводке это медная или алюминиевая жила.',
    whatEn: 'A material or part that carries current freely — in wiring, a '
        'copper or aluminium core.',
    purpose: 'Проводник соединяет источник с нагрузкой. Материал и сечение '
        'определяют нагрев и потерю напряжения.',
    caution: 'Медь и алюминий не соединяют прямой скруткой: контакт '
        'окисляется и греется. Нужна клемма, рассчитанная на оба металла.',
    source: _pue,
    edition: _pue,
    aliases: ['жила', 'медь', 'алюминий'],
  ),
  ElectricianCard(
    id: 'glossary_line',
    section: ElectricianSection.glossary,
    titleRu: 'Фаза',
    titleEn: 'Line conductor',
    whatRu: 'Проводник под напряжением относительно земли и нейтрали. В '
        'однофазной сети он один, в трёхфазной их три.',
    whatEn: 'A conductor live with respect to earth and neutral: one in a '
        'single-phase system, three in a three-phase one.',
    purpose: 'Фаза приносит напряжение к потребителю. Выключатель и аппарат '
        'защиты ставят именно в неё.',
    caution: 'Фазу определяют указателем напряжения. Цвет изоляции — '
        'подсказка, а не доказательство: в старой проводке цвета могут не '
        'соответствовать назначению.',
    source: _pueEarthing,
    edition: _pueEarthing,
    aliases: ['L', 'фазный проводник'],
  ),
  ElectricianCard(
    id: 'glossary_neutral',
    section: ElectricianSection.glossary,
    titleRu: 'Нейтраль',
    titleEn: 'Neutral',
    whatRu: 'Рабочий нулевой проводник N: по нему возвращается ток однофазной '
        'нагрузки.',
    whatEn: 'The neutral conductor N, through which current returns from a '
        'single-phase load.',
    purpose: 'Нейтраль замыкает цепь однофазного потребителя, а в трёхфазной '
        'сети принимает несимметрию нагрузки.',
    caution: 'Нейтраль — рабочий проводник, а не защитный: под нагрузкой на '
        'ней есть напряжение относительно земли. Путать её с PE нельзя.',
    source: _pueEarthing,
    edition: _pueEarthing,
    aliases: ['N', 'ноль', 'нулевой рабочий'],
  ),
  ElectricianCard(
    id: 'glossary_earthing',
    section: ElectricianSection.glossary,
    titleRu: 'Заземление',
    titleEn: 'Earthing',
    whatRu: 'Соединение открытых проводящих частей оборудования с землёй '
        'защитным проводником PE.',
    whatEn: 'Connecting exposed conductive parts of equipment to earth '
        'through the PE protective conductor.',
    purpose: 'Заземление уводит опасный потенциал с корпуса и даёт защите '
        'сработать при пробое изоляции на корпус.',
    caution: 'Защитный проводник не подключают к трубам, к нейтрали «по '
        'месту» или к случайной металлоконструкции: система заземления '
        'задаётся проектом.',
    source: _pueEarthing,
    edition: _pueEarthing,
    aliases: ['PE', 'защитный проводник', 'зануление'],
  ),
  ElectricianCard(
    id: 'glossary_short_circuit',
    section: ElectricianSection.glossary,
    titleRu: 'Короткое замыкание',
    titleEn: 'Short circuit',
    whatRu: 'Соединение проводников с разным потенциалом почти без '
        'сопротивления. Ток вырастает в десятки и сотни раз.',
    whatEn: 'A near-zero-resistance connection between conductors at '
        'different potential; the current rises by orders of magnitude.',
    purpose: 'От короткого замыкания защищает автоматический выключатель: '
        'электромагнитный расцепитель отключает линию за доли секунды.',
    caution: 'Копоть, оплавленная изоляция и запах гари после срабатывания '
        'означают, что линию нельзя включать до выяснения причины.',
    source: _pue,
    edition: _pue,
    aliases: ['КЗ', 'замыкание', 'искрение'],
  ),
  ElectricianCard(
    id: 'glossary_breaker',
    section: ElectricianSection.glossary,
    titleRu: 'Автоматический выключатель',
    titleEn: 'Circuit breaker',
    whatRu: 'Аппарат, отключающий линию при перегрузке и при коротком '
        'замыкании. Внутри два расцепителя: тепловой и электромагнитный.',
    whatEn: 'A device that disconnects a line on overload and on short '
        'circuit, using a thermal and an electromagnetic release.',
    purpose: 'Автомат защищает провод, а не прибор: номинал выбирают так, '
        'чтобы жила не перегрелась раньше, чем он отключит линию.',
    caution: 'Поставить автомат крупнее, чтобы «не выбивало», значит снять '
        'защиту с провода. Причину срабатывания ищут, а не обходят.',
    source: 'ГОСТ IEC 60898-1-2020',
    edition: 'ГОСТ IEC 60898-1-2020',
    aliases: ['автомат', 'АВ', 'расцепитель', 'номинал'],
  ),
  ElectricianCard(
    id: 'glossary_rcd',
    section: ElectricianSection.glossary,
    titleRu: 'УЗО',
    titleEn: 'Residual current device',
    whatRu: 'Выключатель, управляемый дифференциальным током: сравнивает '
        'ток, ушедший в нагрузку, с током, вернувшимся обратно.',
    whatEn: 'A residual current device: it compares the current going into '
        'the load with the current returning from it.',
    purpose: 'УЗО отключает линию, когда часть тока уходит мимо — через '
        'изоляцию, через воду или через человека.',
    caution: 'УЗО не защищает от перегрузки и короткого замыкания, для этого '
        'нужен автомат. Повторное срабатывание нельзя игнорировать: это '
        'признак утечки, а не каприз аппарата.',
    source: 'ГОСТ IEC 61008-1-2020',
    edition: 'ГОСТ IEC 61008-1-2020, введён с 01.03.2021',
    aliases: ['ВДТ', 'дифференциальный ток', 'утечка', '30 мА'],
  ),
  ElectricianCard(
    id: 'glossary_rcbo',
    section: ElectricianSection.glossary,
    titleRu: 'Дифавтомат',
    titleEn: 'RCBO',
    whatRu: 'Один аппарат, соединяющий в себе автоматический выключатель и '
        'УЗО.',
    whatEn: 'A single device combining a circuit breaker and a residual '
        'current device.',
    purpose: 'Дифавтомат ставят, когда в щите мало места: он закрывает и '
        'сверхток, и утечку одной модульной единицей.',
    caution: 'При срабатывании не всегда видно, что произошло — перегрузка '
        'или утечка. Аппараты с указателем причины дороже, но избавляют от '
        'гадания.',
    source: 'ГОСТ IEC 61009-1-2014',
    edition: 'ГОСТ IEC 61009-1-2014',
    aliases: ['АВДТ', 'дифференциальный автомат'],
  ),
];
