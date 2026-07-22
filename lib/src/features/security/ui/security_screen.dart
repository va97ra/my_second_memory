import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/notebook/notebook_background.dart';
import '../../../shared/ui/app_shell.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../accounts/state/accounts_controller.dart';
import '../../recurrence/state/recurrence_controller.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../shift_schedules/state/shift_schedules_controller.dart';
import '../data/security_data_migration_service.dart';
import '../state/security_provider.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _pinController = TextEditingController();
  final _migrationService = const SecurityDataMigrationService();
  String? _message;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final session = ref.watch(securitySessionProvider);

    return AppShell(
      currentIndex: 3,
      child: Scaffold(
        appBar: AppPageAppBar(
          fallbackLocation: '/settings',
          title: Text(strings.pinSecurity),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
                boxShadow: notebookSurfaceShadow(
                  context,
                  NotebookSurfaceDepth.panel,
                ).isNotEmpty
                    ? notebookSurfaceShadow(
                        context,
                        NotebookSurfaceDepth.panel,
                      )
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.035),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SizedBox(
                        height: 74,
                        child: Icon(
                          Icons.verified_user_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StatusRow(
                      icon: Icons.lock_outline,
                      title: strings.pinStatus,
                      value:
                          session.hasPin ? strings.enabled : strings.disabled,
                      isEnabled: session.hasPin,
                    ),
                    const SizedBox(height: 8),
                    _StatusRow(
                      icon: Icons.fingerprint,
                      title: strings.biometrics,
                      value: session.biometricsEnabled
                          ? strings.enabled
                          : strings.disabled,
                      isEnabled: session.biometricsEnabled,
                    ),
                    const SizedBox(height: 16),
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
                      label: Text(
                        session.hasPin ? strings.changePin : strings.enablePin,
                      ),
                    ),
                    if (session.hasPin) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _disablePin,
                        icon: const Icon(Icons.lock_open_outlined),
                        label: Text(strings.disablePin),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SwitchListTile(
                      value: session.biometricsEnabled,
                      onChanged: session.hasPin ? _setBiometricsEnabled : null,
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.fingerprint),
                      title: Text(strings.biometrics),
                      subtitle: Text(
                        session.hasPin
                            ? strings.biometricsSubtitle
                            : strings.biometricsNeedsPin,
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Text(_message!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePin() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      return;
    }

    final currentSession = ref.read(securitySessionProvider);
    final snapshot = await _migrationService.snapshotEncryptedData(
      currentSession.cipher,
    );

    await ref.read(securitySessionProvider.notifier).setPin(pin);

    final newCipher = ref.read(securitySessionProvider).cipher;
    if (newCipher != null) {
      await _migrationService.encryptPlainData(
        cipher: newCipher,
        snapshot: snapshot,
      );
    }

    _pinController.clear();
    _invalidateProtectedProviders();
    if (!mounted) return;
    setState(() => _message = AppStrings.of(context).pinSaved);
  }

  Future<void> _disablePin() async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.disablePin),
        content: Text(strings.disablePinWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.disablePin),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final pin = await _askCurrentPin();
    if (pin == null || pin.isEmpty) {
      return;
    }
    final cipher = await ref.read(securityServiceProvider).unlockWithPin(pin);
    if (cipher == null) {
      if (!mounted) return;
      setState(() => _message = strings.wrongPin);
      return;
    }

    await _migrationService.decryptToPlainData(cipher);
    await ref.read(securitySessionProvider.notifier).clearPinSession();
    _invalidateProtectedProviders();
    if (!mounted) return;
    setState(() => _message = strings.pinDisabled);
  }

  Future<String?> _askCurrentPin() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.of(context).currentPin),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'PIN'),
          onSubmitted: (_) => Navigator.of(context).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppStrings.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(AppStrings.of(context).unlock),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _setBiometricsEnabled(bool value) async {
    final ok = await ref
        .read(securitySessionProvider.notifier)
        .setBiometricsEnabled(value);
    if (!mounted) return;
    final strings = AppStrings.of(context);
    setState(() {
      _message = ok ? strings.saved : strings.biometricsUnavailable;
    });
  }

  void _invalidateProtectedProviders() {
    ref.invalidate(memoryRepositoryProvider);
    ref.invalidate(memoryItemsControllerProvider);
    ref.invalidate(shiftScheduleRepositoryProvider);
    ref.invalidate(shiftSchedulesControllerProvider);
    ref.invalidate(accountRepositoryProvider);
    ref.invalidate(accountsControllerProvider);
    ref.invalidate(recurrenceRepositoryProvider);
    ref.invalidate(recurrenceExceptionRepositoryProvider);
    ref.invalidate(recurrenceExceptionControllerProvider);
    ref.invalidate(recurrenceSeriesControllerProvider);
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.isEnabled,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final color = isEnabled
        ? const Color(0xFF16A34A)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isEnabled
            ? Color.alphaBlend(
                const Color(0xFF16A34A).withValues(alpha: 0.12),
                Theme.of(context).colorScheme.surface,
              )
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEnabled
              ? const Color(0xFFBFE8C9)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
            Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
