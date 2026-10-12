import 'jarvis_command.dart';

/// Что нейросеть Джарвиса может вызвать.
///
/// Глаза — весь Ежедневник, кроме «Аккаунтов»: дни, записи с полным
/// текстом, записки, архив, деньги, страница на экране. Руки — точные
/// функции: завести и поправить запись, записать расход или доход, открыть
/// страницу; исполняют их те же руки, что и правила, с той же отменой.
/// Остальное — калькулятор, конвертер, телефон, настройки — [runCommand]:
/// короткая команда тем же правилам. Решение владельца 12 октября 2026: «он
/// должен понимать полностью весь блокнот и отвечать по нему, вообще всё».
abstract final class JarvisBrainFunctions {
  static const runCommand = 'run_command';
  static const listDays = 'list_days';
  static const findRecords = 'find_records';
  static const weather = 'get_weather';
  static const wikiLookup = 'wiki_lookup';
  static const news = 'get_news';
  static const listFinance = 'list_finance';
  static const rememberFact = 'remember_fact';
  static const forgetFact = 'forget_fact';
  static const createRecord = 'create_record';
  static const updateRecord = 'update_record';
  static const addFinance = 'add_finance';
  static const openPage = 'open_page';
  static const listNotes = 'list_notes';
  static const listArchive = 'list_archive';
  static const lookAtScreen = 'look_at_screen';
  static const getSettings = 'get_settings';
  static const changeSetting = 'change_setting';

  static final specs = <Map<String, Object?>>[
    {
      'name': runCommand,
      'description': 'Выполнить действие, для которого нет своей функции: '
          'калькулятор и конвертер Ежедневника, курс валют, смены, '
          'праздники, будильники Ежедневника, тема. И телефон: '
          'фонарик, будильник и таймер в «Часах», позвонить или написать '
          'контакту, открыть приложение, маршрут. Записи, деньги и страницы '
          '— своими функциями. Возвращает, что сделано.',
      'parameters': {
        'type': 'object',
        'properties': {
          'phrase': {
            'type': 'string',
            'description': 'Короткая команда по-русски, как сказал бы человек: '
                '«завтра в 10 врач», «перенеси врача на пятницу в 12», '
                '«отметь стоматолога сделанным», «открой финансы», «расход '
                '500 на такси», «курс доллара».',
          },
        },
        'required': ['phrase'],
      },
    },
    {
      'name': listDays,
      'description': 'Дни с from по to включительно: записи календаря, смены '
          'по графикам владельца, праздники, выходные. Нужна для любого '
          'вопроса о делах, планах, работе и свободном времени.',
      'parameters': {
        'type': 'object',
        'properties': {
          'from': {'type': 'string', 'description': 'Первый день, YYYY-MM-DD'},
          'to': {'type': 'string', 'description': 'Последний день, YYYY-MM-DD'},
        },
        'required': ['from', 'to'],
      },
    },
    {
      'name': findRecords,
      'description': 'Найти записи и записки по словам.',
      'parameters': {
        'type': 'object',
        'properties': {
          'query': {'type': 'string', 'description': 'Слова для поиска'},
        },
        'required': ['query'],
      },
    },
    {
      'name': weather,
      'description': 'Погода из интернета (MET Norway): на день и сейчас.',
      'parameters': {
        'type': 'object',
        'properties': {
          'place': {
            'type': 'string',
            'description': 'Город. Не назван — тот, что владелец называл '
                'раньше.',
          },
          'date': {
            'type': 'string',
            'description': 'День, YYYY-MM-DD. Не указан — сегодня.',
          },
        },
      },
    },
    {
      'name': wikiLookup,
      'description': 'Справка из русской Википедии: люди, фильмы, книги, '
          'места, понятия, события.',
      'parameters': {
        'type': 'object',
        'properties': {
          'query': {'type': 'string', 'description': 'Что найти'},
        },
        'required': ['query'],
      },
    },
    {
      'name': listFinance,
      'description': 'Расходы и доходы из журнала «Финансы» Ежедневника с '
          'from по to включительно: дата, вид, сумма, валюта, категория, и '
          'итоги. Только то, что записано в Ежедневнике.',
      'parameters': {
        'type': 'object',
        'properties': {
          'from': {'type': 'string', 'description': 'Первый день, YYYY-MM-DD'},
          'to': {'type': 'string', 'description': 'Последний день, YYYY-MM-DD'},
        },
        'required': ['from', 'to'],
      },
    },
    {
      'name': rememberFact,
      'description': 'Запомнить о хозяине то, что он просит запомнить: '
          'город, близких, привычки. Одна мысль — одним предложением.',
      'parameters': {
        'type': 'object',
        'properties': {
          'fact': {'type': 'string', 'description': 'Что запомнить'},
        },
        'required': ['fact'],
      },
    },
    {
      'name': forgetFact,
      'description': 'Забыть запомненное о хозяине.',
      'parameters': {
        'type': 'object',
        'properties': {
          'fact': {'type': 'string', 'description': 'Что забыть'},
        },
        'required': ['fact'],
      },
    },
    {
      'name': news,
      'description': 'Свежие заголовки новостей (ТАСС, РИА, Лента.ру).',
      'parameters': {
        'type': 'object',
        'properties': {
          'topic': {
            'type': 'string',
            'description': 'Тема, если спросили про что-то определённое',
          },
        },
      },
    },
    {
      'name': createRecord,
      'description': 'Завести запись в календарь или записку. Всё, что '
          'хозяин сказал о деле, клади в поля, а не в название: адрес — '
          'address, что сделать — todo, срочно — urgent, сколько займёт — '
          'duration_minutes. Без даты — записка. Одно дело — один вызов.',
      'parameters': {
        'type': 'object',
        'properties': {
          'title': {
            'type': 'string',
            'description': 'Коротко, что за дело: «Врач», «Купить хлеб»',
          },
          'date': {
            'type': 'string',
            'description': 'День, YYYY-MM-DD. Нет дня — записка без даты',
          },
          'time': {
            'type': 'string',
            'description': 'Время начала, ЧЧ:ММ. Не назвали — на весь день',
          },
          'duration_minutes': {
            'type': 'integer',
            'description': 'Сколько займёт, минут',
          },
          'address': {
            'type': 'string',
            'description': 'Куда ехать — адрес целиком',
          },
          'todo': {
            'type': 'string',
            'description': 'Что сделать там: взять, спросить, отдать',
          },
          'urgent': {'type': 'boolean', 'description': 'Срочное, важное'},
          'repeat': {
            'type': 'string',
            'enum': ['monthly', 'yearly'],
            'description': 'Повторять каждый месяц или каждый год',
          },
        },
        'required': ['title'],
      },
    },
    {
      'name': updateRecord,
      'description': 'Поправить запись: перенести, переименовать, дописать, '
          'напоминание, срочность, длительность, повтор, отметить '
          'сделанной, убрать в архив или вернуть. Запись — по id из list_days, find_records '
          'или list_notes; нет id — query, слова из названия. Меняется '
          'только названное.',
      'parameters': {
        'type': 'object',
        'properties': {
          'id': {'type': 'string', 'description': 'Номер записи'},
          'query': {
            'type': 'string',
            'description': 'Слова из названия, если нет id',
          },
          'date': {'type': 'string', 'description': 'Новый день, YYYY-MM-DD'},
          'time': {'type': 'string', 'description': 'Новое время, ЧЧ:ММ'},
          'shift_minutes': {
            'type': 'integer',
            'description': 'Сдвинуть на столько минут: 60 — на час позже, '
                '-30 — на полчаса раньше, 1440 — на день позже',
          },
          'duration_minutes': {
            'type': 'integer',
            'description': 'Сколько займёт, минут',
          },
          'title': {'type': 'string', 'description': 'Новое название'},
          'add_text': {
            'type': 'string',
            'description': 'Дописать в текст записи',
          },
          'urgent': {'type': 'boolean'},
          'remind_minutes_before': {
            'type': 'integer',
            'description': 'Напомнить за столько минут до начала; 0 — в '
                'момент начала',
          },
          'remove_reminder': {'type': 'boolean'},
          'alarm': {
            'type': 'boolean',
            'description': 'Будильник: звенит громко, как будильник, а не '
                'тихим уведомлением; false — снять будильник',
          },
          'repeat': {
            'type': 'string',
            'enum': ['monthly', 'yearly', 'none'],
            'description': 'Повторять каждый месяц, каждый год; none — '
                'перестать повторять',
          },
          'status': {
            'type': 'string',
            'enum': ['done', 'active', 'archived', 'restored'],
            'description': 'Сделано, снова в работу, в архив, из архива',
          },
        },
      },
    },
    {
      'name': addFinance,
      'description': 'Записать в журнал «Финансы» Ежедневника. Покупка, '
          'трата, оплата — expense; деньги, пришедшие хозяину: зарплата, '
          'перевод ему, возврат, — income.',
      'parameters': {
        'type': 'object',
        'properties': {
          'kind': {
            'type': 'string',
            'enum': ['expense', 'income'],
          },
          'amount': {'type': 'number', 'description': 'Сумма'},
          'currency': {
            'type': 'string',
            'description': 'Код валюты: RUB, USD, EUR. Не назвали — не '
                'указывай',
          },
          'category': {
            'type': 'string',
            'description': 'На что или откуда: «Продукты», «Такси», '
                '«Зарплата»',
          },
          'date': {
            'type': 'string',
            'description': 'День, YYYY-MM-DD. Не назвали — сегодня',
          },
        },
        'required': ['kind', 'amount', 'category'],
      },
    },
    {
      'name': openPage,
      'description': 'Открыть страницу Ежедневника.',
      'parameters': {
        'type': 'object',
        'properties': {
          'page': {
            'type': 'string',
            'enum': [for (final place in JarvisPlace.values) place.name],
          },
          'date': {
            'type': 'string',
            'description': 'День для календаря, дня и праздников, '
                'YYYY-MM-DD',
          },
        },
        'required': ['page'],
      },
    },
    {
      'name': listNotes,
      'description': 'Записки без даты — с полным текстом.',
      'parameters': {'type': 'object', 'properties': {}},
    },
    {
      'name': listArchive,
      'description': 'Записи в архиве, убранные последними — первыми.',
      'parameters': {'type': 'object', 'properties': {}},
    },
    {
      'name': getSettings,
      'description': 'Настройки Ежедневника и твои: тема, подсказки, '
          'праздники, международные дни, отзыв на имя (wakeWord), '
          'напоминания вслух, подробная карточка дела, утренняя и вечерняя '
          'сводки со временем.',
      'parameters': {'type': 'object', 'properties': {}},
    },
    {
      'name': changeSetting,
      'description': 'Включить или выключить настройку; сводке — назначить '
          'время. Тема — run_command «тёмная тема». PIN, синхронизацию и '
          'резервные копии меняет только хозяин — open_page settings.',
      'parameters': {
        'type': 'object',
        'properties': {
          'setting': {
            'type': 'string',
            'enum': [for (final setting in JarvisSwitch.values) setting.name],
          },
          'enabled': {'type': 'boolean'},
          'time': {
            'type': 'string',
            'description': 'Для сводок: во сколько, ЧЧ:ММ',
          },
        },
        'required': ['setting'],
      },
    },
    {
      'name': lookAtScreen,
      'description': 'Что сейчас на экране у хозяина: какая страница и что '
          'на ней.',
      'parameters': {'type': 'object', 'properties': {}},
    },
  ];
}
