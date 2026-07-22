import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/ui/accounts_screen.dart';
import '../../features/backup/ui/backup_screen.dart';
import '../../features/calendar/ui/calendar_screen.dart';
import '../../features/calendar/ui/calendar_day_screen.dart';
import '../../features/calendar/ui/holiday_detail_screen.dart';
import '../../features/home_feed/ui/home_feed_screen.dart';
import '../../features/memory_items/ui/memory_item_detail_screen.dart';
import '../../features/memory_items/ui/memory_library_screen.dart';
import '../../features/memory_items/ui/memory_item_view_screen.dart';
import '../../features/security/ui/security_screen.dart';
import '../../features/recurrence/domain/recurrence_series.dart';
import '../../features/recurrence/ui/recurring_overview_screen.dart';
import '../../features/settings/ui/settings_screen.dart';
import '../../features/shift_schedules/ui/shift_schedules_screen.dart';
import '../../shared/ui/app_shell.dart';
import '../../shared/ui/page_turn_transition.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
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
        path: '/recurring/:frequency',
        pageBuilder: (context, state) {
          final frequency = state.pathParameters['frequency'] == 'yearly'
              ? RecurrenceFrequency.yearly
              : RecurrenceFrequency.monthly;
          return pageTurnPage(
            context: context,
            state: state,
            child: RecurringOverviewScreen(frequency: frequency),
          );
        },
      ),
      GoRoute(
        path: '/memory',
        pageBuilder: (context, state) => pageTurnPage(
          context: context,
          state: state,
          child: const MemoryLibraryScreen(),
        ),
      ),
      GoRoute(
        path: '/memory/item/:id',
        pageBuilder: (context, state) {
          return pageTurnPage(
            context: context,
            state: state,
            child: MemoryItemDetailScreen(
              itemId: state.pathParameters['id'] ?? '',
            ),
          );
        },
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
            child: MemoryItemDetailScreen(
              initialDate: DateTime(date.year, date.month, date.day),
            ),
          );
        },
      ),
      GoRoute(
        path: '/memory/view/:id',
        pageBuilder: (context, state) {
          return pageTurnPage(
            context: context,
            state: state,
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
          child: const ShiftSchedulesScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/backup',
        pageBuilder: (context, state) => pageTurnPage(
          context: context,
          state: state,
          child: const BackupScreen(),
        ),
      ),
      GoRoute(
        path: '/security',
        pageBuilder: (context, state) => pageTurnPage(
          context: context,
          state: state,
          child: const SecurityScreen(),
        ),
      ),
    ],
  );
});
