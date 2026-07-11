import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../media/data/media_storage.dart';
import '../../security/data/app_cipher.dart';
import '../../security/state/security_provider.dart';

final voiceNotePlaybackProvider = Provider<VoiceNotePlaybackController>((ref) {
  final controller = VoiceNotePlaybackController(
    ref.watch(securitySessionProvider).cipher,
  );
  ref.onDispose(() => unawaited(controller.dispose()));
  return controller;
});

class VoiceNotePlaybackController {
  VoiceNotePlaybackController(this._cipher);

  final AppCipher? _cipher;
  final _mediaStorage = MediaStorage();
  final player = AudioPlayer();
  String? activePath;
  String? _temporaryPath;

  Stream<PlayerState> get playerStateStream => player.playerStateStream;

  Future<void> toggle(String path) async {
    if (activePath == path && player.playing) {
      await player.pause();
      return;
    }
    if (activePath != path) {
      await player.stop();
      await _clearTemporaryAudio();
      activePath = path;
      final cipher = _cipher;
      final playablePath = path.endsWith('.ezm') && cipher != null
          ? await _mediaStorage.materializeAudio(path, cipher)
          : path;
      if (playablePath != path) _temporaryPath = playablePath;
      await player.setFilePath(playablePath);
    }
    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero);
    }
    await player.play();
  }

  Future<void> _clearTemporaryAudio() async {
    final path = _temporaryPath;
    _temporaryPath = null;
    if (path != null) await _mediaStorage.deleteTemporaryAudio(path);
  }

  Future<void> dispose() async {
    await player.dispose();
    await _clearTemporaryAudio();
  }
}
