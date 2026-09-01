import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'diagnosis_walk_sheet.dart';

/// Список неисправностей: выбирают симптом и отвечают на вопросы.
class ElectricianDiagnosisList extends StatelessWidget {
  const ElectricianDiagnosisList({required this.query, super.key});

  final String query;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final ru = strings.isRu;
    final needle = query.trim().toLowerCase();
    final trees = [
      for (final tree in diagnosisTrees)
        if (needle.isEmpty || tree.title(ru).toLowerCase().contains(needle))
          tree,
    ];
    if (trees.isEmpty) {
      return Center(child: Text(strings.nothingFound));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: trees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final tree = trees[index];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.troubleshoot_rounded),
            title: Text(tree.title(ru)),
            subtitle: Text(strings.diagnosisSubtitle),
            onTap: () => showDiagnosisWalkSheet(context, tree),
          ),
        );
      },
    );
  }
}
