/// Поиск причины неисправности деревом вопросов.
///
/// Шаг говорит, что сделать, и предлагает два исхода, названные словами:
/// «Работает» и «Тоже не работает», а не «да» и «нет». Всё, что предлагается
/// сделать, делается **не вскрывая установку**: переставить прибор,
/// посмотреть на щит, сравнить с соседней точкой. Вывод, требующий работы со снятием
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

/// Шаг проверки: что сделать, на что смотреть и два исхода.
///
/// Исходы названы словами — «УЗО включилось», «Сразу выключается», — а не
/// «да» и «нет». «Да» отвечает на вопрос, который человек ещё не проверял,
/// и после него непонятно, да к чему именно.
class DiagnosisQuestion extends DiagnosisNode {
  const DiagnosisQuestion({
    required String id,
    required this.actionRu,
    required this.actionEn,
    required this.textRu,
    required this.textEn,
    required this.yesLabelRu,
    required this.yesLabelEn,
    required this.noLabelRu,
    required this.noLabelEn,
    required this.yes,
    required this.no,
  }) : super(id);

  /// Что сделать — повелительным наклонением, без вскрытия установки.
  final String actionRu;
  final String actionEn;

  /// На что после этого смотреть.
  final String textRu;
  final String textEn;

  /// Первый исход и его подпись на кнопке.
  final String yesLabelRu;
  final String yesLabelEn;

  /// Второй исход.
  final String noLabelRu;
  final String noLabelEn;

  /// Идентификаторы следующих узлов.
  final String yes;
  final String no;

  String action(bool ru) => ru ? actionRu : actionEn;
  String text(bool ru) => ru ? textRu : textEn;
  String yesLabel(bool ru) => ru ? yesLabelRu : yesLabelEn;
  String noLabel(bool ru) => ru ? noLabelRu : noLabelEn;
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
        actionRu: 'Возьмите прибор и включите его в другую розетку — ту, '
            'которая точно работает.',
        actionEn: 'Take the device and plug it into another socket — one that '
            'certainly works.',
        textRu: 'Что делает прибор в исправной розетке?',
        textEn: 'What does the device do in the good socket?',
        yesLabelRu: 'Работает',
        yesLabelEn: 'It works',
        noLabelRu: 'Тоже не работает',
        noLabelEn: 'It does not work either',
        yes: 'socket_breaker',
        no: 'socket_answer_device',
      ),
      DiagnosisQuestion(
        id: 'socket_breaker',
        actionRu: 'Подойдите к щиту и посмотрите на автоматы и УЗО этой линии.',
        actionEn: 'Go to the board and look at the breakers and RCDs of this '
            'line.',
        textRu: 'В каком они положении?',
        textEn: 'What position are they in?',
        yesLabelRu: 'Все включены',
        yesLabelEn: 'All switched on',
        noLabelRu: 'Какой-то выключен или сброшен',
        noLabelEn: 'One is off or tripped',
        yes: 'socket_neighbours',
        no: 'socket_answer_protection',
      ),
      DiagnosisQuestion(
        id: 'socket_neighbours',
        actionRu: 'Включите лампу или заведомо рабочий прибор в соседние '
            'розетки той же группы.',
        actionEn: 'Plug a lamp or a device known to work into the '
            'neighbouring sockets of the same group.',
        textRu: 'Что в соседних розетках?',
        textEn: 'What happens in them?',
        yesLabelRu: 'Работают',
        yesLabelEn: 'They work',
        noLabelRu: 'Тоже не работают',
        noLabelEn: 'They do not work either',
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
        actionRu: 'Выключите выключатель и поставьте заведомо рабочую лампу. '
            'Менять лучше при обесточенной линии.',
        actionEn: 'Switch the light off and fit a lamp known to work — better '
            'with the line dead.',
        textRu: 'Что со светом после замены?',
        textEn: 'What does the light do now?',
        yesLabelRu: 'Загорелся',
        yesLabelEn: 'It lights up',
        noLabelRu: 'Не загорелся',
        noLabelEn: 'Still dark',
        yes: 'light_answer_lamp',
        no: 'light_breaker',
      ),
      DiagnosisQuestion(
        id: 'light_breaker',
        actionRu: 'Посмотрите в щите на автомат линии освещения.',
        actionEn: 'Look at the lighting breaker in the board.',
        textRu: 'В каком он положении?',
        textEn: 'What position is it in?',
        yesLabelRu: 'Включён',
        yesLabelEn: 'Switched on',
        noLabelRu: 'Выключен или сброшен',
        noLabelEn: 'Off or tripped',
        yes: 'light_others',
        no: 'light_answer_protection',
      ),
      DiagnosisQuestion(
        id: 'light_others',
        actionRu: 'Включите свет в других комнатах этой же линии.',
        actionEn: 'Switch on the light in other rooms of the same line.',
        textRu: 'Что там со светом?',
        textEn: 'What happens there?',
        yesLabelRu: 'Горит',
        yesLabelEn: 'It lights up',
        noLabelRu: 'Тоже не горит',
        noLabelEn: 'Dark there too',
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
        actionRu: 'Выньте из розеток линии все вилки, выключите светильники и '
            'включите автомат.',
        actionEn: 'Unplug everything on the line, switch the lights off and '
            'put the breaker back on.',
        textRu: 'Что делает автомат?',
        textEn: 'What does the breaker do?',
        yesLabelRu: 'Держит, не выключается',
        yesLabelEn: 'It holds',
        noLabelRu: 'Сразу выключается',
        noLabelEn: 'It trips at once',
        yes: 'breaker_one_device',
        no: 'breaker_answer_short',
      ),
      DiagnosisQuestion(
        id: 'breaker_one_device',
        actionRu: 'Включайте приборы по одному и смотрите, на каком автомат '
            'выключится.',
        actionEn: 'Switch the devices on one by one and watch which one trips '
            'the breaker.',
        textRu: 'Когда автомат выключается?',
        textEn: 'When does it trip?',
        yesLabelRu: 'На одном определённом приборе',
        yesLabelEn: 'On one particular device',
        noLabelRu: 'Когда работают несколько сразу',
        noLabelEn: 'When several run together',
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
        actionRu: 'Отключите от линии все приборы и включите УЗО.',
        actionEn: 'Unplug everything on the line and switch the RCD on.',
        textRu: 'Что делает УЗО?',
        textEn: 'What does the RCD do?',
        yesLabelRu: 'Включилось и держит',
        yesLabelEn: 'It holds',
        noLabelRu: 'Сразу выключается',
        noLabelEn: 'It trips at once',
        yes: 'rcd_one_device',
        no: 'rcd_answer_wiring',
      ),
      DiagnosisQuestion(
        id: 'rcd_one_device',
        actionRu: 'Включайте приборы по одному.',
        actionEn: 'Switch the devices on one by one.',
        textRu: 'Когда УЗО выключается?',
        textEn: 'When does the RCD trip?',
        yesLabelRu: 'На одном определённом приборе',
        yesLabelEn: 'On one particular device',
        noLabelRu: 'Ни на одном — выключается само',
        noLabelEn: 'On none — it trips by itself',
        yes: 'rcd_answer_device',
        no: 'rcd_water',
      ),
      DiagnosisQuestion(
        id: 'rcd_water',
        actionRu: 'Вспомните, когда оно выключалось: в дождь, при включении '
            'бойлера, стиральной машины, полива.',
        actionEn: 'Recall when it tripped: in the rain, when a water heater, '
            'a washing machine or watering started.',
        textRu: 'Совпадает ли это с водой или сыростью?',
        textEn: 'Does that match water or damp?',
        yesLabelRu: 'Да, совпадает',
        yesLabelEn: 'Yes, it matches',
        noLabelRu: 'Нет, без всякой связи',
        noLabelEn: 'No connection at all',
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
        actionRu: 'Отключите нагрузку, дайте остыть и осторожно, тыльной '
            'стороной руки, сравните нагрев корпуса розетки и кабеля рядом. '
            'Ничего не разбирайте.',
        actionEn: 'Remove the load, let it cool and carefully compare the '
            'socket body with the nearby cable, using the back of your hand. '
            'Open nothing.',
        textRu: 'Что горячее?',
        textEn: 'Which is hotter?',
        yesLabelRu: 'Сама розетка или зажим',
        yesLabelEn: 'The socket or the terminal',
        noLabelRu: 'Кабель по всей длине',
        noLabelEn: 'The cable along its length',
        yes: 'heat_answer_contact',
        no: 'heat_load',
      ),
      DiagnosisQuestion(
        id: 'heat_load',
        actionRu: 'Сложите мощности приборов, которые работали на линии, и '
            'сравните с номиналом автомата — расчёт мощности есть в '
            'Инженерке.',
        actionEn: 'Add up the power of the devices that were running and '
            'compare with the breaker rating — the power calculation is in '
            'the engineering tab.',
        textRu: 'Насколько нагрузка близка к номиналу автомата?',
        textEn: 'How close is the load to the breaker rating?',
        yesLabelRu: 'Близка или выше',
        yesLabelEn: 'Close or above',
        noLabelRu: 'Заметно меньше',
        noLabelEn: 'Well below',
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
