import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'account_copy_button.dart';

/// Строка карточки аккаунта: значок, значение одной строкой и кнопка копирования.
class AccountInfoLine extends StatelessWidget {
  const AccountInfoLine({
    super.key,
    required this.icon,
    required this.text,
    required this.copyTooltip,
    required this.copiedMessage,
    this.shownText,
    this.action,
  });

  static const _height = 30.0;
  static const _iconSize = 14.0;

  /// Высота строки: растёт вместе с системным размером шрифта.
  static double heightOf(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(_height);

  final IconData icon;

  /// Что копируется.
  final String text;
  final String copyTooltip;
  final String copiedMessage;

  /// Что написано вместо [text], если показывать его нельзя.
  final String? shownText;

  /// Ещё одна кнопка перед копированием.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = AppContentTypography.of(context).apply(
      Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
      manropeWeight: FontWeight.w600,
    );

    return SizedBox(
      height: heightOf(context),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(icon, size: _iconSize, color: colors.onSurface),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              shownText ?? text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          if (action case final button?) button,
          AccountCopyButton(
            text: text,
            tooltip: copyTooltip,
            copiedMessage: copiedMessage,
          ),
        ],
      ),
    );
  }
}
