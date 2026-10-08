import 'jarvis_command.dart';
import 'russian_words.dart';

/// Настройки голосом: «включи тёмную тему», «тема космос», «выключи
/// подсказки», «покажи международные дни».
///
/// Только то, что безопасно переключить туда и обратно одной фразой. PIN,
/// вход в синхронизацию и всё, что касается паролей, сюда не входит.
JarvisCommand? settingCommand(String work) {
  final theme = _themeOf(work);
  if (theme != null) return ChangeTheme(theme);

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
    '|включить)$wordEnd');
final _disable = phrasePattern('^(?:выключи|отключи|скрой|убери|спрячь'
    '|не\\s+показывай|выключить|отключить|скрыть)$wordEnd');

final _switches = <(RegExp, JarvisSwitch)>[
  (phrasePattern('$wordStartподсказк[а-я]*'), JarvisSwitch.hints),
  // «международные праздники» — это международные дни, а не праздники.
  (
    phrasePattern('$wordStart(?:международн[а-я]*|неофициальн[а-я]*)'),
    JarvisSwitch.observances
  ),
  (phrasePattern('$wordStartпраздник[а-я]*'), JarvisSwitch.holidays),
];
