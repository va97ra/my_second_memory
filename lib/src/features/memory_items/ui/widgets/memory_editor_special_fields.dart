import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../state/memory_editor_form.dart';
import 'birthday_fields.dart';
import 'payment_fields.dart';

/// Поля, которые есть только у некоторых видов записи: сумма у платежа и год
/// рождения у дня рождения.
class MemoryEditorSpecialFields extends StatelessWidget {
  const MemoryEditorSpecialFields({
    super.key,
    required this.form,
    required this.amountController,
    required this.canEditSubscriptionTerm,
    required this.onCategoryChanged,
    required this.onChanged,
    required this.onSubscriptionTermTap,
    required this.onBirthYearTap,
    required this.onClearBirthYear,
  });

  /// Есть ли у этого вида записи собственные поля.
  static bool supports(MemoryType type) =>
      type == MemoryType.payment || type == MemoryType.birthday;

  final MemoryEditorForm form;
  final TextEditingController amountController;
  final bool canEditSubscriptionTerm;
  final ValueChanged<PaymentCategory> onCategoryChanged;
  final VoidCallback onChanged;
  final VoidCallback onSubscriptionTermTap;
  final VoidCallback onBirthYearTap;
  final VoidCallback? onClearBirthYear;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    if (form.type == MemoryType.payment) {
      return PaymentFields(
        amountController: amountController,
        category: form.paymentCategory,
        locale: locale,
        onCategoryChanged: onCategoryChanged,
        onChanged: onChanged,
        subscriptionTermMonths: form.subscriptionTermMonths,
        onSubscriptionTermTap:
            canEditSubscriptionTerm ? onSubscriptionTermTap : null,
      );
    }

    return BirthdayFields(
      birthYear: form.birthYear,
      locale: locale,
      onTap: onBirthYearTap,
      onClear: onClearBirthYear,
    );
  }
}
