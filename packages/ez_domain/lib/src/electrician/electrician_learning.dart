/// Обучение: темы по уровням и короткий тест после каждой.
///
/// Единицы измерения отдельными темами не заводятся: ампер, вольт, ом, ватт
/// и герц определены в словаре, и второй раз то же самое здесь писать
/// нельзя. Тема ссылается на словарь словами, а поиск находит карточку.
///
/// Уровень 1 написан целиком. Уровни 2–5 из технического задания —
/// электрические цепи, провода и кабели, щит, измерения — ещё не написаны.
library;

/// Вопрос теста: четыре варианта, один верный и объяснение после ответа.
class QuizQuestion {
  const QuizQuestion({
    required this.questionRu,
    required this.questionEn,
    required this.optionsRu,
    required this.optionsEn,
    required this.correctIndex,
    required this.explanationRu,
    required this.explanationEn,
  });

  final String questionRu;
  final String questionEn;
  final List<String> optionsRu;
  final List<String> optionsEn;
  final int correctIndex;
  final String explanationRu;
  final String explanationEn;

  String question(bool ru) => ru ? questionRu : questionEn;
  List<String> options(bool ru) => ru ? optionsRu : optionsEn;
  String explanation(bool ru) => ru ? explanationRu : explanationEn;
}

class LearningTopic {
  const LearningTopic({
    required this.id,
    required this.level,
    required this.titleRu,
    required this.titleEn,
    required this.explanationRu,
    required this.explanationEn,
    required this.exampleRu,
    required this.exampleEn,
    required this.quiz,
  });

  final String id;

  /// Номер уровня: темы идут по возрастанию сложности.
  final int level;
  final String titleRu;
  final String titleEn;
  final String explanationRu;
  final String explanationEn;

  /// Пример из работы, а не из учебника.
  final String exampleRu;
  final String exampleEn;
  final List<QuizQuestion> quiz;

  String title(bool ru) => ru ? titleRu : titleEn;
  String explanation(bool ru) => ru ? explanationRu : explanationEn;
  String example(bool ru) => ru ? exampleRu : exampleEn;
}

const learningTopics = <LearningTopic>[
  LearningTopic(
    id: 'learn_current',
    level: 1,
    titleRu: 'Что такое электрический ток',
    titleEn: 'What electric current is',
    explanationRu: 'Ток — это движение заряженных частиц по проводнику. Пока '
        'цепь разомкнута, движения нет; замкнули — заряды пошли, и по пути '
        'они греют провод и вращают двигатель. Измеряется ток в амперах.',
    explanationEn: 'Current is the movement of charge along a conductor. An '
        'open circuit means no movement; closing it starts the charge '
        'moving, heating the wire and turning motors. Current is measured in '
        'amperes.',
    exampleRu: 'Чайник на 2 кВт в сети 230 В берёт около 8,7 А. Столько же '
        'проходит и по проводу до розетки — и именно этот ток его греет.',
    exampleEn: 'A 2 kW kettle on 230 V draws about 8.7 A. The same current '
        'flows through the wire to the socket and heats it.',
    quiz: [
      QuizQuestion(
        questionRu: 'Что измеряется в амперах?',
        questionEn: 'What is measured in amperes?',
        optionsRu: ['Напряжение', 'Ток', 'Сопротивление', 'Мощность'],
        optionsEn: ['Voltage', 'Current', 'Resistance', 'Power'],
        correctIndex: 1,
        explanationRu: 'Ампер — единица силы тока. Напряжение меряют в '
            'вольтах, сопротивление в омах, мощность в ваттах.',
        explanationEn: 'The ampere is the unit of current. Voltage is in '
            'volts, resistance in ohms, power in watts.',
      ),
      QuizQuestion(
        questionRu: 'Что происходит с током в разомкнутой цепи?',
        questionEn: 'What happens to current in an open circuit?',
        optionsRu: [
          'Он течёт медленнее',
          'Он не течёт',
          'Он растёт',
          'Он меняет направление',
        ],
        optionsEn: [
          'It flows more slowly',
          'It does not flow',
          'It increases',
          'It reverses',
        ],
        correctIndex: 1,
        explanationRu: 'Току нужен замкнутый путь. Разрыв в любом месте цепи '
            'останавливает его целиком.',
        explanationEn: 'Current needs a closed path: a break anywhere stops '
            'it completely.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_voltage',
    level: 1,
    titleRu: 'Что такое напряжение',
    titleEn: 'What voltage is',
    explanationRu: 'Напряжение — это разность потенциалов, то, что заставляет '
        'заряды двигаться. Его сравнивают с давлением в трубе: чем больше '
        'разность, тем сильнее «давит» на заряды. Измеряется в вольтах.',
    explanationEn: 'Voltage is the potential difference that pushes charge '
        'along, often compared with pressure in a pipe. It is measured in '
        'volts.',
    exampleRu: 'В розетке 230 В между фазой и нулём. Между двумя фазами '
        'трёхфазной сети — 400 В, и это разные величины, а не опечатка.',
    exampleEn: 'A socket has 230 V between line and neutral; between two '
        'lines of a three-phase supply it is 400 V.',
    quiz: [
      QuizQuestion(
        questionRu: 'Между чем в бытовой розетке 230 В?',
        questionEn: 'Between what is there 230 V in a domestic socket?',
        optionsRu: [
          'Между двумя фазами',
          'Между фазой и нулём',
          'Между нулём и землёй',
          'Между двумя нулями',
        ],
        optionsEn: [
          'Between two lines',
          'Between line and neutral',
          'Between neutral and earth',
          'Between two neutrals',
        ],
        correctIndex: 1,
        explanationRu: 'Между фазой и нулём — 230 В, между двумя фазами — '
            '400 В.',
        explanationEn: 'Line to neutral is 230 V; line to line is 400 V.',
      ),
      QuizQuestion(
        questionRu: 'Чем проверяют, что напряжение снято?',
        questionEn: 'What proves that the voltage is off?',
        optionsRu: [
          'Положением автомата',
          'Погасшей лампой',
          'Указателем напряжения',
          'На ощупь',
        ],
        optionsEn: [
          'The breaker position',
          'A lamp going dark',
          'A voltage detector',
          'By touch',
        ],
        correctIndex: 2,
        explanationRu: 'Только указателем и на всех жилах. Автомат может '
            'быть не тот, а лампа — перегоревшей.',
        explanationEn: 'Only a detector, on every conductor: the breaker may '
            'be the wrong one and the lamp may simply have failed.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_resistance',
    level: 1,
    titleRu: 'Что такое сопротивление',
    titleEn: 'What resistance is',
    explanationRu: 'Сопротивление показывает, насколько проводник мешает '
        'току. Оно зависит от материала, сечения и длины: тонкая длинная '
        'жила сопротивляется сильнее толстой и короткой. Измеряется в омах.',
    explanationEn: 'Resistance shows how much a conductor opposes current. '
        'It depends on material, cross-section and length, and is measured '
        'in ohms.',
    exampleRu: 'Двадцать метров медной жилы 2,5 мм² имеют около 0,14 Ом. '
        'Кажется мало — но при токе 16 А на них теряется заметная часть '
        'напряжения.',
    exampleEn: 'Twenty metres of 2.5 mm² copper is about 0.14 Ω — small, yet '
        'at 16 A it costs a noticeable share of the voltage.',
    quiz: [
      QuizQuestion(
        questionRu: 'Что произойдёт с сопротивлением жилы при нагреве?',
        questionEn: 'What happens to conductor resistance when it heats up?',
        optionsRu: ['Вырастет', 'Упадёт', 'Не изменится', 'Станет нулевым'],
        optionsEn: ['It rises', 'It falls', 'It stays', 'It becomes zero'],
        correctIndex: 0,
        explanationRu: 'У металлов сопротивление растёт с температурой: '
            'горячая жила сопротивляется примерно на пятую часть сильнее.',
        explanationEn: 'In metals resistance grows with temperature: a hot '
            'conductor resists about a fifth more.',
      ),
      QuizQuestion(
        questionRu: 'Какая жила будет сопротивляться меньше?',
        questionEn: 'Which conductor has the lower resistance?',
        optionsRu: [
          'Тонкая и длинная',
          'Толстая и короткая',
          'Тонкая и короткая',
          'Все одинаково',
        ],
        optionsEn: [
          'Thin and long',
          'Thick and short',
          'Thin and short',
          'All the same',
        ],
        correctIndex: 1,
        explanationRu: 'Сопротивление растёт с длиной и падает с сечением.',
        explanationEn: 'Resistance grows with length and falls with area.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_power',
    level: 1,
    titleRu: 'Что такое мощность',
    titleEn: 'What power is',
    explanationRu: 'Мощность — скорость, с которой передаётся энергия. Для '
        'активной нагрузки это напряжение, умноженное на ток. Измеряется в '
        'ваттах, а счётчик считает уже киловатт-часы — количество энергии.',
    explanationEn: 'Power is the rate of energy transfer: for a resistive '
        'load, voltage times current. It is measured in watts, while the '
        'meter counts kilowatt-hours of energy.',
    exampleRu: 'Обогреватель 2 кВт, включённый на час, съедает 2 кВт·ч. '
        'Мощность у него всё время одна, а энергия набегает со временем.',
    exampleEn: 'A 2 kW heater running for an hour uses 2 kWh: the power is '
        'constant, the energy accumulates.',
    quiz: [
      QuizQuestion(
        questionRu: 'Сколько мощности берёт нагрузка при 230 В и 5 А?',
        questionEn: 'What power does a load take at 230 V and 5 A?',
        optionsRu: ['46 Вт', '235 Вт', '1150 Вт', '1150 кВт'],
        optionsEn: ['46 W', '235 W', '1150 W', '1150 kW'],
        correctIndex: 2,
        explanationRu: 'P = U · I = 230 · 5 = 1150 Вт для активной нагрузки.',
        explanationEn: 'P = U · I = 230 · 5 = 1150 W for a resistive load.',
      ),
      QuizQuestion(
        questionRu: 'Что считает электрический счётчик?',
        questionEn: 'What does the electricity meter count?',
        optionsRu: ['Ватты', 'Киловатт-часы', 'Амперы', 'Вольты'],
        optionsEn: ['Watts', 'Kilowatt-hours', 'Amperes', 'Volts'],
        correctIndex: 1,
        explanationRu: 'Счётчик считает энергию — киловатт-часы. Ватт — это '
            'мощность в данный момент.',
        explanationEn: 'The meter counts energy in kilowatt-hours; the watt '
            'is power at an instant.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_ac_dc',
    level: 1,
    titleRu: 'Постоянный и переменный ток',
    titleEn: 'Direct and alternating current',
    explanationRu: 'Постоянный ток течёт в одну сторону — так работает '
        'батарейка. Переменный меняет направление пятьдесят раз в секунду, и '
        'именно он приходит в дом: его удобно передавать на расстояние и '
        'преобразовывать трансформатором.',
    explanationEn: 'Direct current flows one way, as from a battery. '
        'Alternating current reverses fifty times a second and is what '
        'reaches the home: it travels well and transforms easily.',
    exampleRu: 'Блок питания ноутбука принимает переменные 230 В и отдаёт '
        'постоянные 19 В. Внутри прибора почти всегда постоянный ток.',
    exampleEn: 'A laptop supply takes 230 V AC and gives 19 V DC; inside the '
        'device the current is almost always direct.',
    quiz: [
      QuizQuestion(
        questionRu: 'Какая частота у сети в России?',
        questionEn: 'What is the mains frequency in Russia?',
        optionsRu: ['50 Гц', '60 Гц', '100 Гц', 'Частоты нет'],
        optionsEn: ['50 Hz', '60 Hz', '100 Hz', 'There is none'],
        correctIndex: 0,
        explanationRu: 'Пятьдесят герц — пятьдесят перемен направления в '
            'секунду.',
        explanationEn: 'Fifty hertz means fifty reversals per second.',
      ),
      QuizQuestion(
        questionRu: 'Почему в сеть подают переменный ток?',
        questionEn: 'Why is alternating current used in the grid?',
        optionsRu: [
          'Он безопаснее',
          'Его удобно передавать и преобразовывать',
          'Он дешевле в производстве',
          'Он не греет провода',
        ],
        optionsEn: [
          'It is safer',
          'It travels and transforms easily',
          'It is cheaper to make',
          'It does not heat wires',
        ],
        correctIndex: 1,
        explanationRu: 'Трансформатор поднимает и понижает переменное '
            'напряжение, а это делает передачу на расстояние выгодной. '
            'Безопаснее переменный ток не становится.',
        explanationEn: 'Transformers step alternating voltage up and down, '
            'which makes long-distance transmission viable. It is no safer.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_units',
    level: 1,
    titleRu: 'Единицы измерения',
    titleEn: 'Units of measurement',
    explanationRu: 'Четыре единицы держат всю электрику: вольт для '
        'напряжения, ампер для тока, ом для сопротивления, ватт для '
        'мощности. Пятая — герц — описывает частоту. Определение каждой '
        'лежит в словаре учебника.',
    explanationEn: 'Four units carry electrical work: volt, ampere, ohm and '
        'watt, with the hertz for frequency. Each is defined in the '
        'glossary.',
    exampleRu: 'Приставки означают множитель: милли — тысячная доля, кило — '
        'тысяча. Уставка УЗО 30 мА — это 0,03 А, а ввод 15 кВт — это '
        '15 000 Вт.',
    exampleEn: 'Prefixes are multipliers: milli is a thousandth, kilo a '
        'thousand. An RCD set to 30 mA is 0.03 A; a 15 kW supply is '
        '15 000 W.',
    quiz: [
      QuizQuestion(
        questionRu: 'Сколько ампер в 30 миллиамперах?',
        questionEn: 'How many amperes are 30 milliamperes?',
        optionsRu: ['0,03 А', '0,3 А', '3 А', '30 000 А'],
        optionsEn: ['0.03 A', '0.3 A', '3 A', '30 000 A'],
        correctIndex: 0,
        explanationRu: 'Милли — одна тысячная: 30 мА = 0,03 А. Это '
            'обычная уставка УЗО.',
        explanationEn: 'Milli is one thousandth: 30 mA = 0.03 A, a common '
            'RCD setting.',
      ),
      QuizQuestion(
        questionRu: 'В чём измеряют сопротивление изоляции?',
        questionEn: 'In what is insulation resistance measured?',
        optionsRu: ['В омах', 'В мегаомах', 'В ваттах', 'В вольтах'],
        optionsEn: ['Ohms', 'Megohms', 'Watts', 'Volts'],
        correctIndex: 1,
        explanationRu: 'Исправная изоляция сопротивляется миллионами ом, '
            'поэтому её меряют мегаомметром в мегаомах.',
        explanationEn: 'Sound insulation resists in millions of ohms, so it '
            'is measured in megohms.',
      ),
    ],
  ),
];

/// Темы одного уровня.
List<LearningTopic> topicsOfLevel(int level) =>
    [for (final topic in learningTopics) if (topic.level == level) topic];

/// Доля изученного, от 0 до 1.
double learningProgress(Set<String> passedIds) => learningTopics.isEmpty
    ? 0
    : passedIds.where(_isKnownTopic).length / learningTopics.length;

bool _isKnownTopic(String id) =>
    learningTopics.any((topic) => topic.id == id);
