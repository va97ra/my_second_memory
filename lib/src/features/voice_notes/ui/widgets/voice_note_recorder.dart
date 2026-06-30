import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../../../../core/localization/app_strings.dart';
import '../../data/voice_note_storage.dart';

class VoiceNoteRecorder extends StatefulWidget {
  const VoiceNoteRecorder({
    required this.onSaved,
    super.key,
  });

  final void Function(String path, int durationSeconds) onSaved;

  @override
  State<VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

class _VoiceNoteRecorderState extends State<VoiceNoteRecorder> {
  final _recorder = AudioRecorder();
  final _storage = VoiceNoteStorage();
  DateTime? _startedAt;
  bool _isRecording = false;
  String? _savedPath;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.voice, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_savedPath != null)
              Text(
                _savedPath!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isRecording ? _stop : _start,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(
                _isRecording ? strings.stopRecording : strings.startRecording,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      return;
    }

    final path = await _storage.buildNewPath();
    await _recorder.start(const RecordConfig(), path: path);
    setState(() {
      _startedAt = DateTime.now();
      _isRecording = true;
      _savedPath = path;
    });
  }

  Future<void> _stop() async {
    final path = await _recorder.stop();
    final startedAt = _startedAt;
    final duration = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt).inSeconds;

    setState(() => _isRecording = false);

    if (path != null) {
      widget.onSaved(path, duration);
    }
  }
}
