import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

/// Главный экран учебника: разделы плитками.
///
/// Плитка честно говорит, сколько в разделе карточек. Пустой раздел не
/// прячется: он объявлен, и видно, что работа над ним не закончена.
class ElectricianTiles extends StatelessWidget {
  const ElectricianTiles({required this.onSelected, super.key});

  final ValueChanged<ElectricianSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        const padding = 16.0;
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        final width =
            (constraints.maxWidth - padding * 2 - gap * (columns - 1)) /
                columns;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(padding, 8, padding, 24),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final section in ElectricianSection.values)
                SizedBox(
                  width: width,
                  child: _Tile(
                    icon: sectionIcon(section),
                    title: sectionTitle(strings, section),
                    subtitle: _countLabel(strings, sectionCardCount(section)),
                    enabled: sectionCardCount(section) > 0,
                    onTap: () => onSelected(section),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _countLabel(AppStrings strings, int count) =>
      count == 0 ? strings.sectionEmpty : '$count ${strings.cardsCount}';
}

IconData sectionIcon(ElectricianSection section) => switch (section) {
      ElectricianSection.learning => Icons.school_rounded,
      ElectricianSection.tools => Icons.handyman_rounded,
      ElectricianSection.components => Icons.power_rounded,
      ElectricianSection.glossary => Icons.abc_rounded,
      ElectricianSection.schematics => Icons.schema_rounded,
      ElectricianSection.diagnostics => Icons.troubleshoot_rounded,
      ElectricianSection.safety => Icons.health_and_safety_rounded,
      ElectricianSection.reference => Icons.menu_book_rounded,
    };

String sectionTitle(AppStrings strings, ElectricianSection section) =>
    switch (section) {
      ElectricianSection.learning => strings.sectionLearning,
      ElectricianSection.tools => strings.sectionTools,
      ElectricianSection.components => strings.sectionComponents,
      ElectricianSection.glossary => strings.sectionGlossary,
      ElectricianSection.schematics => strings.sectionSchematics,
      ElectricianSection.diagnostics => strings.sectionDiagnostics,
      ElectricianSection.safety => strings.sectionSafety,
      ElectricianSection.reference => strings.sectionReference,
    };

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: ink),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(color: ink),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
