import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';

import '../../features/memory_items/state/memory_items_controller.dart';
import '../../features/recurrence/state/recurrence_providers.dart';
import 'media_cleanup.dart';

final mediaStorageProvider = Provider<MediaStorage>((ref) => MediaStorage());

/// Одна уборка на записи и повторы: владельцев у файла три вида, и решать за
/// них может только тот, кто видит все три.
///
/// Списки читаются в момент уборки, а не при сборке провайдера: контроллеры
/// записей и повторов сами пользуются уборкой, и подписка на них отсюда
/// замкнула бы круг. По той же причине контроллеры не подписаны на уборку, а
/// берут её, когда удаляют: подписка с любой стороны делает из двух чтений
/// круг зависимостей.
final Provider<MediaCleanup> mediaCleanupProvider = Provider((ref) {
  return MediaCleanup(
    ref.watch(mediaStorageProvider),
    owned: () {
      final loaded = ref.read(memoryItemsLoadProvider).hasValue &&
          ref.read(recurrenceLoadProvider).hasValue;
      if (!loaded) return null;
      return mediaReferencesOf(
        items: ref.read(memoryItemsControllerProvider),
        series: ref.read(recurrenceSeriesControllerProvider),
        exceptions: ref.read(recurrenceExceptionControllerProvider),
      );
    },
  );
});
