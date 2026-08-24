import 'dart:convert';
import 'dart:io';

import 'package:ez_domain/ez_domain.dart';
import 'package:ez_data/ez_data.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length < 3 || !{'encode', 'decode'}.contains(arguments.first)) {
    throw ArgumentError(
      'Usage: dart run tool/sync_probe.dart encode|decode BASE64_KEY VALUE',
    );
  }
  final cipher = AppCipher.fromKeyBytes(base64Decode(arguments[1]));
  try {
    if (arguments.first == 'encode') {
      final now = DateTime.utc(2026, 8, 18, 12);
      final item = MemoryItem(
        id: 'sync-probe',
        type: MemoryType.note,
        title: arguments[2],
        memoryDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final encrypted = await cipher.encryptString(jsonEncode(item.toJson()));
      stdout.writeln(base64Encode(utf8.encode(encrypted)));
      return;
    }

    final encrypted = utf8.decode(base64Decode(arguments[2]));
    final json = Map<String, Object?>.from(
      jsonDecode(await cipher.decryptString(encrypted)) as Map,
    );
    stdout.writeln(MemoryItem.fromJson(json).title);
  } finally {
    cipher.destroy();
  }
}
