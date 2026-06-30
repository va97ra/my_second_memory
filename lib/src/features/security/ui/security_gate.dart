import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../state/security_provider.dart';

class SecurityGate extends ConsumerStatefulWidget {
  const SecurityGate({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  ConsumerState<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends ConsumerState<SecurityGate> {
  final _pinController = TextEditingController();
  bool _isLoading = true;
  bool _hasPin = false;
  bool _isUnlocked = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPin || _isUnlocked) {
      return widget.child;
    }

    final strings = AppStrings.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 42),
                  const SizedBox(height: 18),
                  Text(
                    strings.pinSecurity,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 8,
                    decoration: const InputDecoration(labelText: 'PIN'),
                    onSubmitted: (_) => _unlockWithPin(),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _unlockWithPin,
                    icon: const Icon(Icons.lock_open),
                    label: Text(strings.unlock),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _unlockWithBiometrics,
                    icon: const Icon(Icons.fingerprint),
                    label: Text(strings.biometrics),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    final hasPin = await ref.read(securityServiceProvider).hasPin();
    if (!mounted) {
      return;
    }
    setState(() {
      _hasPin = hasPin;
      _isLoading = false;
    });
  }

  Future<void> _unlockWithPin() async {
    final ok = await ref
        .read(securityServiceProvider)
        .verifyPin(_pinController.text.trim());
    if (!mounted) {
      return;
    }
    setState(() {
      _isUnlocked = ok;
      _error = ok ? null : AppStrings.of(context).wrongPin;
    });
  }

  Future<void> _unlockWithBiometrics() async {
    final ok =
        await ref.read(securityServiceProvider).authenticateWithBiometrics();
    if (!mounted) {
      return;
    }
    setState(() {
      _isUnlocked = ok;
      _error = ok ? null : AppStrings.of(context).biometricsUnavailable;
    });
  }
}
