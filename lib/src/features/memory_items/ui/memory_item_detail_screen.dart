import 'dart:async';

import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../calendar/state/calendar_preferences_controller.dart';
import 'package:ez_domain/ez_domain.dart';
import '../../recurrence/state/recurrence_controller.dart';
import '../state/memory_items_controller.dart';
import '../state/memory_item_selectors.dart';
import '../state/memory_editor_draft.dart';
import '../state/memory_editor_save_coordinator.dart';
import '../state/memory_attachment_service.dart';
import '../state/memory_editor_saver.dart';
import 'widgets/memory_item_presentation.dart';
import 'widgets/time_reminder_sheet.dart';
import 'widgets/record_editor.dart';
import 'widgets/editor_body.dart';
import 'widgets/payment_fields.dart';
import 'widgets/subscription_term_sheet.dart';
import 'widgets/birthday_fields.dart';
import 'widgets/multi_date_picker_sheet.dart';
import '../../../navigation/page_turn_navigation.dart';
import '../../notifications/state/notification_providers.dart';

part 'memory_item_initialization.dart';
part 'memory_item_editing_actions.dart';
part 'memory_item_persistence.dart';
part 'memory_item_deletion_navigation.dart';

class MemoryItemDetailScreen extends ConsumerStatefulWidget {
  const MemoryItemDetailScreen({
    this.itemId,
    this.initialDate,
    this.createUndated = false,
    this.newlyCreated = false,
    super.key,
  });

  final String? itemId;
  final DateTime? initialDate;
  final bool createUndated;
  final bool newlyCreated;

  @override
  ConsumerState<MemoryItemDetailScreen> createState() =>
      _MemoryItemDetailScreenState();
}

class _MemoryItemDetailScreenState extends ConsumerState<MemoryItemDetailScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _bodyController = TextEditingController();
  final _amountController = TextEditingController();
  final _attachments = MemoryAttachmentService();
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
  int? _subscriptionTermMonths;
  bool _subscriptionTermDirty = false;
  int? _birthYear;
  bool _editFutureOccurrences = false;
  bool _scopeRequested = false;
  bool _refreshNewSeriesTemplate = false;
  bool _isRecording = false;
  bool _isSaving = false;
  bool _isUndated = false;
  String? _saveError;
  bool _allowPop = false;
  bool _isLeaving = false;
  final _saveCoordinator = MemoryEditorSaveCoordinator();

  /// Метка ещё не сохранённого черновика в [_loadedItemId].
  static const _newRecordKey = '__new__';

  /// Уводит с экрана исчезнувшей записи после того, как кадр дорисован.
  ///
  /// Без перелистывания: анимировать нечего, а сама анимация в этот момент
  /// может быть занята другим переходом и отменила бы уход.
  void _leaveAfterFrame() {
    if (_isLeaving) return;
    _isLeaving = true;
    _saveCoordinator.discardPending();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshNewSeriesTemplate = widget.newlyCreated;
    _scopeRequested = widget.newlyCreated;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveCoordinator.dispose();
    _bodyController.dispose();
    _amountController.dispose();
    _attachments.dispose();
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
    final needsRecurrenceForSubscriptionTerm =
        item?.type == MemoryType.payment &&
            item?.paymentCategory == PaymentCategory.subscription.name &&
            item?.seriesId != null;

    if (loadState.isLoading ||
        (((item == null && widget.itemId != null) ||
                needsRecurrenceForSubscriptionTerm) &&
            recurrenceLoadState.isLoading)) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(key: ValueKey('editor_loading')),
        ),
      );
    }
    if (loadState.hasError || recurrenceLoadState.hasError) {
      return Scaffold(body: Center(child: Text(strings.loadFailed)));
    }

    if (item == null && widget.itemId != null) {
      // Запись, исчезнувшую при открытом редакторе (её удалили здесь или на
      // другом устройстве), править больше нечем: экран уходит назад сам.
      if (_loadedItemId != null && _loadedItemId != _newRecordKey) {
        _leaveAfterFrame();
        return const Scaffold(body: SizedBox.shrink());
      }
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
                _isUndated
                    ? item == null
                        ? strings.newNote
                        : strings.editNote
                    : item == null
                        ? strings.newRecord
                        : strings.editRecord,
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
                width: 40,
                height: 40,
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
                      ? Icons.cloud_off_rounded
                      : _isSaving
                          ? Icons.sync_rounded
                          : Icons.cloud_done_rounded,
                  key: ValueKey(
                    _saveError != null
                        ? 'memory_autosave_error'
                        : _isSaving
                            ? 'memory_autosave_saving'
                            : 'memory_autosave_saved',
                  ),
                  size: 22,
                  color: _saveError != null
                      ? Theme.of(context).colorScheme.error
                      : _isSaving
                          ? const Color(0xFFB7791F)
                          : const Color(0xFF168653),
                ),
              ),
            ),
            if (!_isUndated || item != null)
              PopupMenuButton<String>(
                key: const ValueKey('memory_editor_menu'),
                tooltip: _isUndated
                    ? strings.delete
                    : Localizations.localeOf(context).languageCode == 'ru'
                        ? 'Повтор и действия'
                        : 'Repeat and actions',
                iconSize: 22,
                padding: const EdgeInsets.all(9),
                icon: Icon(
                  _isUndated
                      ? Icons.more_vert_rounded
                      : Icons.event_repeat_rounded,
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
                  if (!_isUndated)
                    PopupMenuItem(
                      value: 'repeat',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_repeat_rounded),
                        title: Text(
                          Localizations.localeOf(context).languageCode == 'ru'
                              ? 'Настроить повтор'
                              : 'Set recurrence',
                        ),
                      ),
                    ),
                  if (!_isUndated && item != null)
                    PopupMenuItem(
                      value: 'duplicate',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.content_copy_rounded),
                        title: Text(
                          Localizations.localeOf(context).languageCode == 'ru'
                              ? 'Дублировать на даты'
                              : 'Duplicate to dates',
                        ),
                      ),
                    ),
                  if (!_isUndated && item?.seriesId != null)
                    PopupMenuItem(
                      value: 'future',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.update_rounded),
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
                          Icons.delete_rounded,
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
            child: EditorBody(
              isUndated: _isUndated,
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
              specialFields: _isUndated ? null : _buildSpecialFields(),
              showRecurrenceHint:
                  !_isUndated && showHints && _recurrenceFrequency == null,
              onRecurrenceHintTap: _openRepeatPicker,
              recordEditor: RecordEditor(
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
        (_loadedItemId == null || _loadedItemId == _newRecordKey
            ? null
            : _loadedItemId);
  }

  void _update(VoidCallback callback) => setState(callback);
}
