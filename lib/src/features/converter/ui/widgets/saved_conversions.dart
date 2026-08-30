import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';

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
        final items = snapshot.calculations
            .where((item) => item.payload is SavedConversionPayload)
            .toList();
        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('${strings.savedCalculations} (${items.length})'),
          children: items.isEmpty
              ? [ListTile(title: Text(strings.noSavedCalculations))]
              : [
                  for (final item in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.name),
                      subtitle: Text(
                          _summary(item.payload as SavedConversionPayload)),
                      onTap: () =>
                          onLoad(item.payload as SavedConversionPayload),
                      trailing: IconButton(
                        tooltip: strings.delete,
                        onPressed: () => ref
                            .read(toolDataControllerProvider.notifier)
                            .deleteCalculation(item.id),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ),
                ],
        );
      },
    );
  }

  String _summary(SavedConversionPayload value) =>
      '${formatToolNumber(value.value)} ${value.fromUnit} → ${value.toUnit}';
}
