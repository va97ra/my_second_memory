import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/app_shell.dart';
import '../../accounts/data/encrypted_account_repository.dart';
import '../../accounts/data/local_account_repository.dart';
import '../../accounts/state/accounts_controller.dart';
import '../../memory_items/data/encrypted_memory_repository.dart';
import '../../memory_items/data/memory_repository_factory.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../shift_schedules/data/encrypted_shift_schedule_repository.dart';
import '../../shift_schedules/data/local_shift_schedule_repository.dart';
import '../../shift_schedules/state/shift_schedules_controller.dart';
import '../data/encrypted_json_store.dart';
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
    final session = ref.watch(securitySessionProvider);

    return AppShell(
      currentIndex: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(strings.pinSecurity),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDDE3EA)),
                boxShadow: [
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
                        color: const Color(0xFFEAF3FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SizedBox(
                        height: 74,
                        child: Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF2563EB),
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
    final oldCipher = currentSession.cipher;
    final memoryItems = oldCipher == null
        ? null
        : await EncryptedMemoryRepository(
            store: EncryptedJsonStore(cipher: oldCipher),
            plainRepository: createMemoryRepository(),
          ).loadItems();
    final shiftSchedules = oldCipher == null
        ? null
        : await EncryptedShiftScheduleRepository(
            store: EncryptedJsonStore(cipher: oldCipher),
            plainRepository: const LocalShiftScheduleRepository(),
          ).loadSchedules();
    final accounts = oldCipher == null
        ? null
        : await EncryptedAccountRepository(
            store: EncryptedJsonStore(cipher: oldCipher),
            plainRepository: const LocalAccountRepository(),
          ).loadAccounts();

    await ref.read(securitySessionProvider.notifier).setPin(pin);

    final newCipher = ref.read(securitySessionProvider).cipher;
    if (newCipher != null) {
      final newMemoryRepository = EncryptedMemoryRepository(
        store: EncryptedJsonStore(cipher: newCipher),
        plainRepository: createMemoryRepository(),
      );
      final newShiftRepository = EncryptedShiftScheduleRepository(
        store: EncryptedJsonStore(cipher: newCipher),
        plainRepository: const LocalShiftScheduleRepository(),
      );
      final newAccountRepository = EncryptedAccountRepository(
        store: EncryptedJsonStore(cipher: newCipher),
        plainRepository: const LocalAccountRepository(),
      );
      if (memoryItems != null) {
        await newMemoryRepository.saveItems(memoryItems);
      } else {
        await newMemoryRepository.loadItems();
      }
      if (shiftSchedules != null) {
        await newShiftRepository.saveSchedules(shiftSchedules);
      } else {
        await newShiftRepository.loadSchedules();
      }
      if (accounts != null) {
        await newAccountRepository.saveAccounts(accounts);
      } else {
        await newAccountRepository.loadAccounts();
      }
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

    final store = EncryptedJsonStore(cipher: cipher);
    final plainMemory = createMemoryRepository();
    final memoryRepository = EncryptedMemoryRepository(
      store: store,
      plainRepository: plainMemory,
    );
    final items = await memoryRepository.loadItems();
    await plainMemory.saveItems(items);
    await store.remove(EncryptedMemoryRepository.storageKey);

    const plainShifts = LocalShiftScheduleRepository();
    final shiftRepository = EncryptedShiftScheduleRepository(
      store: store,
      plainRepository: plainShifts,
    );
    final schedules = await shiftRepository.loadSchedules();
    await plainShifts.saveSchedules(schedules);
    await store.remove(EncryptedShiftScheduleRepository.storageKey);

    const plainAccounts = LocalAccountRepository();
    final accountRepository = EncryptedAccountRepository(
      store: store,
      plainRepository: plainAccounts,
    );
    final accounts = await accountRepository.loadAccounts();
    await plainAccounts.saveAccounts(accounts);
    await store.remove(EncryptedAccountRepository.storageKey);

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
    final color = isEnabled ? const Color(0xFF16A34A) : const Color(0xFF6B7280);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isEnabled ? const Color(0xFFEAF7EE) : const Color(0xFFF7F4EF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEnabled ? const Color(0xFFBFE8C9) : const Color(0xFFE4DDD2),
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
