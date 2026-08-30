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
      for (var index = 3; index <= 5; index++)
        AppDestination.placeholder(
          id: 'tool_placeholder_$index',
          icon: Icons.help_outline_rounded,
          label: strings.toolPlaceholder,
        ),
    ];
