import 'package:ez_core/ez_core.dart';
import 'package:ezhednevnik_v2/src/features/accounts/ui/widgets/account_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Лист стоит у нижнего края, а клавиатура ложится поверх него. Высоту листа
  // и отступ под клавиатуру нельзя уменьшать на неё оба раза: поля сжимаются в
  // полоску.
  testWidgets('клавиатура не сжимает поля листа аккаунта', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Consumer(
            builder: (context, ref, _) => MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 800),
                padding: EdgeInsets.only(top: 24),
                viewInsets: EdgeInsets.only(bottom: 320),
              ),
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: AccountEditor(ref: ref),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = tester.getRect(find.byType(SingleChildScrollView));
    expect(fields.height, greaterThan(250));
    final save = tester.getRect(find.byType(FilledButton));
    expect(save.bottom, lessThanOrEqualTo(800 - 320));
    expect(tester.takeException(), isNull);
  });
}
