import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final voiceNotePlaybackProvider = Provider<VoiceNotePlaybackController>((ref) {
  final controller = VoiceNotePlaybackController();
  ref.onDispose(() => unawaited(controller.dispose()));
  return controller;
});

class VoiceNotePlaybackController {
  final player = AudioPlayer();
  String? activePath;

  Stream<PlayerState> get playerStateStream => player.playerStateStream;

  Future<void> toggle(String path) async {
    if (activePath == path && player.playing) {
      await player.pause();
      return;
    }
    if (activePath != path) {
      await player.stop();
      activePath = path;
      await player.setFilePath(path);
    }
    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero);
    }
    await player.play();
  }

  Future<void> dispose() => player.dispose();
}
