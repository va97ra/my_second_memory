import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/accounts/state/accounts_controller.dart';
import 'package:ezhednevnik_v2/src/features/accounts/ui/widgets/account_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/backup_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final account = AccountItem(
    id: 'mail',
    serviceName: 'Почта',
    login: 'user',
    password: 'secret',
    email: 'user@mail.test',
    website: 'https://mail.test',
    note: 'Заметка',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  for (final width in [320.0, 360.0, 600.0, 840.0]) {
    testWidgets('каждое поле копируется своей кнопкой на ширине $width',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountRepositoryProvider
                .overrideWithValue(FakeAccountRepository([account])),
          ],
          child: MaterialApp(
            locale: const Locale('ru'),
            supportedLocales: AppStrings.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Scaffold(
              body: SingleChildScrollView(
                child: AccountCard(
                  accountId: 'mail',
                  onEdit: (_) {},
                  onDelete: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final (tooltip, value) in [
        ('Скопировать логин', 'user'),
        ('Скопировать почту', 'user@mail.test'),
        ('Скопировать пароль', 'secret'),
        ('Скопировать сайт', 'https://mail.test'),
        ('Скопировать заметку', 'Заметка'),
      ]) {
        await tester.tap(find.byTooltip(tooltip));
        await tester.pump();
        expect(clipboard, value);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
