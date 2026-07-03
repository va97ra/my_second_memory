import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';

import '../../../core/localization/app_strings.dart';
import '../../home_feed/domain/feed_rules.dart';
import '../../home_feed/ui/widgets/memory_image_preview.dart';
import '../../home_feed/ui/widgets/memory_image_viewer.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/domain/memory_type.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../shift_schedules/domain/shift_schedule.dart';
import '../../shift_schedules/state/shift_schedules_controller.dart';
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
        .where((item) =>
            !item.isArchived && isSameDay(item.memoryDate, widget.date))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final workingSchedules = ref
        .watch(shiftSchedulesControllerProvider)
        .where((schedule) => schedule.isWorkday(widget.date))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7ECDB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF3E8),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.go('/calendar'),
          icon: const Icon(Icons.arrow_back),
        ),
        titleSpacing: 0,
        title: Text(
          DateFormat.yMMMMEEEEd(locale).format(widget.date),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF172033),
              ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFDDE7F3)),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFBF3E8),
              Color(0xFFF7ECDB),
              Color(0xFFFCF7EF),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              if (workingSchedules.isNotEmpty)
                _WorkingShiftChips(schedules: workingSchedules),
              Expanded(
                child: dayItems.isEmpty
                    ? Center(
                        child: _EmptyDayMessage(text: strings.noMessagesForDay),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
                        itemCount: dayItems.length,
                        itemBuilder: (context, index) {
                          final item = dayItems[index];
                          return _ChatBubble(
                            item: item,
                            onOpen: () {
                              context.push(
                                '/memory/item/${Uri.encodeComponent(item.id)}',
                              );
                            },
                          );
                        },
                      ),
              ),
              _MessageComposer(
                controller: _messageController,
                imagePaths: _imagePaths,
                isRecording: _isRecording,
                onAttachImage: _pickImage,
                onRemoveImage: (path) =>
                    setState(() => _imagePaths.remove(path)),
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

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final mimeType = file.mimeType ?? _mimeTypeForName(file.name);
      final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
      setState(() => _imagePaths.add(dataUrl));
      return;
    }

    setState(() => _imagePaths.add(file.path));
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
    final duration =
        startedAt == null ? 0 : DateTime.now().difference(startedAt).inSeconds;
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

  String _titleFromText(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 48) {
      return compact;
    }
    return '${compact.substring(0, 48)}...';
  }
}

class _WorkingShiftChips extends StatelessWidget {
  const _WorkingShiftChips({required this.schedules});

  final List<ShiftSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final schedule in schedules)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(schedule.colorValue).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Color(schedule.colorValue).withValues(alpha: 0.34),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(schedule.colorValue),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const SizedBox(width: 10, height: 10),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${strings.workingToday}: ${schedule.organizationName}',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: const Color(0xFF172033),
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDayMessage extends StatelessWidget {
  const _EmptyDayMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE7F3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(
                width: 34,
                height: 34,
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF2563EB),
                  size: 19,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.item,
    required this.onOpen,
  });

  final MemoryItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = item.body.isNotEmpty ? item.body : item.title;
    final color = _typeColor(item.type);
    final bubbleColor =
        item.isDone ? const Color(0xFFEAF8EF) : color.withValues(alpha: 0.11);
    final borderColor =
        item.isDone ? const Color(0xFF86EFAC) : color.withValues(alpha: 0.24);

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(3),
                  ),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.07),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.imagePaths.isNotEmpty) ...[
                      _BubbleImageGrid(paths: item.imagePaths),
                      if (text.isNotEmpty) const SizedBox(height: 8),
                    ],
                    if (item.audioPath != null)
                      VoiceNotePlayer(path: item.audioPath!),
                    if (text.isNotEmpty && item.type != MemoryType.voiceNote)
                      Text(
                        text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF172033),
                              height: 1.28,
                            ),
                      ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        DateFormat.Hm().format(item.createdAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('chat_image_$path'),
              onTap: () => openMemoryImageViewer(context, path),
              borderRadius: BorderRadius.circular(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 180,
                  height: 128,
                  child: MemoryImagePreview(path: path),
                ),
              ),
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
    final hasDraft = widget.controller.text.trim().isNotEmpty ||
        widget.imagePaths.isNotEmpty;
    final canSend = hasDraft && !widget.isRecording;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: Color(0xFFDDE7F3))),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.imagePaths.isNotEmpty)
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.imagePaths.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final path = widget.imagePaths[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 96,
                            height: 72,
                            child: GestureDetector(
                              key: ValueKey('composer_image_$path'),
                              onTap: () => openMemoryImageViewer(context, path),
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
                _ComposerActionButton(
                  tooltip: strings.addImage,
                  icon: Icons.photo_camera_outlined,
                  color: const Color(0xFF2563EB),
                  onPressed: widget.onAttachImage,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: strings.messageHint,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFD6E2EF),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.4,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ComposerActionButton(
                  tooltip: canSend ? strings.save : strings.voice,
                  icon: canSend
                      ? Icons.send
                      : widget.isRecording
                          ? Icons.stop
                          : Icons.mic_none,
                  color: canSend
                      ? const Color(0xFF2563EB)
                      : widget.isRecording
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFDB2777),
                  onPressed: canSend ? widget.onSubmit : widget.onVoicePressed,
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

class _ComposerActionButton extends StatelessWidget {
  const _ComposerActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        fixedSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.13),
        side: BorderSide(color: color.withValues(alpha: 0.28)),
      ),
    );
  }
}
