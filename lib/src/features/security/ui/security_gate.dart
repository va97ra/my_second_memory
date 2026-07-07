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

    final session = ref.watch(securitySessionProvider);

    if (!session.hasPin || session.isUnlocked) {
      return widget.child;
    }

    final strings = AppStrings.of(context);

    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => Scaffold(
            body: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFBF3E8),
                    Color(0xFFF7ECDB),
                    Color(0xFFFFF7ED),
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFCF6).withValues(alpha: 0.9),
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AspectRatio(
                                  aspectRatio: 2.4,
                                  child: Image.asset(
                                    'assets/images/memory_banner.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Icon(
                                Icons.lock_outline,
                                size: 38,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                strings.appTitle,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                strings.unlock,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF5F6B7A),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _pinController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                maxLength: 8,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(letterSpacing: 6),
                                decoration: const InputDecoration(
                                  labelText: 'PIN',
                                  counterText: '',
                                ),
                                onSubmitted: (_) => _unlockWithPin(),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _unlockWithPin,
                                  icon: const Icon(Icons.lock_open),
                                  label: Text(strings.unlock),
                                ),
                              ),
                              if (session.biometricsEnabled) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _unlockWithBiometrics,
                                    icon: const Icon(Icons.fingerprint),
                                    label: Text(strings.biometrics),
                                  ),
                                ),
                              ],
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
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _load() async {
    await ref.read(securitySessionProvider.notifier).load();
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _unlockWithPin() async {
    final ok = await ref
        .read(securitySessionProvider.notifier)
        .unlockWithPin(_pinController.text.trim());
    if (!mounted) {
      return;
    }
    setState(() => _error = ok ? null : AppStrings.of(context).wrongPin);
  }

  Future<void> _unlockWithBiometrics() async {
    final ok =
        await ref.read(securitySessionProvider.notifier).unlockWithBiometrics();
    if (!mounted) {
      return;
    }
    setState(() =>
        _error = ok ? null : AppStrings.of(context).biometricsUnavailable);
  }
}
