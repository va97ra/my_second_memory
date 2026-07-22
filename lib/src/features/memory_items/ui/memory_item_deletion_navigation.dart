part of 'memory_item_detail_screen.dart';

extension _MemoryItemDeletionNavigation on _MemoryItemDetailScreenState {
  Future<void> _confirmDelete(MemoryItem item) async {
    final strings = AppStrings.of(context);
    final deleteScope = item.seriesId == null
        ? 'one'
        : await showModalBottomSheet<String>(
            context: context,
            showDragHandle: true,
            builder: (context) {
              final ru = Localizations.localeOf(context).languageCode == 'ru';
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.event_note_outlined),
                      title: Text(ru
                          ? 'Удалить только эту запись'
                          : 'Delete only this record'),
                      onTap: () => Navigator.of(context).pop('one'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.event_busy_outlined),
                      title: Text(ru
                          ? 'Удалить эту и будущие'
                          : 'Delete this and future records'),
                      onTap: () => Navigator.of(context).pop('future'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep_outlined),
                      title: Text(ru
                          ? 'Удалить всю серию'
                          : 'Delete the entire series'),
                      onTap: () => Navigator.of(context).pop('series'),
                    ),
                  ],
                ),
              );
            },
          );
    if (deleteScope == null) return;
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteRecordQuestion),
        content: Text(item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }
    _saveCoordinator.discardPending();
    if (deleteScope == 'series' && item.seriesId != null) {
      await ref
          .read(recurrenceSeriesControllerProvider.notifier)
          .deleteSeries(item.seriesId!);
    } else if (deleteScope == 'future' && item.seriesId != null) {
      await ref
          .read(recurrenceSeriesControllerProvider.notifier)
          .deleteFromDate(item.seriesId!, item.memoryDate);
    } else {
      if (item.seriesId != null) {
        await ref
            .read(recurrenceSeriesControllerProvider.notifier)
            .deleteOccurrence(item);
      } else {
        await ref.read(memoryItemsControllerProvider.notifier).delete(item.id);
      }
    }

    if (mounted) {
      await _goBack(skipSave: true);
    }
  }

  Future<void> _goBack({bool skipSave = false}) async {
    if (_isLeaving) {
      return;
    }
    _isLeaving = true;
    if (!skipSave) {
      await _flushAutosave();
      if (_saveError != null) {
        _isLeaving = false;
        return;
      }
    }
    if (!mounted) {
      return;
    }
    _update(() => _allowPop = true);
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }
}
