import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'app_destination.dart';

/// Быстрые инструменты верхней панели в порядке показа.
///
/// Последней стоят настройки: им отдано первое из двух свободных мест, а
/// Джарвис, который сначала стоял здесь, переехал вниз, под палец
/// (решение владельца 8 октября 2026). Настройки остаются вкладкой
/// оболочки — кнопка просто живёт наверху.
///
/// Второе свободное место снято с панели 1 сентября 2026: пустая кнопка
/// видна на каждом экране и ничего не даёт. Маршрут `/tools/slot-two`, экран
/// `EmptyToolScreen` и подпись `toolSlotTwo` оставлены нарочно: место
/// возвращается одной записью в этот список, а не сборкой заново.
///
/// ```dart
/// AppDestination.route(
///   id: 'slot_two',
///   icon: Icons.widgets_outlined,
///   label: strings.toolSlotTwo,
///   location: '/tools/slot-two',
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
      AppDestination.branch(
        id: 'settings',
        icon: Icons.tune_rounded,
        label: strings.settings,
        location: '/settings',
        branchIndex: 3,
      ),
    ];
