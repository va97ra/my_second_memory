import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/accounts/ui/accounts_screen.dart';
import '../features/backup/ui/backup_screen.dart';
import '../features/calendar/ui/calendar_screen.dart';
import '../features/calendar/ui/calendar_day_screen.dart';
import '../features/calendar/ui/holiday_detail_screen.dart';
import '../features/home_feed/ui/home_feed_screen.dart';
import '../features/memory_items/ui/memory_item_detail_screen.dart';
import '../features/memory_items/ui/memory_library_screen.dart';
import '../features/memory_items/ui/memory_item_view_screen.dart';
import '../features/security/ui/security_screen.dart';
import '../features/settings/ui/settings_screen.dart';
import '../features/sync/ui/sync_screen.dart';
import '../features/shift_schedules/ui/shift_schedules_screen.dart';
import '../app/app_shell.dart';
import 'page_turn_transition.dart';
import 'shell_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/calendar',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
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
        path: '/memory',
        pageBuilder: (context, state) => shellPage(
          context: context,
          state: state,
          panel: 'settings',
          backFallback: '/settings',
          child: const MemoryLibraryScreen(),
        ),
      ),
      GoRoute(
        path: '/memory/item/:id',
        pageBuilder: (context, state) => shellPage(
          context: context,
          state: state,
          panel: recordPanelOf(state),
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
          return shellPage(
            context: context,
            state: state,
            panel: 'calendar',
            interceptBack: false,
            child: MemoryItemDetailScreen(
              initialDate: DateTime(date.year, date.month, date.day),
            ),
          );
        },
      ),
      GoRoute(
        path: '/memory/note/new',
        pageBuilder: (context, state) => shellPage(
          context: context,
          state: state,
          panel: 'add_note',
          interceptBack: false,
          child: const MemoryItemDetailScreen(createUndated: true),
        ),
      ),
      GoRoute(
        path: '/memory/view/:id',
        pageBuilder: (context, state) {
          return shellPage(
            context: context,
            state: state,
            panel: recordPanelOf(state),
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
          return shellPage(
            context: context,
            state: state,
            panel: 'calendar',
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
          return shellPage(
            context: context,
            state: state,
            panel: 'calendar',
            backFallback: _calendarDayLocation(date),
            child: HolidayDetailScreen(
              date: DateTime(date.year, date.month, date.day),
            ),
          );
        },
      ),
      GoRoute(
        path: '/settings/shifts',
        pageBuilder: (context, state) => shellPage(
          context: context,
          state: state,
          panel: 'settings',
          backFallback: '/settings',
          child: const ShiftSchedulesScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/backup',
        pageBuilder: (context, state) => shellPage(
          context: context,
          state: state,
          panel: 'settings',
          backFallback: '/settings',
          child: const BackupScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/sync',
        pageBuilder: (context, state) => shellPage(
          context: context,
          state: state,
          panel: 'settings',
          backFallback: '/settings',
          child: const SyncScreen(),
        ),
      ),
      GoRoute(
        path: '/security',
        pageBuilder: (context, state) => shellPage(
          context: context,
          state: state,
          panel: 'settings',
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
