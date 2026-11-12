import 'package:flutter_test/flutter_test.dart';
import 'package:ez_data/ez_data.dart';

void main() {
  test('reminder payload is decoded safely', () {
    expect(
      decodeReminderPayload(
        '{"source":"memory_reminder","itemId":"record-1"}',
      ),
      containsPair('itemId', 'record-1'),
    );
    expect(decodeReminderPayload('not-json'), isNull);
    expect(decodeReminderPayload(null), isNull);
  });

  test('a pending notification is read with its source and fingerprint', () {
    final pending = pendingReminderOf(
      42,
      '{"source":"recurrence_reminder","itemId":"a","fingerprint":17}',
    );

    expect(pending.notificationId, 42);
    expect(pending.source, 'recurrence_reminder');
    expect(pending.fingerprint, 17);
  });

  test('a payload from an older version has no fingerprint', () {
    final pending = pendingReminderOf(
      42,
      '{"source":"memory_reminder","itemId":"a"}',
    );

    expect(pending.fingerprint, isNull);
  });
}
