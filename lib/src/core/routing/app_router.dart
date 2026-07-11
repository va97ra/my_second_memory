import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/ui/accounts_screen.dart';
import '../../features/backup/ui/backup_screen.dart';
import '../../features/calendar/ui/calendar_screen.dart';
import '../../features/calendar/ui/calendar_day_screen.dart';
import '../../features/home_feed/ui/home_feed_screen.dart';
import '../../features/memory_items/ui/memory_item_detail_screen.dart';
import '../../features/memory_items/ui/memory_library_screen.dart';
import '../../features/memory_items/ui/memory_item_view_screen.dart';
import '../../features/security/ui/security_screen.dart';
import '../../features/settings/ui/settings_screen.dart';
import '../../features/shift_schedules/ui/shift_schedules_screen.dart';
import '../../shared/ui/app_shell.dart';

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
                builder: (context, state) => const HomeFeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/accounts',
                builder: (context, state) => const AccountsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/memory',
        builder: (context, state) => const MemoryLibraryScreen(),
      ),
      GoRoute(
        path: '/memory/item/:id',
        builder: (context, state) {
          return MemoryItemDetailScreen(
            itemId: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/memory/new',
        builder: (context, state) {
          final rawDate = state.uri.queryParameters['date'];
          final date = rawDate == null
              ? DateTime.now()
              : DateTime.tryParse(rawDate) ?? DateTime.now();
          return MemoryItemDetailScreen(
            initialDate: DateTime(date.year, date.month, date.day),
          );
        },
      ),
      GoRoute(
        path: '/memory/view/:id',
        builder: (context, state) {
          return MemoryItemViewScreen(
            itemId: state.pathParameters['id'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/calendar/day',
        builder: (context, state) {
          final rawDate = state.uri.queryParameters['date'];
          final date = rawDate == null
              ? DateTime.now()
              : DateTime.tryParse(rawDate) ?? DateTime.now();
          return CalendarDayScreen(
            date: DateTime(date.year, date.month, date.day),
          );
        },
      ),
      GoRoute(
        path: '/settings/shifts',
        builder: (context, state) => const ShiftSchedulesScreen(),
      ),
      GoRoute(
        path: '/settings/backup',
        builder: (context, state) => const BackupScreen(),
      ),
      GoRoute(
        path: '/security',
        builder: (context, state) => const SecurityScreen(),
      ),
    ],
  );
});
