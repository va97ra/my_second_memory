import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/state/feed_layout_provider.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/state/feed_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/provider_test_support.dart';

void main() {
  test('«Все записи» и фильтры по виду показывают все даты', () {
    final day = FeedViewState(
      anchorDate: DateTime(2026, 8, 22),
      filter: FeedFilter.day,
    );
    expect(day.allDates, isFalse);
    for (final filter in [
      FeedFilter.all,
      FeedFilter.done,
      FeedFilter.task,
    ]) {
      final state = day.copyWith(filter: filter);
      expect(state.allDates, isTrue);
      expect(FeedPeriodQuery.fromState(state).start, isNull);
    }
    expect(day.copyWith(filter: FeedFilter.recurringMonthly).allDates, isFalse);
  });

  test('со всех дат «сегодня» и выбор дня возвращают на страницу дня', () {
    final controller = testContainer(overrides: [
      feedViewProvider.overrideWithBuild((_, __) => FeedViewState(
            anchorDate: DateTime(2026, 8, 22),
            filter: FeedFilter.all,
          ))
    ]).read(feedViewProvider.notifier);
    final now = DateTime.now();
    expect(controller.state.showsPeriodOf(now), isFalse);

    controller.movePeriod(1);
    expect(controller.state.anchorDate, DateTime(2026, 8, 22));

    controller.goToToday();
    expect(controller.state.filter, FeedFilter.day);
    expect(controller.state.showsPeriodOf(now), isTrue);

    controller.selectFilter(FeedFilter.all);
    controller.selectDate(DateTime(2026, 12, 5));
    expect(controller.state.filter, FeedFilter.day);
    expect(controller.state.anchorDate, DateTime(2026, 12, 5));
  });

  test('day feed shows exactly the anchored day', () {
    final query = FeedPeriodQuery.fromState(
      FeedViewState(
        anchorDate: DateTime(2028, 2, 20),
        filter: FeedFilter.day,
      ),
    );

    expect(query.start, DateTime(2028, 2, 20));
    expect(query.end, DateTime(2028, 2, 20));
  });

  test('recurring filters open the feed onto their own period', () {
    final month = FeedPeriodQuery.fromState(
      FeedViewState(
        anchorDate: DateTime(2028, 2, 20),
        filter: FeedFilter.recurringMonthly,
      ),
    );
    final year = FeedPeriodQuery.fromState(
      FeedViewState(
        anchorDate: DateTime(2028, 8, 20),
        filter: FeedFilter.recurringYearly,
      ),
    );

    expect(month.start, DateTime(2028, 2));
    expect(month.end, DateTime(2028, 2, 29));
    expect(year.start, DateTime(2028));
    expect(year.end, DateTime(2028, 12, 31));
  });

  test('page movement follows the period the filter opened', () {
    final controller = testContainer(overrides: [
      feedViewProvider.overrideWithBuild((_, __) => FeedViewState(
            anchorDate: DateTime(2028, 1, 31),
            filter: FeedFilter.day,
          ))
    ]).read(feedViewProvider.notifier);

    controller.movePeriod(1);
    expect(controller.state.anchorDate, DateTime(2028, 2));

    controller.selectFilter(FeedFilter.recurringMonthly);
    controller.movePeriod(1);
    expect(controller.state.anchorDate, DateTime(2028, 3));

    controller.selectFilter(FeedFilter.recurringYearly);
    controller.movePeriod(1);
    expect(controller.state.anchorDate, DateTime(2029, 3));
  });

  test('monthly movement clamps to a day the month really has', () {
    final controller = testContainer(overrides: [
      feedViewProvider.overrideWithBuild((_, __) => FeedViewState(
            anchorDate: DateTime(2028, 1, 31),
            filter: FeedFilter.recurringMonthly,
          ))
    ]).read(feedViewProvider.notifier);

    controller.movePeriod(1);
    expect(controller.state.anchorDate, DateTime(2028, 2, 29));
  });

  test('search keeps its query only while open and starts empty each time', () {
    final controller = testContainer(overrides: [
      feedViewProvider.overrideWithBuild((_, __) => FeedViewState(
            anchorDate: DateTime(2026, 10, 1),
            filter: FeedFilter.day,
          ))
    ]).read(feedViewProvider.notifier);

    controller.search('счётчик');
    expect(controller.state.searchQuery, isEmpty);

    controller.toggleSearch();
    controller.search('счётчик');
    expect(controller.state.searchQuery, 'счётчик');

    controller.toggleSearch();
    expect(controller.state.searchQuery, isEmpty);
    controller.toggleSearch();
    expect(controller.state.searchQuery, isEmpty);
  });

  test('picking a day leaves the search', () {
    final controller = testContainer(overrides: [
      feedViewProvider.overrideWithBuild((_, __) => FeedViewState(
            anchorDate: DateTime(2026, 10, 1),
            filter: FeedFilter.day,
            search: const MemorySearchBar(isOpen: true, query: 'счётчик'),
          ))
    ]).read(feedViewProvider.notifier);

    controller.selectDate(DateTime(2026, 9, 3));

    expect(controller.state.searching, isFalse);
    expect(controller.state.searchQuery, isEmpty);
  });
}
