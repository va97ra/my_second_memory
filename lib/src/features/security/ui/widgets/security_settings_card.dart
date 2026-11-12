import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../../settings/settings.dart';
import '../../state/security_provider.dart';

/// Настройки защиты: что включено — плитками, ниже поле нового PIN.
class SecuritySettingsCard extends StatelessWidget {
  const SecuritySettingsCard({
    super.key,
    required this.session,
    required this.pinController,
    required this.message,
    required this.onSavePin,
    required this.onDisablePin,
    required this.onBiometricsChanged,
  });

  final SecuritySessionState session;
  final TextEditingController pinController;
  final String? message;
  final VoidCallback onSavePin;
  final VoidCallback onDisablePin;
  final ValueChanged<bool> onBiometricsChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final biometrics = session.biometricsEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSection(
          children: [
            SettingsTile(
              key: const ValueKey('security_pin_status'),
              icon: Icons.lock_rounded,
              color: AppPalette.indigo,
              title: strings.pinStatus,
              subtitle: session.hasPin ? strings.enabled : strings.disabled,
              lit: session.hasPin,
              trailing: session.hasPin
                  ? const Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: AppPalette.success,
                    )
                  : null,
            ),
            SettingsTile(
              key: const ValueKey('security_biometrics'),
              icon: Icons.fingerprint_rounded,
              color: AppPalette.turquoise,
              title: strings.biometrics,
              // Биометрия отпирает тот же ключ, что и PIN: без PIN отпирать нечего.
              subtitle: session.hasPin ? null : strings.biometricsNeedsPin,
              lit: biometrics,
              toggled: biometrics,
              enabled: session.hasPin,
              trailing: SettingsToggle(value: biometrics),
              onTap: () => onBiometricsChanged(!biometrics),
            ),
          ],
        ),
        const SizedBox(height: 12),
        NotebookCardSurface(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 8,
                // Длину и так не дадут превысить, а счётчик висел бы служебной
                // цифрой, не совпадающей с краем поля.
                buildCounter: (
                  _, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) =>
                    null,
                decoration: const InputDecoration(labelText: 'PIN'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: onSavePin,
                icon: const Icon(Icons.lock_rounded),
                label: Text(
                  session.hasPin ? strings.changePin : strings.enablePin,
                ),
              ),
              if (session.hasPin) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onDisablePin,
                  icon: const Icon(Icons.lock_open_rounded),
                  label: Text(strings.disablePin),
                ),
              ],
              if (message case final text?) ...[
                const SizedBox(height: 10),
                Text(text, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
