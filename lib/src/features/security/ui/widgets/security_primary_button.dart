import 'package:flutter/material.dart';

/// Главная кнопка карточки замка. Пока идёт работа, вместо значка крутится
/// колесо, а сама кнопка не нажимается.
class SecurityPrimaryButton extends StatelessWidget {
  const SecurityPrimaryButton({
    super.key,
    required this.busy,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool busy;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: busy ? null : onPressed,
        icon: busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(label),
      ),
    );
  }
}
