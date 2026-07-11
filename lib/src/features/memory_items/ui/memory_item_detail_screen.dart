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
import '../../../core/async/sequential_task_queue.dart';
import '../../home_feed/ui/widgets/memory_image_preview.dart';
import '../../home_feed/ui/widgets/memory_image_viewer.dart';
import '../../notifications/data/notification_service.dart';
import '../../voice_notes/data/voice_note_storage.dart';
import '../../voice_notes/ui/widgets/voice_note_player.dart';
import '../data/memory_image_storage.dart';
import '../domain/memory_item.dart';
import '../domain/memory_status.dart';
import '../domain/memory_type.dart';
import '../state/memory_items_controller.dart';
import '../state/memory_editor_draft.dart';
import 'widgets/memory_item_presentation.dart';

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
  final _recorder = AudioRecorder();
  final _voiceStorage = VoiceNoteStorage();
  final _imageStorage = MemoryImageStorage();
  final _imagePicker = ImagePicker();
  final _imagePaths = <String>[];

  String? _loadedItemId;
  DateTime _memoryDate = DateTime.now();
  int? _timeMinutes;
  DateTime? _remindAt;
  String? _reminderSoundUri;
  String? _reminderSoundName;
  MemoryStatus _status = MemoryStatus.active;
  MemoryType _type = MemoryType.note;
  String? _audioPath;
  int? _audioDurationSeconds;
  DateTime? _recordingStartedAt;
  bool _isRecording = false;
  bool _isSaving = false;
  String? _saveError;
  bool _hasPendingAutosave = false;
  bool _allowPop = false;
  bool _isLeaving = false;
  int _saveRevision = 0;
  Timer? _autosaveTimer;
  final _saves = SequentialTaskQueue();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autosaveTimer?.cancel();
    _bodyController.dispose();
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
    final item = _watchItem();

    if (loadState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (loadState.hasError) {
      return Scaffold(body: Center(child: Text(strings.loadFailed)));
    }

    if (item == null && widget.itemId != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back),
          ),
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
        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item == null ? strings.newRecord : strings.editRecord,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF202531),
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
                              : const Color(0xFF6B7280),
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
            if (item != null)
              PopupMenuButton<String>(
                tooltip: strings.delete,
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDelete(item);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(strings.delete),
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
                setState(() => _type = type);
                _scheduleAutosave();
              },
              recordEditor: _RecordEditor(
                controller: _bodyController,
                imagePaths: _imagePaths,
                audioPath: _audioPath,
                audioDurationSeconds: _audioDurationSeconds,
                memoryDate: _memoryDate,
                isRecording: _isRecording,
                onPickImage: _pickImage,
                onRemoveImage: (path) => setState(() {
                  _imagePaths.remove(path);
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
    return _findItem(ref.watch(memoryItemsControllerProvider));
  }

  MemoryItem? _readItem() {
    return _findItem(ref.read(memoryItemsControllerProvider));
  }

  MemoryItem? _findItem(List<MemoryItem> items) {
    final itemId = widget.itemId ??
        (_loadedItemId == null || _loadedItemId == '__new__'
            ? null
            : _loadedItemId);
    if (itemId == null) {
      return null;
    }
    for (final item in items) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  void _initializeFrom(MemoryItem item) {
    if (_loadedItemId == item.id) {
      return;
    }
    _loadedItemId = item.id;
    _bodyController.text = item.body;
    _memoryDate = item.memoryDate;
    _timeMinutes = item.timeMinutes;
    _remindAt = item.remindAt;
    _reminderSoundUri = item.reminderSoundUri;
    _reminderSoundName = item.reminderSoundName;
    _status = item.status;
    _type =
        editableMemoryTypes.contains(item.type) ? item.type : MemoryType.note;
    _audioPath = item.audioPath;
    _audioDurationSeconds = item.audioDurationSeconds;
    _imagePaths
      ..clear()
      ..addAll(item.imagePaths);
  }

  void _initializeNew() {
    if (_loadedItemId == '__new__') {
      return;
    }
    final date = widget.initialDate ?? DateTime.now();
    _loadedItemId = '__new__';
    _bodyController.clear();
    _memoryDate = DateTime(date.year, date.month, date.day);
    _timeMinutes = null;
    _remindAt = null;
    _reminderSoundUri = null;
    _reminderSoundName = null;
    _status = MemoryStatus.active;
    _type = MemoryType.note;
    _audioPath = null;
    _audioDurationSeconds = null;
    _imagePaths.clear();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _memoryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) {
      return;
    }
    setState(() {
      _memoryDate = DateTime(date.year, date.month, date.day);
      if (_remindAt != null && _timeMinutes != null) {
        final nextReminder = _dateTimeFor(_memoryDate, _timeMinutes!);
        _remindAt = nextReminder.isAfter(DateTime.now()) ? nextReminder : null;
      }
    });
    _scheduleAutosave();
  }

  String _formattedDate(BuildContext context) {
    return DateFormat('d MMM y', Localizations.localeOf(context).languageCode)
        .format(_memoryDate);
  }

  String? _formattedTime() {
    final minutes = _timeMinutes;
    if (minutes == null) {
      return null;
    }
    return formatMemoryTime(minutes);
  }

  Future<void> _openTimeAndReminder() async {
    final result = await showModalBottomSheet<_TimeReminderDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFCF6),
      builder: (context) => _TimeReminderSheet(
        initialTimeMinutes: _timeMinutes,
        initialReminderEnabled: _remindAt != null,
        initialSoundUri: _reminderSoundUri,
        initialSoundName: _reminderSoundName,
        memoryDate: _memoryDate,
        scheduler: ref.read(notificationServiceProvider),
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _timeMinutes = result.timeMinutes;
      _remindAt = result.reminderEnabled && result.timeMinutes != null
          ? _dateTimeFor(_memoryDate, result.timeMinutes!)
          : null;
      _reminderSoundUri = result.soundUri;
      _reminderSoundName = result.soundName;
    });
    _scheduleAutosave();
  }

  DateTime _dateTimeFor(DateTime date, int minutes) => DateTime(
        date.year,
        date.month,
        date.day,
        minutes ~/ 60,
        minutes % 60,
      );

  Future<void> _pickImage() async {
    final file = kIsWeb ? await _pickImageForWeb() : await _pickImageForIo();
    if (file == null) {
      return;
    }

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final mimeType = file.mimeType ?? _mimeTypeForName(file.name);
      final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
      setState(() => _imagePaths.add(dataUrl));
      _scheduleAutosave();
      return;
    }

    final savedPath = await _imageStorage.savePickedImage(file);
    setState(() => _imagePaths.add(savedPath));
    _scheduleAutosave();
  }

  Future<XFile?> _pickImageForWeb() async {
    const imageGroup = file_selector.XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );
    return file_selector.openFile(acceptedTypeGroups: [imageGroup]);
  }

  Future<XFile?> _pickImageForIo() async {
    final strings = AppStrings.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(strings.gallery),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(strings.camera),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) {
      return null;
    }
    return _imagePicker.pickImage(source: source, imageQuality: 92);
  }

  Future<void> _startVoice() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      return;
    }

    final path = await _voiceStorage.buildNewPath();
    await _recorder.start(const RecordConfig(), path: path);
    setState(() {
      _recordingStartedAt = DateTime.now();
      _isRecording = true;
    });
  }

  Future<void> _stopAndSaveVoice() async {
    final path = await _recorder.stop();
    final startedAt = _recordingStartedAt;
    final duration =
        startedAt == null ? 0 : DateTime.now().difference(startedAt).inSeconds;

    setState(() {
      _recordingStartedAt = null;
      _isRecording = false;
      if (path != null) {
        _audioPath = path;
        _audioDurationSeconds = duration;
      }
    });
    _scheduleAutosave();
  }

  String _mimeTypeForName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  Future<void> _save({bool showMessage = true}) async {
    if (_formKey.currentState?.validate() == false) {
      return;
    }
    if (!_hasContent()) {
      return;
    }

    final now = DateTime.now();
    final snapshot = MemoryEditorDraft(
      type: _type,
      title: memoryTitleFromRecord(
        _bodyController.text,
        _type,
        Localizations.localeOf(context).languageCode,
      ),
      body: _bodyController.text.trim(),
      timeMinutes: _timeMinutes,
      remindAt: _remindAt,
      reminderSoundUri: _reminderSoundUri,
      reminderSoundName: _reminderSoundName,
      memoryDate: DateTime(
        _memoryDate.year,
        _memoryDate.month,
        _memoryDate.day,
      ),
      status: _status,
      audioPath: _audioPath,
      audioDurationSeconds: _audioDurationSeconds,
      imagePaths: List.unmodifiable(_imagePaths),
      savedAt: now,
    );
    final revision = ++_saveRevision;
    _hasPendingAutosave = false;
    if (mounted) {
      setState(() {
        _isSaving = true;
        _saveError = null;
      });
    }

    final operation = _saves.add(() => _persistSnapshot(snapshot));

    try {
      await operation;
      if (!mounted || revision != _saveRevision) {
        return;
      }
      setState(() => _isSaving = false);
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).saved)),
        );
      }
    } catch (_) {
      if (!mounted || revision != _saveRevision) {
        return;
      }
      setState(() {
        _isSaving = false;
        _saveError = AppStrings.of(context).saveFailed;
      });
    }
  }

  Future<void> _persistSnapshot(MemoryEditorDraft snapshot) async {
    final item = _readItem();
    if (item == null) {
      final created = MemoryItem(
        id: snapshot.savedAt.microsecondsSinceEpoch.toString(),
        type: snapshot.type,
        title: snapshot.title,
        body: snapshot.body,
        timeMinutes: snapshot.timeMinutes,
        remindAt: snapshot.remindAt,
        reminderSoundUri: snapshot.reminderSoundUri,
        reminderSoundName: snapshot.reminderSoundName,
        memoryDate: snapshot.memoryDate,
        createdAt: snapshot.savedAt,
        updatedAt: snapshot.savedAt,
        status: snapshot.status,
        audioPath: snapshot.audioPath,
        audioDurationSeconds: snapshot.audioDurationSeconds,
        imagePaths: snapshot.imagePaths,
      );
      await ref.read(memoryItemsControllerProvider.notifier).add(created);
      _loadedItemId = created.id;

      if (mounted && widget.itemId == null) {
        context.replace('/memory/item/${Uri.encodeComponent(created.id)}');
      }
      return;
    }

    final updated = item.copyWith(
      type: snapshot.type,
      title: snapshot.title,
      body: snapshot.body,
      timeMinutes: snapshot.timeMinutes,
      clearTime: snapshot.timeMinutes == null,
      remindAt: snapshot.remindAt,
      clearReminder: snapshot.remindAt == null,
      reminderSoundUri: snapshot.reminderSoundUri,
      reminderSoundName: snapshot.reminderSoundName,
      memoryDate: snapshot.memoryDate,
      status: snapshot.status,
      audioPath: snapshot.audioPath,
      audioDurationSeconds: snapshot.audioDurationSeconds,
      imagePaths: snapshot.imagePaths,
      updatedAt: snapshot.savedAt,
    );
    await ref.read(memoryItemsControllerProvider.notifier).update(updated);
  }

  bool _hasContent() {
    return _bodyController.text.trim().isNotEmpty ||
        _imagePaths.isNotEmpty ||
        _audioPath != null;
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    if (_isRecording || !_hasContent()) {
      return;
    }
    _hasPendingAutosave = true;
    _autosaveTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        unawaited(_save(showMessage: false));
      }
    });
  }

  Future<void> _flushAutosave() async {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    if (_hasPendingAutosave && !_isRecording && _hasContent()) {
      await _save(showMessage: false);
    }
    await _saves.idle;
  }

  Future<void> _confirmDelete(MemoryItem item) async {
    final strings = AppStrings.of(context);
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
    _autosaveTimer?.cancel();
    _hasPendingAutosave = false;
    await ref.read(memoryItemsControllerProvider.notifier).delete(item.id);

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
    setState(() => _allowPop = true);
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }
}

class _TimeReminderDraft {
  const _TimeReminderDraft({
    required this.timeMinutes,
    required this.reminderEnabled,
    required this.soundUri,
    required this.soundName,
  });

  final int? timeMinutes;
  final bool reminderEnabled;
  final String? soundUri;
  final String? soundName;
}

class _TimeReminderSheet extends StatefulWidget {
  const _TimeReminderSheet({
    required this.initialTimeMinutes,
    required this.initialReminderEnabled,
    required this.initialSoundUri,
    required this.initialSoundName,
    required this.memoryDate,
    required this.scheduler,
  });

  final int? initialTimeMinutes;
  final bool initialReminderEnabled;
  final String? initialSoundUri;
  final String? initialSoundName;
  final DateTime memoryDate;
  final ReminderScheduler scheduler;

  @override
  State<_TimeReminderSheet> createState() => _TimeReminderSheetState();
}

class _TimeReminderSheetState extends State<_TimeReminderSheet> {
  int? _timeMinutes;
  late bool _reminderEnabled;
  String? _soundUri;
  String? _soundName;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _timeMinutes = widget.initialTimeMinutes;
    _reminderEnabled = widget.initialReminderEnabled;
    _soundUri = widget.initialSoundUri;
    _soundName = widget.initialSoundName;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 0, 18, 18 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.timeAndReminder,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 14),
            _ReminderSheetTile(
              icon: Icons.schedule_outlined,
              title: strings.time,
              value: _formattedTime(strings),
              onTap: _pickTime,
              trailing: _timeMinutes == null
                  ? null
                  : IconButton(
                      tooltip: strings.delete,
                      onPressed: () => setState(() {
                        _timeMinutes = null;
                        _reminderEnabled = false;
                        _error = null;
                      }),
                      icon: const Icon(Icons.close, size: 18),
                    ),
            ),
            const SizedBox(height: 8),
            Material(
              color: const Color(0xFFFFFDF8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFD8C8B4)),
              ),
              child: SwitchListTile.adaptive(
                secondary: const Icon(Icons.notifications_active_outlined),
                title: Text(strings.soundNotification),
                subtitle: !widget.scheduler.isSupported
                    ? Text(strings.androidOnlyReminder)
                    : null,
                value: _reminderEnabled,
                onChanged: !widget.scheduler.isSupported || _busy
                    ? null
                    : _toggleReminder,
              ),
            ),
            if (_reminderEnabled) ...[
              const SizedBox(height: 8),
              _ReminderSheetTile(
                icon: Icons.music_note_outlined,
                title: strings.chooseSound,
                value: _soundName ?? strings.systemAlarmSound,
                onTap: _busy ? null : _selectSound,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _soundUri == null || _busy
                      ? null
                      : () => setState(() {
                            _soundUri = null;
                            _soundName = null;
                          }),
                  child: Text(strings.useSystemSound),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                key: const ValueKey('memory_reminder_error'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const ValueKey('memory_reminder_done'),
              onPressed: _busy ? null : _finish,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(strings.ready),
            ),
          ],
        ),
      ),
    );
  }

  String _formattedTime(AppStrings strings) {
    final minutes = _timeMinutes;
    if (minutes == null) {
      return strings.timeNotSet;
    }
    return formatMemoryTime(minutes);
  }

  Future<bool> _pickTime() async {
    final minutes = _timeMinutes;
    final picked = await showTimePicker(
      context: context,
      initialEntryMode: TimePickerEntryMode.inputOnly,
      initialTime: minutes == null
          ? TimeOfDay.now()
          : TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked == null || !mounted) {
      return false;
    }
    setState(() {
      _timeMinutes = picked.hour * 60 + picked.minute;
      _error = null;
    });
    return true;
  }

  Future<void> _toggleReminder(bool enabled) async {
    if (!enabled) {
      setState(() {
        _reminderEnabled = false;
        _error = null;
      });
      return;
    }
    if (_timeMinutes == null && !await _pickTime()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final allowed = await widget.scheduler.requestPermissions();
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _reminderEnabled = allowed;
      if (!allowed) {
        _error = AppStrings.of(context).reminderPermissionRequired;
      }
    });
  }

  Future<void> _selectSound() async {
    setState(() => _busy = true);
    ReminderSoundSelection? selected;
    try {
      selected = await widget.scheduler.selectSound(currentUri: _soundUri);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppStrings.of(context).soundPickerUnavailable;
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      if (selected != null) {
        _soundUri = selected.uri;
        _soundName = selected.name;
      }
    });
  }

  void _finish() {
    final minutes = _timeMinutes;
    if (_reminderEnabled &&
        (minutes == null ||
            !_reminderDateTime(minutes).isAfter(DateTime.now()))) {
      setState(() {
        _error = AppStrings.of(context).reminderFutureRequired;
      });
      return;
    }
    Navigator.of(context).pop(
      _TimeReminderDraft(
        timeMinutes: minutes,
        reminderEnabled: _reminderEnabled,
        soundUri: _soundUri,
        soundName: _soundName,
      ),
    );
  }

  DateTime _reminderDateTime(int minutes) => DateTime(
        widget.memoryDate.year,
        widget.memoryDate.month,
        widget.memoryDate.day,
        minutes ~/ 60,
        minutes % 60,
      );
}

class _ReminderSheetTile extends StatelessWidget {
  const _ReminderSheetTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFDF8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFD8C8B4)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF425D85)),
        title: Text(title),
        subtitle: Text(value),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _EditorBody extends StatelessWidget {
  const _EditorBody({
    required this.selectedType,
    required this.dateText,
    required this.timeText,
    required this.reminderEnabled,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onClearTime,
    required this.onTypeChanged,
    required this.recordEditor,
  });

  final MemoryType selectedType;
  final String dateText;
  final String? timeText;
  final bool reminderEnabled;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final VoidCallback? onClearTime;
  final ValueChanged<MemoryType> onTypeChanged;
  final Widget recordEditor;

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = keyboardVisible || constraints.maxHeight < 520;
        final bottomPadding = keyboardVisible ? 8.0 : 24.0;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
              child: Column(
                children: [
                  _EditorMetadataBar(
                    selectedType: selectedType,
                    dateText: dateText,
                    timeText: timeText,
                    reminderEnabled: reminderEnabled,
                    onDateTap: onDateTap,
                    onTimeTap: onTimeTap,
                    onClearTime: onClearTime,
                    onTypeChanged: onTypeChanged,
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  Expanded(child: recordEditor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EditorMetadataBar extends StatelessWidget {
  const _EditorMetadataBar({
    required this.selectedType,
    required this.dateText,
    required this.timeText,
    required this.reminderEnabled,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onClearTime,
    required this.onTypeChanged,
  });

  final MemoryType selectedType;
  final String dateText;
  final String? timeText;
  final bool reminderEnabled;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final VoidCallback? onClearTime;
  final ValueChanged<MemoryType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final typeColor = memoryTypeColor(selectedType);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8C8B4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4F35).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: _MetadataAction(
                key: const ValueKey('memory_type_picker'),
                icon: memoryTypeIcon(selectedType),
                label: strings.recordType,
                value: selectedType.label(locale),
                color: typeColor,
                onTap: () => _showTypePicker(context),
              ),
            ),
            const _MetadataDivider(),
            Expanded(
              flex: 10,
              child: _MetadataAction(
                key: const ValueKey('memory_date_picker'),
                icon: Icons.event_outlined,
                label: strings.date,
                value: dateText,
                color: const Color(0xFF425D85),
                onTap: onDateTap,
              ),
            ),
            const _MetadataDivider(),
            Expanded(
              flex: 9,
              child: _MetadataAction(
                key: const ValueKey('memory_time_picker'),
                icon: Icons.schedule_outlined,
                label: strings.time,
                value: timeText ?? strings.timeNotSet,
                isPlaceholder: timeText == null,
                color: const Color(0xFF425D85),
                onTap: onTimeTap,
                onClear: onClearTime,
                badgeIcon: reminderEnabled ? Icons.notifications_active : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTypePicker(BuildContext context) async {
    final selected = await showModalBottomSheet<MemoryType>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFCF6),
      builder: (context) {
        final locale = Localizations.localeOf(context).languageCode;
        final strings = AppStrings.of(context);

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                child: Text(
                  strings.recordType,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              for (final type in editableMemoryTypes)
                _TypePickerRow(
                  type: type,
                  label: type.label(locale),
                  selected: type == selectedType,
                  onTap: () => Navigator.of(context).pop(type),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      onTypeChanged(selected);
    }
  }
}

class _MetadataDivider extends StatelessWidget {
  const _MetadataDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: const Color(0xFFE6D9C9),
    );
  }
}

class _MetadataAction extends StatelessWidget {
  const _MetadataAction({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    this.isPlaceholder = false,
    this.onClear,
    this.badgeIcon,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isPlaceholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final IconData? badgeIcon;

  @override
  Widget build(BuildContext context) {
    final valueColor = isPlaceholder ? const Color(0xFF7C746B) : color;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 17, color: valueColor),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF81776D),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: valueColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                    ),
                  ],
                ),
              ),
              if (badgeIcon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    badgeIcon,
                    key: const ValueKey('memory_reminder_enabled'),
                    size: 14,
                    color: const Color(0xFF168653),
                  ),
                ),
              if (onClear != null)
                Tooltip(
                  message: AppStrings.of(context).delete,
                  child: InkResponse(
                    onTap: onClear,
                    radius: 14,
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close, size: 13),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordEditor extends StatelessWidget {
  const _RecordEditor({
    required this.controller,
    required this.imagePaths,
    required this.audioPath,
    required this.audioDurationSeconds,
    required this.memoryDate,
    required this.isRecording,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onVoicePressed,
    required this.onChanged,
  });

  final TextEditingController controller;
  final List<String> imagePaths;
  final String? audioPath;
  final int? audioDurationSeconds;
  final DateTime memoryDate;
  final bool isRecording;
  final VoidCallback onPickImage;
  final ValueChanged<String> onRemoveImage;
  final VoidCallback onVoicePressed;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 360;
        final imageHeight = compact ? 56.0 : 72.0;
        final imageWidth = compact ? 76.0 : 96.0;
        final buttonSize = compact ? 38.0 : 42.0;

        return DecoratedBox(
          key: const ValueKey('record_editor_panel'),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF8).withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD8C8B4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B4F35).withValues(alpha: 0.09),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 12, compact ? 8 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imagePaths.isNotEmpty) ...[
                  SizedBox(
                    height: imageHeight,
                    child: ListView.separated(
                      key: const ValueKey('record_editor_images'),
                      scrollDirection: Axis.horizontal,
                      itemCount: imagePaths.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final path = imagePaths[index];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: imageWidth,
                                height: imageHeight,
                                child: GestureDetector(
                                  key: ValueKey('editor_image_$path'),
                                  onTap: () =>
                                      openMemoryImageViewer(context, path),
                                  child: MemoryImagePreview(path: path),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: IconButton.filledTonal(
                                constraints: const BoxConstraints.tightFor(
                                  width: 24,
                                  height: 24,
                                ),
                                padding: EdgeInsets.zero,
                                tooltip: strings.delete,
                                onPressed: () => onRemoveImage(path),
                                icon: const Icon(Icons.close, size: 14),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 12),
                ],
                if (audioPath != null) ...[
                  VoiceNotePlayer(
                    path: audioPath!,
                    recordedAt: memoryDate,
                    durationSeconds: audioDurationSeconds,
                  ),
                  SizedBox(height: compact ? 8 : 12),
                ] else if (isRecording) ...[
                  _RecordingPill(text: strings.recordingNow),
                  SizedBox(height: compact ? 8 : 12),
                ],
                Expanded(
                  child: TextFormField(
                    key: const ValueKey('record_editor_text'),
                    controller: controller,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    textAlignVertical: TextAlignVertical.top,
                    scrollPadding: const EdgeInsets.only(bottom: 120),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF292A2D),
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                    decoration: InputDecoration(
                      labelText: strings.description,
                      alignLabelWithHint: true,
                      labelStyle:
                          Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: const Color(0xFF81776D),
                                fontWeight: FontWeight.w600,
                              ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                SizedBox(height: compact ? 8 : 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SquareActionButton(
                        tooltip: strings.addImage,
                        icon: Icons.photo_camera_outlined,
                        color: const Color(0xFF2563EB),
                        size: buttonSize,
                        onPressed: onPickImage,
                      ),
                      const SizedBox(width: 8),
                      _SquareActionButton(
                        tooltip:
                            isRecording ? strings.stopRecording : strings.voice,
                        icon: isRecording ? Icons.stop : Icons.mic_none,
                        color: isRecording
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFDB2777),
                        size: buttonSize,
                        onPressed: onVoicePressed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecordingPill extends StatelessWidget {
  const _RecordingPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fiber_manual_record,
              size: 12,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF991B1B),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareActionButton extends StatelessWidget {
  const _SquareActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.size = 42,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        fixedSize: Size.square(size),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.12),
        side: BorderSide(color: color.withValues(alpha: 0.22)),
      ),
    );
  }
}

class _TypePickerRow extends StatelessWidget {
  const _TypePickerRow({
    required this.type,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final MemoryType type;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = memoryTypeColor(type);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color:
            selected ? color.withValues(alpha: 0.12) : const Color(0xFFFFFDF8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected
                ? color.withValues(alpha: 0.36)
                : const Color(0xFFD8C8B4),
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(memoryTypeIcon(type), color: color),
          title: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
          trailing: selected ? Icon(Icons.check_circle, color: color) : null,
        ),
      ),
    );
  }
}
