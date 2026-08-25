import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/protected_data_reload.dart';
import '../state/security_provider.dart';
import 'widgets/current_pin_dialog.dart';

/// Включение и отключение PIN.
///
/// Оба действия переписывают все защищённые данные, поэтому после каждого
/// репозитории и контроллеры перечитываются заново: до этого они держат данные,
/// зашифрованные прежним ключом.
class SecurityActions {
  const SecurityActions({required this.context, required this.ref});

  final BuildContext context;
  final WidgetRef ref;

  /// Ставит новый PIN и переносит под него уже накопленные данные.
  ///
  /// Снимок делается прежним ключом до смены, иначе расшифровать старое будет
  /// уже нечем.
  Future<String?> savePin(String pin) async {
    if (pin.isEmpty) return null;

    final migration = ref.read(securityDataMigrationServiceProvider);
    final snapshot = await migration.snapshotEncryptedData(
      ref.read(securitySessionProvider).cipher,
    );

    await ref.read(securitySessionProvider.notifier).setPin(pin);

    final newCipher = ref.read(securitySessionProvider).cipher;
    if (newCipher != null) {
      await migration.encryptPlainData(cipher: newCipher, snapshot: snapshot);
    }
    reloadProtectedData(ref);
    return context.mounted ? AppStrings.of(context).pinSaved : null;
  }

  /// Снимает PIN, расшифровав данные обратно. Спрашивает подтверждение и сам
  /// PIN: без него расшифровать нечем.
  Future<String?> disablePin() async {
    final strings = AppStrings.of(context);
    if (!await _confirmDisable(strings)) return null;
    if (!context.mounted) return null;

    final pin = await askCurrentPin(context);
    if (pin == null || pin.isEmpty) return null;

    final cipher = await ref.read(securityServiceProvider).unlockWithPin(pin);
    if (cipher == null) return strings.wrongPin;

    try {
      await ref
          .read(securityDataMigrationServiceProvider)
          .decryptToPlainData(cipher);
    } finally {
      cipher.destroy();
    }
    await ref.read(securitySessionProvider.notifier).clearPinSession();
    reloadProtectedData(ref);
    return strings.pinDisabled;
  }

  Future<bool> _confirmDisable(AppStrings strings) async {
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
    return confirmed ?? false;
  }

  Future<String?> setBiometricsEnabled(bool value) async {
    final ok = await ref
        .read(securitySessionProvider.notifier)
        .setBiometricsEnabled(value);
    if (!context.mounted) return null;
    final strings = AppStrings.of(context);
    return ok ? strings.saved : strings.biometricsUnavailable;
  }
}
