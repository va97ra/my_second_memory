import 'package:ezhednevnik_v2/src/shared/state/media_cleanup.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_items_test_support.dart';

void main() {
  test('nothing is deleted while it is unknown who owns what', () async {
    // Записи или серии ещё грузятся: фото серии могло бы показаться ничьим.
    final storage = TrackingMediaStorage();
    final cleanup = MediaCleanup(storage, owned: () => null);

    await cleanup.release(['image_series.jpg']);

    expect(storage.deleted, isEmpty);
  });

  test('only files nobody owns are deleted', () async {
    final storage = TrackingMediaStorage();
    final cleanup = MediaCleanup(storage, owned: () => {'image_kept.jpg'});

    await cleanup.release(['image_kept.jpg', 'image_gone.jpg']);

    expect(storage.deleted, ['image_gone.jpg']);
  });
}
