import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/state/feed_layout_provider.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/state/feed_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('day feed shows exactly the anchored day', () {
    final query = FeedPeriodQuery.fromState(
      FeedViewState(
        anchorDate: DateTime(2028, 2, 20),
        filter: FeedFilter.all,
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
    final controller = FeedViewController(
      initialState: FeedViewState(
        anchorDate: DateTime(2028, 1, 31),
        filter: FeedFilter.all,
      ),
    );

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
    final controller = FeedViewController(
      initialState: FeedViewState(
        anchorDate: DateTime(2028, 1, 31),
        filter: FeedFilter.recurringMonthly,
      ),
    );

    controller.movePeriod(1);
    expect(controller.state.anchorDate, DateTime(2028, 2, 29));
  });

  test('search keeps its query only while open and starts empty each time',
      () {
    final controller = FeedViewController(
      initialState: FeedViewState(
        anchorDate: DateTime(2026, 10, 1),
        filter: FeedFilter.all,
      ),
    );

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
    final controller = FeedViewController(
      initialState: FeedViewState(
        anchorDate: DateTime(2026, 10, 1),
        filter: FeedFilter.all,
        searching: true,
        searchQuery: 'счётчик',
      ),
    );

    controller.selectDate(DateTime(2026, 9, 3));

    expect(controller.state.searching, isFalse);
    expect(controller.state.searchQuery, isEmpty);
  });

}
