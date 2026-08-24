import 'package:flutter/material.dart';

/// Сообщение об ошибке под карточкой замка.
class SecurityErrorText extends StatelessWidget {
  const SecurityErrorText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
