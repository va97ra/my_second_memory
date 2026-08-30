import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/accounts/accounts.dart';
import '../features/backup/backup.dart';
import '../features/calendar/calendar.dart';
import '../features/home_feed/home_feed.dart';
import '../features/memory_items/memory_items.dart';
import '../features/security/security.dart';
import '../features/settings/settings.dart';
import '../features/sync/sync.dart';
import '../features/shift_schedules/shift_schedules.dart';
import '../features/calculator/calculator.dart';
import '../features/finance/finance.dart';
import '../features/converter/converter.dart';
import '../features/engineering/engineering.dart';
import '../features/technical_reference/technical_reference.dart';
import 'page_turn_transition.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/calendar',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => navigationShell,
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                pageBuilder: (context, state) => pageTurnPage(
                  context: context,
                  state: state,
                  child: const CalendarScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) => pageTurnPage(
                  context: context,
                  state: state,
                  child: const HomeFeedScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/accounts',
                pageBuilder: (context, state) => pageTurnPage(
                  context: context,
                  state: state,
                  child: const AccountsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => pageTurnPage(
                  context: context,
                  state: state,
                  child: const SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/tools/calculator',
        pageBuilder: (context, state) => pageTurnPage(
          context: context,
          state: state,
          child: const CalculatorScreen(),
        ),
      ),
      GoRoute(
        path: '/tools/finance',
        pageBuilder: (context, state) => pageTurnPage(
          context: context,
          state: state,
          child: const FinanceScreen(),
        ),
      ),
      GoRoute(
        path: '/tools/converter',
        pageBuilder: (context, state) => pageTurnPage(
          context: context,
          state: state,
          child: const ConverterScreen(),
        ),
      ),
      GoRoute(
        path: '/tools/engineering',
        pageBuilder: (context, state) => pageTurnPage(
          context: context,
          state: state,
          child: const EngineeringScreen(),
        ),
      ),
      GoRoute(
        path: '/tools/reference',
        pageBuilder: (context, state) => pageTurnPage(
          context: context,
          state: state,
          child: const TechnicalReferenceScreen(),
        ),
      ),
      GoRoute(
        path: '/memory',
        pageBuilder: (context, state) => pageTurnPage(
          context: context,
          state: state,
          backFallback: '/settings',
          child: const MemoryLibraryScreen(),
        ),
      ),
      GoRoute(
        path: '/memory/item/:id',
        pageBuilder: (context, state) => pageTurnPage(
          context: context,
          state: state,
          interceptBack: false,
          child: MemoryItemDetailScreen(
            itemId: state.pathParameters['id'] ?? '',
            newlyCreated: state.uri.queryParameters['new'] == '1',
          ),
        ),
      ),
      GoRoute(
        path: '/memory/new',
        pageBuilder: (context, state) {
          final rawDate = state.uri.queryParameters['date'];
          final date = rawDate == null
              ? DateTime.now()
              : DateTime.tryParse(rawDate) ?? DateTime.now();
          return pageTurnPage(
            context: context,
            state: state,
            interceptBack: false,
            child: MemoryItemDetailScreen(
              initialDate: DateTime(date.year, date.month, date.day),
            ),
          );
        },
      ),
      GoRoute(
        path: '/memory/note/new',
        pageBuilder: (context, state) => pageTurnPage(
          context: context,
          state: state,
          interceptBack: false,
          child: const MemoryItemDetailScreen(createUndated: true),
        ),
      ),
      GoRoute(
        path: '/memory/view/:id',
        pageBuilder: (context, state) {
          return pageTurnPage(
            context: context,
            state: state,
            backFallback: '/',
            child: MemoryItemViewScreen(
              itemId: state.pathParameters['id'] ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: '/calendar/day',
        pageBuilder: (context, state) {
          final rawDate = state.uri.queryParameters['date'];
          final date = rawDate == null
              ? DateTime.now()
              : DateTime.tryParse(rawDate) ?? DateTime.now();
          return pageTurnPage(
            context: context,
            state: state,
            backFallback: '/calendar',
            child: CalendarDayScreen(
              date: DateTime(date.year, date.month, date.day),
            ),
          );
        },
      ),
      GoRoute(
        path: '/calendar/holidays',
        pageBuilder: (context, state) {
          final rawDate = state.uri.queryParameters['date'];
          final date = rawDate == null
              ? DateTime.now()
              : DateTime.tryParse(rawDate) ?? DateTime.now();
          return pageTurnPage(
            context: context,
            state: state,
            backFallback: _calendarDayLocation(date),
            child: HolidayDetailScreen(
              date: DateTime(date.year, date.month, date.day),
            ),
          );
        },
      ),
      GoRoute(
        path: '/settings/shifts',
        pageBuilder: (context, state) => pageTurnPage(
          context: context,
          state: state,
          backFallback: '/settings',
          child: const ShiftSchedulesScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/backup',
        pageBuilder: (context, state) => pageTurnPage(
          context: context,
          state: state,
          backFallback: '/settings',
          child: const BackupScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/sync',
        pageBuilder: (context, state) => pageTurnPage(
          context: context,
          state: state,
          backFallback: '/settings',
          child: const SyncScreen(),
        ),
      ),
      GoRoute(
        path: '/security',
        pageBuilder: (context, state) => pageTurnPage(
          context: context,
          state: state,
          backFallback: '/settings',
          child: const SecurityScreen(),
        ),
      ),
    ],
  );
});

String _calendarDayLocation(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '/calendar/day?date=${date.year}-$month-$day';
}
