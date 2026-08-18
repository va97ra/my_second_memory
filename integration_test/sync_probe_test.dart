import 'dart:convert';

import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/security/data/app_cipher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android reads a Windows payload and returns an encrypted edit',
      (tester) async {
    const encodedKey = String.fromEnvironment('SYNC_PROBE_KEY');
    const encodedPayload = String.fromEnvironment('SYNC_PROBE_PAYLOAD');
    expect(encodedKey, isNotEmpty);
    expect(encodedPayload, isNotEmpty);

    final cipher = AppCipher.fromKeyBytes(base64Decode(encodedKey));
    addTearDown(cipher.destroy);
    final encrypted = utf8.decode(base64Decode(encodedPayload));
    final json = Map<String, Object?>.from(
      jsonDecode(await cipher.decryptString(encrypted)) as Map,
    );
    final windowsItem = MemoryItem.fromJson(json);
    expect(windowsItem.title, 'Windows probe');

    final androidItem = windowsItem.copyWith(
      title: 'Android probe',
      updatedAt: windowsItem.updatedAt.add(const Duration(minutes: 1)),
    );
    final androidPayload = await cipher.encryptString(
      jsonEncode(androidItem.toJson()),
    );
    // The host-side probe reads this marker and decrypts the returned payload.
    debugPrint(
      'SYNC_PROBE_RESULT=${base64Encode(utf8.encode(androidPayload))}',
    );
  });
}
