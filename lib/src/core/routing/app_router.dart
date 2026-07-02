import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/ui/calendar_screen.dart';
import '../../features/calendar/ui/calendar_day_screen.dart';
import '../../features/home_feed/ui/home_feed_screen.dart';
import '../../features/memory_items/ui/add_memory_item_screen.dart';
import '../../features/memory_items/ui/memory_item_detail_screen.dart';
import '../../features/memory_items/ui/memory_library_screen.dart';
import '../../features/people/ui/people_screen.dart';
import '../../features/projects/ui/projects_screen.dart';
import '../../features/security/ui/security_screen.dart';
import '../../features/settings/ui/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeFeedScreen(),
      ),
      GoRoute(
        path: '/add',
        builder: (context, state) => const AddMemoryItemScreen(),
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
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
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
        path: '/people',
        builder: (context, state) => const PeopleScreen(),
      ),
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/security',
        builder: (context, state) => const SecurityScreen(),
      ),
    ],
  );
});
