import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import '../state/security_provider.dart';

part 'security_gate_views.dart';

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
  bool _showPinFallback = false;
  bool _biometricAttempted = false;
  bool _biometricBusy = false;
  bool _pinUnlockBusy = false;
  bool _setupBusy = false;
  bool _offerBiometrics = false;
  String? _error;
  String? _startupError;

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
    final session = ref.watch(securitySessionProvider);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(key: ValueKey('gate_loading')),
        ),
      );
    }

    if (_startupError != null) {
      return _SecurityScaffold(
        child: _SecurityCard(
          children: [
            Icon(
              Icons.shield_rounded,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.of(context).secureStorageStartFailed,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.of(context).secureStorageStartFailedSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppStrings.of(context).retry),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: SystemNavigator.pop,
                child: Text(AppStrings.of(context).closeApp),
              ),
            ),
          ],
        ),
      );
    }

    if (_setupBusy) {
      return _SecurityScaffold(
        child: _SecurityCard(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(AppStrings.of(context).createPin),
          ],
        ),
      );
    }

    if (_offerBiometrics) {
      return _SecurityScaffold(
        child: _EnableBiometricsCard(
          busy: _biometricBusy,
          onEnable: _enableInitialBiometrics,
          onSkip: () => setState(() => _offerBiometrics = false),
        ),
      );
    }

    if (!session.setupCompleted && !session.hasPin) {
      return _SecurityScaffold(
        child: _SetupPinCard(
          controller: _pinController,
          busy: _setupBusy,
          error: _error,
          onCreatePin: _createInitialPin,
        ),
      );
    }

    if (!session.hasPin || session.isUnlocked) {
      return widget.child;
    }

    if (session.biometricsEnabled && !_showPinFallback) {
      _scheduleBiometricUnlock();
      return _SecurityScaffold(
        child: _BiometricUnlockCard(
          busy: _biometricBusy,
          error: _error,
          onRetry: _unlockWithBiometrics,
          onShowPin: () {
            _pinController.clear();
            setState(() {
              _showPinFallback = true;
              _error = null;
            });
          },
        ),
      );
    }

    return _SecurityScaffold(
      child: _PinUnlockCard(
        controller: _pinController,
        busy: _pinUnlockBusy,
        error: _error,
        onUnlock: _unlockWithPin,
        onBiometrics: session.biometricsEnabled
            ? () {
                _pinController.clear();
                setState(() {
                  _showPinFallback = false;
                  _biometricAttempted = false;
                  _error = null;
                });
              }
            : null,
      ),
    );
  }

  Future<void> _load() async {
    _pinController.clear();
    if (mounted) {
      setState(() {
        _isLoading = true;
        _startupError = null;
      });
    }
    try {
      await ref
          .read(securitySessionProvider.notifier)
          .load()
          .timeout(const Duration(seconds: 8));
    } on Object catch (error) {
      if (mounted) {
        setState(() => _startupError = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scheduleBiometricUnlock() {
    if (_biometricAttempted || _biometricBusy) {
      return;
    }
    _biometricAttempted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _unlockWithBiometrics();
      }
    });
  }

  Future<void> _createInitialPin() async {
    final strings = AppStrings.of(context);
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = strings.wrongPin);
      return;
    }

    setState(() {
      _setupBusy = true;
      _error = null;
    });
    _pinController.clear();
    await ref.read(securitySessionProvider.notifier).setPin(pin);
    if (!mounted) {
      return;
    }

    if (mounted) {
      setState(() {
        _setupBusy = false;
        _offerBiometrics = true;
      });
    }
  }

  Future<void> _enableInitialBiometrics() async {
    setState(() => _biometricBusy = true);
    final ok =
        await ref.read(securitySessionProvider.notifier).setBiometricsEnabled(
              true,
            );
    if (!mounted) {
      return;
    }
    setState(() {
      _biometricBusy = false;
      _offerBiometrics = false;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).biometricsUnavailable)),
      );
    }
  }

  Future<void> _unlockWithPin() async {
    if (_pinUnlockBusy) {
      return;
    }
    final pin = _pinController.text.trim();
    _pinController.clear();
    if (pin.isEmpty) {
      setState(() => _error = AppStrings.of(context).wrongPin);
      return;
    }
    setState(() {
      _pinUnlockBusy = true;
      _error = null;
    });
    try {
      final ok =
          await ref.read(securitySessionProvider.notifier).unlockWithPin(pin);
      if (mounted) {
        setState(() => _error = ok ? null : AppStrings.of(context).wrongPin);
      }
    } finally {
      if (mounted) {
        setState(() => _pinUnlockBusy = false);
      }
    }
  }

  Future<void> _unlockWithBiometrics() async {
    setState(() {
      _biometricBusy = true;
      _error = null;
    });
    final ok =
        await ref.read(securitySessionProvider.notifier).unlockWithBiometrics();
    if (!mounted) {
      return;
    }
    setState(() {
      _biometricBusy = false;
      _error = ok ? null : AppStrings.of(context).biometricsUnavailable;
    });
  }
}
