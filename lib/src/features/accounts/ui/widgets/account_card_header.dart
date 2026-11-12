import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'account_info_line.dart';
import 'account_row_button.dart';
import 'service_avatar.dart';

/// Верх карточки: буква сервиса, рядом название или полоска выбора цвета.
class AccountCardHeader extends StatelessWidget {
  const AccountCardHeader({
    super.key,
    required this.account,
    required this.accent,
    required this.picker,
    required this.onAvatarTap,
  });

  final AccountItem account;
  final Color accent;
  final Widget? picker;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: AccountInfoLine.heightOf(context),
      child: Row(
        children: [
          Tooltip(
            message: AppStrings.of(context).accountColor,
            child: NotebookPressable(
              key: ValueKey('account_color_${account.id}'),
              onTap: onAvatarTap,
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: AccountRowButton.rowWidth,
                height: double.infinity,
                child: Center(
                  child: ServiceAvatar(
                    name: account.serviceName,
                    color: accent,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: picker ??
                Text(
                  account.serviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
