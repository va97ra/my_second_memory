import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import '../../state/security_provider.dart';
import 'security_card.dart';
import 'security_status_row.dart';

/// Карточка настроек защиты: что включено, поле нового PIN и биометрия.
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
    final colors = Theme.of(context).colorScheme;

    return SecurityCard(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            height: 74,
            child: Icon(
              Icons.verified_user_rounded,
              color: colors.primary,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SecurityStatusRow(
          icon: Icons.lock_rounded,
          title: strings.pinStatus,
          value: session.hasPin ? strings.enabled : strings.disabled,
          isEnabled: session.hasPin,
        ),
        const SizedBox(height: 8),
        SecurityStatusRow(
          icon: Icons.fingerprint_rounded,
          title: strings.biometrics,
          value: session.biometricsEnabled ? strings.enabled : strings.disabled,
          isEnabled: session.biometricsEnabled,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 8,
          // Длину и так не дадут превысить, а счётчик висел бы служебной
          // цифрой, не совпадающей с краем поля.
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
          decoration: const InputDecoration(labelText: 'PIN'),
        ),
        // Кнопки тянутся во всю колонку карточки: иначе каждая встаёт по
        // ширине своей подписи и края не сходятся ни с полями, ни между собой.
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onSavePin,
            icon: const Icon(Icons.lock_rounded),
            label: Text(session.hasPin ? strings.changePin : strings.enablePin),
          ),
        ),
        if (session.hasPin) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDisablePin,
              icon: const Icon(Icons.lock_open_rounded),
              label: Text(strings.disablePin),
            ),
          ),
        ],
        const SizedBox(height: 14),
        SwitchListTile(
          value: session.biometricsEnabled,
          // Биометрия отпирает тот же ключ, что и PIN: без PIN отпирать нечего.
          onChanged: session.hasPin ? onBiometricsChanged : null,
          // Те же 12 и 10, что у строк состояния выше: значок и подпись
          // обязаны стоять с ними на одной вертикали.
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          minLeadingWidth: 24,
          horizontalTitleGap: 10,
          secondary: const Icon(Icons.fingerprint_rounded),
          title: Text(strings.biometrics),
          subtitle: Text(
            session.hasPin
                ? strings.biometricsSubtitle
                : strings.biometricsNeedsPin,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(message!),
        ],
      ],
    );
  }
}
