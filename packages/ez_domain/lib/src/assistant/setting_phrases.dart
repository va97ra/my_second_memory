import 'jarvis_command.dart';
import 'moment_hits.dart';
import 'phrase_scan.dart';
import 'russian_words.dart';
import 'time_phrases.dart';

/// Настройки голосом: «включи тёмную тему», «тема космос», «выключи
/// подсказки», «покажи международные дни», «не читай напоминания вслух»,
/// «утреннюю сводку в 8», «не присылай вечернюю сводку».
///
/// Только то, что безопасно переключить туда и обратно одной фразой. PIN,
/// вход в синхронизацию и всё, что касается паролей, сюда не входит.
JarvisCommand? settingCommand(String work) {
  final theme = _themeOf(work);
  if (theme != null) return ChangeTheme(theme);
  final briefing = _briefingAt(work);
  if (briefing != null) return briefing;

  final enable = _enable.hasMatch(work);
  final disable = _disable.hasMatch(work);
  if (enable == disable) return null;
  for (final (pattern, setting) in _switches) {
    if (pattern.hasMatch(work)) {
      return SwitchSetting(setting, enabled: enable);
    }
  }
  return null;
}

/// «Утреннюю сводку в 8», «вечернюю — в 9»: без отказа и с временем.
BriefingAt? _briefingAt(String work) {
  final evening = _evening.hasMatch(work);
  if (!evening && !_morning.hasMatch(work)) return null;
  if (_disable.hasMatch(work)) return null;
  final hits = MomentHits();
  collectTimes(PhraseScan(work), hits);
  if (hits.times.isEmpty) return null;
  // Часть суток — от сводки, а день — не сегодняшний: «в 9» вечерней
  // сводки — всегда девять вечера, сколько бы ни было сейчас.
  final minutes = resolveTime(
      hits.times.first,
      evening ? DayPart.evening : DayPart.morning,
      DateTime(2000),
      DateTime(2001));
  return BriefingAt(evening: evening, minutes: minutes);
}

JarvisTheme? _themeOf(String work) {
  final mentionsTheme = _themeWord.hasMatch(work);
  final asksChange = _changeVerb.hasMatch(work);
  if (!mentionsTheme && !asksChange) return null;
  if (_cosmos.hasMatch(work)) return JarvisTheme.cosmos;
  // Без слова «тема» прилагательное ничего не значит: «светлая мысль».
  if (!mentionsTheme) return null;
  if (_dark.hasMatch(work)) return JarvisTheme.dark;
  if (_light.hasMatch(work)) return JarvisTheme.light;
  return null;
}

final _themeWord =
    phrasePattern('$wordStart(?:тем[аеуы]|оформлени[а-я]*)$wordEnd');
final _changeVerb = phrasePattern('^(?:включи|поставь|сделай|смени|поменяй'
    '|переключи|верни|хочу)$wordEnd');
final _cosmos = phrasePattern('$wordStartкосм[а-я]*');
final _dark = phrasePattern('$wordStart(?:темн[а-я]*|черн[а-я]*|ночн[а-я]*)');
final _light = phrasePattern(
    '$wordStart(?:светл[а-я]*|бел[а-я]*|дневн[а-я]*|обычн[а-я]*)');

// «Покажи праздники» — просьба открыть страницу, а не включить настройку.
final _enable = phrasePattern('^(?:включи|показывай|верни|отображай'
    '|включить|читай|говори|озвучивай|присылай|отзывайся|откликайся'
    '|спрашивай)$wordEnd');
final _disable = phrasePattern('^(?:выключи|отключи|скрой|убери|спрячь'
    '|выключить|отключить|скрыть|без|не\\s+(?:показывай|читай|говори'
    '|озвучивай|присылай|отзывайся|откликайся|спрашивай|надо))$wordEnd');

final _morning = phrasePattern('$wordStartутренн[а-я]*\\s+сводк');
final _evening = phrasePattern('$wordStartвечерн[а-я]*\\s+сводк');

final _switches = <(RegExp, JarvisSwitch)>[
  (phrasePattern('$wordStartподсказк[а-я]*'), JarvisSwitch.hints),
  // «международные праздники» — это международные дни, а не праздники.
  (
    phrasePattern('$wordStart(?:международн[а-я]*|неофициальн[а-я]*)'),
    JarvisSwitch.observances
  ),
  (phrasePattern('$wordStartпраздник[а-я]*'), JarvisSwitch.holidays),
  (
    phrasePattern('$wordStart(?:отзыв[а-я]*|отклика[а-я]*|откликн[а-я]*)'
        '(?:\\s+на)?\\s+(?:им[яени]|джарвис)'),
    JarvisSwitch.wakeWord
  ),
  // «Не читай напоминания вслух»; «включи напоминание» — о записи, не сюда.
  (
    phrasePattern('$wordStartнапоминани[а-я]*\\s+(?:вслух|голосом)'
        '|$wordStart(?:читай|озвучивай|говори)\\s+напоминани'),
    JarvisSwitch.speakReminders
  ),
  (
    phrasePattern('$wordStart(?:подробн[а-я]*\\s+карточк|карточк[а-я]*\\s+дел'
        '|спрашивай\\s+(?:подробност|детал))'),
    JarvisSwitch.detailedCards
  ),
  (_morning, JarvisSwitch.morningBriefing),
  (_evening, JarvisSwitch.eveningBriefing),
];
