import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../state/security_provider.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _pinController = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.pinSecurity)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 8,
            decoration: const InputDecoration(labelText: 'PIN'),
          ),
          FilledButton.icon(
            onPressed: _savePin,
            icon: const Icon(Icons.lock),
            label: Text(strings.save),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _tryBiometrics,
            icon: const Icon(Icons.fingerprint),
            label: Text(strings.biometrics),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!),
          ],
        ],
      ),
    );
  }

  Future<void> _savePin() async {
    await ref
        .read(securityServiceProvider)
        .setPin(_pinController.text.trim());
    if (!mounted) return;
    setState(() => _message = AppStrings.of(context).pinSaved);
  }

  Future<void> _tryBiometrics() async {
    final ok =
        await ref.read(securityServiceProvider).authenticateWithBiometrics();
    if (!mounted) return;
    final strings = AppStrings.of(context);
    setState(
      () => _message = ok ? strings.biometricsOk : strings.biometricsUnavailable,
    );
  }
}
