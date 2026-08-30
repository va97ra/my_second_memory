import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/security_gate_controller.dart';
import '../state/security_provider.dart';
import 'widgets/biometric_unlock_card.dart';
import 'widgets/enable_biometrics_card.dart';
import 'widgets/pin_unlock_card.dart';
import 'widgets/secure_storage_error_card.dart';
import 'widgets/security_card.dart';
import 'widgets/security_scaffold.dart';
import 'widgets/setup_pin_card.dart';

/// Замок приложения: пока он не открыт, за ним ничего не показывается.
class SecurityGate extends ConsumerStatefulWidget {
  const SecurityGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends ConsumerState<SecurityGate> {
  final _pinController = TextEditingController();
  late final SecurityGateController _gate;

  @override
  void initState() {
    super.initState();
    _gate = SecurityGateController(
      ref.read(securitySessionProvider.notifier),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _gate.load();
  }

  @override
  void dispose() {
    _gate.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(securitySessionProvider);

    if (_gate.isLoading) {
      return const SecurityScaffold(
        child: Center(
          child: CircularProgressIndicator(key: ValueKey('gate_loading')),
        ),
      );
    }

    if (_gate.startupError != null) {
      return SecurityScaffold(
        child: SecureStorageErrorCard(onRetry: _reload),
      );
    }

    if (_gate.setupBusy) {
      return SecurityScaffold(
        child: SecurityCard(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(AppStrings.of(context).createPin),
          ],
        ),
      );
    }

    if (_gate.offerBiometrics) {
      return SecurityScaffold(
        child: EnableBiometricsCard(
          busy: _gate.biometricBusy,
          onEnable: _enableInitialBiometrics,
          onSkip: () => setState(() => _gate.offerBiometrics = false),
        ),
      );
    }

    if (!session.setupCompleted && !session.hasPin) {
      return SecurityScaffold(
        child: SetupPinCard(
          controller: _pinController,
          busy: _gate.setupBusy,
          error: _errorText(context),
          onCreatePin: _createInitialPin,
        ),
      );
    }

    if (!session.hasPin || session.isUnlocked) {
      return widget.child;
    }

    if (session.biometricsEnabled && !_gate.showPinFallback) {
      _scheduleBiometricUnlock();
      return SecurityScaffold(
        child: BiometricUnlockCard(
          busy: _gate.biometricBusy,
          error: _errorText(context),
          onRetry: _gate.unlockWithBiometrics,
          onShowPin: () => _switchTo(pinFallback: true),
        ),
      );
    }

    return SecurityScaffold(
      child: PinUnlockCard(
        controller: _pinController,
        busy: _gate.pinUnlockBusy,
        error: _errorText(context),
        onUnlock: _unlockWithPin,
        onBiometrics: session.biometricsEnabled
            ? () => _switchTo(pinFallback: false)
            : null,
      ),
    );
  }

  void _switchTo({required bool pinFallback}) {
    // Набранное стирается: чужой способ его всё равно не примет.
    _pinController.clear();
    _gate.switchTo(pinFallback: pinFallback);
  }

  void _scheduleBiometricUnlock() {
    if (!_gate.takeBiometricAttempt()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _gate.unlockWithBiometrics();
    });
  }

  void _reload() {
    _pinController.clear();
    _gate.load();
  }

  void _createInitialPin() {
    final pin = _pinController.text.trim();
    _pinController.clear();
    _gate.createInitialPin(pin);
  }

  void _unlockWithPin() {
    final pin = _pinController.text.trim();
    _pinController.clear();
    _gate.unlockWithPin(pin);
  }

  Future<void> _enableInitialBiometrics() async {
    final ok = await _gate.enableInitialBiometrics();
    if (ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).biometricsUnavailable)),
    );
  }

  String? _errorText(BuildContext context) {
    final strings = AppStrings.of(context);
    return switch (_gate.problem) {
      null => null,
      SecurityGateProblem.wrongPin => strings.wrongPin,
      SecurityGateProblem.biometricsUnavailable =>
        strings.biometricsUnavailable,
    };
  }
}
