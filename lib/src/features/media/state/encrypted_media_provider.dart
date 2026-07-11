import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../security/state/security_provider.dart';
import '../data/media_storage.dart';

final encryptedMediaBytesProvider =
    FutureProvider.family<List<int>, String>((ref, path) async {
  final cipher = ref.watch(securitySessionProvider).cipher;
  if (cipher == null) throw StateError('Application is locked');
  return MediaStorage().readEncryptedBytes(path, cipher);
});
