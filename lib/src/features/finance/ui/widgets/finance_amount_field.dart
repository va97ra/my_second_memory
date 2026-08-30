import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FinanceAmountField extends StatelessWidget {
  const FinanceAmountField({
    required this.controller,
    required this.currencyCode,
    required this.validator,
    super.key,
  });

  final TextEditingController controller;
  final String currencyCode;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        key: const ValueKey('finance_amount'),
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
        ],
        decoration: InputDecoration(
          labelText: AppStrings.of(context).amount,
          suffixText: currencyCode,
        ),
        validator: validator,
      );
}
