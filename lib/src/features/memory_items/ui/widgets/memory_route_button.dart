import 'dart:async';

import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/state/maps_route.dart';

/// «Маршрут» в шапке записи, у которой есть адрес: карты телефона
/// прокладывают дорогу туда (просьба владельца 12 октября 2026: «ссылку
/// на навигатор или на карту, куда это ехать»).
class MemoryRouteButton extends ConsumerWidget {
  const MemoryRouteButton({required this.address, super.key});

  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    return IconButton(
      key: const ValueKey('memory_route'),
      tooltip: strings.recordRoute,
      iconSize: 22,
      style: notebookIconButtonStyle(),
      onPressed: () => unawaited(_open(context, ref)),
      icon: const Icon(Icons.directions_rounded),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final noMaps = AppStrings.of(context).recordRouteNoMaps;
    final opened = await ref.read(mapsRouteProvider).open(address);
    if (opened == null) {
      messenger?.showSnackBar(SnackBar(content: Text(noMaps)));
    }
  }
}
