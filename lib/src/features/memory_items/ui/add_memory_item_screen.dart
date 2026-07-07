import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../voice_notes/ui/widgets/voice_note_recorder.dart';
import '../domain/memory_item.dart';
import '../domain/memory_type.dart';
import '../state/memory_items_controller.dart';
import 'widgets/memory_type_picker.dart';

class AddMemoryItemScreen extends ConsumerStatefulWidget {
  const AddMemoryItemScreen({super.key});

  @override
  ConsumerState<AddMemoryItemScreen> createState() =>
      _AddMemoryItemScreenState();
}

class _AddMemoryItemScreenState extends ConsumerState<AddMemoryItemScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  MemoryType _type = MemoryType.task;
  DateTime _memoryDate = DateTime.now();
  String? _audioPath;
  int? _audioDurationSeconds;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(strings.add),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              MemoryTypePicker(
                selected: _type,
                onSelected: (type) => setState(() => _type = type),
              ),
              const SizedBox(height: 16),
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
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  '${strings.date}: ${DateFormat.yMMMd(locale).format(_memoryDate)}',
                ),
              ),
              if (_type == MemoryType.voiceNote) ...[
                const SizedBox(height: 16),
                VoiceNoteRecorder(
                  onSaved: (path, duration) {
                    setState(() {
                      _audioPath = path;
                      _audioDurationSeconds = duration;
                    });
                  },
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(strings.save),
              ),
            ],
          ),
        ),
      ),
    );
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
    setState(() => _memoryDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_type == MemoryType.voiceNote && _audioPath == null) {
      final strings = AppStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.recordAudioBeforeSaving)),
      );
      return;
    }

    final now = DateTime.now();
    final item = MemoryItem(
      id: now.microsecondsSinceEpoch.toString(),
      type: _type,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      memoryDate:
          DateTime(_memoryDate.year, _memoryDate.month, _memoryDate.day),
      createdAt: now,
      updatedAt: now,
      audioPath: _audioPath,
      audioDurationSeconds: _audioDurationSeconds,
    );

    await ref.read(memoryItemsControllerProvider.notifier).add(item);

    if (mounted) {
      context.go('/');
    }
  }
}
