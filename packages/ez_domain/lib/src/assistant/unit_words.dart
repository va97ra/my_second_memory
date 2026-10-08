import '../tools/unit_converter.dart';
import '../language/russian_plural.dart';

/// Единица конвертера, названная словами.
class UnitWord {
  const UnitWord(
    this.category,
    this.unitId,
    this.stems, {
    required this.one,
    required this.few,
    required this.many,
  });

  final UnitCategory category;

  /// Ключ единицы в [UnitConverter.units].
  final String unitId;

  /// Как единицу называют: основы слов без окончаний.
  final String stems;

  /// «1 метр», «2 метра», «5 метров». Дробное число читается с [few]:
  /// «2,5 метра».
  final String one;
  final String few;
  final String many;

  String nameFor(double value) {
    if (value != value.roundToDouble()) return few;
    return russianPlural(value.toInt(), one, few, many);
  }
}

/// Таблица названий. Порядок важен: составные названия («километров в
/// час», «квадратных метров», «градусов Цельсия») идут раньше простых, иначе
/// в них нашёлся бы просто «метр».
const unitWords = [
  // Скорость.
  UnitWord(UnitCategory.speed, 'km_h', 'километр[а-я]*\\s+в\\s+час',
      one: 'километр в час', few: 'километра в час', many: 'километров в час'),
  UnitWord(UnitCategory.speed, 'm_s', 'метр[а-я]*\\s+в\\s+секунду',
      one: 'метр в секунду', few: 'метра в секунду', many: 'метров в секунду'),
  UnitWord(UnitCategory.speed, 'mph', 'мил[а-я]*\\s+в\\s+час',
      one: 'миля в час', few: 'мили в час', many: 'миль в час'),
  UnitWord(UnitCategory.speed, 'knot', 'узл[а-я]*|узел',
      one: 'узел', few: 'узла', many: 'узлов'),
  // Частота вращения.
  UnitWord(UnitCategory.frequency, 'rpm', 'оборот[а-я]*\\s+в\\s+минуту',
      one: 'оборот в минуту',
      few: 'оборота в минуту',
      many: 'оборотов в минуту'),
  // Площадь.
  UnitWord(UnitCategory.area, 'm2', 'квадратн[а-я]*\\s+метр[а-я]*',
      one: 'квадратный метр',
      few: 'квадратных метра',
      many: 'квадратных метров'),
  UnitWord(UnitCategory.area, 'km2', 'квадратн[а-я]*\\s+километр[а-я]*',
      one: 'квадратный километр',
      few: 'квадратных километра',
      many: 'квадратных километров'),
  UnitWord(UnitCategory.area, 'cm2', 'квадратн[а-я]*\\s+сантиметр[а-я]*',
      one: 'квадратный сантиметр',
      few: 'квадратных сантиметра',
      many: 'квадратных сантиметров'),
  UnitWord(UnitCategory.area, 'sotka', 'сот(?:к[а-я]*|ок)',
      one: 'сотка', few: 'сотки', many: 'соток'),
  UnitWord(UnitCategory.area, 'ha', 'гектар[а-я]*|га',
      one: 'гектар', few: 'гектара', many: 'гектаров'),
  UnitWord(UnitCategory.area, 'acre', 'акр[а-я]*',
      one: 'акр', few: 'акра', many: 'акров'),
  // Объём.
  UnitWord(UnitCategory.volume, 'm3',
      'кубическ[а-я]*\\s+метр[а-я]*|кубометр[а-я]*|куб(?:а|ов)?',
      one: 'кубометр', few: 'кубометра', many: 'кубометров'),
  UnitWord(UnitCategory.volume, 'ml', 'миллилитр[а-я]*|мл',
      one: 'миллилитр', few: 'миллилитра', many: 'миллилитров'),
  UnitWord(UnitCategory.volume, 'l', 'литр[а-я]*|л',
      one: 'литр', few: 'литра', many: 'литров'),
  UnitWord(UnitCategory.volume, 'gallon_us', 'галлон[а-я]*',
      one: 'галлон', few: 'галлона', many: 'галлонов'),
  UnitWord(UnitCategory.volume, 'barrel_oil', 'баррел[а-я]*',
      one: 'баррель', few: 'барреля', many: 'баррелей'),
  // Температура — раньше углов: «градусов Цельсия» не угол.
  UnitWord(UnitCategory.temperature, 'celsius',
      '(?:градус[а-я]*\\s+)?(?:по\\s+)?цельси[а-я]*',
      one: 'градус Цельсия', few: 'градуса Цельсия', many: 'градусов Цельсия'),
  UnitWord(UnitCategory.temperature, 'fahrenheit',
      '(?:градус[а-я]*\\s+)?(?:по\\s+)?фаренгейт[а-я]*',
      one: 'градус Фаренгейта',
      few: 'градуса Фаренгейта',
      many: 'градусов Фаренгейта'),
  UnitWord(UnitCategory.temperature, 'kelvin', 'кельвин[а-я]*',
      one: 'кельвин', few: 'кельвина', many: 'кельвинов'),
  // Давление.
  UnitWord(UnitCategory.pressure, 'mmhg',
      'миллиметр[а-я]*\\s+ртутн[а-я]*\\s+столба|мм\\s+рт\\.?\\s*ст\\.?',
      one: 'миллиметр ртутного столба',
      few: 'миллиметра ртутного столба',
      many: 'миллиметров ртутного столба'),
  UnitWord(UnitCategory.pressure, 'kpa', 'килопаскал[а-я]*',
      one: 'килопаскаль', few: 'килопаскаля', many: 'килопаскалей'),
  UnitWord(UnitCategory.pressure, 'mpa', 'мегапаскал[а-я]*',
      one: 'мегапаскаль', few: 'мегапаскаля', many: 'мегапаскалей'),
  UnitWord(UnitCategory.pressure, 'pa', 'паскал[а-я]*',
      one: 'паскаль', few: 'паскаля', many: 'паскалей'),
  UnitWord(UnitCategory.pressure, 'atm', 'атмосфер[а-я]*',
      one: 'атмосфера', few: 'атмосферы', many: 'атмосфер'),
  UnitWord(UnitCategory.pressure, 'bar', 'бар(?:а|ов)?',
      one: 'бар', few: 'бара', many: 'бар'),
  // Длина.
  UnitWord(UnitCategory.length, 'mm', 'миллиметр[а-я]*|мм',
      one: 'миллиметр', few: 'миллиметра', many: 'миллиметров'),
  UnitWord(UnitCategory.length, 'cm', 'сантиметр[а-я]*|см',
      one: 'сантиметр', few: 'сантиметра', many: 'сантиметров'),
  UnitWord(UnitCategory.length, 'km', 'километр[а-я]*|км',
      one: 'километр', few: 'километра', many: 'километров'),
  UnitWord(UnitCategory.length, 'm', 'метр[а-я]*|м',
      one: 'метр', few: 'метра', many: 'метров'),
  UnitWord(UnitCategory.length, 'inch', 'дюйм[а-я]*',
      one: 'дюйм', few: 'дюйма', many: 'дюймов'),
  UnitWord(UnitCategory.length, 'foot', 'фут(?:а|ов|ы)?',
      one: 'фут', few: 'фута', many: 'футов'),
  UnitWord(UnitCategory.length, 'yard', 'ярд[а-я]*',
      one: 'ярд', few: 'ярда', many: 'ярдов'),
  UnitWord(UnitCategory.length, 'mile', 'мил[яиюье]|миль|милях|милями',
      one: 'миля', few: 'мили', many: 'миль'),
  // Масса.
  UnitWord(UnitCategory.mass, 'mg', 'миллиграмм[а-я]*|мг',
      one: 'миллиграмм', few: 'миллиграмма', many: 'миллиграммов'),
  UnitWord(UnitCategory.mass, 'kg', 'килограмм[а-я]*|кило|кг',
      one: 'килограмм', few: 'килограмма', many: 'килограммов'),
  UnitWord(UnitCategory.mass, 'g', 'грамм[а-я]*|гр?',
      one: 'грамм', few: 'грамма', many: 'граммов'),
  UnitWord(UnitCategory.mass, 'centner', 'центнер[а-я]*',
      one: 'центнер', few: 'центнера', many: 'центнеров'),
  UnitWord(UnitCategory.mass, 't', 'тонн[а-я]*',
      one: 'тонна', few: 'тонны', many: 'тонн'),
  UnitWord(UnitCategory.mass, 'oz', 'унци[а-я]*',
      one: 'унция', few: 'унции', many: 'унций'),
  UnitWord(UnitCategory.mass, 'lb', 'фунт(?:а|ов|ы)?',
      one: 'фунт', few: 'фунта', many: 'фунтов'),
  // Мощность и энергия.
  UnitWord(UnitCategory.energy, 'kwh', 'киловатт[а-я]*[\\s-]*час[а-я]*',
      one: 'киловатт-час', few: 'киловатт-часа', many: 'киловатт-часов'),
  UnitWord(UnitCategory.energy, 'wh', 'ватт[а-я]*[\\s-]*час[а-я]*',
      one: 'ватт-час', few: 'ватт-часа', many: 'ватт-часов'),
  UnitWord(UnitCategory.power, 'hp_metric',
      'лошадин[а-я]*\\s+сил[а-я]*|л\\.?\\s*с\\.?',
      one: 'лошадиная сила', few: 'лошадиные силы', many: 'лошадиных сил'),
  UnitWord(UnitCategory.power, 'kw', 'киловатт[а-я]*|квт',
      one: 'киловатт', few: 'киловатта', many: 'киловатт'),
  UnitWord(UnitCategory.power, 'mw', 'мегаватт[а-я]*',
      one: 'мегаватт', few: 'мегаватта', many: 'мегаватт'),
  UnitWord(UnitCategory.power, 'w', 'ватт[а-я]*|вт',
      one: 'ватт', few: 'ватта', many: 'ватт'),
  UnitWord(UnitCategory.energy, 'kcal', 'килокалори[а-я]*|ккал',
      one: 'килокалория', few: 'килокалории', many: 'килокалорий'),
  UnitWord(UnitCategory.energy, 'cal', 'калори[а-я]*',
      one: 'калория', few: 'калории', many: 'калорий'),
  UnitWord(UnitCategory.energy, 'kj', 'килоджоул[а-я]*',
      one: 'килоджоуль', few: 'килоджоуля', many: 'килоджоулей'),
  UnitWord(UnitCategory.energy, 'j', 'джоул[а-я]*',
      one: 'джоуль', few: 'джоуля', many: 'джоулей'),
  // Время.
  UnitWord(UnitCategory.time, 'ms', 'миллисекунд[а-я]*',
      one: 'миллисекунда', few: 'миллисекунды', many: 'миллисекунд'),
  UnitWord(UnitCategory.time, 's', 'секунд[а-я]*',
      one: 'секунда', few: 'секунды', many: 'секунд'),
  UnitWord(UnitCategory.time, 'min', 'минут[а-я]*',
      one: 'минута', few: 'минуты', many: 'минут'),
  UnitWord(UnitCategory.time, 'h', 'час(?:а|ов|ах)?',
      one: 'час', few: 'часа', many: 'часов'),
  UnitWord(UnitCategory.time, 'day', 'сут(?:ки|ок|ках)|дн(?:я|ей|ях)|день',
      one: 'сутки', few: 'суток', many: 'суток'),
  UnitWord(UnitCategory.time, 'week', 'недел[а-я]*',
      one: 'неделя', few: 'недели', many: 'недель'),
  // Углы.
  UnitWord(UnitCategory.angle, 'radian', 'радиан[а-я]*',
      one: 'радиан', few: 'радиана', many: 'радиан'),
  UnitWord(UnitCategory.angle, 'degree', 'градус[а-я]*',
      one: 'градус', few: 'градуса', many: 'градусов'),
  // Информация.
  UnitWord(UnitCategory.data, 'kb', 'килобайт[а-я]*',
      one: 'килобайт', few: 'килобайта', many: 'килобайт'),
  UnitWord(UnitCategory.data, 'mb', 'мегабайт[а-я]*',
      one: 'мегабайт', few: 'мегабайта', many: 'мегабайт'),
  UnitWord(UnitCategory.data, 'gb', 'гигабайт[а-я]*|гиг[а-я]*',
      one: 'гигабайт', few: 'гигабайта', many: 'гигабайт'),
  UnitWord(UnitCategory.data, 'tb', 'терабайт[а-я]*',
      one: 'терабайт', few: 'терабайта', many: 'терабайт'),
  UnitWord(UnitCategory.data, 'byte', 'байт[а-я]*',
      one: 'байт', few: 'байта', many: 'байт'),
  UnitWord(UnitCategory.data, 'bit', 'бит(?:а|ов|ы)?',
      one: 'бит', few: 'бита', many: 'бит'),
  // Электричество.
  UnitWord(UnitCategory.voltage, 'kv', 'киловольт[а-я]*',
      one: 'киловольт', few: 'киловольта', many: 'киловольт'),
  UnitWord(UnitCategory.voltage, 'mv', 'милливольт[а-я]*',
      one: 'милливольт', few: 'милливольта', many: 'милливольт'),
  UnitWord(UnitCategory.voltage, 'v', 'вольт[а-я]*',
      one: 'вольт', few: 'вольта', many: 'вольт'),
  UnitWord(UnitCategory.current, 'ma', 'миллиампер[а-я]*',
      one: 'миллиампер', few: 'миллиампера', many: 'миллиампер'),
  UnitWord(UnitCategory.current, 'a', 'ампер[а-я]*',
      one: 'ампер', few: 'ампера', many: 'ампер'),
  UnitWord(UnitCategory.resistance, 'kohm', 'килоом[а-я]*',
      one: 'килоом', few: 'килоома', many: 'килоом'),
  UnitWord(UnitCategory.resistance, 'megohm', 'мегаом[а-я]*',
      one: 'мегаом', few: 'мегаома', many: 'мегаом'),
  UnitWord(UnitCategory.resistance, 'ohm', 'ом(?:а|ов|ы)?',
      one: 'ом', few: 'ома', many: 'ом'),
  UnitWord(UnitCategory.frequency, 'ghz', 'гигагерц[а-я]*',
      one: 'гигагерц', few: 'гигагерца', many: 'гигагерц'),
  UnitWord(UnitCategory.frequency, 'mhz', 'мегагерц[а-я]*',
      one: 'мегагерц', few: 'мегагерца', many: 'мегагерц'),
  UnitWord(UnitCategory.frequency, 'khz', 'килогерц[а-я]*',
      one: 'килогерц', few: 'килогерца', many: 'килогерц'),
  UnitWord(UnitCategory.frequency, 'hz', 'герц[а-я]*',
      one: 'герц', few: 'герца', many: 'герц'),
];
