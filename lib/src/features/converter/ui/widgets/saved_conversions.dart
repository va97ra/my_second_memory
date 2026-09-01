import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';
import 'converter_helpers.dart';

class SavedConversions extends ConsumerWidget {
  const SavedConversions({required this.onLoad, super.key});

  final ValueChanged<SavedConversionPayload> onLoad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final data = ref.watch(toolDataControllerProvider);
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text(error.toString()),
      data: (snapshot) {
        final items = [
          for (final item in snapshot.calculations)
            if (item.payload case final SavedConversionPayload payload)
              (item: item, payload: payload),
        ];
        return ExpansionTile(
          key: const ValueKey('converter_saved'),
          tilePadding: EdgeInsets.zero,
          title: Text('${strings.savedCalculations} (${items.length})'),
          children: items.isEmpty
              ? [ListTile(title: Text(strings.noSavedCalculations))]
              : [
                  for (final entry in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.item.name),
                      subtitle: Text(_summary(entry.payload)),
                      onTap: () => onLoad(entry.payload),
                      trailing: IconButton(
                        tooltip: strings.delete,
                        onPressed: () => ref
                            .read(toolDataControllerProvider.notifier)
                            .deleteCalculation(entry.item.id),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ),
                ],
        );
      },
    );
  }

  /// Строка расчёта обозначениями, а не ключами: «1 м → см» вместо
  /// «1 m → cm». Ключ — это то, чем запись хранится, а не то, что читают.
  String _summary(SavedConversionPayload value) {
    final from = unitSymbol(value.category, value.fromUnit);
    final to = unitSymbol(value.category, value.toUnit);
    return '${formatToolNumber(value.value)} $from → $to';
  }
}
