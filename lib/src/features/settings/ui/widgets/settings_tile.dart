import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'settings_icon_plate.dart';

/// Плитка настроек: цветной значок, справа состояние, внизу название.
/// Нажимается вся целиком.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.lit = true,
    this.selected = false,
    this.toggled,
    this.enabled = true,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Горит ли значок. Выключенная настройка стоит серой.
  final bool lit;

  /// Обведена ли плитка: так отмечен выбранный вариант.
  final bool selected;

  /// Включена ли настройка, если у плитки есть такое состояние.
  final bool? toggled;

  /// Выключенная плитка видна, но не нажимается: так остаётся видно, что
  /// настройка есть и от чего она зависит.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      toggled: toggled,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: NotebookPressable(
          onTap: enabled ? onTap : null,
          child: NotebookCardSurface(
            borderColor: selected ? colors.primary : null,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SettingsIconPlate(icon: icon, color: color, lit: lit),
                      const Spacer(),
                      if (trailing case final state?) state,
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle case final text?)
                    Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
