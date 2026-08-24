import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Поле ввода PIN.
///
/// Подсказки, автозамены и обучение клавиатуры выключены: PIN не должен
/// попасть ни в словарь, ни в автозаполнение.
class PinField extends StatelessWidget {
  const PinField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      obscureText: true,
      maxLength: 8,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      autofillHints: const <String>[],
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 6),
      decoration: const InputDecoration(labelText: 'PIN', counterText: ''),
      onSubmitted: (_) => onSubmitted(),
    );
  }
}
