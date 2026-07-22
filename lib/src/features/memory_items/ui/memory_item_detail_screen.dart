import 'dart:convert';
import 'dart:async';

import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_content_font.dart';
import '../../../core/theme/notebook/notebook_background.dart';
import '../../../core/theme/notebook/notebook_visuals.dart';
import '../../../shared/ui/notebook_action_button.dart';
import '../../../shared/ui/notebook_pressable.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../calendar/state/calendar_preferences_controller.dart';
import '../../home_feed/ui/widgets/memory_image_preview.dart';
import '../../home_feed/ui/widgets/memory_image_viewer.dart';
import '../../media/data/media_storage.dart';
import '../../notifications/data/notification_service.dart';
import '../../notifications/ui/reminder_sound_picker.dart';
import '../../recurrence/domain/recurrence_series.dart';
import '../../recurrence/state/recurrence_controller.dart';
import '../../voice_notes/ui/widgets/voice_note_player.dart';
import '../domain/memory_item.dart';
import '../domain/memory_status.dart';
import '../domain/memory_type.dart';
import '../state/memory_items_controller.dart';
import '../state/memory_item_selectors.dart';
import '../state/memory_editor_draft.dart';
import '../state/memory_editor_save_coordinator.dart';
import 'widgets/memory_item_presentation.dart';

part 'widgets/memory_item_reminder_widgets.dart';
part 'widgets/memory_item_metadata_widgets.dart';
part 'widgets/memory_item_record_editor.dart';
part 'widgets/memory_item_picker_widgets.dart';
part 'memory_item_initialization.dart';
part 'memory_item_editing_actions.dart';
part 'memory_item_persistence.dart';
part 'memory_item_deletion_navigation.dart';

class MemoryItemDetailScreen extends ConsumerStatefulWidget {
  const MemoryItemDetailScreen({
    this.itemId,
    this.initialDate,
    super.key,
  });

  final String? itemId;
  final DateTime? initialDate;

  @override
  ConsumerState<MemoryItemDetailScreen> createState() =>
      _MemoryItemDetailScreenState();
}

class _MemoryItemDetailScreenState extends ConsumerState<MemoryItemDetailScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _bodyController = TextEditingController();
  final _amountController = TextEditingController();
  final _recorder = AudioRecorder();
  final _mediaStorage = MediaStorage();
  final _imagePicker = ImagePicker();
  final _imagePaths = <String>[];

  String? _loadedItemId;
  DateTime _memoryDate = DateTime.now();
  DateTime? _originalOccurrenceDate;
  int? _timeMinutes;
  DateTime? _remindAt;
  String? _reminderSoundUri;
  String? _reminderSoundName;
  MemoryStatus _status = MemoryStatus.active;
  MemoryType _type = MemoryType.note;
  String? _audioPath;
  int? _audioDurationSeconds;
  RecurrenceFrequency? _recurrenceFrequency;
  PaymentCategory _paymentCategory = PaymentCategory.other;
  int? _birthYear;
  bool _editFutureOccurrences = false;
  bool _scopeRequested = false;
  DateTime? _recordingStartedAt;
  bool _isRecording = false;
  bool _isSaving = false;
  String? _saveError;
  bool _allowPop = false;
  bool _isLeaving = false;
  final _saveCoordinator = MemoryEditorSaveCoordinator();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveCoordinator.dispose();
    _bodyController.dispose();
    _amountController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_flushAutosave());
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final loadState = ref.watch(memoryItemsLoadProvider);
    final recurrenceLoadState = ref.watch(recurrenceLoadProvider);
    final item = _watchItem();
    final showHints = ref.watch(appHintsProvider);

    if (loadState.isLoading ||
        (item == null &&
            widget.itemId != null &&
            recurrenceLoadState.isLoading)) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (loadState.hasError || recurrenceLoadState.hasError) {
      return Scaffold(body: Center(child: Text(strings.loadFailed)));
    }

    if (item == null && widget.itemId != null) {
      return Scaffold(
        appBar: AppPageAppBar(
          onBack: _goBack,
          title: Text(strings.editRecord),
        ),
        body: Center(child: Text(strings.recordNotFound)),
      );
    }

    if (item == null) {
      _initializeNew();
    } else {
      _initializeFrom(item);
    }

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          unawaited(_goBack());
        }
      },
      child: Scaffold(
        appBar: AppPageAppBar(
          onBack: _goBack,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item == null ? strings.newRecord : strings.editRecord,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                _saveError != null
                    ? strings.saveFailed
                    : _isSaving
                        ? strings.saving
                        : strings.saved,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _saveError != null
                          ? Theme.of(context).colorScheme.error
                          : _isSaving
                              ? const Color(0xFF9A6A32)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          actions: [
            Tooltip(
              message: _saveError != null
                  ? strings.saveFailed
                  : _isSaving
                      ? strings.saving
                      : strings.saved,
              child: AnimatedContainer(
                key: const ValueKey('memory_autosave_status'),
                duration: const Duration(milliseconds: 220),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: (_saveError != null
                          ? Theme.of(context).colorScheme.error
                          : _isSaving
                              ? const Color(0xFFD59A48)
                              : const Color(0xFF239B61))
                      .withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _saveError != null
                      ? Icons.cloud_off_outlined
                      : _isSaving
                          ? Icons.sync
                          : Icons.cloud_done_outlined,
                  key: ValueKey(
                    _saveError != null
                        ? 'memory_autosave_error'
                        : _isSaving
                            ? 'memory_autosave_saving'
                            : 'memory_autosave_saved',
                  ),
                  size: 20,
                  color: _saveError != null
                      ? Theme.of(context).colorScheme.error
                      : _isSaving
                          ? const Color(0xFFB7791F)
                          : const Color(0xFF168653),
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: Localizations.localeOf(context).languageCode == 'ru'
                  ? 'Повтор и действия'
                  : 'Repeat and actions',
              icon: Icon(
                Icons.event_repeat,
                color: _recurrenceFrequency == null
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.primary,
              ),
              onSelected: (value) {
                if (value == 'repeat') {
                  _openRepeatPicker();
                }
                if (value == 'duplicate' && item != null) {
                  _duplicateToDates(item);
                }
                if (value == 'future' && item != null) {
                  setState(() => _editFutureOccurrences = true);
                  ref
                      .read(recurrenceSeriesControllerProvider.notifier)
                      .applyToFuture(item);
                }
                if (value == 'delete') {
                  _confirmDelete(item!);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'repeat',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_repeat),
                    title: Text(
                      Localizations.localeOf(context).languageCode == 'ru'
                          ? 'Настроить повтор'
                          : 'Set recurrence',
                    ),
                  ),
                ),
                if (item != null)
                  PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.content_copy_outlined),
                      title: Text(
                        Localizations.localeOf(context).languageCode == 'ru'
                            ? 'Дублировать на даты'
                            : 'Duplicate to dates',
                      ),
                    ),
                  ),
                if (item?.seriesId != null)
                  PopupMenuItem(
                    value: 'future',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.update_outlined),
                      title: Text(
                        Localizations.localeOf(context).languageCode == 'ru'
                            ? 'Применить к будущим'
                            : 'Apply to future',
                      ),
                    ),
                  ),
                if (item != null)
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(strings.delete),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: _EditorBody(
              selectedType: _type,
              dateText: _formattedDate(context),
              timeText: _formattedTime(),
              reminderEnabled: _remindAt != null,
              onDateTap: _pickDate,
              onTimeTap: _openTimeAndReminder,
              onClearTime: _timeMinutes == null
                  ? null
                  : () {
                      setState(() {
                        _timeMinutes = null;
                        _remindAt = null;
                      });
                      _scheduleAutosave();
                    },
              onTypeChanged: (type) {
                _changeType(type);
                _scheduleAutosave();
              },
              specialFields: _buildSpecialFields(),
              showRecurrenceHint: showHints && _recurrenceFrequency == null,
              onRecurrenceHintTap: _openRepeatPicker,
              recordEditor: _RecordEditor(
                controller: _bodyController,
                imagePaths: _imagePaths,
                audioPath: _audioPath,
                audioDurationSeconds: _audioDurationSeconds,
                memoryDate: _memoryDate,
                isRecording: _isRecording,
                recurrenceFrequency: _recurrenceFrequency,
                onRecurrenceTap: _openRepeatPicker,
                onPickImage: _pickImage,
                onRemoveImage: (path) => setState(() {
                  _imagePaths.remove(path);
                  _scheduleAutosave();
                }),
                onRemoveAudio: () => setState(() {
                  _audioPath = null;
                  _audioDurationSeconds = null;
                  _scheduleAutosave();
                }),
                onVoicePressed: _isRecording ? _stopAndSaveVoice : _startVoice,
                onChanged: _scheduleAutosave,
              ),
            ),
          ),
        ),
      ),
    );
  }

  MemoryItem? _watchItem() {
    final id = _currentItemId();
    return id == null ? null : ref.watch(memoryItemByIdProvider(id));
  }

  MemoryItem? _readItem() {
    final id = _currentItemId();
    return id == null ? null : ref.read(memoryItemByIdProvider(id));
  }

  String? _currentItemId() {
    return widget.itemId ??
        (_loadedItemId == null || _loadedItemId == '__new__'
            ? null
            : _loadedItemId);
  }

  void _update(VoidCallback callback) => setState(callback);
}
