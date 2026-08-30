import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';

class EngineeringSavedList extends ConsumerWidget {
  const EngineeringSavedList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    return ref.watch(toolDataControllerProvider).when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text(error.toString()),
          data: (snapshot) {
            final items = snapshot.calculations
                .where((item) => item.payload is SavedEngineeringPayload)
                .toList();
            return ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('${strings.savedCalculations} (${items.length})'),
              children: [
                for (final item in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    subtitle: Text(
                      (item.payload as SavedEngineeringPayload).calculator,
                    ),
                    onTap: () => _rename(context, ref, item),
                    trailing: IconButton(
                      tooltip: strings.delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => ref
                          .read(toolDataControllerProvider.notifier)
                          .deleteCalculation(item.id),
                    ),
                  ),
              ],
            );
          },
        );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    SavedToolCalculation item,
  ) async {
    final name = await askCalculationName(context, initial: item.name);
    if (name != null) {
      await ref
          .read(toolDataControllerProvider.notifier)
          .renameCalculation(item.id, name);
    }
  }
}
