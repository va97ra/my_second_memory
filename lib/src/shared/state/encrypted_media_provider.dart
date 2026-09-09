import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/security/security.dart';
import 'package:ez_data/ez_data.dart';

/// Открытые байты вложения.
///
/// Зашифрован файл на диске или нет, решает сам файл, а не состояние
/// устройства: на одном и том же компьютере снимок, сделанный здесь, лежит
/// открытым, а приехавший синхронизацией — зашифрованным. Хранилище находит
/// ту форму, которая есть, и ключ ему нужен только для второй.
///
/// `autoDispose`: байты снимка — это мегабайты, и держать их после того, как
/// картинка ушла с экрана, незачем.
final mediaBytesProvider =
    FutureProvider.autoDispose.family<Uint8List, String>((ref, reference) {
  final cipher = ref.watch(securitySessionProvider).cipher;
  return MediaStorage().readPlainBytes(reference, cipher);
});
