import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../navigation/leave_after_frame.dart' as navigation;
import '../../../navigation/page_turn_navigation.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../recurrence/recurrence.dart';
import '../state/memory_item_selectors.dart';
import '../state/memory_items_controller.dart';
import 'widgets/editor_load_gate.dart';
import 'widgets/memory_view_sheet.dart';

/// Безопасный просмотр записи: её видно целиком, но случайно не правится.
class MemoryItemViewScreen extends ConsumerStatefulWidget {
  const MemoryItemViewScreen({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<MemoryItemViewScreen> createState() =>
      _MemoryItemViewScreenState();
}

class _MemoryItemViewScreenState extends ConsumerState<MemoryItemViewScreen> {
  /// Показывали ли эту запись хоть раз.
  ///
  /// Запись, которую удалили при открытом просмотре, — не ошибка адреса:
  /// смотреть больше нечего, и экран уходит назад сам. Показать вместо неё
  /// «Запись не найдена» значило бы оставить человека наедине с пустой
  /// страницей там, где он только что был.
  bool _wasShown = false;
  bool _isLeaving = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final item = ref.watch(memoryItemByIdProvider(widget.itemId));
    final loading = editorLoadingView(
      context,
      items: ref.watch(memoryItemsLoadProvider),
      series: ref.watch(recurrenceLoadProvider),
      needsSeries: item == null,
    );
    if (loading != null) return loading;

    if (item == null) return _missingRecord(strings);
    _wasShown = true;

    return Scaffold(
      appBar: AppPageAppBar(
        onBack: _goBack,
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: item.isUndated ? strings.editNote : strings.editRecord,
            onPressed: () => context.pageTurnPush(
              '/memory/item/${Uri.encodeComponent(item.id)}',
            ),
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: SafeArea(child: MemoryViewSheet(item: item)),
    );
  }

  Widget _missingRecord(AppStrings strings) {
    if (_wasShown) {
      if (!_isLeaving) {
        _isLeaving = true;
        navigation.leaveAfterFrame(context);
      }
      return const Scaffold(body: SizedBox.shrink());
    }
    // Сюда попадают только по несуществующему адресу — например, из старого
    // уведомления. Тут сообщение уместно.
    return Scaffold(
      appBar: AppPageAppBar(
        onBack: _goBack,
        title: Text(strings.recordNotFound),
      ),
      body: Center(child: Text(strings.recordNotFound)),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pageTurnPop();
      return;
    }
    context.pageTurnGo('/', direction: PageTurnDirection.backward);
  }
}
