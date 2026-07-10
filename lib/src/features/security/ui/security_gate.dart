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
  bool _showPinFallback = false;
  bool _biometricAttempted = false;
  bool _biometricBusy = false;
  bool _setupBusy = false;
  bool _offerBiometrics = false;
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
    final session = ref.watch(securitySessionProvider);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        error: _error,
        onUnlock: _unlockWithPin,
        onBiometrics: session.biometricsEnabled
            ? () {
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
    await ref.read(securitySessionProvider.notifier).load();
    if (mounted) {
      setState(() => _isLoading = false);
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
    final ok = await ref
        .read(securitySessionProvider.notifier)
        .unlockWithPin(_pinController.text.trim());
    if (mounted) {
      setState(() => _error = ok ? null : AppStrings.of(context).wrongPin);
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

class _SecurityScaffold extends StatelessWidget {
  const _SecurityScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF1E7DA),
              Color(0xFFE9DECF),
              Color(0xFFFFF7ED),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _SetupPinCard extends StatelessWidget {
  const _SetupPinCard({
    required this.controller,
    required this.busy,
    required this.error,
    required this.onCreatePin,
  });

  final TextEditingController controller;
  final bool busy;
  final String? error;
  final VoidCallback onCreatePin;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _SecurityCard(
      children: [
        const Icon(Icons.shield_outlined, size: 42, color: Color(0xFF2563EB)),
        const SizedBox(height: 12),
        Text(
          strings.setupPinTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          strings.setupPinSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5F6B7A),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 18),
        _PinField(controller: controller, onSubmitted: onCreatePin),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : onCreatePin,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_outline),
            label: Text(strings.createPin),
          ),
        ),
        if (error != null) _ErrorText(error!),
      ],
    );
  }
}

class _BiometricUnlockCard extends StatelessWidget {
  const _BiometricUnlockCard({
    required this.busy,
    required this.error,
    required this.onRetry,
    required this.onShowPin,
  });

  final bool busy;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onShowPin;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _SecurityCard(
      children: [
        const Icon(Icons.fingerprint, size: 52, color: Color(0xFF2563EB)),
        const SizedBox(height: 12),
        Text(
          strings.appTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : onRetry,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fingerprint),
            label: Text(strings.tryBiometricsAgain),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onShowPin,
            icon: const Icon(Icons.password_outlined),
            label: Text(strings.unlockWithPin),
          ),
        ),
        if (error != null) _ErrorText(error!),
      ],
    );
  }
}

class _EnableBiometricsCard extends StatelessWidget {
  const _EnableBiometricsCard({
    required this.busy,
    required this.onEnable,
    required this.onSkip,
  });

  final bool busy;
  final VoidCallback onEnable;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _SecurityCard(
      children: [
        const Icon(Icons.fingerprint, size: 52, color: Color(0xFF2563EB)),
        const SizedBox(height: 12),
        Text(
          strings.enableBiometricsQuestion,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : onEnable,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fingerprint),
            label: Text(strings.biometrics),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: busy ? null : onSkip,
            child: Text(strings.maybeLater),
          ),
        ),
      ],
    );
  }
}

class _PinUnlockCard extends StatelessWidget {
  const _PinUnlockCard({
    required this.controller,
    required this.error,
    required this.onUnlock,
    this.onBiometrics,
  });

  final TextEditingController controller;
  final String? error;
  final VoidCallback onUnlock;
  final VoidCallback? onBiometrics;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _SecurityCard(
      children: [
        const Icon(Icons.lock_outline, size: 42, color: Color(0xFF2563EB)),
        const SizedBox(height: 12),
        Text(
          strings.appTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        _PinField(controller: controller, onSubmitted: onUnlock),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onUnlock,
            icon: const Icon(Icons.lock_open),
            label: Text(strings.unlock),
          ),
        ),
        if (onBiometrics != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onBiometrics,
              icon: const Icon(Icons.fingerprint),
              label: Text(strings.biometrics),
            ),
          ),
        ],
        if (error != null) _ErrorText(error!),
      ],
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: 8,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 6),
      decoration: const InputDecoration(labelText: 'PIN', counterText: ''),
      onSubmitted: (_) => onSubmitted(),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

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
