import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/ui/screen_chrome.dart';
import '../state/security_provider.dart';
import 'security_actions.dart';
import 'widgets/security_settings_card.dart';

/// PIN и биометрия: чем закрыты данные приложения.
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
      appBar: AppPageAppBar(
        fallbackLocation: '/settings',
        title: Text(strings.pinSecurity),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SecuritySettingsCard(
            session: ref.watch(securitySessionProvider),
            pinController: _pinController,
            message: _message,
            onSavePin: _savePin,
            onDisablePin: _disablePin,
            onBiometricsChanged: _setBiometricsEnabled,
          ),
        ],
      ),
    );
  }

  SecurityActions get _actions => SecurityActions(context: context, ref: ref);

  Future<void> _savePin() async {
    final pin = _pinController.text.trim();
    _pinController.clear();
    _report(await _actions.savePin(pin));
  }

  Future<void> _disablePin() async => _report(await _actions.disablePin());

  Future<void> _setBiometricsEnabled(bool value) async {
    _report(await _actions.setBiometricsEnabled(value));
  }

  /// Молчание действия — это отказ от него: сообщать не о чем.
  void _report(String? message) {
    if (message == null || !mounted) return;
    setState(() => _message = message);
  }
}
