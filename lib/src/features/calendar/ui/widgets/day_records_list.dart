import 'package:flutter/material.dart';

import 'day_record_card.dart';

/// Записи выбранного дня.
///
/// Из дня запись открывается в редакторе, а не в безопасном просмотре: сюда
/// заходят, чтобы править.
class DayRecordsList extends StatelessWidget {
  const DayRecordsList({super.key, required this.itemIds});

  final List<String> itemIds;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
      itemCount: itemIds.length,
      itemBuilder: (context, index) => DayRecordCard(itemIds[index]),
    );
  }
}
