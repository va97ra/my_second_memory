import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/localization/app_strings.dart';

class VoiceNotePlayer extends StatefulWidget {
  const VoiceNotePlayer({
    required this.path,
    super.key,
  });

  final String path;

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return OutlinedButton.icon(
      onPressed: _toggle,
      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
      label: Text(strings.play),
    );
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }

    await _player.setFilePath(widget.path);
    if (mounted) {
      setState(() => _isPlaying = true);
    }
    await _player.play();
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }
}
