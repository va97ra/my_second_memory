/// Поиск причины неисправности деревом вопросов.
///
/// Каждый вопрос отвечается «да» или «нет» и приводит либо к следующему
/// вопросу, либо к выводу. Вопросы устроены так, чтобы на них можно было
/// ответить **не вскрывая установку**: переставить прибор, посмотреть на
/// щит, сравнить с соседней точкой. Вывод, требующий работы со снятием
/// напряжения или квалификации, помечен и заканчивается тем, что делать
/// дальше — а не тем, как чинить.
///
/// Опора — Правила по охране труда при эксплуатации электроустановок,
/// приказ Минтруда России от 15.12.2020 № 903н в редакции от 29.04.2025.
/// Порядок действий описан по общепринятой практике и по тексту документа
/// не сверен.
library;

/// Узел дерева: вопрос или вывод.
sealed class DiagnosisNode {
  const DiagnosisNode(this.id);

  final String id;
}

/// Вопрос, на который отвечают «да» или «нет».
class DiagnosisQuestion extends DiagnosisNode {
  const DiagnosisQuestion({
    required String id,
    required this.textRu,
    required this.textEn,
    required this.howRu,
    required this.howEn,
    required this.yes,
    required this.no,
  }) : super(id);

  final String textRu;
  final String textEn;

  /// Как проверить, не вскрывая установку.
  final String howRu;
  final String howEn;

  /// Идентификаторы следующих узлов.
  final String yes;
  final String no;

  String text(bool ru) => ru ? textRu : textEn;
  String how(bool ru) => ru ? howRu : howEn;
}

/// Вывод: что это означает и что делать.
class DiagnosisAnswer extends DiagnosisNode {
  const DiagnosisAnswer({
    required String id,
    required this.titleRu,
    required this.titleEn,
    required this.adviceRu,
    required this.adviceEn,
    this.callSpecialist = false,
  }) : super(id);

  final String titleRu;
  final String titleEn;
  final String adviceRu;
  final String adviceEn;

  /// Дальше нужна работа со снятием напряжения или квалификация.
  final bool callSpecialist;

  String title(bool ru) => ru ? titleRu : titleEn;
  String advice(bool ru) => ru ? adviceRu : adviceEn;
}

class DiagnosisTree {
  const DiagnosisTree({
    required this.id,
    required this.titleRu,
    required this.titleEn,
    required this.nodes,
  });

  final String id;
  final String titleRu;
  final String titleEn;

  /// Первый узел — корень дерева.
  final List<DiagnosisNode> nodes;

  String title(bool ru) => ru ? titleRu : titleEn;

  DiagnosisNode get root => nodes.first;

  DiagnosisNode nodeById(String id) =>
      nodes.firstWhere((node) => node.id == id);
}

const diagnosisTrees = <DiagnosisTree>[
  DiagnosisTree(
    id: 'tree_socket',
    titleRu: 'Не работает розетка',
    titleEn: 'A socket is dead',
    nodes: [
      DiagnosisQuestion(
        id: 'socket_device',
        textRu: 'Прибор работает в другой, заведомо исправной розетке?',
        textEn: 'Does the device work in another socket known to be good?',
        howRu: 'Переставить прибор в розетку, которая точно работает.',
        howEn: 'Move the device to a socket that certainly works.',
        yes: 'socket_breaker',
        no: 'socket_answer_device',
      ),
      DiagnosisQuestion(
        id: 'socket_breaker',
        textRu: 'В щите все аппараты этой линии включены?',
        textEn: 'Are all devices of this line switched on in the board?',
        howRu: 'Посмотреть на щит: рукоятки автоматов и УЗО в верхнем '
            'положении, флажки не сброшены.',
        howEn: 'Look at the board: breaker and RCD handles up, no tripped '
            'flags.',
        yes: 'socket_neighbours',
        no: 'socket_answer_protection',
      ),
      DiagnosisQuestion(
        id: 'socket_neighbours',
        textRu: 'Соседние розетки этой же линии работают?',
        textEn: 'Do the neighbouring sockets on the same line work?',
        howRu: 'Проверить лампой или заведомо рабочим прибором соседние '
            'точки той же группы.',
        howEn: 'Check neighbouring points of the same group with a lamp or a '
            'device known to work.',
        yes: 'socket_answer_point',
        no: 'socket_answer_line',
      ),
      DiagnosisAnswer(
        id: 'socket_answer_device',
        titleRu: 'Дело в приборе',
        titleEn: 'The device is at fault',
        adviceRu: 'Розетка и линия ни при чём: прибор не работает и в '
            'исправной точке. Дальше — ремонт прибора, а не проводки.',
        adviceEn: 'The socket and the line are fine: the device fails in a '
            'good socket too. The device needs repair, not the wiring.',
      ),
      DiagnosisAnswer(
        id: 'socket_answer_protection',
        titleRu: 'Сработала защита',
        titleEn: 'The protection has tripped',
        adviceRu: 'Причина не в розетке, а в том, почему отключился аппарат. '
            'Разбор — в деревьях «Отключается автомат» и «Сработало УЗО». '
            'Включать наугад, не выяснив причину, нельзя.',
        adviceEn: 'The cause is why the device tripped. See the breaker and '
            'RCD trees; do not simply switch it back on.',
      ),
      DiagnosisAnswer(
        id: 'socket_answer_point',
        titleRu: 'Неисправна сама розетка или её подключение',
        titleEn: 'The socket or its connection is faulty',
        adviceRu: 'Линия жива, мертва одна точка — чаще всего это ослабший '
            'контакт в зажиме. Он же и греется. Дальше нужна работа со '
            'снятием напряжения: отключить линию, убедиться указателем, что '
            'напряжения нет, и только потом вскрывать.',
        adviceEn: 'The line is alive and one point is dead — usually a loose '
            'terminal, which is also the part that heats. Further work needs '
            'the line dead and verified with a detector.',
        callSpecialist: true,
      ),
      DiagnosisAnswer(
        id: 'socket_answer_line',
        titleRu: 'Не работает вся линия',
        titleEn: 'The whole line is dead',
        adviceRu: 'Обрыв или отсоединение до розеток — в распределительной '
            'коробке или в щите. Поиск ведут на обесточенной линии с '
            'указателем напряжения; без подготовки и права на такие работы '
            'сюда лезть не следует.',
        adviceEn: 'A break or a disconnection upstream, in a junction box or '
            'the board. The search is done on a dead line and needs proper '
            'training.',
        callSpecialist: true,
      ),
    ],
  ),
  DiagnosisTree(
    id: 'tree_light',
    titleRu: 'Не работает свет',
    titleEn: 'The light does not work',
    nodes: [
      DiagnosisQuestion(
        id: 'light_lamp',
        textRu: 'С заведомо рабочей лампой свет появился?',
        textEn: 'Does the light come on with a lamp known to work?',
        howRu: 'Заменить лампу на исправную. Менять при выключенном '
            'выключателе, а лучше при обесточенной линии.',
        howEn: 'Fit a working lamp, with the switch off — better with the '
            'line dead.',
        yes: 'light_answer_lamp',
        no: 'light_breaker',
      ),
      DiagnosisQuestion(
        id: 'light_breaker',
        textRu: 'Автомат линии освещения включён?',
        textEn: 'Is the lighting breaker on?',
        howRu: 'Посмотреть на щит.',
        howEn: 'Look at the board.',
        yes: 'light_others',
        no: 'light_answer_protection',
      ),
      DiagnosisQuestion(
        id: 'light_others',
        textRu: 'Свет в других помещениях этой линии есть?',
        textEn: 'Is there light elsewhere on the same line?',
        howRu: 'Включить свет в соседних комнатах той же группы.',
        howEn: 'Switch on the light in neighbouring rooms of the group.',
        yes: 'light_answer_local',
        no: 'light_answer_line',
      ),
      DiagnosisAnswer(
        id: 'light_answer_lamp',
        titleRu: 'Перегорела лампа',
        titleEn: 'The lamp had failed',
        adviceRu: 'Самая частая причина и самая простая. Если лампы в этом '
            'светильнике горят подозрительно часто, дело может быть в '
            'контакте патрона или в перегреве — это уже повод присмотреться.',
        adviceEn: 'The most common and simplest cause. Lamps failing often '
            'in one luminaire hint at a poor holder contact or overheating.',
      ),
      DiagnosisAnswer(
        id: 'light_answer_protection',
        titleRu: 'Сработала защита',
        titleEn: 'The protection has tripped',
        adviceRu: 'Сначала выясняют, почему отключился аппарат — см. деревья '
            '«Отключается автомат» и «Сработало УЗО».',
        adviceEn: 'First find out why the device tripped — see the breaker '
            'and RCD trees.',
      ),
      DiagnosisAnswer(
        id: 'light_answer_local',
        titleRu: 'Неисправен светильник или выключатель',
        titleEn: 'The luminaire or the switch is faulty',
        adviceRu: 'Линия жива, не работает одна точка. Дальше — со снятием '
            'напряжения: отключить линию, проверить отсутствие напряжения '
            'указателем на всех жилах и только потом вскрывать выключатель '
            'или светильник.',
        adviceEn: 'The line is alive and one point is not. Further work '
            'needs the line dead and verified on every conductor.',
        callSpecialist: true,
      ),
      DiagnosisAnswer(
        id: 'light_answer_line',
        titleRu: 'Не работает линия освещения',
        titleEn: 'The lighting line is dead',
        adviceRu: 'Обрыв или отсоединение до светильников. Поиск — в щите и '
            'коробках, на обесточенной линии, человеком с правом на такие '
            'работы.',
        adviceEn: 'A break upstream of the luminaires. The search is in the '
            'board and the boxes, on a dead line, by a qualified person.',
        callSpecialist: true,
      ),
    ],
  ),
  DiagnosisTree(
    id: 'tree_breaker',
    titleRu: 'Отключается автомат',
    titleEn: 'The breaker keeps tripping',
    nodes: [
      DiagnosisQuestion(
        id: 'breaker_empty',
        textRu: 'Автомат включается, если отключить от линии всё?',
        textEn: 'Does the breaker hold with everything unplugged?',
        howRu: 'Вынуть из розеток линии все вилки, выключить светильники и '
            'попробовать включить автомат.',
        howEn: 'Unplug everything on the line, switch the lights off and try '
            'the breaker.',
        yes: 'breaker_one_device',
        no: 'breaker_answer_short',
      ),
      DiagnosisQuestion(
        id: 'breaker_one_device',
        textRu: 'Отключается при включении одного определённого прибора?',
        textEn: 'Does it trip when one particular device is switched on?',
        howRu: 'Подключать приборы по одному и следить, на каком отключится.',
        howEn: 'Plug the devices in one by one and see which one trips it.',
        yes: 'breaker_answer_device',
        no: 'breaker_answer_overload',
      ),
      DiagnosisAnswer(
        id: 'breaker_answer_short',
        titleRu: 'Короткое замыкание в проводке',
        titleEn: 'A short circuit in the wiring',
        adviceRu: 'Нагрузки нет, а автомат всё равно отключается — значит '
            'замкнуло саму линию. Линию не включают до устранения причины. '
            'Копоть, запах гари и оплавленная изоляция означают, что искать '
            'должен человек с приборами и правом на такие работы.',
        adviceEn: 'No load and still tripping means the line itself is '
            'shorted. Do not re-energise it; soot, a burnt smell or melted '
            'insulation mean a qualified person with instruments.',
        callSpecialist: true,
      ),
      DiagnosisAnswer(
        id: 'breaker_answer_device',
        titleRu: 'Неисправен прибор',
        titleEn: 'The device is faulty',
        adviceRu: 'Прибор либо неисправен, либо берёт больше, чем рассчитана '
            'линия. Проверять его в другой линии — и не возвращать в работу, '
            'пока причина не ясна.',
        adviceEn: 'The device is faulty or draws more than the line allows. '
            'Test it on another line and keep it out of service until the '
            'cause is clear.',
      ),
      DiagnosisAnswer(
        id: 'breaker_answer_overload',
        titleRu: 'Перегрузка суммой нагрузки',
        titleEn: 'Overload by the total load',
        adviceRu: 'Ни один прибор по отдельности линию не валит, а вместе — '
            'валят: токи параллельных потребителей складываются. Выход — '
            'распределить нагрузку или проложить отдельную линию. Автомат '
            'большего номинала выходом не является: он защищает провод.',
        adviceEn: 'No single device trips it, but together they do: parallel '
            'currents add. Spread the load or run a separate line. A larger '
            'breaker is not a solution — it protects the wire.',
      ),
    ],
  ),
  DiagnosisTree(
    id: 'tree_rcd',
    titleRu: 'Сработало УЗО',
    titleEn: 'The RCD tripped',
    nodes: [
      DiagnosisQuestion(
        id: 'rcd_empty',
        textRu: 'УЗО включается, когда все приборы линии отключены?',
        textEn: 'Does the RCD hold with all devices unplugged?',
        howRu: 'Отключить от линии всё и попробовать включить УЗО.',
        howEn: 'Unplug everything on the line and try the RCD.',
        yes: 'rcd_one_device',
        no: 'rcd_answer_wiring',
      ),
      DiagnosisQuestion(
        id: 'rcd_one_device',
        textRu: 'Срабатывает при включении определённого прибора?',
        textEn: 'Does it trip on one particular device?',
        howRu: 'Подключать приборы по одному.',
        howEn: 'Plug the devices in one by one.',
        yes: 'rcd_answer_device',
        no: 'rcd_water',
      ),
      DiagnosisQuestion(
        id: 'rcd_water',
        textRu: 'Срабатывает в сырую погоду или когда идёт вода?',
        textEn: 'Does it trip in damp weather or when water runs?',
        howRu: 'Сопоставить срабатывания с погодой и с работой воды: '
            'бойлера, стиральной машины, полива.',
        howEn: 'Match the trips with the weather and with water use: a '
            'heater, a washing machine, watering.',
        yes: 'rcd_answer_moisture',
        no: 'rcd_answer_intermittent',
      ),
      DiagnosisAnswer(
        id: 'rcd_answer_wiring',
        titleRu: 'Утечка в самой проводке',
        titleEn: 'Leakage in the wiring itself',
        adviceRu: 'Нагрузки нет, а ток всё равно уходит мимо — повреждена '
            'изоляция линии. Ищут мегаомметром на обесточенной линии. Это '
            'работа для специалиста, и обходить УЗО перемычкой нельзя ни в '
            'каком виде.',
        adviceEn: 'With no load the current still leaks: the line insulation '
            'is damaged. It is found with an insulation tester on a dead '
            'line, by a specialist. Never bypass the RCD.',
        callSpecialist: true,
      ),
      DiagnosisAnswer(
        id: 'rcd_answer_device',
        titleRu: 'Утечка в приборе',
        titleEn: 'Leakage in a device',
        adviceRu: 'Прибор пропускает ток мимо рабочей цепи — через изоляцию '
            'или на корпус. Пользоваться им нельзя: именно от этого УЗО и '
            'защищает человека.',
        adviceEn: 'The device passes current outside its working circuit — '
            'through the insulation or to the case. Do not use it: this is '
            'exactly what the RCD protects a person from.',
      ),
      DiagnosisAnswer(
        id: 'rcd_answer_moisture',
        titleRu: 'Влага в цепи',
        titleEn: 'Moisture in the circuit',
        adviceRu: 'Вода даёт путь току мимо цепи. Найти, где она попадает: '
            'уличная розетка, ввод в дом, соединение в сыром месте. До '
            'устранения — линию не включать.',
        adviceEn: 'Water gives the current a path around the circuit. Find '
            'where it gets in — an outdoor socket, a service entry, a joint '
            'in a damp place — and keep the line off until fixed.',
        callSpecialist: true,
      ),
      DiagnosisAnswer(
        id: 'rcd_answer_intermittent',
        titleRu: 'Периодическая утечка',
        titleEn: 'Intermittent leakage',
        adviceRu: 'Утечка есть, но появляется не всегда — так ведёт себя '
            'подсыхающая или потрескавшаяся изоляция. Нужны измерения и '
            'наблюдение, а не догадки: повторные срабатывания игнорировать '
            'нельзя.',
        adviceEn: 'The leakage comes and goes, as damp or cracked insulation '
            'does. It needs measurement and observation, not guesswork; '
            'repeated trips must not be ignored.',
        callSpecialist: true,
      ),
    ],
  ),
  DiagnosisTree(
    id: 'tree_heat',
    titleRu: 'Греется розетка, автомат или кабель',
    titleEn: 'A socket, breaker or cable gets hot',
    nodes: [
      DiagnosisQuestion(
        id: 'heat_point',
        textRu: 'Греется именно точка подключения, а не кабель по длине?',
        textEn: 'Is it the connection point that heats, not the cable along '
            'its length?',
        howRu: 'Снять нагрузку, дать остыть и осторожно сравнить нагрев '
            'корпуса розетки и кабеля рядом. Ничего не разбирая.',
        howEn: 'Remove the load, let it cool and compare the socket body '
            'with the nearby cable — without opening anything.',
        yes: 'heat_answer_contact',
        no: 'heat_load',
      ),
      DiagnosisQuestion(
        id: 'heat_load',
        textRu: 'Нагрузка линии близка к номиналу автомата?',
        textEn: 'Is the line load close to the breaker rating?',
        howRu: 'Сложить мощности включённых приборов и сравнить с номиналом '
            'автомата — расчёт мощности есть в Инженерке.',
        howEn: 'Add up the connected loads and compare with the breaker '
            'rating — the power calculation is in the engineering tab.',
        yes: 'heat_answer_overload',
        no: 'heat_answer_specialist',
      ),
      DiagnosisAnswer(
        id: 'heat_answer_contact',
        titleRu: 'Ослабший контакт',
        titleEn: 'A loose contact',
        adviceRu: 'Греется место соединения — там выделяется мощность, '
            'которой быть не должно. Это начало пожара, а не мелочь. Линию '
            'обесточить и не включать; подтягивать зажимы под напряжением '
            'нельзя.',
        adviceEn: 'The joint dissipates power it should not. This is the '
            'start of a fire, not a nuisance: de-energise the line and never '
            'tighten terminals live.',
        callSpecialist: true,
      ),
      DiagnosisAnswer(
        id: 'heat_answer_overload',
        titleRu: 'Линия перегружена',
        titleEn: 'The line is overloaded',
        adviceRu: 'Кабель греется по всей длине — значит через него идёт '
            'больше тока, чем он рассчитан нести. Снять часть нагрузки, а '
            'дальше считать сечение и защиту заново: подбор сечения есть в '
            'Инженерке.',
        adviceEn: 'The cable heats along its length: more current than it is '
            'sized for. Reduce the load and re-check the size and the '
            'protection — the sizing tool is in the engineering tab.',
        callSpecialist: true,
      ),
      DiagnosisAnswer(
        id: 'heat_answer_specialist',
        titleRu: 'Нужна проверка специалистом',
        titleEn: 'A specialist check is needed',
        adviceRu: 'Нагрев без явной перегрузки означает, что причина скрыта: '
            'повреждённая жила, плохое соединение в коробке, неисправный '
            'аппарат. Нужны измерения на обесточенной линии.',
        adviceEn: 'Heating without an obvious overload means a hidden cause: '
            'a damaged core, a bad joint in a box, a faulty device. '
            'Measurements on a dead line are needed.',
        callSpecialist: true,
      ),
    ],
  ),
];
