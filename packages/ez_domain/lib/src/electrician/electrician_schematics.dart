/// Условные обозначения на схемах и планах.
///
/// Начертания взяты по ГОСТ 21.614-88 «Система проектной документации для
/// строительства. Изображения условные графические электрооборудования и
/// проводок на планах». Рисует их приложение, а не картинка из файла: имя
/// обозначения лежит в поле `symbol`, а перо — на экране.
///
/// Ни одно начертание не сверено по тексту стандарта: пометка снимается
/// вместе с изданием на столе.
library;

import 'electrician_card.dart';

const _plans = 'ГОСТ 21.614-88';

const electricianSchematics = <ElectricianCard>[
  ElectricianCard(
    id: 'symbol_line',
    section: ElectricianSection.schematics,
    symbol: 'line',
    titleRu: 'Фазный проводник L',
    titleEn: 'Line conductor L',
    whatRu: 'Линия проводки с одним косым штрихом: один фазный проводник в '
        'линии. Число штрихов показывает число проводников.',
    whatEn: 'A wiring line with one oblique stroke: a single line conductor. '
        'The number of strokes shows the number of conductors.',
    purpose: 'На плане по штрихам считают, сколько жил идёт по трассе, не '
        'заглядывая в спецификацию.',
    caution: 'Штрих обозначает проводник, а не кабель: три штриха могут быть '
        'и тремя одножильными проводами, и одним трёхжильным кабелем.',
    source: _plans,
    edition: _plans,
    aliases: ['L', 'фаза', 'штрих', 'проводка'],
  ),
  ElectricianCard(
    id: 'symbol_neutral',
    section: ElectricianSection.schematics,
    symbol: 'neutral',
    titleRu: 'Нулевой рабочий проводник N',
    titleEn: 'Neutral conductor N',
    whatRu: 'Та же линия проводки, но с двумя штрихами: фаза и рабочий ноль.',
    whatEn: 'The same wiring line with two strokes: line and neutral.',
    purpose: 'Двухпроводная линия — обычная линия освещения или розетки без '
        'защитного проводника.',
    caution: 'Линия без PE в новых установках не применяется: защитный '
        'проводник обязателен там, где есть открытые проводящие части.',
    source: _plans,
    edition: _plans,
    aliases: ['N', 'ноль', 'два провода'],
  ),
  ElectricianCard(
    id: 'symbol_pe',
    section: ElectricianSection.schematics,
    symbol: 'protectiveEarth',
    titleRu: 'Защитный проводник PE и заземление',
    titleEn: 'Protective earth PE',
    whatRu: 'Три горизонтальные черты убывающей длины под вертикальной '
        'линией — знак заземления.',
    whatEn: 'Three horizontal bars of decreasing length below a vertical '
        'line — the earthing symbol.',
    purpose: 'Знак показывает точку присоединения к заземляющему устройству '
        'или защитному проводнику.',
    caution: 'Знак заземления и знак корпуса — разные вещи. Присоединение к '
        'корпусу не заменяет присоединения к PE.',
    source: _plans,
    edition: _plans,
    aliases: ['PE', 'земля', 'заземление', 'зануление'],
  ),
  ElectricianCard(
    id: 'symbol_socket',
    section: ElectricianSection.schematics,
    symbol: 'socket',
    titleRu: 'Штепсельная розетка',
    titleEn: 'Socket outlet',
    whatRu: 'Полукруг на конце линии проводки, обращённый вверх.',
    whatEn: 'A half-circle at the end of a wiring line, facing upwards.',
    purpose: 'Показывает место установки розетки на плане помещения.',
    caution: 'Число розеток в блоке и наличие защитного контакта обозначение '
        'само по себе не передаёт — их указывают рядом.',
    source: _plans,
    edition: _plans,
    aliases: ['розетка', 'штепсель'],
  ),
  ElectricianCard(
    id: 'symbol_switch',
    section: ElectricianSection.schematics,
    symbol: 'switchOne',
    titleRu: 'Выключатель однополюсный',
    titleEn: 'Single-pole switch',
    whatRu: 'Точка на линии с отходящим наклонным штрихом — рычагом.',
    whatEn: 'A dot on the line with an oblique stroke standing for the lever.',
    purpose: 'Показывает место выключателя и то, что он разрывает один '
        'проводник.',
    caution: 'Выключатель ставят в фазный проводник. Разрыв нуля оставляет '
        'светильник под напряжением при выключенном свете.',
    source: _plans,
    edition: _plans,
    aliases: ['выключатель', 'клавиша'],
  ),
  ElectricianCard(
    id: 'symbol_lamp',
    section: ElectricianSection.schematics,
    symbol: 'lamp',
    titleRu: 'Светильник',
    titleEn: 'Luminaire',
    whatRu: 'Круг с двумя диагоналями.',
    whatEn: 'A circle crossed by two diagonals.',
    purpose: 'Обозначает светильник общего назначения на плане.',
    caution: 'Тип лампы и мощность знак не передаёт: их пишут рядом с '
        'обозначением.',
    source: _plans,
    edition: _plans,
    aliases: ['лампа', 'светильник', 'свет'],
  ),
  ElectricianCard(
    id: 'symbol_breaker',
    section: ElectricianSection.schematics,
    symbol: 'breaker',
    titleRu: 'Автоматический выключатель',
    titleEn: 'Circuit breaker',
    whatRu: 'Разомкнутый контакт с косым рычагом и крестом привода.',
    whatEn: 'An open contact with an oblique lever and a cross for the drive.',
    purpose: 'На однолинейной схеме щита показывает аппарат защиты линии.',
    caution: 'Номинал и характеристика расцепления не входят в знак: их '
        'подписывают, иначе схема не говорит, что защищает линию.',
    source: _plans,
    edition: _plans,
    aliases: ['автомат', 'АВ'],
  ),
  ElectricianCard(
    id: 'symbol_rcd',
    section: ElectricianSection.schematics,
    symbol: 'residualCurrentDevice',
    titleRu: 'УЗО',
    titleEn: 'Residual current device',
    whatRu: 'Два проводника, охваченные овалом дифференциального '
        'трансформатора.',
    whatEn: 'Two conductors encircled by the oval of the residual current '
        'transformer.',
    purpose: 'Показывает аппарат, который следит за разницей токов и '
        'отключает линию при утечке.',
    caution: 'Уставку по дифференциальному току подписывают рядом: 10, 30 и '
        '300 мА защищают от разного.',
    source: _plans,
    edition: _plans,
    aliases: ['УЗО', 'ВДТ', 'дифференциальный'],
  ),
  ElectricianCard(
    id: 'symbol_junction_box',
    section: ElectricianSection.schematics,
    symbol: 'junctionBox',
    titleRu: 'Распределительная коробка',
    titleEn: 'Junction box',
    whatRu: 'Круг с отходящими линиями по числу подходящих трасс.',
    whatEn: 'A circle with lines leaving it for each incoming route.',
    purpose: 'Место, где линии расходятся: соединения делают внутри коробки, '
        'а не в стене.',
    caution: 'Коробка должна оставаться доступной. Замурованное соединение '
        'нельзя ни осмотреть, ни подтянуть, а греется именно оно.',
    source: _plans,
    edition: _plans,
    aliases: ['коробка', 'распайка', 'соединение'],
  ),
  ElectricianCard(
    id: 'symbol_board',
    section: ElectricianSection.schematics,
    symbol: 'distributionBoard',
    titleRu: 'Щит распределительный',
    titleEn: 'Distribution board',
    whatRu: 'Вытянутый прямоугольник с закрашенной частью.',
    whatEn: 'An elongated rectangle with one part filled.',
    purpose: 'Показывает щит, из которого расходятся линии по помещениям.',
    caution: 'Схема щита — отдельный документ. План показывает, где щит '
        'стоит, но не что внутри него.',
    source: _plans,
    edition: _plans,
    aliases: ['щит', 'щиток', 'ВРУ'],
  ),
  ElectricianCard(
    id: 'symbol_joint',
    section: ElectricianSection.schematics,
    symbol: 'wireJoint',
    titleRu: 'Соединение проводников',
    titleEn: 'Conductor junction',
    whatRu: 'Точка на пересечении линий: проводники соединены.',
    whatEn: 'A dot at the crossing: the conductors are joined.',
    purpose: 'Отличает соединение от простого пересечения на чертеже.',
    caution: 'Точку ставят только там, где соединение есть на самом деле. '
        'Лишняя точка на схеме превращается в лишнюю скрутку в стене.',
    source: _plans,
    edition: _plans,
    aliases: ['точка', 'соединение', 'скрутка'],
  ),
  ElectricianCard(
    id: 'symbol_crossing',
    section: ElectricianSection.schematics,
    symbol: 'wireCrossing',
    titleRu: 'Пересечение без соединения',
    titleEn: 'Crossing without connection',
    whatRu: 'Линии пересекаются, точки нет — проводники идут мимо друг '
        'друга.',
    whatEn: 'Lines cross with no dot: the conductors simply pass each other.',
    purpose: 'Позволяет чертить плотные схемы, не путая трассы.',
    caution: 'Отсутствие точки — такая же информация, как её наличие. '
        'Читать схему нужно внимательно именно в этих местах.',
    source: _plans,
    edition: _plans,
    aliases: ['пересечение', 'без соединения'],
  ),
];
