import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/security/state/security_provider.dart';
import 'package:ez_data/ez_data.dart';

final encryptedMediaBytesProvider =
    FutureProvider.family<Uint8List, String>((ref, path) async {
  final cipher = ref.watch(securitySessionProvider).cipher;
  if (cipher == null) throw StateError('Application is locked');
  return MediaStorage().readEncryptedBytes(path, cipher);
});
