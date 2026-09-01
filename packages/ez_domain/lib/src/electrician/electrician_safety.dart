/// Электробезопасность.
///
/// Опирается на Правила по охране труда при эксплуатации электроустановок —
/// приказ Минтруда России от 15.12.2020 № 903н в редакции от 29.04.2025.
/// Полный текст правил доступен по подписке, поэтому карточки этого раздела
/// помечены как несверенные: порядок действий описан по общепринятой
/// практике, а не выверен по тексту пункта. Снять пометку должен человек с
/// документом.
///
/// Раздел нарочно не учит выполнять работы под напряжением и не заменяет
/// обучение и группу по электробезопасности.
library;

import 'electrician_card.dart';

const _rules = 'Приказ Минтруда России от 15.12.2020 № 903н';
const _rulesEdition = 'Приказ Минтруда № 903н, редакция от 29.04.2025';

const electricianSafety = <ElectricianCard>[
  ElectricianCard(
    id: 'safety_preparation',
    section: ElectricianSection.safety,
    titleRu: 'Подготовка рабочего места',
    titleEn: 'Preparing the workplace',
    whatRu: 'Последовательность действий, после которой на месте работы '
        'гарантированно нет напряжения: отключить питание, принять меры '
        'против ошибочного или самопроизвольного включения, вывесить '
        'запрещающие плакаты, проверить отсутствие напряжения, установить '
        'заземление там, где оно требуется, и оградить рабочее место.',
    whatEn: 'The sequence that leaves the workplace provably dead: '
        'disconnect, prevent accidental re-energising, post prohibition '
        'signs, verify the absence of voltage, apply earthing where '
        'required, and fence off the workplace.',
    purpose: 'Порядок нужен целиком и в этом порядке. Каждый шаг закрывает '
        'свой способ получить напряжение обратно: чужую руку на автомате, '
        'вторую линию питания, ошибку в определении нужной цепи.',
    caution: 'Шаги нельзя менять местами и нельзя пропускать. Отключить и '
        'сразу работать — самая частая причина поражения: линия могла быть '
        'запитана с другой стороны, а автомат — оказаться не тем.',
    source: _rules,
    edition: _rulesEdition,
    aliases: ['отключение', 'плакаты', 'заземление', 'допуск'],
  ),
  ElectricianCard(
    id: 'safety_voltage_check',
    section: ElectricianSection.safety,
    titleRu: 'Проверка отсутствия напряжения',
    titleEn: 'Verifying the absence of voltage',
    whatRu: 'Проверка указателем напряжения на всех жилах и между всеми '
        'сочетаниями проводников, а не только между фазой и нулём.',
    whatEn: 'A check with a voltage detector on every conductor and every '
        'combination of them, not only between line and neutral.',
    purpose: 'Проверка отвечает на единственный вопрос: снято ли напряжение '
        'именно здесь и сейчас. Ответ на него не даёт ни положение автомата, '
        'ни погасшая лампа.',
    caution: 'Исправность самого указателя проверяют до и после проверки — '
        'на заведомо находящейся под напряжением части. Однополюсный '
        'индикатор-отвёртка для этого не годится: он показывает наличие '
        'фазы, но его молчание ничего не доказывает.',
    source: _rules,
    edition: _rulesEdition,
    aliases: ['указатель напряжения', 'индикатор', 'прозвонка'],
  ),
  ElectricianCard(
    id: 'safety_protective_equipment',
    section: ElectricianSection.safety,
    titleRu: 'Средства защиты',
    titleEn: 'Protective equipment',
    whatRu: 'Диэлектрические перчатки, изолированный инструмент, защитные '
        'очки, диэлектрический коврик и указатель напряжения — то, чем '
        'работают в электроустановке.',
    whatEn: 'Insulating gloves, insulated tools, eye protection, an '
        'insulating mat and a voltage detector — the equipment used when '
        'working on an installation.',
    purpose: 'Средства защиты рассчитаны на конкретное напряжение и имеют '
        'срок испытания. Годность подтверждается штампом, а не внешним '
        'видом.',
    caution: 'Перчатки с проколом, коврик с трещиной и инструмент с '
        'повреждённой изоляцией не защищают, а создают ложное чувство '
        'безопасности. Просроченные средства защиты равны их отсутствию.',
    source: _rules,
    edition: _rulesEdition,
    aliases: ['перчатки', 'коврик', 'очки', 'СИЗ'],
  ),
  ElectricianCard(
    id: 'safety_stop_work',
    section: ElectricianSection.safety,
    titleRu: 'Когда работу нужно прекратить',
    titleEn: 'When to stop work',
    whatRu: 'Признаки, при которых работу останавливают и зовут '
        'квалифицированного специалиста: открытые токоведущие части, '
        'повреждённая изоляция, следы перегрева и копоти, запах гари, '
        'искрение, повреждённое оборудование, вода на электроустановке и '
        'неизвестная схема проводки.',
    whatEn: 'Signs that mean stopping and calling a qualified electrician: '
        'exposed live parts, damaged insulation, overheating marks, a burnt '
        'smell, arcing, damaged equipment, water on the installation and '
        'unknown wiring.',
    purpose: 'Каждый из признаков говорит, что установка уже вышла за '
        'пределы исправного состояния и ведёт себя непредсказуемо.',
    caution: 'Неизвестная схема проводки — тоже причина остановиться. Пока '
        'неизвестно, откуда запитана линия, ни один способ проверки не даёт '
        'уверенности, что она обесточена целиком.',
    source: _rules,
    edition: _rulesEdition,
    aliases: ['опасность', 'гарь', 'искрение', 'перегрев', 'вода'],
  ),
  ElectricianCard(
    id: 'safety_scope',
    section: ElectricianSection.safety,
    titleRu: 'Чего это приложение не заменяет',
    titleEn: 'What this app does not replace',
    whatRu: 'Справочник объясняет устройство и понятия. Он не даёт допуска к '
        'работам, не заменяет обучение, группу по электробезопасности и '
        'проект электроустановки.',
    whatEn: 'This reference explains concepts and equipment. It grants no '
        'permit to work and replaces neither training, nor an electrical '
        'safety qualification, nor a design.',
    purpose: 'Понимание — первый шаг, но допуск к работе даёт обучение и '
        'проверка знаний, а не прочитанная карточка.',
    caution: 'Правильное решение почти всегда зависит от конкретной '
        'установки: от системы заземления, от схемы питания, от состояния '
        'проводки. Универсального ответа, годного для любой квартиры, здесь '
        'нет и быть не может.',
    source: _rules,
    edition: _rulesEdition,
    aliases: ['предупреждение', 'ответственность', 'допуск'],
  ),
];
