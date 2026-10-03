import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/state/feed_layout_provider.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/state/feed_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('day feed shows exactly the anchored day', () {
    final query = FeedPeriodQuery.fromState(
      FeedViewState(
        section: FeedSection.day,
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
        section: FeedSection.day,
        anchorDate: DateTime(2028, 2, 20),
        filter: FeedFilter.recurringMonthly,
      ),
    );
    final year = FeedPeriodQuery.fromState(
      FeedViewState(
        section: FeedSection.day,
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
        section: FeedSection.day,
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
        section: FeedSection.day,
        anchorDate: DateTime(2028, 1, 31),
        filter: FeedFilter.recurringMonthly,
      ),
    );

    controller.movePeriod(1);
    expect(controller.state.anchorDate, DateTime(2028, 2, 29));
  });

  test('picking a day returns the feed to the day section', () {
    final controller = FeedViewController(
      initialState: FeedViewState(
        section: FeedSection.notes,
        anchorDate: DateTime(2026, 8, 22),
        filter: FeedFilter.all,
      ),
    );

    controller.selectDate(DateTime(2026, 12, 5, 18, 30));

    expect(controller.state.section, FeedSection.day);
    expect(controller.state.anchorDate, DateTime(2026, 12, 5));
  });

  test('notes have no date range and keep the common anchor', () {
    final anchor = DateTime(2026, 8, 22);
    final controller = FeedViewController(
      initialState: FeedViewState(
        section: FeedSection.notes,
        anchorDate: anchor,
        filter: FeedFilter.done,
      ),
    );

    controller.movePeriod(1);
    final query = FeedPeriodQuery.fromState(controller.state);
    expect(query.start, isNull);
    expect(query.end, isNull);
    expect(controller.state.anchorDate, anchor);
  });

  test('search keeps its query only while open and starts empty each time',
      () {
    final controller = FeedViewController(
      initialState: FeedViewState(
        section: FeedSection.day,
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
        section: FeedSection.day,
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

  test('search stays open across tabs and lists all dates only on the day',
      () {
    final controller = FeedViewController(
      initialState: FeedViewState(
        section: FeedSection.day,
        anchorDate: DateTime(2026, 10, 1),
        filter: FeedFilter.all,
      ),
    );

    controller.toggleSearch();
    controller.search('пароль');
    expect(controller.state.allDates, isTrue);

    controller.selectSection(FeedSection.notes);
    expect(controller.state.searching, isTrue);
    expect(controller.state.searchQuery, 'пароль');
    expect(controller.state.allDates, isFalse);
  });
}
