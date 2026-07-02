import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../home_feed/ui/widgets/memory_image_preview.dart';
import '../../voice_notes/ui/widgets/voice_note_player.dart';
import '../domain/memory_item.dart';
import '../domain/memory_status.dart';
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
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imagePaths = <String>[];

  String? _loadedItemId;
  DateTime _memoryDate = DateTime.now();
  MemoryStatus _status = MemoryStatus.active;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
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
        title: Text(strings.editRecord),
        actions: [
          IconButton(
            tooltip: strings.save,
            onPressed: () => _save(item),
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _DonePanel(
                value: _status == MemoryStatus.done,
                onChanged: (value) {
                  setState(() {
                    _status = value ? MemoryStatus.done : MemoryStatus.active;
                  });
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: strings.title),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return strings.title;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                decoration: InputDecoration(labelText: strings.description),
                minLines: 4,
                maxLines: 10,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  '${strings.date}: ${DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(_memoryDate)}',
                ),
              ),
              if (item.audioPath != null) ...[
                const SizedBox(height: 16),
                VoiceNotePlayer(path: item.audioPath!),
              ],
              const SizedBox(height: 18),
              _ImagesEditor(
                imagePaths: _imagePaths,
                onAdd: _pickImage,
                onRemove: (path) => setState(() => _imagePaths.remove(path)),
              ),
            ],
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
    _titleController.text = item.title;
    _bodyController.text = item.body;
    _memoryDate = item.memoryDate;
    _status = item.status;
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

  Future<void> _save(MemoryItem item) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updated = item.copyWith(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      memoryDate: DateTime(
        _memoryDate.year,
        _memoryDate.month,
        _memoryDate.day,
      ),
      status: _status,
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

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }
}

class _DonePanel extends StatelessWidget {
  const _DonePanel({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    const color = Color(0xFF16A34A);

    return Material(
      color: value ? const Color(0xFFEAF8EF) : const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: value ? const Color(0xFF86EFAC) : const Color(0xFFDDE3EA),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: color,
        secondary: Icon(
          value ? Icons.check_circle : Icons.check_circle_outline,
          color: color,
        ),
        title: Text(
          strings.completed,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: value ? const Color(0xFF14532D) : null,
              ),
        ),
      ),
    );
  }
}

class _ImagesEditor extends StatelessWidget {
  const _ImagesEditor({
    required this.imagePaths,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> imagePaths;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE3EA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.photo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(strings.addImage),
                ),
              ],
            ),
            if (imagePaths.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final path in imagePaths)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 148,
                            height: 108,
                            child: MemoryImagePreview(path: path),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: IconButton.filledTonal(
                            constraints: const BoxConstraints.tightFor(
                              width: 28,
                              height: 28,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: strings.delete,
                            onPressed: () => onRemove(path),
                            icon: const Icon(Icons.close, size: 16),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
