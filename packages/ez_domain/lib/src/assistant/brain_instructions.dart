import '../finance/finance_entry.dart';
import '../memory/memory_item.dart';
import '../recurrence/recurrence_series.dart';
import 'address_phrases.dart';
import 'russian_numbers.dart';
import 'russian_words.dart';
import 'spoken_moments.dart';

/// Инструкция для нейросети на этот момент: кто она, какое сегодня число и
/// ближайшие дни — без календаря в голове «в пятницу» не превратить в дату.
String jarvisBrainInstructions(DateTime now, {List<String> facts = const []}) {
  final today = DateTime(now.year, now.month, now.day);
  final monday =
      DateTime(today.year, today.month, today.day - today.weekday + 1);
  final sunday = DateTime(monday.year, monday.month, monday.day + 6);
  final nextMonday = DateTime(monday.year, monday.month, monday.day + 7);
  final nextSunday = DateTime(monday.year, monday.month, monday.day + 13);
  // День недели нейросеть сама высчитывает с ошибками («четверг, 6
  // октября»), поэтому каждый день назван готовым: число, день недели,
  // месяц — от понедельника этой недели и на две недели вперёд.
  final days = StringBuffer();
  for (var day = monday;
      !day.isAfter(nextSunday);
      day = DateTime(day.year, day.month, day.day + 1)) {
    final offset = day.difference(today).inDays;
    final label = switch (offset) {
      0 => ' (сегодня)',
      1 => ' (завтра)',
      2 => ' (послезавтра)',
      < 0 => ' (прошёл)',
      _ => '',
    };
    days.writeln('- ${_isoDate(day)} — ${_dayName(day)}$label');
  }
  final time = '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}';
  final known = facts.isEmpty
      ? ''
      : 'Что хозяин просил тебя запомнить:\n'
          '${facts.map((fact) => '- $fact').join('\n')}\n'
          'Пользуйся этим: город для погоды, имена близких и прочее бери '
          'отсюда, если хозяин их не назвал.\n';
  return '''
Ты — Джарвис, дворецкий своего хозяина в приложении «Ежедневник»: календарь, записи, записки, финансы, графики смен, настройки.
Ты говоришь только со своим хозяином: обращайся к нему «сэр», говори ему «вы». Никогда не называй его «пользователь».
Отвечай по-русски, живо и по-человечески — как умный собеседник, а не справочник. Длину подбирай под вопрос: на простой вопрос — одно-два предложения; когда просят рассказать, объяснить, пересказать новости или просто болтают — рассказывай подробно и связно, до семи-восьми предложений. Без списков, эмодзи и разметки: ответ прочитают вслух.

Сейчас: ${_dayName(today)} ${today.year} года, $time.
Эта неделя — с понедельника ${_date(monday)} по воскресенье ${_date(sunday)}; следующая — с понедельника ${_date(nextMonday)} по воскресенье ${_date(nextSunday)}.
Дни:
$days
Дни недели и числа бери только из этого списка, сам их не высчитывай. Число без месяца («на 12 число», «12-го») — ближайшее такое: в этом месяце, а если оно уже прошло — в следующем. «Завтра», «послезавтра», дни недели бери отсюда и не переспрашивай месяц и год. Дальние даты пиши как ГГГГ-ММ-ДД, а день недели для них бери из ответа list_days.
$known

Записи хозяина хранятся в приложении, сам ты их не помнишь, но видишь всё приложение — смотри, прежде чем отвечать: любой день календаря с делами, сменами и праздниками — list_days; записи и записки по словам — find_records; записки без даты — list_notes; архив — list_archive; деньги — list_finance; что сейчас у хозяина на экране — look_at_screen; настройки — get_settings, поменять — change_setting; будильники — run_command «какие у меня будильники». Закрыта тебе только вкладка «Аккаунты»: там пароли.
1. Хозяин говорит свободно, длинно, с оговорками — дослушай всё и разложи сам, без наводящих вопросов. Дела, планы, встречи — create_record, по одному вызову на дело; адрес, что сделать, срочность и сколько займёт — в поля, а не в название. Мысль или дело без дня — create_record без даты (записка). Покупка, трата, оплата — add_finance расходом; деньги, пришедшие хозяину, — доходом. Поменять, перенести, отметить, дописать, напомнить, повторять или перестать, убрать в архив — update_record по id из list_days или find_records. Открыть страницу — open_page. Остальное — run_command короткой командой. Не говори, что сделал, пока не вызвал функцию; перескажи своими словами её результат.
Спрашивай, только если без ответа никак — например, не ясно, на какой день; время не названо — записывай без времени. Обычный разговор, рассказ, новости и вопросы — не дела: не записывай их. Не понял, о чём речь, — переспроси по сути.
2. На любой вопрос о делах, планах, работе и свободном времени сначала вызови list_days за нужные дни или find_records по словам — без этого не отвечай. У хозяина работа по графикам смен: день со сменой — рабочий, даже если это суббота. Свободный день — без смен и без записей. Не выдумывай записей, которых нет в ответе функции.
Рассказывая о днях, не перечисляй всё подряд одной кучей: сначала смена, потом дела по времени, затем задачи без времени, отдельно — дни рождения, годовщины и праздники. Дел много — скажи, сколько их, и начни с главного.
Прошлое тоже спрашивай у list_days: там видно, что сделано (done), а что нет; за полгода — несколькими вызовами по шесть недель. Важнее те дела, где стоит будильник (alarm) или напоминание (reminder), есть время и слова вроде «срочно», «оплатить», «врач», «документы»; просят главное — начни с него.
Деньги — только list_finance: это журнал «Финансы» Ежедневника, туда записи попадают голосом и из уведомлений банков. В приложения банков ты не заходишь. Записать деньги — add_finance: покупка, трата, оплата — всегда expense («морковь и сигареты на 500» — расход 500, статья «Морковь и сигареты»); income — только деньги, пришедшие хозяину: зарплата, перевод ему, возврат.
3. Курс валют, счёт, перевод величин, смены, праздники и будильники — тоже run_command: «курс доллара», «сколько будет 25 на 4», «я завтра работаю», «какие у меня будильники». Калькулятор Ежедневника — тоже: посчитанное стоит на нём, и дальше можно «прибавь 10», «умножь на 3», «сохрани в память», «очисти калькулятор»; сам не считай — считает калькулятор. Конвертер величин — так же: «переведи 5 футов в метры», потом «а в сантиметрах?», «а если 10?», «поменяй местами». Телефон — тоже: «включи фонарик», «разбуди меня в 6:30», «таймер на 10 минут», «позвони маме», «напиши Васе в ватсап, что опоздаю», «открой камеру». Звонок и сообщение не уходят сами — хозяин нажимает «Вызов» или «Отправить».
4. Из интернета: погода — get_weather, справка о людях, фильмах, книгах, местах и понятиях — wiki_lookup, новости — get_news. Не выдумывай погоду и новости. Коротко назови источник («по данным MET Norway»). Если функция вернула ошибку — скажи об этом или сделай, как она советует; справка недоступна — ответь по памяти и предупреди, что это по памяти.
5. Пароли, логины и PIN-код не трогай и не спрашивай: это хозяин делает сам.
6. На обычные вопросы, советы, объяснения и просьбы написать текст отвечай сам, по делу и столько, сколько нужно для ответа.
7. Если просьба непонятна, задай один короткий уточняющий вопрос.
8. Просит запомнить что-то о себе — remember_fact; забыть — forget_fact. Пароли и коды не запоминай.
9. Адрес дела — поле address. Спросили, как туда попасть, — run_command «как доехать до …»: карты телефона проложат маршрут, а ты коротко скажи, куда и когда выезжать, чтобы успеть.
Стиль: учтивый английский дворецкий с тёплым, суховатым юмором. Живой и внимательный: поддерживай разговор, можешь сам что-то уточнить или предложить, но без навязчивости. Обращайся «сэр» — естественно, не в каждой фразе.''';
}

/// День так, как его видит нейросеть: записи, смены по графикам и
/// праздники вместе — «свободный день» иначе не понять.
Map<String, Object?> dayForBrain(
  DateTime day, {
  required List<MemoryItem> records,
  required List<String> shifts,
  required List<String> holidays,
  required bool hasShiftSchedules,
}) =>
    {
      'date': _isoDate(day),
      'day': _dayName(day),
      if (day.weekday >= DateTime.saturday) 'weekend': true,
      if (hasShiftSchedules)
        'shifts': shifts.isEmpty ? 'выходной по графикам' : shifts,
      if (holidays.isNotEmpty) 'holidays': holidays,
      'records': [for (final item in records) recordForBrain(item)],
    };

/// Запись так, как её видит нейросеть: день — словами, чтобы ей не
/// пришлось высчитывать день недели самой. [textLimit] — сколько текста
/// записи показать: в обзоре дней — начало, у записок и архива — весь.
Map<String, Object?> recordForBrain(MemoryItem item, {int textLimit = 200}) => {
      // По номеру нейросеть правит запись: update_record.
      'id': item.id,
      'title': item.title,
      if (!item.isUndated) 'date': _isoDate(item.memoryDate),
      if (!item.isUndated) 'day': _dayName(item.memoryDate),
      if (item.timeMinutes != null) 'time': spokenClock(item.timeMinutes!),
      if (item.endMinutes != null) 'until': spokenClock(item.endMinutes!),
      // Одинаковые записи по месяцам — один повтор, а не много дел.
      if (_repeatOf(item) case final repeat?) 'repeat': repeat,
      if (item.isDone) 'done': true,
      if (item.isArchived) 'archived': true,
      if (item.isUndated) 'note': true,
      if (recordAddress(item) case final address?) 'address': address,
      if (item.priority > 0) 'urgent': true,
      if (item.reminderSoundUri != null) 'alarm': true,
      if (item.remindAt != null) 'reminder': true,
      if (_textOf(item, textLimit) case final text?) 'text': text,
    };

String? _repeatOf(MemoryItem item) =>
    switch (RecurrenceFrequency.values.asNameMap()[item.repeatRule]) {
      RecurrenceFrequency.monthly => 'каждый месяц',
      RecurrenceFrequency.yearly => 'каждый год',
      null => null,
    };

/// Текст записи, если он не повторяет заголовок: не длиннее [limit].
String? _textOf(MemoryItem item, int limit) {
  final body = item.plainBody.trim();
  if (body.isEmpty || body == item.title.trim()) return null;
  return body.length <= limit ? body : '${body.substring(0, limit)}…';
}

/// Ответ нейросети без разметки: его читают вслух.
///
/// Длину задаёт инструкция, а не обрезка: рассказ — до семи-восьми
/// предложений. Если ответ оборвал лимит токенов ([cut]), недоговорённое
/// предложение отбрасывается — вслух не читается полуслово.
String cleanBrainReply(String raw, {bool cut = false}) {
  var text = raw
      .replaceAll(RegExp(r'<[^>]{1,40}>'), ' ')
      .replaceAll(RegExp(r'[*_#`>|]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cut) {
    // Конец предложения — знак, за которым пробел или конец текста:
    // точка в «2.5» предложение не заканчивает.
    final end = RegExp(r'[.!?…](?=\s|$)').allMatches(text).lastOrNull;
    text = end == null ? '$text…' : text.substring(0, end.end);
  }
  return capitalizeFirst(text);
}

/// Дата из ответа нейросети: `YYYY-MM-DD`.
DateTime? parseBrainDate(Object? value) {
  final match =
      RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch('${value ?? ''}'.trim());
  if (match == null) return null;
  final date = DateTime(int.parse(match.group(1)!), int.parse(match.group(2)!),
      int.parse(match.group(3)!));
  return date.month == int.parse(match.group(2)!) ? date : null;
}

/// «четверг, 8 октября».
String _dayName(DateTime day) => '${_weekdays[day.weekday - 1]}, ${_date(day)}';

/// «8 октября».
String _date(DateTime day) => '${day.day} ${monthsGenitive[day.month - 1]}';

String _isoDate(DateTime day) => '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

const _weekdays = [
  'понедельник',
  'вторник',
  'среда',
  'четверг',
  'пятница',
  'суббота',
  'воскресенье',
];

/// Деньги для нейросети: записи журнала за период и итоги. Не больше
/// восьмидесяти записей за раз — ответ читается целиком.
Map<String, Object?> financeForBrain(
  List<FinanceEntry> entries, {
  required DateTime from,
  required DateTime to,
}) {
  final found = [
    for (final entry in entries)
      if (!entry.occurredOn.isBefore(from) &&
          !DateTime(entry.occurredOn.year, entry.occurredOn.month,
                  entry.occurredOn.day)
              .isAfter(to))
        entry,
  ]..sort((left, right) => left.occurredOn.compareTo(right.occurredOn));
  final totals = <String, double>{};
  for (final entry in found) {
    final key =
        '${entry.kind == FinanceEntryKind.expense ? 'расходы' : 'доходы'}'
        ' ${entry.currencyCode}';
    totals[key] = (totals[key] ?? 0) + (double.tryParse(entry.amount) ?? 0);
  }
  return {
    'entries': [
      for (final entry in found.take(80))
        {
          'date': _isoDate(entry.occurredOn),
          'kind': entry.kind == FinanceEntryKind.expense ? 'расход' : 'доход',
          'amount': entry.amount,
          'currency': entry.currencyCode,
          'category': entry.category,
        },
    ],
    if (found.length > 80) 'more': found.length - 80,
    'totals': {
      for (final MapEntry(:key, :value) in totals.entries)
        key: value.toStringAsFixed(2),
    },
  };
}
