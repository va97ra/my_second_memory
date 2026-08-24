import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Нужны ли редактору серии: записи ещё нет, или это подписка, срок которой
/// лежит не в ней самой, а в серии.
bool editorNeedsSeries(MemoryItem? item, {required bool hasItemId}) {
  if (item == null) return hasItemId;
  return item.type == MemoryType.payment &&
      item.paymentCategory == PaymentCategory.subscription.name &&
      item.seriesId != null;
}

/// Что показать, пока редактору нечего показывать, — или null, если данные
/// готовы и можно строить сам редактор.
Widget? editorLoadingView(
  BuildContext context, {
  required AsyncValue<void> items,
  required AsyncValue<void> series,
  required bool needsSeries,
}) {
  if (items.isLoading || (needsSeries && series.isLoading)) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(key: ValueKey('editor_loading')),
      ),
    );
  }
  if (items.hasError || series.hasError) {
    return Scaffold(
      body: Center(child: Text(AppStrings.of(context).loadFailed)),
    );
  }
  return null;
}
