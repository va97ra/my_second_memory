import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_exception_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/state/recurrence_series_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/memory_items_test_support.dart';
import '../../support/recurrence_test_support.dart';

/// Б4 и Б5: файл удаляется, только когда на него не ссылается ни запись, ни
/// шаблон серии, ни правка отдельной даты, — и удаляется, когда не ссылается
/// никто.
void main() {
  late TrackingMediaStorage media;
  late MemoryItemsController memories;
  late RecurrenceExceptionController exceptions;
  late RecurrenceSeriesController series;

  Future<void> launch({List<MemoryItem> items = const []}) async {
    final (series: seriesValue, :override) = seriesWithMedia();
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': encodeItems(items),
      LocalRecurrenceRepository.storageKey: encodeSeries([seriesValue]),
      LocalRecurrenceExceptionRepository.storageKey:
          encodeExceptions([override]),
    });
    media = TrackingMediaStorage();
    final cleanup = cleanupOver(
      media,
      items: () => memories.state,
      series: () => series.state,
      exceptions: () => exceptions.state,
    );
    memories =
        MemoryItemsController(const LocalMemoryRepository(), null, cleanup);
    exceptions = RecurrenceExceptionController(
      const LocalRecurrenceExceptionRepository(),
    );
    final reminders = NotificationService();
    addTearDown(reminders.dispose);
    series = RecurrenceSeriesController(
      const LocalRecurrenceRepository(),
      exceptions,
      memories,
      reminders,
      null,
      cleanup,
    );
    await series.load();
  }

  test('deleting a plain copy keeps the photo the series still shows',
      () async {
    final date = DateTime(2026, 11, 12);
    await launch(items: [
      MemoryItem(
        id: 'copy',
        type: MemoryType.note,
        title: 'Копия',
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
        imagePaths: const ['image_series.jpg'],
      ),
    ]);

    await memories.delete('copy');

    expect(media.deleted, isNot(contains('image_series.jpg')));
  });

  test('removing a photo from a plain copy keeps the series photo', () async {
    final date = DateTime(2026, 11, 12);
    final copy = MemoryItem(
      id: 'copy',
      type: MemoryType.note,
      title: 'Копия',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
      imagePaths: const ['image_series.jpg'],
    );
    await launch(items: [copy]);

    await memories.update(copy.copyWith(imagePaths: const []));

    expect(media.deleted, isNot(contains('image_series.jpg')));
  });

  test('deleting a series removes the files only it held', () async {
    await launch();

    await series.deleteSeries('series');

    expect(
      media.deleted,
      containsAll(['image_series.jpg', 'image_override.jpg']),
    );
  });

  test('deleting a series keeps a file a plain record still shows', () async {
    final date = DateTime(2026, 11, 12);
    await launch(items: [
      MemoryItem(
        id: 'copy',
        type: MemoryType.note,
        title: 'Копия',
        memoryDate: date,
        createdAt: date,
        updatedAt: date,
        imagePaths: const ['image_series.jpg'],
      ),
    ]);

    await series.deleteSeries('series');

    expect(media.deleted, contains('image_override.jpg'));
    expect(media.deleted, isNot(contains('image_series.jpg')));
  });

  test('deleting one occurrence frees its own photo, not the template one',
      () async {
    await launch();
    final occurrence = exceptions.state.single.item!;

    await series.deleteOccurrence(occurrence);

    expect(media.deleted, contains('image_override.jpg'));
    expect(media.deleted, isNot(contains('image_series.jpg')));
  });
}
