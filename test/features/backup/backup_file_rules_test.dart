import 'package:ezhednevnik_v2/src/features/backup/state/backup_file_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('имя копии несёт дату и время съёма', () {
    expect(
      backupFileName(DateTime(2026, 8, 24, 18, 5)),
      'ezhednevnik_v2_backup_20260824_1805.zip',
    );
  });

  test('зашифрованная копия узнаётся по началу zip', () {
    expect(looksLikeZip([0x50, 0x4B, 0x03, 0x04, 0x00]), isTrue);
    expect(looksLikeZip('{"items":[]}'.codeUnits), isFalse);
    expect(looksLikeZip([0x50, 0x4B]), isFalse);
    expect(looksLikeZip(const []), isFalse);
  });
}
