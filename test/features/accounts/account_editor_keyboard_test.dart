import 'package:ez_core/ez_core.dart';
import 'package:ezhednevnik_v2/src/features/accounts/ui/account_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Окно на весь экран: клавиатура поднимает кнопку, а поля остаются прокручиваться
  // над ней, и места под них хватает.
  testWidgets('при открытой клавиатуре полям аккаунта хватает места',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              padding: EdgeInsets.only(top: 24),
              viewInsets: EdgeInsets.only(bottom: 320),
            ),
            child: child!,
          ),
          home: const AccountEditorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = tester.getRect(find.byType(SingleChildScrollView));
    expect(fields.height, greaterThan(250));
    final save = tester.getRect(find.byKey(const ValueKey('account_save')));
    expect(save.bottom, lessThanOrEqualTo(800 - 320));
    expect(tester.takeException(), isNull);
  });
}
