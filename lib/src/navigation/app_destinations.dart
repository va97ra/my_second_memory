import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'app_destination.dart';

/// Пункты нижней панели в порядке показа.
///
/// Единственное место, где описано, из чего состоит панель. Порядок здесь —
/// это порядок на экране; индексы веток заданы явно, поэтому вставка пункта в
/// середину ничего не сдвигает.
List<AppDestination> appDestinations(AppStrings strings) => [
      AppDestination.branch(
        id: 'calendar',
        icon: Icons.calendar_month_rounded,
        label: strings.calendar,
        location: '/calendar',
        branchIndex: 0,
      ),
      AppDestination.branch(
        id: 'feed',
        icon: Icons.view_agenda_rounded,
        label: strings.feed,
        location: '/',
        branchIndex: 1,
      ),
      AppDestination.route(
        id: 'add_note',
        icon: Icons.edit_note_rounded,
        label: strings.noteCard,
        location: '/memory/note/new',
      ),
      AppDestination.branch(
        id: 'accounts',
        icon: Icons.vpn_key_rounded,
        label: strings.accounts,
        location: '/accounts',
        branchIndex: 2,
      ),
      AppDestination.branch(
        id: 'settings',
        icon: Icons.tune_rounded,
        label: strings.settings,
        location: '/settings',
        branchIndex: 3,
      ),
    ];
