/// Уровень 3: провода и кабели.
///
/// Что такое жила, изоляция и кабель, описано в разделе компонентов — здесь
/// это не повторяется. Уровень объясняет то, что решает на объекте: чем
/// провод отличается от кабеля, почему сечение выбирают не по одному току и
/// как читать маркировку.
///
/// Ни одна цифра допустимого тока здесь не называется: они лежат в таблицах
/// ПУЭ, которые в проекте ещё не сверены. Тема учит порядку выбора, а не
/// значениям.
library;

import 'electrician_learning.dart';

const learningLevel3 = <LearningTopic>[
  LearningTopic(
    id: 'learn_wire_vs_cable',
    level: 3,
    titleRu: 'Провод и кабель: в чём разница',
    titleEn: 'Wire and cable: the difference',
    explanationRu: 'У кабеля жилы лежат в общей оболочке, у провода её нет. '
        'Оболочка — это защита изоляции от повреждения и влаги, и именно она '
        'решает, где изделие можно прокладывать.',
    explanationEn: 'A cable has its cores in a common sheath; a wire does '
        'not. The sheath protects the insulation from damage and moisture, '
        'and it decides where the product may be installed.',
    exampleRu: 'ВВГнг 3×2,5 — кабель: три жилы в общей оболочке. ПВ-1 — '
        'провод: одна жила в изоляции, и в стену без трубы он не идёт.',
    exampleEn: 'A three-core sheathed cable goes into the wall; a single '
        'insulated wire does not, unless it runs in a conduit.',
    quiz: [
      QuizQuestion(
        questionRu: 'Что отличает кабель от провода?',
        questionEn: 'What distinguishes a cable from a wire?',
        optionsRu: [
          'Число жил',
          'Общая оболочка поверх изоляции',
          'Материал жилы',
          'Цвет изоляции',
        ],
        optionsEn: [
          'The number of cores',
          'A common sheath over the insulation',
          'The core material',
          'The insulation colour',
        ],
        correctIndex: 1,
        explanationRu: 'Оболочка. Кабель бывает и одножильным, а провод — '
            'многожильным, так что число жил ничего не решает.',
        explanationEn: 'The sheath. A cable may be single-core and a wire '
            'stranded, so the count decides nothing.',
      ),
      QuizQuestion(
        questionRu: 'Зачем кабелю оболочка?',
        questionEn: 'What is the sheath for?',
        optionsRu: [
          'Чтобы жилы не путались',
          'Для защиты изоляции от повреждения и влаги',
          'Чтобы уменьшить сопротивление',
          'Для красоты',
        ],
        optionsEn: [
          'To keep cores tidy',
          'To protect the insulation from damage and moisture',
          'To lower the resistance',
          'For looks',
        ],
        correctIndex: 1,
        explanationRu: 'Оболочка не проводит и не изолирует жилы друг от '
            'друга — она защищает то, что изолирует.',
        explanationEn: 'The sheath neither conducts nor insulates the cores '
            'from each other: it protects what does.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_section_choice',
    level: 3,
    titleRu: 'Почему сечение не выбирают по одному току',
    titleEn: 'Why current alone does not size a conductor',
    explanationRu: 'Ток — только первое условие. На выбор влияют материал '
        'жилы, способ прокладки, число кабелей рядом, температура, длина '
        'линии и падение напряжения на ней, а сверху — номинал защиты, '
        'который должен защищать именно провод.',
    explanationEn: 'Current is only the first condition. Material, '
        'installation method, grouping, temperature, run length, voltage '
        'drop and the protective device rating all matter, and the device '
        'must protect the conductor.',
    exampleRu: 'Одно и то же сечение в открытой прокладке несёт больше тока, '
        'чем в трубе: в тесноте жила хуже остывает. А на длинной линии '
        'сечение может определить не нагрев, а падение напряжения.',
    exampleEn: 'The same section carries more current in open air than in a '
        'conduit, and on a long run the voltage drop, not heating, may set '
        'the size.',
    quiz: [
      QuizQuestion(
        questionRu: 'Почему в трубе жила выдерживает меньший ток?',
        questionEn: 'Why does a conductor in a conduit carry less current?',
        optionsRu: [
          'Растёт сопротивление',
          'Хуже отводится тепло',
          'Труба экранирует',
          'Изоляция толще',
        ],
        optionsEn: [
          'Resistance rises',
          'Heat escapes worse',
          'The conduit shields it',
          'The insulation is thicker',
        ],
        correctIndex: 1,
        explanationRu: 'Допустимый ток задаётся нагревом. В трубе тепло '
            'уходит хуже, и тот же ток греет жилу сильнее.',
        explanationEn: 'The rating is set by heating; in a conduit the heat '
            'escapes worse and the same current runs hotter.',
      ),
      QuizQuestion(
        questionRu: 'Что защищает автоматический выключатель?',
        questionEn: 'What does the circuit breaker protect?',
        optionsRu: [
          'Подключённый прибор',
          'Провод линии',
          'Счётчик',
          'Человека от удара током',
        ],
        optionsEn: [
          'The connected device',
          'The line conductor',
          'The meter',
          'A person from shock',
        ],
        correctIndex: 1,
        explanationRu: 'Провод. Поэтому номинал выбирают по тому, что '
            'выдержит жила, а от удара током защищает УЗО.',
        explanationEn: 'The conductor. The rating follows what the wire can '
            'take; shock protection is the RCD job.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_cable_marking',
    level: 3,
    titleRu: 'Как читать маркировку кабеля',
    titleEn: 'Reading cable markings',
    explanationRu: 'Марка складывается из букв и чисел. Буквы говорят о '
        'материале жилы, изоляции и оболочки и о поведении в огне, числа — о '
        'количестве жил и сечении. Запись 3×2,5 означает три жилы по '
        '2,5 мм².',
    explanationEn: 'The type code combines letters and numbers: letters for '
        'the core, insulation and sheath materials and the fire behaviour, '
        'numbers for the core count and section. 3×2.5 means three cores of '
        '2.5 mm².',
    exampleRu: 'Индекс «нг» и буквы за ним говорят о поведении при пожаре: '
        'не распространяет горение, мало дымит, не выделяет галогенов. Для '
        'путей эвакуации это не украшение, а требование.',
    exampleEn: 'The flame-retardant index and the letters after it describe '
        'fire behaviour — on escape routes that is a requirement, not a '
        'decoration.',
    quiz: [
      QuizQuestion(
        questionRu: 'Что означает запись 3×2,5 в марке кабеля?',
        questionEn: 'What does 3×2.5 mean in a cable code?',
        optionsRu: [
          'Три метра сечением 2,5',
          'Три жилы по 2,5 мм²',
          'Сечение 7,5 мм²',
          'Три фазы по 2,5 А',
        ],
        optionsEn: [
          'Three metres of 2.5',
          'Three cores of 2.5 mm² each',
          'A 7.5 mm² section',
          'Three phases at 2.5 A',
        ],
        correctIndex: 1,
        explanationRu: 'Первое число — количество жил, второе — сечение '
            'каждой из них.',
        explanationEn: 'The first number is the core count, the second the '
            'section of each.',
      ),
      QuizQuestion(
        questionRu: 'О чём говорит индекс «нг» в марке?',
        questionEn: 'What does the flame-retardant index tell you?',
        optionsRu: [
          'О числе жил',
          'О поведении кабеля в огне',
          'О материале жилы',
          'О допустимом токе',
        ],
        optionsEn: [
          'The core count',
          'How the cable behaves in fire',
          'The core material',
          'The current rating',
        ],
        correctIndex: 1,
        explanationRu: 'Он о нераспространении горения. Буквы после него '
            'уточняют дымообразование и выделение галогенов.',
        explanationEn: 'It is about not spreading flame; the letters after '
            'it refine smoke and halogen behaviour.',
      ),
    ],
  ),
  LearningTopic(
    id: 'learn_cable_choice',
    level: 3,
    titleRu: 'Где какой кабель применяют',
    titleEn: 'Where each cable is used',
    explanationRu: 'Условия задают выбор: сухое помещение или влажное, скрытая '
        'проводка или открытая, жилая квартира или путь эвакуации, '
        'неподвижная линия или подвижное соединение. Под каждое сочетание '
        'существует своя марка.',
    explanationEn: 'Conditions drive the choice: dry or damp, concealed or '
        'surface, dwelling or escape route, fixed run or flexible '
        'connection. Each combination has its own type.',
    exampleRu: 'К переносному инструменту идёт гибкий провод с '
        'многопроволочной жилой, а в стену — кабель с жёсткой жилой в '
        'оболочке. Поменять их местами — значит либо сломать жилу изгибами, '
        'либо не суметь закрепить её в зажиме.',
    exampleEn: 'A portable tool needs a flexible stranded cord; a wall run '
        'needs a sheathed cable with solid cores. Swapping them breaks the '
        'core by flexing or fails in the terminal.',
    quiz: [
      QuizQuestion(
        questionRu: 'Какая жила подходит для подвижного соединения?',
        questionEn: 'Which core suits a flexible connection?',
        optionsRu: [
          'Однопроволочная жёсткая',
          'Многопроволочная гибкая',
          'Алюминиевая',
          'Любая',
        ],
        optionsEn: [
          'Solid and stiff',
          'Stranded and flexible',
          'Aluminium',
          'Any',
        ],
        correctIndex: 1,
        explanationRu: 'Жёсткая жила от изгибов ломается. Гибкую зажимают '
            'через наконечник.',
        explanationEn: 'A solid core breaks with flexing; a stranded one is '
            'terminated through a ferrule.',
      ),
      QuizQuestion(
        questionRu: 'Что решает выбор марки кабеля?',
        questionEn: 'What decides the cable type?',
        optionsRu: [
          'Цена',
          'Условия прокладки и требования к пожарной безопасности',
          'Цвет оболочки',
          'Наличие в магазине',
        ],
        optionsEn: [
          'Price',
          'Installation conditions and fire requirements',
          'Sheath colour',
          'What the shop has',
        ],
        correctIndex: 1,
        explanationRu: 'Марка — это ответ на условия. Подбирать её по цене '
            'или по наличию значит менять условия задним числом.',
        explanationEn: 'The type answers the conditions; choosing by price '
            'or stock changes the conditions after the fact.',
      ),
    ],
  ),
];
