import 'package:ez_core/ez_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Подсказка страницы — это подсказка, а не учебник: две фразы о том, что
/// со страницы не видно. Учебник у нас уже был и устарел, потому что его
/// правили отдельно от экранов.
void main() {
  List<String> hintsOf(AppStrings s) => [
        s.feedPageHint,
        s.calendarPageHint,
        s.dayPageHint,
        s.recordPageHint,
        s.archivePageHint,
        s.accountsPageHint,
        s.settingsPageHint,
        s.securityPageHint,
        s.syncPageHint,
        s.backupPageHint,
        s.shiftsPageHint,
        s.holidayPageHint,
        s.calculatorPageHint,
        s.financePageHint,
        s.converterPageHint,
      ];

  test('every page hint is at most two sentences in both languages', () {
    for (final locale in AppStrings.supportedLocales) {
      for (final hint in hintsOf(AppStrings(locale))) {
        expect(
          '.'.allMatches(hint).length,
          lessThanOrEqualTo(2),
          reason: '${locale.languageCode}: $hint',
        );
        expect(hint.trim(), endsWith('.'), reason: hint);
      }
    }
  });
}
