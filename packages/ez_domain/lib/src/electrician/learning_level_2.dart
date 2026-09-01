/// Уровень 2: электрические цепи.
///
/// Восемь пунктов задания сведены к пяти темам. Источник питания, нагрузка и
/// проводник — не отдельные уроки, а три части одной цепи, и порознь они не
/// объясняются. Определения проводника и короткого замыкания лежат в
/// словаре: здесь они не повторяются, здесь показано, как цепь работает и
/// как ломается.
library;

import 'electrician_learning.dart';

const learningLevel2 = <LearningTopic>[
  LearningTopic(
    id: 'learn_circuit',
    level: 2,
    titleRu: 'Что такое электрическая цепь',
    titleEn: 'What an electric circuit is',
    explanationRu: 'Цепь — это замкнутый путь для тока, и в ней всегда три '
        'части. Источник создаёт напряжение, нагрузка превращает энергию в '
        'тепло, свет или движение, проводники соединяют их. Уберите любую из '
        'трёх — тока не будет.',
    explanationEn: 'A circuit is a closed path for current with three parts: '
        'a source making the voltage, a load turning energy into heat, light '
        'or motion, and conductors joining them. Remove any one and no '
        'current flows.',
    exampleRu: 'Светильник в комнате: источник — сеть на вводе, нагрузка — '
        'лампа, проводники — кабель от щита. Выключатель не четвёртая часть, '
        'а способ разорвать проводник.',
    exampleEn: 'A room light: the source is the incoming supply, the load is '
        'the lamp, the conductors are the cable from the board. The switch '
        'is not a fourth part but a way to break a conductor.',
    quiz: [
      QuizQuestion(
        questionRu: 'Чего не хватает цепи, если провод оборван?',
        questionEn: 'What is missing when a conductor is broken?',
        optionsRu: [
          'Источника',
          'Нагрузки',
          'Замкнутого пути',
          'Напряжения',
        ],
        optionsEn: ['A source', 'A load', 'A closed path', 'Voltage'],
        correctIndex: 2,
        explanationRu: 'Источник и нагрузка на месте, но путь разорван — и '
            'ток не идёт. Напряжение при этом на месте обрыва остаётся.',
        explanationEn: 'The source and the load are there, but the path is '
            'broken. The voltage at the break remains.',
      ),
      QuizQuestion(
        questionRu: 'Что делает нагрузка в цепи?',
        questionEn: 'What does the load do?',
        optionsRu: [
          'Создаёт напряжение',
          'Превращает энергию в работу',
          'Соединяет провода',
          'Разрывает цепь',
        ],
        optionsEn: [
          'Creates voltage',
          'Turns energy into work',
          'Joins the wires',
          'Breaks the circuit',
        ],
        correctIndex: 1,
        explanationRu: 'Нагрузка — то, ради чего цепь собрана: лампа, '
            'двигатель, нагреватель.',
        explanationEn: 'The load is the reason the circuit exists: a lamp, a '
            'motor, a heater.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_open_closed',
    level: 2,
    titleRu: 'Замкнутая и разомкнутая цепь',
    titleEn: 'Closed and open circuits',
    explanationRu: 'Замкнутая цепь проводит ток, разомкнутая — нет. Но '
        'разомкнутая цепь не значит безопасная: со стороны источника '
        'напряжение никуда не делось и ждёт на контактах выключателя.',
    explanationEn: 'A closed circuit carries current, an open one does not. '
        'Open does not mean safe: on the source side the voltage is still '
        'there, waiting at the switch contacts.',
    exampleRu: 'Выключенный свет. Лампа не горит, ток не идёт — но на одном '
        'из контактов патрона напряжение есть, если выключатель разрывает '
        'ноль вместо фазы.',
    exampleEn: 'A light switched off: no current flows, yet one lamp-holder '
        'contact is live if the switch breaks the neutral instead of the '
        'line.',
    quiz: [
      QuizQuestion(
        questionRu: 'Что верно для разомкнутой цепи?',
        questionEn: 'What is true of an open circuit?',
        optionsRu: [
          'В ней нет напряжения',
          'Ток не идёт, но напряжение остаётся',
          'Она безопасна',
          'Ток идёт медленнее',
        ],
        optionsEn: [
          'It has no voltage',
          'No current flows but voltage remains',
          'It is safe',
          'Current flows more slowly',
        ],
        correctIndex: 1,
        explanationRu: 'Разрыв останавливает ток, но не убирает напряжение '
            'со стороны источника. Поэтому проверяют указателем, а не по '
            'положению выключателя.',
        explanationEn: 'A break stops the current but not the voltage on the '
            'source side, which is why a detector is used.',
      ),
      QuizQuestion(
        questionRu: 'Какой проводник должен разрывать выключатель?',
        questionEn: 'Which conductor should the switch break?',
        optionsRu: ['Нулевой', 'Фазный', 'Защитный', 'Любой'],
        optionsEn: ['Neutral', 'Line', 'Protective earth', 'Any'],
        correctIndex: 1,
        explanationRu: 'Фазный. Разрыв нуля оставляет светильник под '
            'напряжением, а защитный проводник не разрывают никогда.',
        explanationEn: 'The line. Breaking the neutral leaves the lamp live, '
            'and the protective conductor is never broken.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_series',
    level: 2,
    titleRu: 'Последовательное соединение',
    titleEn: 'Series connection',
    explanationRu: 'Последовательно — это друг за другом, одним путём. Ток '
        'через все элементы одинаковый, а напряжение делится между ними. '
        'Сопротивления складываются.',
    explanationEn: 'In series the elements follow one another on a single '
        'path: the same current in all, the voltage divided between them, '
        'the resistances adding up.',
    exampleRu: 'Гирлянда из ламп: перегорела одна — погасли все, потому что '
        'путь один. Так же соединён и аппарат защиты с линией: через него '
        'проходит весь её ток.',
    exampleEn: 'A string of lamps: one fails and all go dark, because there '
        'is a single path. A protective device sits in series too — the '
        'whole line current passes through it.',
    quiz: [
      QuizQuestion(
        questionRu: 'Что одинаково у последовательно соединённых элементов?',
        questionEn: 'What is the same for elements in series?',
        optionsRu: ['Напряжение', 'Ток', 'Мощность', 'Сопротивление'],
        optionsEn: ['Voltage', 'Current', 'Power', 'Resistance'],
        correctIndex: 1,
        explanationRu: 'Путь один, значит ток один и тот же. Напряжение '
            'делится пропорционально сопротивлениям.',
        explanationEn: 'One path means one current; the voltage divides in '
            'proportion to the resistances.',
      ),
      QuizQuestion(
        questionRu: 'Два сопротивления по 10 Ом соединены последовательно. '
            'Какое общее?',
        questionEn: 'Two 10 Ω resistances in series make what total?',
        optionsRu: ['5 Ом', '10 Ом', '20 Ом', '100 Ом'],
        optionsEn: ['5 Ω', '10 Ω', '20 Ω', '100 Ω'],
        correctIndex: 2,
        explanationRu: 'Последовательные сопротивления складываются: '
            '10 + 10 = 20 Ом.',
        explanationEn: 'Series resistances add: 10 + 10 = 20 Ω.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_parallel',
    level: 2,
    titleRu: 'Параллельное соединение',
    titleEn: 'Parallel connection',
    explanationRu: 'Параллельно — это рядом, разными путями от одних и тех же '
        'точек. Напряжение на всех элементах одинаковое, а ток делится между '
        'ними и в общем проводе складывается.',
    explanationEn: 'In parallel the elements sit side by side between the '
        'same two points: the same voltage on all, the current dividing '
        'between them and adding up in the common conductor.',
    exampleRu: 'Розетки одной линии соединены параллельно: на каждой свои '
        '230 В, а токи включённых приборов складываются в кабеле до щита. '
        'Поэтому линию перегружают не одним прибором, а их суммой.',
    exampleEn: 'Sockets on a line are in parallel: each has its own 230 V, '
        'while the currents add up in the cable back to the board. A line is '
        'overloaded by the sum, not by one device.',
    quiz: [
      QuizQuestion(
        questionRu: 'Что одинаково у параллельно соединённых приборов?',
        questionEn: 'What is the same for devices in parallel?',
        optionsRu: ['Ток', 'Напряжение', 'Мощность', 'Сечение провода'],
        optionsEn: ['Current', 'Voltage', 'Power', 'Wire size'],
        correctIndex: 1,
        explanationRu: 'Они подключены к одним и тем же точкам, значит '
            'напряжение на них одно. Ток каждый берёт свой.',
        explanationEn: 'They share the same two points, so the voltage is '
            'the same; each draws its own current.',
      ),
      QuizQuestion(
        questionRu: 'Три прибора по 5 А включены в одну линию. Какой ток в '
            'кабеле до щита?',
        questionEn: 'Three 5 A devices on one line: what current in the '
            'cable to the board?',
        optionsRu: ['5 А', '10 А', '15 А', 'Зависит от длины'],
        optionsEn: ['5 A', '10 A', '15 A', 'It depends on length'],
        correctIndex: 2,
        explanationRu: 'В общем проводе токи параллельных ветвей '
            'складываются: 5 + 5 + 5 = 15 А. Именно на этот ток выбирают '
            'сечение и автомат.',
        explanationEn: 'Parallel branch currents add in the common '
            'conductor: 15 A. The cable and the breaker are chosen for it.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_short_circuit_mode',
    level: 2,
    titleRu: 'Короткое замыкание как аварийный режим',
    titleEn: 'The short circuit as a fault',
    explanationRu: 'Если проводники с разным потенциалом соединились почти '
        'без сопротивления, ток ограничивает только сопротивление самой '
        'линии — и он вырастает в десятки и сотни раз. За доли секунды '
        'выделяется столько тепла, что изоляция плавится.',
    explanationEn: 'When conductors at different potential meet with almost '
        'no resistance, only the line itself limits the current, and it '
        'rises by orders of magnitude, melting insulation in a fraction of a '
        'second.',
    exampleRu: 'Пробитая изоляция в коробке замыкает фазу на ноль. '
        'Электромагнитный расцепитель автомата отключает линию раньше, чем '
        'кабель успевает нагреться — в этом и есть его работа.',
    exampleEn: 'Damaged insulation in a box shorts line to neutral; the '
        'breaker magnetic release disconnects before the cable heats up.',
    quiz: [
      QuizQuestion(
        questionRu: 'Что ограничивает ток при коротком замыкании?',
        questionEn: 'What limits the current in a short circuit?',
        optionsRu: [
          'Нагрузка',
          'Сопротивление самой линии',
          'Напряжение сети',
          'Ничего не ограничивает',
        ],
        optionsEn: [
          'The load',
          'The line resistance itself',
          'The supply voltage',
          'Nothing limits it',
        ],
        correctIndex: 1,
        explanationRu: 'Нагрузки в цепи больше нет, и остаётся только '
            'сопротивление проводов и источника. Оно мало — поэтому ток '
            'огромен.',
        explanationEn: 'The load is gone, leaving only the wires and the '
            'source: a small resistance, hence a huge current.',
      ),
      QuizQuestion(
        questionRu: 'Что делать, если автомат отключился и пахнет гарью?',
        questionEn: 'What if the breaker tripped and there is a burnt smell?',
        optionsRu: [
          'Включить снова',
          'Поставить автомат побольше',
          'Не включать и найти причину',
          'Подождать и включить',
        ],
        optionsEn: [
          'Switch it back on',
          'Fit a larger breaker',
          'Leave it off and find the cause',
          'Wait and switch on',
        ],
        correctIndex: 2,
        explanationRu: 'Запах гари означает, что где-то уже плавилась '
            'изоляция. Повторное включение подаёт напряжение на повреждённое '
            'место.',
        explanationEn: 'A burnt smell means insulation has already melted; '
            'switching on re-energises the damaged spot.',
      ),
    ],
  ),
];
