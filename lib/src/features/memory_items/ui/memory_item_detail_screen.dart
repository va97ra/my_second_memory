import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';

import '../../../core/localization/app_strings.dart';
import '../../home_feed/ui/widgets/memory_image_preview.dart';
import '../../voice_notes/data/voice_note_storage.dart';
import '../../voice_notes/ui/widgets/voice_note_player.dart';
import '../domain/memory_item.dart';
import '../domain/memory_status.dart';
import '../domain/memory_type.dart';
import '../state/memory_items_controller.dart';

class MemoryItemDetailScreen extends ConsumerStatefulWidget {
  const MemoryItemDetailScreen({
    required this.itemId,
    super.key,
  });

  final String itemId;

  @override
  ConsumerState<MemoryItemDetailScreen> createState() =>
      _MemoryItemDetailScreenState();
}

class _MemoryItemDetailScreenState
    extends ConsumerState<MemoryItemDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bodyController = TextEditingController();
  final _recorder = AudioRecorder();
  final _voiceStorage = VoiceNoteStorage();
  final _imagePaths = <String>[];

  String? _loadedItemId;
  DateTime _memoryDate = DateTime.now();
  MemoryStatus _status = MemoryStatus.active;
  MemoryType _type = MemoryType.note;
  String? _audioPath;
  int? _audioDurationSeconds;
  DateTime? _recordingStartedAt;
  bool _isRecording = false;

  @override
  void dispose() {
    _bodyController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final item = _findItem();

    if (item == null) {
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

    _initializeFrom(item);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: _EditorTitle(
          title: strings.editRecord,
          dateText: _formattedDate(context),
          onDateTap: _pickDate,
        ),
        actions: [
          IconButton(
            tooltip: strings.save,
            onPressed: _isRecording ? null : () => _save(item),
            icon: const Icon(Icons.save_outlined),
          ),
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
            onTypeChanged: (type) {
              setState(() => _type = type);
            },
            recordEditor: _RecordEditor(
              controller: _bodyController,
              imagePaths: _imagePaths,
              audioPath: _audioPath,
              isRecording: _isRecording,
              onPickImage: _pickImage,
              onRemoveImage: (path) => setState(() {
                _imagePaths.remove(path);
              }),
              onVoicePressed: _isRecording ? _stopAndSaveVoice : _startVoice,
            ),
          ),
        ),
      ),
    );
  }

  MemoryItem? _findItem() {
    final items = ref.watch(memoryItemsControllerProvider);
    for (final item in items) {
      if (item.id == widget.itemId) {
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
    _status = item.status;
    _type =
        editableMemoryTypes.contains(item.type) ? item.type : MemoryType.note;
    _audioPath = item.audioPath;
    _audioDurationSeconds = item.audioDurationSeconds;
    _imagePaths
      ..clear()
      ..addAll(item.imagePaths);
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
    setState(() => _memoryDate = DateTime(date.year, date.month, date.day));
  }

  String _formattedDate(BuildContext context) {
    return DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
        .format(_memoryDate);
  }

  Future<void> _pickImage() async {
    const imageGroup = XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: [imageGroup]);
    if (file == null) {
      return;
    }

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final mimeType = file.mimeType ?? _mimeTypeForName(file.name);
      final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
      setState(() => _imagePaths.add(dataUrl));
      return;
    }

    setState(() => _imagePaths.add(file.path));
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

  Future<void> _save(MemoryItem item) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updated = item.copyWith(
      type: _type,
      title: _titleFromRecord(
        _bodyController.text,
        _type,
        Localizations.localeOf(context).languageCode,
      ),
      body: _bodyController.text.trim(),
      memoryDate: DateTime(
        _memoryDate.year,
        _memoryDate.month,
        _memoryDate.day,
      ),
      status: _status,
      audioPath: _audioPath,
      audioDurationSeconds: _audioDurationSeconds,
      imagePaths: List.unmodifiable(_imagePaths),
      updatedAt: DateTime.now(),
    );
    await ref.read(memoryItemsControllerProvider.notifier).update(updated);

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).saved)),
    );
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
    await ref.read(memoryItemsControllerProvider.notifier).delete(item.id);

    if (mounted) {
      _goBack();
    }
  }

  String _titleFromRecord(
    String body,
    MemoryType type,
    String languageCode,
  ) {
    final compact = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) {
      return type.label(languageCode);
    }
    if (compact.length <= 48) {
      return compact;
    }
    return '${compact.substring(0, 48)}...';
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }
}

class _EditorBody extends StatelessWidget {
  const _EditorBody({
    required this.selectedType,
    required this.onTypeChanged,
    required this.recordEditor,
  });

  final MemoryType selectedType;
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
                  _TypeEditor(
                    selectedType: selectedType,
                    compact: compact,
                    onTypeChanged: onTypeChanged,
                  ),
                  SizedBox(height: compact ? 8 : 12),
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

class _EditorTitle extends StatelessWidget {
  const _EditorTitle({
    required this.title,
    required this.dateText,
    required this.onDateTap,
  });

  final String title;
  final String dateText;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 2),
        InkWell(
          key: const ValueKey('memory_date_picker'),
          onTap: onDateTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Text(
              dateText,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordEditor extends StatelessWidget {
  const _RecordEditor({
    required this.controller,
    required this.imagePaths,
    required this.audioPath,
    required this.isRecording,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onVoicePressed,
  });

  final TextEditingController controller;
  final List<String> imagePaths;
  final String? audioPath;
  final bool isRecording;
  final VoidCallback onPickImage;
  final ValueChanged<String> onRemoveImage;
  final VoidCallback onVoicePressed;

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
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDE3EA)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, compact ? 8 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    decoration: InputDecoration(
                      labelText: strings.description,
                      alignLabelWithHint: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (audioPath != null) ...[
                  SizedBox(height: compact ? 8 : 10),
                  VoiceNotePlayer(path: audioPath!),
                ] else if (isRecording) ...[
                  SizedBox(height: compact ? 8 : 10),
                  _RecordingPill(text: strings.recordingNow),
                ],
                if (imagePaths.isNotEmpty) ...[
                  SizedBox(height: compact ? 8 : 12),
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
                                child: MemoryImagePreview(path: path),
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
                ],
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

class _TypeEditor extends StatelessWidget {
  const _TypeEditor({
    required this.selectedType,
    required this.onTypeChanged,
    this.compact = false,
  });

  final MemoryType selectedType;
  final ValueChanged<MemoryType> onTypeChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final label = selectedType.label(locale);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE3EA)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, compact ? 6 : 8, 12, compact ? 6 : 12),
        child: compact
            ? _TypeSelectorTile(
                type: selectedType,
                label: label,
                onTap: () => _showTypePicker(context),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.recordType,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _TypeSelectorTile(
                    type: selectedType,
                    label: label,
                    onTap: () => _showTypePicker(context),
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

class _TypeSelectorTile extends StatelessWidget {
  const _TypeSelectorTile({
    required this.type,
    required this.label,
    required this.onTap,
  });

  final MemoryType type;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(_iconFor(type), color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Icon(Icons.expand_more, color: color),
            ],
          ),
        ),
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
    final color = _typeColor(type);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: selected
            ? color.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected
                ? color.withValues(alpha: 0.36)
                : const Color(0xFFDDE3EA),
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(_iconFor(type), color: color),
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

IconData _iconFor(MemoryType type) {
  return switch (type) {
    MemoryType.task => Icons.check_circle_outline,
    MemoryType.note => Icons.notes,
    MemoryType.voiceNote => Icons.mic_none,
    MemoryType.event => Icons.event,
    MemoryType.person => Icons.person_outline,
    MemoryType.habit => Icons.repeat,
    MemoryType.goal => Icons.flag_outlined,
    MemoryType.project => Icons.folder_outlined,
    MemoryType.purchase => Icons.shopping_bag_outlined,
    MemoryType.document => Icons.description_outlined,
    MemoryType.place => Icons.place_outlined,
  };
}

Color _typeColor(MemoryType type) {
  return switch (type) {
    MemoryType.task => const Color(0xFF16A34A),
    MemoryType.note => const Color(0xFF2563EB),
    MemoryType.voiceNote => const Color(0xFFDB2777),
    MemoryType.event => const Color(0xFF7C3AED),
    MemoryType.person => const Color(0xFF0891B2),
    MemoryType.habit => const Color(0xFF059669),
    MemoryType.goal => const Color(0xFFEA580C),
    MemoryType.project => const Color(0xFF4F46E5),
    MemoryType.purchase => const Color(0xFFCA8A04),
    MemoryType.document => const Color(0xFF475569),
    MemoryType.place => const Color(0xFFDC2626),
  };
}
