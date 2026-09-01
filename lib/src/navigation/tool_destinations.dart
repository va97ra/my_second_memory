import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'app_destination.dart';

/// Быстрые инструменты верхней панели в порядке показа.
List<AppDestination> toolDestinations(AppStrings strings) => [
      AppDestination.route(
        id: 'calculator',
        icon: Icons.calculate_rounded,
        label: strings.calculator,
        location: '/tools/calculator',
      ),
      AppDestination.route(
        id: 'finance',
        icon: Icons.account_balance_wallet_rounded,
        label: strings.finance,
        location: '/tools/finance',
      ),
      AppDestination.route(
        id: 'converter',
        icon: Icons.swap_horiz_rounded,
        label: strings.converter,
        location: '/tools/converter',
      ),
      AppDestination.route(
        id: 'engineering',
        icon: Icons.engineering_rounded,
        label: strings.engineering,
        location: '/tools/engineering',
      ),
      AppDestination.route(
        id: 'reference',
        icon: Icons.school_rounded,
        label: strings.electricianGuide,
        location: '/tools/reference',
      ),
    ];
