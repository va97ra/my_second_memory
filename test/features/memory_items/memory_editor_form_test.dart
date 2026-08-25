import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_editor_form.dart';
import 'package:flutter_test/flutter_test.dart';

MemoryItem _item({
  MemoryType type = MemoryType.note,
  String? repeatRule,
  String? seriesId,
  String? paymentCategory,
  int? birthYear,
  DateTime? memoryDate,
}) {
  final date = memoryDate ?? DateTime(2026, 5, 20);
  return MemoryItem(
    id: 'item',
    type: type,
    title: 'Запись',
    body: 'Запись',
    memoryDate: date,
    createdAt: date,
    updatedAt: date,
    repeatRule: repeatRule,
    seriesId: seriesId,
    paymentCategory: paymentCategory,
    birthYear: birthYear,
  );
}

void main() {
  test('a birthday repeats yearly and warns a day ahead', () {
    final form = MemoryEditorForm.blank(
      date: DateTime(2026, 5, 20),
      isUndated: false,
    ).withType(MemoryType.birthday);

    expect(form.recurrenceFrequency, RecurrenceFrequency.yearly);
    expect(form.timeMinutes, 9 * 60);
    expect(form.remindAt, DateTime(2026, 5, 19, 9));
  });

  test('a payment repeats monthly and warns three days ahead', () {
    final form = MemoryEditorForm.blank(
      date: DateTime(2026, 5, 20),
      isUndated: false,
    ).withType(MemoryType.payment);

    expect(form.recurrenceFrequency, RecurrenceFrequency.monthly);
    expect(form.remindAt, DateTime(2026, 5, 17, 9));
  });

  test('leaving payment drops the subscription term and marks it changed', () {
    final payment = MemoryEditorForm.blank(
      date: DateTime(2026, 5, 20),
      isUndated: false,
    ).withType(MemoryType.payment).copyWith(
          paymentCategory: PaymentCategory.subscription,
          subscriptionTermMonths: 6,
          subscriptionTermDirty: false,
        );

    final note = payment.withType(MemoryType.note);

    expect(note.subscriptionTermMonths, isNull);
    expect(note.subscriptionTermDirty, isTrue);
  });

  test('only a subscription keeps a term', () {
    final form = MemoryEditorForm.blank(
      date: DateTime(2026, 5, 20),
      isUndated: false,
    ).withType(MemoryType.payment).copyWith(
          paymentCategory: PaymentCategory.subscription,
          subscriptionTermMonths: 12,
        );

    final utilities = form.withPaymentCategory(PaymentCategory.utilities);

    expect(utilities.subscriptionTermMonths, isNull);
    expect(utilities.subscriptionTermDirty, isTrue);
  });

  test('dropping the monthly repeat clears the subscription term', () {
    final subscription = MemoryEditorForm.blank(
      date: DateTime(2026, 5, 20),
      isUndated: false,
    ).withType(MemoryType.payment).copyWith(
          paymentCategory: PaymentCategory.subscription,
          subscriptionTermMonths: 6,
          subscriptionTermDirty: false,
        );

    final yearly = subscription.withRecurrence(RecurrenceFrequency.yearly);
    expect(yearly.subscriptionTermMonths, isNull);
    expect(yearly.subscriptionTermDirty, isTrue);

    final none = subscription.withRecurrence(null);
    expect(none.recurrenceFrequency, isNull);
    expect(none.subscriptionTermMonths, isNull);
    expect(none.subscriptionTermDirty, isTrue);

    // Ежемесячный повтор — единственный, при котором срок имеет смысл.
    final monthly = subscription.withRecurrence(RecurrenceFrequency.monthly);
    expect(monthly.subscriptionTermMonths, 6);
    expect(monthly.subscriptionTermDirty, isFalse);
  });

  test('an unknown record type opens as a note instead of being lost', () {
    final form = MemoryEditorForm.fromItem(_item(type: MemoryType.habit));

    expect(form.type, MemoryType.note);
  });

  test('an occurrence remembers the date it was opened on', () {
    final standalone = MemoryEditorForm.fromItem(_item());
    final occurrence = MemoryEditorForm.fromItem(
      _item(
        seriesId: 'series',
        repeatRule: RecurrenceFrequency.monthly.name,
        memoryDate: DateTime(2026, 7, 20),
      ),
    );

    expect(standalone.originalOccurrenceDate, isNull);
    expect(occurrence.originalOccurrenceDate, DateTime(2026, 7, 20));
    expect(occurrence.recurrenceFrequency, RecurrenceFrequency.monthly);
  });

  test('the draft carries only the fields the type actually has', () {
    final birthday = MemoryEditorForm.blank(
      date: DateTime(2026, 5, 20),
      isUndated: false,
    ).withType(MemoryType.birthday).copyWith(birthYear: 1958);

    final draft = birthday.toDraft(
      title: 'Слава',
      body: 'Слава',
      amountMinor: null,
      savedAt: DateTime(2026, 5, 20, 12),
    );

    expect(draft.birthYear, 1958);
    expect(draft.paymentCategory, isNull);
    expect(draft.subscriptionTermMonths, isNull);
    expect(draft.repeatRule, RecurrenceFrequency.yearly.name);

    final note = birthday.withType(MemoryType.note).copyWith(birthYear: 1958);
    final noteDraft = note.toDraft(
      title: 'Слава',
      body: 'Слава',
      amountMinor: null,
      savedAt: DateTime(2026, 5, 20, 12),
    );
    expect(noteDraft.birthYear, isNull);
  });
}
