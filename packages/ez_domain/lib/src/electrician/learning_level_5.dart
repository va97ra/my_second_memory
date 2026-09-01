/// Уровень 5: электроизмерения.
///
/// Уровень объясняет, что и чем меряют и где ошибаются. Он не учит работать
/// под напряжением: каждая тема исходит из того, что измерение делают либо
/// на обесточенной цепи, либо прибором, рассчитанным на эту работу, и
/// человеком, который имеет на неё право.
library;

import 'electrician_learning.dart';

const learningLevel5 = <LearningTopic>[
  LearningTopic(
    id: 'learn_multimeter',
    level: 5,
    titleRu: 'Мультиметр и его режимы',
    titleEn: 'The multimeter and its modes',
    explanationRu: 'Один прибор меряет разные величины, и режим выбирают '
        'переключателем. Напряжение меряют параллельно нагрузке, ток — '
        'включив прибор в разрыв цепи, сопротивление — только на '
        'обесточенном участке.',
    explanationEn: 'One instrument measures different quantities by a mode '
        'switch: voltage across the load, current in series with it, '
        'resistance only on a de-energised part.',
    exampleRu: 'Прибор, забытый в режиме измерения тока и подключённый к '
        'розетке, замыкает её через себя: внутри режима тока сопротивление '
        'почти нулевое.',
    exampleEn: 'An instrument left in current mode and put across a socket '
        'shorts it: in that mode its resistance is nearly zero.',
    quiz: [
      QuizQuestion(
        questionRu: 'Как включают мультиметр для измерения напряжения?',
        questionEn: 'How is a multimeter connected to measure voltage?',
        optionsRu: [
          'В разрыв цепи',
          'Параллельно участку',
          'Вместо нагрузки',
          'Последовательно с нагрузкой',
        ],
        optionsEn: [
          'In series with the circuit',
          'Across the section',
          'Instead of the load',
          'In series with the load',
        ],
        correctIndex: 1,
        explanationRu: 'Напряжение — разность между двумя точками, поэтому '
            'щупы ставят на эти две точки.',
        explanationEn: 'Voltage is a difference between two points, so the '
            'probes go on those two points.',
      ),
      QuizQuestion(
        questionRu: 'Когда меряют сопротивление?',
        questionEn: 'When is resistance measured?',
        optionsRu: [
          'Под напряжением',
          'На обесточенном участке',
          'В любой момент',
          'Только на новой проводке',
        ],
        optionsEn: [
          'While energised',
          'On a de-energised part',
          'Any time',
          'Only on new wiring',
        ],
        correctIndex: 1,
        explanationRu: 'Прибор сам подаёт для этого небольшое напряжение. '
            'Чужое напряжение в цепи испортит и измерение, и прибор.',
        explanationEn: 'The instrument supplies its own small voltage; an '
            'external one ruins both the reading and the meter.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_measure_voltage',
    level: 5,
    titleRu: 'Измерение напряжения',
    titleEn: 'Measuring voltage',
    explanationRu: 'Меряют между двумя точками и всегда называют, между '
        'какими: фаза и ноль, фаза и защитный проводник, две фазы. Одно '
        'число без пары точек ничего не значит.',
    explanationEn: 'Voltage is measured between two named points: line and '
        'neutral, line and earth, two lines. A number without the pair '
        'means nothing.',
    exampleRu: 'В розетке меряют между фазой и нулём, потом между фазой и '
        'защитным контактом. Если второе измерение показывает ноль, '
        'защитного проводника в розетке нет.',
    exampleEn: 'In a socket: line to neutral, then line to the earth pin. A '
        'zero on the second reading means the socket has no protective '
        'conductor.',
    quiz: [
      QuizQuestion(
        questionRu: 'О чём говорит ноль между фазой и защитным контактом '
            'розетки?',
        questionEn: 'What does zero between line and earth pin mean?',
        optionsRu: [
          'Всё исправно',
          'Защитного проводника нет или он не подключён',
          'Напряжение слишком мало',
          'Прибор сломан',
        ],
        optionsEn: [
          'All is well',
          'The protective conductor is missing or not connected',
          'The voltage is too low',
          'The meter is broken',
        ],
        correctIndex: 1,
        explanationRu: 'При исправном заземлении между фазой и PE то же '
            'напряжение, что между фазой и нулём.',
        explanationEn: 'With sound earthing, line to PE reads the same as '
            'line to neutral.',
      ),
      QuizQuestion(
        questionRu: 'Достаточно ли одного измерения фаза–ноль, чтобы снять '
            'напряжение и работать?',
        questionEn: 'Is one line-to-neutral reading enough before work?',
        optionsRu: [
          'Да',
          'Нет, проверяют все сочетания проводников',
          'Да, если прибор новый',
          'Да, если автомат выключен',
        ],
        optionsEn: [
          'Yes',
          'No, every combination is checked',
          'Yes, with a new meter',
          'Yes, if the breaker is off',
        ],
        correctIndex: 1,
        explanationRu: 'Проверяют на всех жилах и между всеми сочетаниями: '
            'напряжение может прийти со стороны, которую не проверили.',
        explanationEn: 'Every conductor and every pair is checked: voltage '
            'may arrive from the side you skipped.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_continuity',
    level: 5,
    titleRu: 'Прозвонка и сопротивление',
    titleEn: 'Continuity and resistance',
    explanationRu: 'Прозвонка отвечает на один вопрос: цела ли жила от одного '
        'конца до другого. Она ничего не говорит о состоянии изоляции — для '
        'изоляции нужен мегаомметр и высокое испытательное напряжение.',
    explanationEn: 'Continuity answers one question: is the core whole from '
        'end to end. It says nothing about insulation, which needs an '
        'insulation tester and a high test voltage.',
    exampleRu: 'Жила звонится, а линия всё равно выбивает УЗО: изоляция '
        'пробита на землю, и прозвонка этого не покажет.',
    exampleEn: 'A core rings through yet the RCD still trips: the '
        'insulation is breaking down to earth, which continuity cannot see.',
    quiz: [
      QuizQuestion(
        questionRu: 'Что показывает прозвонка?',
        questionEn: 'What does a continuity test show?',
        optionsRu: [
          'Состояние изоляции',
          'Целость проводника',
          'Ток нагрузки',
          'Наличие напряжения',
        ],
        optionsEn: [
          'The insulation state',
          'That the conductor is whole',
          'The load current',
          'The presence of voltage',
        ],
        correctIndex: 1,
        explanationRu: 'Только целость. Изоляцию проверяют мегаомметром.',
        explanationEn: 'Only continuity; insulation needs a dedicated '
            'tester.',
      ),
      QuizQuestion(
        questionRu: 'Чем меряют сопротивление изоляции?',
        questionEn: 'What measures insulation resistance?',
        optionsRu: [
          'Мультиметром',
          'Мегаомметром',
          'Токовыми клещами',
          'Указателем напряжения',
        ],
        optionsEn: [
          'A multimeter',
          'An insulation tester',
          'A clamp meter',
          'A voltage detector',
        ],
        correctIndex: 1,
        explanationRu: 'Мегаомметром: он подаёт высокое испытательное '
            'напряжение, которого нет у мультиметра.',
        explanationEn: 'An insulation tester: it applies the high test '
            'voltage a multimeter has not got.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_measure_mistakes',
    level: 5,
    titleRu: 'Типичные ошибки при измерениях',
    titleEn: 'Common measurement mistakes',
    explanationRu: 'Ошибки повторяются из раза в раз: забытый режим тока, '
        'непроверенный прибор, измерение одной пары проводников вместо всех, '
        'вера в положение автомата вместо проверки, работа прибором не той '
        'категории.',
    explanationEn: 'The same mistakes recur: the current mode left on, an '
        'unverified instrument, one pair measured instead of all, trust in '
        'the breaker position, and a meter of the wrong category.',
    exampleRu: 'Указатель напряжения проверяют на заведомо живой части до '
        'работы и после неё. Иначе его молчание может означать не '
        'отсутствие напряжения, а севшую батарейку.',
    exampleEn: 'A voltage detector is verified on a known live part before '
        'and after: otherwise its silence may mean a dead battery, not a '
        'dead circuit.',
    quiz: [
      QuizQuestion(
        questionRu: 'Почему указатель проверяют дважды — до и после?',
        questionEn: 'Why is the detector verified before and after?',
        optionsRu: [
          'Так дольше служит батарейка',
          'Чтобы знать, что он был исправен всё время проверки',
          'Этого не требуется',
          'Чтобы прогреть прибор',
        ],
        optionsEn: [
          'It saves the battery',
          'To know it worked throughout the check',
          'It is not required',
          'To warm the meter up',
        ],
        correctIndex: 1,
        explanationRu: 'Прибор мог отказать между двумя измерениями, и тогда '
            'его молчание ничего не значило.',
        explanationEn: 'It may fail between readings, and then its silence '
            'meant nothing.',
      ),
      QuizQuestion(
        questionRu: 'Что означает надпись о категории измерений на приборе?',
        questionEn: 'What does the measurement category on a meter mean?',
        optionsRu: [
          'Точность прибора',
          'В каких цепях им можно работать',
          'Гарантийный срок',
          'Класс защиты корпуса',
        ],
        optionsEn: [
          'Its accuracy',
          'Which circuits it may be used in',
          'The warranty',
          'The enclosure rating',
        ],
        correctIndex: 1,
        explanationRu: 'Категория говорит, к каким цепям прибор рассчитан. '
            'Прибор не той категории может не выдержать всплеск напряжения.',
        explanationEn: 'The category states the circuits it is built for; a '
            'lower one may not survive a transient.',
      ),
    ],
  ),
];
