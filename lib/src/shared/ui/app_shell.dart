import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_strings.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.currentIndex,
    required this.child,
    this.floatingActionButton,
    super.key,
  });

  final int currentIndex;
  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: child,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: const Border(top: BorderSide(color: Color(0xFFDDE3EA))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/');
                    break;
                  case 1:
                    context.go('/calendar');
                    break;
                  case 2:
                    context.go('/accounts');
                    break;
                  case 3:
                    context.go('/settings');
                    break;
                }
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.view_day_outlined),
                  selectedIcon: const Icon(Icons.view_day),
                  label: strings.feed,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_month_outlined),
                  selectedIcon: const Icon(Icons.calendar_month),
                  label: strings.calendar,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.key_outlined),
                  selectedIcon: const Icon(Icons.key),
                  label: strings.accounts,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.tune_outlined),
                  selectedIcon: const Icon(Icons.tune),
                  label: strings.settings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
