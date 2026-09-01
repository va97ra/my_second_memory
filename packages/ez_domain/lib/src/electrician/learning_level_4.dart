/// Уровень 4: электрический щит.
///
/// Что делает автомат, что УЗО и что дифавтомат, написано в словаре. Здесь
/// объясняется устройство щита: что в нём стоит, в каком порядке и почему
/// линии разделены.
library;

import 'electrician_learning.dart';

const learningLevel4 = <LearningTopic>[
  LearningTopic(
    id: 'learn_board_layout',
    level: 4,
    titleRu: 'Что стоит в щите',
    titleEn: 'What a board contains',
    explanationRu: 'Питание входит через вводной аппарат, проходит счётчик и '
        'расходится по линиям, у каждой из которых свой аппарат защиты. '
        'Нулевые и защитные проводники собираются на своих шинах.',
    explanationEn: 'The supply enters through the incoming device, passes '
        'the meter and splits into lines, each with its own protective '
        'device. Neutral and protective conductors gather on their bars.',
    exampleRu: 'Квартирный щит: вводной автомат, счётчик, УЗО на группу '
        'розеток, автоматы на свет, розетки и мощные приборы, шины N и PE.',
    exampleEn: 'A flat board: incoming breaker, meter, an RCD for the socket '
        'group, breakers for lights, sockets and heavy appliances, and the N '
        'and PE bars.',
    quiz: [
      QuizQuestion(
        questionRu: 'Зачем в щите отдельный аппарат на каждую линию?',
        questionEn: 'Why does each line need its own device?',
        optionsRu: [
          'Так красивее',
          'Чтобы авария на одной линии не гасила остальные',
          'Так требует счётчик',
          'Чтобы уменьшить ток',
        ],
        optionsEn: [
          'It looks better',
          'So a fault on one line does not kill the rest',
          'The meter requires it',
          'To reduce the current',
        ],
        correctIndex: 1,
        explanationRu: 'Разделение линий и есть смысл щита: отключается '
            'повреждённая, а не весь дом.',
        explanationEn: 'Dividing the lines is the point: only the faulty one '
            'goes off.',
      ),
      QuizQuestion(
        questionRu: 'Куда собираются защитные проводники линий?',
        questionEn: 'Where do the protective conductors gather?',
        optionsRu: [
          'На нулевую шину',
          'На шину PE',
          'На корпус щита',
          'На вводной автомат',
        ],
        optionsEn: [
          'On the neutral bar',
          'On the PE bar',
          'On the enclosure',
          'On the incoming breaker',
        ],
        correctIndex: 1,
        explanationRu: 'На свою шину PE. Смешивать её с нулевой рабочей '
            'там, где система заземления их разделяет, нельзя.',
        explanationEn: 'On the PE bar; mixing it with the neutral is not '
            'allowed where the earthing system separates them.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_board_incomer',
    level: 4,
    titleRu: 'Вводной аппарат',
    titleEn: 'The incoming device',
    explanationRu: 'Вводной аппарат снимает напряжение со всего щита разом. '
        'Его номинал согласован с выделенной мощностью и с сечением ввода, '
        'поэтому он не выбирается «с запасом побольше».',
    explanationEn: 'The incoming device de-energises the whole board at '
        'once. Its rating matches the allotted power and the incoming '
        'cable, so it is not chosen oversized.',
    exampleRu: 'Именно вводным аппаратом обесточивают щит перед работой — а '
        'потом проверяют отсутствие напряжения указателем, потому что '
        'положение рукоятки ничего не доказывает.',
    exampleEn: 'It is the incomer that de-energises the board before work — '
        'after which the absence of voltage is verified with a detector.',
    quiz: [
      QuizQuestion(
        questionRu: 'Что доказывает, что щит обесточен?',
        questionEn: 'What proves the board is dead?',
        optionsRu: [
          'Опущенная рукоятка ввода',
          'Погасший свет',
          'Проверка указателем напряжения',
          'Отключённый счётчик',
        ],
        optionsEn: [
          'The incomer handle down',
          'The lights being off',
          'A check with a voltage detector',
          'A disconnected meter',
        ],
        correctIndex: 2,
        explanationRu: 'Только проверка. Часть щита может питаться помимо '
            'вводного аппарата — например, до счётчика.',
        explanationEn: 'Only the check: part of the board may be fed around '
            'the incomer, for instance before the meter.',
      ),
      QuizQuestion(
        questionRu: 'Можно ли поставить вводной аппарат большего номинала?',
        questionEn: 'May the incomer be replaced by a larger one?',
        optionsRu: [
          'Да, будет реже отключаться',
          'Нет, он согласован с вводом и выделенной мощностью',
          'Да, если провод медный',
          'Да, если есть УЗО',
        ],
        optionsEn: [
          'Yes, it will trip less',
          'No, it matches the supply cable and the allotted power',
          'Yes, if the wire is copper',
          'Yes, if there is an RCD',
        ],
        correctIndex: 1,
        explanationRu: 'Больший номинал снимает защиту с вводного кабеля, '
            'который менять никто не будет.',
        explanationEn: 'A larger rating removes protection from the '
            'incoming cable, which nobody is going to replace.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_board_grouping',
    level: 4,
    titleRu: 'Как делят линии',
    titleEn: 'How lines are grouped',
    explanationRu: 'Линии делят по назначению и по нагрузке: свет отдельно от '
        'розеток, мощные приборы — своей линией, влажные помещения — под '
        'защитой от утечки. Так авария остаётся местной, а поиск причины '
        'становится быстрым.',
    explanationEn: 'Lines are split by purpose and load: lighting apart from '
        'sockets, heavy appliances on their own, wet rooms under leakage '
        'protection. A fault stays local and is found quickly.',
    exampleRu: 'Отдельная линия на кухонную технику избавляет от '
        'выключенного холодильника всякий раз, когда сработал автомат '
        'розеток в комнате.',
    exampleEn: 'A separate kitchen line keeps the fridge running when the '
        'room socket breaker trips.',
    quiz: [
      QuizQuestion(
        questionRu: 'Зачем свет и розетки разводят разными линиями?',
        questionEn: 'Why split lighting and sockets?',
        optionsRu: [
          'Так дешевле',
          'Чтобы при аварии в розетках оставался свет',
          'Так требует счётчик',
          'Чтобы уменьшить сечение',
        ],
        optionsEn: [
          'It is cheaper',
          'So the light stays on when a socket faults',
          'The meter requires it',
          'To use thinner cable',
        ],
        correctIndex: 1,
        explanationRu: 'Искать причину в темноте — отдельное удовольствие. '
            'Разделение линий даёт свет во время поиска.',
        explanationEn: 'Hunting a fault in the dark is its own problem; '
            'splitting the lines leaves you light to work by.',
      ),
      QuizQuestion(
        questionRu: 'Какие помещения требуют особого внимания к защите от '
            'утечки?',
        questionEn: 'Which rooms need particular attention to leakage '
            'protection?',
        optionsRu: [
          'Спальня и коридор',
          'Ванная, кухня, улица',
          'Кладовая',
          'Любые одинаково',
        ],
        optionsEn: [
          'Bedroom and hallway',
          'Bathroom, kitchen, outdoors',
          'Storeroom',
          'All equally',
        ],
        correctIndex: 1,
        explanationRu: 'Там, где есть вода и заземлённые поверхности, '
            'утечка через человека опаснее всего.',
        explanationEn: 'Where water and earthed surfaces meet, leakage '
            'through a person is most dangerous.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_board_marking',
    level: 4,
    titleRu: 'Маркировка щита',
    titleEn: 'Marking the board',
    explanationRu: 'Каждый аппарат подписан: что он питает. Подпись делают '
        'при монтаже, а не «потом», потому что потом её не делает никто.',
    explanationEn: 'Every device is labelled with what it feeds. Labels go '
        'on during installation, because later never comes.',
    exampleRu: 'Без подписей поиск нужного автомата при аварии идёт '
        'перебором, а перебор в щите — это отключение работающего '
        'оборудования наугад.',
    exampleEn: 'Without labels the right breaker is found by trial, and '
        'trial in a board means switching off working equipment at random.',
    quiz: [
      QuizQuestion(
        questionRu: 'Когда подписывают аппараты в щите?',
        questionEn: 'When are the devices labelled?',
        optionsRu: [
          'При монтаже',
          'При первой аварии',
          'Перед продажей квартиры',
          'Подписывать не нужно',
        ],
        optionsEn: [
          'During installation',
          'At the first fault',
          'Before selling the flat',
          'No need to label',
        ],
        correctIndex: 0,
        explanationRu: 'При монтаже, пока известно, какая линия куда идёт.',
        explanationEn: 'During installation, while it is still known which '
            'line goes where.',
      ),
      QuizQuestion(
        questionRu: 'Что должна говорить подпись у автомата?',
        questionEn: 'What should the label say?',
        optionsRu: [
          'Номинал в амперах',
          'Что он питает',
          'Дату установки',
          'Марку аппарата',
        ],
        optionsEn: [
          'The rating in amperes',
          'What it feeds',
          'The date fitted',
          'The brand',
        ],
        correctIndex: 1,
        explanationRu: 'Номинал написан на самом аппарате. Человеку нужна '
            'линия: «кухня, розетки».',
        explanationEn: 'The rating is on the device itself; a person needs '
            'the line: “kitchen, sockets”.',
      ),
    ],
  ),
];
