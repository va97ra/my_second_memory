import 'package:flutter_test/flutter_test.dart';
import 'package:ez_data/ez_data.dart';

void main() {
  test('notification ids are stable, positive and record-specific', () {
    final first = stableNotificationId('record-1');

    expect(first, stableNotificationId('record-1'));
    expect(first, greaterThanOrEqualTo(0));
    expect(first, isNot(stableNotificationId('record-2')));
  });

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
}
