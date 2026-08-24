import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

/// Спрашивает действующий PIN — им подтверждают отключение защиты.
Future<String?> askCurrentPin(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const CurrentPinDialog(),
  );
}

/// Ввод действующего PIN.
class CurrentPinDialog extends StatefulWidget {
  const CurrentPinDialog({super.key});

  @override
  State<CurrentPinDialog> createState() => _CurrentPinDialogState();
}

class _CurrentPinDialogState extends State<CurrentPinDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return AlertDialog(
      title: Text(strings.currentPin),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'PIN'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(strings.unlock)),
      ],
    );
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());
}
