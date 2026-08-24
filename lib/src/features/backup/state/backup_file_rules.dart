import 'package:intl/intl.dart';

/// Имя файла копии: по нему видно, какого числа её сняли.
String backupFileName(DateTime now) {
  final stamp = DateFormat('yyyyMMdd_HHmm').format(now);
  return 'ezhednevnik_v2_backup_$stamp.zip';
}

/// Зашифрованная копия — это zip, а незашифрованная — голый JSON. Пароль
/// спрашивают только у первой, и отличают их по началу файла.
bool looksLikeZip(List<int> bytes) {
  return bytes.length >= 4 &&
      bytes[0] == 0x50 &&
      bytes[1] == 0x4B &&
      bytes[2] == 0x03 &&
      bytes[3] == 0x04;
}
