import 'package:ezhednevnik_v2/src/features/home_feed/domain/feed_rules.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/state/feed_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feed period query uses exact calendar boundaries', () {
    final leapMonth = FeedPeriodQuery.fromState(
      FeedViewState(
        section: FeedSection.month,
        anchorDate: DateTime(2028, 2, 20),
        filter: FeedFilter.all,
      ),
    );
    final leapYear = FeedPeriodQuery.fromState(
      FeedViewState(
        section: FeedSection.year,
        anchorDate: DateTime(2028, 8, 20),
        filter: FeedFilter.all,
      ),
    );

    expect(leapMonth.start, DateTime(2028, 2));
    expect(leapMonth.end, DateTime(2028, 2, 29));
    expect(leapYear.start, DateTime(2028));
    expect(leapYear.end, DateTime(2028, 12, 31));
  });

  test('period movement clamps the shared anchor to real book pages', () {
    final controller = FeedViewController(
      initialState: FeedViewState(
        section: FeedSection.month,
        anchorDate: DateTime(2028, 1, 31),
        filter: FeedFilter.task,
      ),
    );

    controller.movePeriod(1);
    expect(controller.state.anchorDate, DateTime(2028, 2, 29));
    controller.selectSection(FeedSection.year);
    controller.movePeriod(1);
    expect(controller.state.anchorDate, DateTime(2029, 2, 28));
    expect(controller.state.filter, FeedFilter.task);
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
}
