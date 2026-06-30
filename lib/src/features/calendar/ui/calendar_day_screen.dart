import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';

import '../../../core/localization/app_strings.dart';
import '../../home_feed/domain/feed_rules.dart';
import '../../home_feed/ui/widgets/memory_image_preview.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/domain/memory_type.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../voice_notes/data/voice_note_storage.dart';
import '../../voice_notes/ui/widgets/voice_note_player.dart';

class CalendarDayScreen extends ConsumerStatefulWidget {
  const CalendarDayScreen({
    required this.date,
    super.key,
  });

  final DateTime date;

  @override
  ConsumerState<CalendarDayScreen> createState() => _CalendarDayScreenState();
}

class _CalendarDayScreenState extends ConsumerState<CalendarDayScreen> {
  final _messageController = TextEditingController();
  final _recorder = AudioRecorder();
  final _voiceStorage = VoiceNoteStorage();
  final _imagePaths = <String>[];
  DateTime? _recordingStartedAt;
  bool _isRecording = false;

  @override
  void dispose() {
    _messageController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final strings = AppStrings.of(context);
    final dayItems = ref
        .watch(memoryItemsControllerProvider)
        .where((item) => !item.isArchived && isSameDay(item.memoryDate, widget.date))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.go('/calendar'),
          icon: const Icon(Icons.arrow_back),
        ),
        titleSpacing: 0,
        title: Text(DateFormat.yMMMMEEEEd(locale).format(widget.date)),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFF3F3F3)),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: dayItems.isEmpty
                    ? Center(child: Text(strings.noMessagesForDay))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                        itemCount: dayItems.length,
                        itemBuilder: (context, index) {
                          final item = dayItems[index];
                          return _ChatBubble(
                            item: item,
                            onDelete: () => _confirmDelete(item),
                          );
                        },
                      ),
              ),
              _MessageComposer(
                controller: _messageController,
                imagePaths: _imagePaths,
                isRecording: _isRecording,
                onAttachImage: _pickImage,
                onRemoveImage: (path) => setState(() => _imagePaths.remove(path)),
                onSubmit: _sendTextAndImages,
                onVoicePressed: _isRecording ? _stopAndSaveVoice : _startVoice,
              ),
            ],
          ),
        ),
      ),
    );
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
    setState(() => _imagePaths.add(file.path));
  }

  Future<void> _sendTextAndImages() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _imagePaths.isEmpty) {
      return;
    }

    final strings = AppStrings.of(context);
    final title = text.isNotEmpty ? _titleFromText(text) : strings.photo;
    await _addItem(
      type: MemoryType.note,
      title: title,
      body: text,
      imagePaths: List.unmodifiable(_imagePaths),
    );

    if (!mounted) {
      return;
    }
    _messageController.clear();
    setState(() => _imagePaths.clear());
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
    final duration = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt).inSeconds;
    setState(() {
      _recordingStartedAt = null;
      _isRecording = false;
    });

    if (path == null) {
      return;
    }

    if (!mounted) {
      return;
    }
    final title = AppStrings.of(context).voiceMessage;
    await _addItem(
      type: MemoryType.voiceNote,
      title: title,
      audioPath: path,
      audioDurationSeconds: duration,
    );
  }

  Future<void> _addItem({
    required MemoryType type,
    required String title,
    String body = '',
    String? audioPath,
    int? audioDurationSeconds,
    List<String> imagePaths = const [],
  }) async {
    final now = DateTime.now();
    final item = MemoryItem(
      id: now.microsecondsSinceEpoch.toString(),
      type: type,
      title: title,
      body: body,
      memoryDate: widget.date,
      createdAt: now,
      updatedAt: now,
      audioPath: audioPath,
      audioDurationSeconds: audioDurationSeconds,
      imagePaths: imagePaths,
    );
    await ref.read(memoryItemsControllerProvider.notifier).add(item);
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

    if (confirmed == true) {
      await ref.read(memoryItemsControllerProvider.notifier).delete(item.id);
    }
  }

  String _titleFromText(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 48) {
      return compact;
    }
    return '${compact.substring(0, 48)}...';
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.item,
    required this.onDelete,
  });

  final MemoryItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final text = item.body.isNotEmpty ? item.body : item.title;

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD6E8FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.imagePaths.isNotEmpty) ...[
                          _BubbleImageGrid(paths: item.imagePaths),
                          if (text.isNotEmpty) const SizedBox(height: 8),
                        ],
                        if (item.audioPath != null)
                          VoiceNotePlayer(path: item.audioPath!),
                        if (text.isNotEmpty && item.type != MemoryType.voiceNote)
                          Text(text),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: AppStrings.of(context).delete,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(AppStrings.of(context).delete),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  DateFormat.Hm().format(item.createdAt),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleImageGrid extends StatelessWidget {
  const _BubbleImageGrid({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final path in paths)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 180,
              height: 128,
              child: MemoryImagePreview(path: path),
            ),
          ),
      ],
    );
  }
}

class _MessageComposer extends StatefulWidget {
  const _MessageComposer({
    required this.controller,
    required this.imagePaths,
    required this.isRecording,
    required this.onAttachImage,
    required this.onRemoveImage,
    required this.onSubmit,
    required this.onVoicePressed,
  });

  final TextEditingController controller;
  final List<String> imagePaths;
  final bool isRecording;
  final VoidCallback onAttachImage;
  final ValueChanged<String> onRemoveImage;
  final VoidCallback onSubmit;
  final VoidCallback onVoicePressed;

  @override
  State<_MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<_MessageComposer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final hasDraft =
        widget.controller.text.trim().isNotEmpty || widget.imagePaths.isNotEmpty;
    final canSend = hasDraft && !widget.isRecording;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.imagePaths.isNotEmpty)
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.imagePaths.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final path = widget.imagePaths[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 96,
                            height: 72,
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
                            onPressed: () => widget.onRemoveImage(path),
                            icon: const Icon(Icons.close, size: 14),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            Row(
              children: [
                IconButton(
                  tooltip: strings.addImage,
                  onPressed: widget.onAttachImage,
                  icon: const Icon(Icons.attach_file),
                ),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: strings.messageHint,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: canSend ? strings.save : strings.voice,
                  onPressed: canSend ? widget.onSubmit : widget.onVoicePressed,
                  icon: Icon(
                    canSend
                        ? Icons.send
                        : widget.isRecording
                            ? Icons.stop
                            : Icons.mic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onTextChanged() => setState(() {});
}
