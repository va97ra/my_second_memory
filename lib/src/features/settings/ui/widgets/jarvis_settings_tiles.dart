import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/ui/time_of_day_dialog.dart';
import '../../../jarvis/jarvis.dart';
import 'settings_tile.dart';

/// Покупки из уведомлений банков. Доступ к уведомлениям даёт человек сам в
/// настройках телефона — строка ведёт туда, пока его нет.
class BankNoticesTile extends ConsumerWidget {
  const BankNoticesTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final enabled = ref.watch(jarvisBankNoticesProvider);
    final access = ref.watch(jarvisBankAccessProvider).valueOrNull ?? true;
    final needsAccess = enabled && !access;
    Future<void> openAccess() async {
      await ref.read(jarvisBankWatcherProvider).openAccess();
      ref.invalidate(jarvisBankAccessProvider);
    }

    return SettingsTile(
      key: const ValueKey('settings_jarvis_bank'),
      icon: Icons.account_balance_wallet_rounded,
      title: strings.jarvisBankNotices,
      subtitle:
          needsAccess ? strings.jarvisBankNoAccess : strings.jarvisBankNoticesHint,
      trailing: Switch(
        value: enabled,
        onChanged: (value) async {
          await ref.read(jarvisBankNoticesProvider.notifier).setEnabled(value);
          if (value && !await ref.read(jarvisBankWatcherProvider).accessGranted()) {
            await openAccess();
          }
        },
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onTap: needsAccess ? openAccess : null,
    );
  }
}

/// Сводка: переключатель и время. Нажатие на строку меняет время.
class BriefingTile extends StatelessWidget {
  const BriefingTile({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.at,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final String title;
  final bool enabled;
  final int at;
  final void Function({bool? enabled, int? at}) onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: enabled
          ? strings.jarvisBriefingAt(formatMinutesOfDay(at))
          : strings.jarvisBriefingOff,
      trailing: Switch(
        value: enabled,
        onChanged: (value) => onChanged(enabled: value),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onTap: () async {
        final picked = await askTimeOfDay(context, initialMinutes: at);
        if (picked != null) onChanged(enabled: true, at: picked);
      },
    );
  }
}
