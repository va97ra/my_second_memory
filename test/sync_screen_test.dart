import 'package:ezhednevnik_v2/src/features/sync/domain/sync_backend_config.dart';
import 'package:ezhednevnik_v2/src/features/sync/data/sync_local_store.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/sync/state/sync_controller.dart';
import 'package:ezhednevnik_v2/src/features/sync/ui/sync_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(320, 720), const Size(840, 900)]) {
    testWidgets('unconfigured sync screen fits ${size.width.toInt()} px',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncBackendConfigProvider.overrideWithValue(
              const SyncBackendConfig(url: '', publishableKey: ''),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ru'),
            supportedLocales: const [Locale('ru'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child!,
            ),
            home: const SyncScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Синхронизация'), findsOneWidget);
      expect(find.textContaining('SUPABASE_URL'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Google sign in fits narrow layout and invokes controller',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _TestSyncController();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncControllerProvider.overrideWith((ref) => controller),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          home: const SyncScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Продолжить с Google'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('sync_google_sign_in')));
    await tester.pump();
    expect(controller.googleSignInCalls, 1);
  });
}

class _TestSyncController extends SyncController {
  _TestSyncController()
      : super(
          remote: null,
          keyStore: SyncKeyStore(),
          tombstones: const SyncTombstoneStore(),
          readMemoryItems: () async => <MemoryItem>[],
          replaceMemoryItems: (_) async {},
        ) {
    state = const SyncState(status: SyncStatus.signedOut);
  }

  int googleSignInCalls = 0;

  @override
  Future<bool> signInWithGoogle() async {
    googleSignInCalls++;
    return true;
  }
}
