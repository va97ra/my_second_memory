import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

/// Спрашивает пароль копии. Пустой пароль и отказ — одно и то же: копию без
/// пароля не снимают.
Future<String?> askBackupPassword(
  BuildContext context, {
  required String title,
  required bool confirmPassword,
  required String submitLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => BackupPasswordDialog(
      title: title,
      confirmPassword: confirmPassword,
      submitLabel: submitLabel,
    ),
  );
}

/// Ввод пароля резервной копии, при создании — с повтором.
class BackupPasswordDialog extends StatefulWidget {
  const BackupPasswordDialog({
    super.key,
    required this.title,
    required this.confirmPassword,
    required this.submitLabel,
  });

  final String title;
  final bool confirmPassword;
  final String submitLabel;

  @override
  State<BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<BackupPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscureText = true;
  String? _confirmationError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('backup_password'),
              controller: _passwordController,
              autofocus: true,
              obscureText: _obscureText,
              textInputAction: widget.confirmPassword
                  ? TextInputAction.next
                  : TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: strings.backupPassword,
                helperText: strings.backupPasswordHint,
                helperMaxLines: 2,
                suffixIcon: _visibilityButton(strings),
              ),
              onChanged: (_) => _clearError(),
              onSubmitted: widget.confirmPassword ? null : (_) => _submit(),
            ),
            if (widget.confirmPassword) ...[
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('backup_password_confirmation'),
                controller: _confirmationController,
                obscureText: _obscureText,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: strings.repeatBackupPassword,
                  errorText: _confirmationError,
                ),
                onChanged: (_) => _clearError(),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          key: const ValueKey('backup_password_submit'),
          onPressed: _submit,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }

  Widget _visibilityButton(AppStrings strings) {
    return IconButton(
      tooltip: _obscureText ? strings.showPassword : strings.hidePassword,
      onPressed: () => setState(() => _obscureText = !_obscureText),
      icon: Icon(
        _obscureText ? Icons.visibility_rounded : Icons.visibility_off_rounded,
      ),
    );
  }

  void _clearError() {
    if (_confirmationError == null) return;
    setState(() => _confirmationError = null);
  }

  /// Пароль копии восстановить нечем, поэтому при создании его набирают
  /// дважды.
  void _submit() {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;
    if (widget.confirmPassword &&
        password != _confirmationController.text.trim()) {
      setState(() {
        _confirmationError = AppStrings.of(context).backupPasswordsDoNotMatch;
      });
      return;
    }
    Navigator.of(context).pop(password);
  }
}
