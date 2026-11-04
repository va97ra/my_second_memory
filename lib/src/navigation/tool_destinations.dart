import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'app_destination.dart';

/// Быстрые инструменты верхней панели в порядке показа.
///
/// Кнопок три. Два свободных места сняты с панели 1 сентября 2026: пустая
/// кнопка видна на каждом экране, занимает пятую часть ширины и ничего не
/// даёт — это шум при каждом запуске, а не место, ожидающее идею.
///
/// Снята только кнопка. Маршруты `/tools/slot-one` и `/tools/slot-two`,
/// экран `EmptyToolScreen` и подписи `toolSlotOne` и `toolSlotTwo` оставлены
/// нарочно: место в панели возвращается одной записью в этот список, а не
/// сборкой заново.
///
/// ```dart
/// AppDestination.route(
///   id: 'slot_one',
///   icon: Icons.engineering_rounded,
///   label: strings.toolSlotOne,
///   location: '/tools/slot-one',
/// ),
/// ```
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
    ];
