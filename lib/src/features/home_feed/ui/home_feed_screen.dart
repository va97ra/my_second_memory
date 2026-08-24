import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../memory_items/state/memory_items_controller.dart';
import '../../recurrence/state/recurrence_controller.dart';
import '../../calendar/state/calendar_preferences_controller.dart';
import '../state/feed_providers.dart';
import 'widgets/feed_page.dart';
import 'widgets/feed_period_swipe_area.dart';
import 'widgets/feed_top_section_selector.dart';
import 'widgets/full_guide_sheet.dart';
import 'widgets/notebook_feed_book.dart';

/// Лента: страница выбранного периода, которую листают закладками и пальцем.
class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final GlobalKey<PageTurnFrameState> _pageTurnKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final loadState = ref.watch(memoryItemsLoadProvider);
    ref.watch(recurrenceLoadProvider);
    final view = ref.watch(feedViewProvider);
    final layout = ref.watch(feedLayoutProvider);
    final showHelp = ref.watch(appHintsProvider);
    final notebook = NotebookVisuals.maybeOf(context);

    return WarmGradientBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useSideTabs = notebook != null && constraints.maxHeight >= 360;
          final page = _page(
            view: view,
            layout: layout,
            loadState: loadState,
            showHelp: showHelp,
            alignToRuling: useSideTabs,
          );

          if (!useSideTabs) {
            return Column(
              children: [
                FeedTopSectionSelector(
                  selected: view.section,
                  onSelected: _selectSection,
                ),
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: page,
                  ),
                ),
              ],
            );
          }

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: constraints.maxWidth.clamp(0, 760),
              height: constraints.maxHeight,
              child: NotebookFeedBook(
                selected: view.section,
                onSelected: _selectSection,
                page: page,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _page({
    required FeedViewState view,
    required FeedLayout layout,
    required AsyncValue<void> loadState,
    required bool showHelp,
    required bool alignToRuling,
  }) {
    final sheet = PageTurnFrame(
      key: _pageTurnKey,
      child: FeedPage(
        view: view,
        layout: layout,
        loadState: loadState,
        showHelp: showHelp,
        alignToRuling: alignToRuling,
        onGoToToday: view.showsPeriodOf(DateTime.now()) ? null : _goToToday,
        onFilterSelected: (filter) =>
            ref.read(feedViewProvider.notifier).selectFilter(filter),
        onPickDate: _pickDate,
        onMovePeriod: _movePeriod,
        onShowHelp: () => showFeedGuide(
          context,
          ru: Localizations.localeOf(context).languageCode == 'ru',
        ),
      ),
    );

    // Страницу листают пальцем, а не только стрелками. У записок периода нет,
    // поэтому они остаются на месте.
    if (view.section == FeedSection.notes) return sheet;
    return FeedPeriodSwipeArea(onMovePeriod: _movePeriod, child: sheet);
  }

  Future<void> _selectSection(FeedSection section) async {
    final current = ref.read(feedViewProvider).section;
    if (section == current) return;
    await _turnPage(
      forward: section.index > current.index,
      switchContent: () =>
          ref.read(feedViewProvider.notifier).selectSection(section),
    );
  }

  /// Открывает любой день, не листая ленту по одному.
  Future<void> _pickDate() async {
    final view = ref.read(feedViewProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: view.anchorDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    ref.read(feedViewProvider.notifier).selectDate(picked);
  }

  Future<void> _goToToday() async {
    final view = ref.read(feedViewProvider);
    if (view.showsPeriodOf(DateTime.now())) return;
    // Сегодня почти всегда позади открытой страницы, поэтому лист падает
    // назад, а не переворачивается вперёд.
    final now = DateTime.now();
    await _turnPage(
      forward: !view.anchorDate.isAfter(DateTime(now.year, now.month, now.day)),
      switchContent: () => ref.read(feedViewProvider.notifier).goToToday(),
    );
  }

  Future<void> _movePeriod(int delta) async {
    if (delta == 0) return;
    await _turnPage(
      forward: delta > 0,
      switchContent: () =>
          ref.read(feedViewProvider.notifier).movePeriod(delta),
    );
  }

  /// Переворачивает лист и меняет содержимое посреди переворота. Без рамки
  /// (её ещё нет в дереве) содержимое меняется сразу.
  Future<void> _turnPage({
    required bool forward,
    required VoidCallback switchContent,
  }) async {
    final frame = _pageTurnKey.currentState;
    if (frame == null) {
      switchContent();
      return;
    }
    await frame.beginTurn(
      direction:
          forward ? PageTurnDirection.forward : PageTurnDirection.backward,
      switchContent: switchContent,
    );
  }
}
