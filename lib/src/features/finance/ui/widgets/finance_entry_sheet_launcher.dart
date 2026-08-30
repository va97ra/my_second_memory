import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'finance_entry_sheet.dart';

Future<FinanceEntry?> showFinanceEntrySheet(
  BuildContext context, {
  required FinanceEntryKind kind,
  required String currencyCode,
  required List<String> categories,
  FinanceEntry? entry,
}) {
  // Лист собран один раз и отдаётся тем же самым: пока клавиатура выезжает,
  // Flutter пересобирает обёртку модального листа на каждом кадре, и с нею
  // пересобирались бы все поля внутри.
  final sheet = FinanceEntrySheet(
    kind: kind,
    currencyCode: currencyCode,
    categories: categories,
    entry: entry,
  );
  return showModalBottomSheet<FinanceEntry>(
    context: context,
    isScrollControlled: true,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 160),
      reverseDuration: Duration(milliseconds: 140),
    ),
    builder: (context) => sheet,
  );
}
