import 'dart:async';

import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme_colors_controller.dart';
import '../../../app/theme/app_theme_controller.dart';
import '../../../app/theme/app_theme_data_provider.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../shift_schedules/shift_schedules.dart';
import 'widgets/theme_color_panel.dart';
import 'widgets/theme_color_previews.dart';
import 'widgets/theme_color_target.dart';
import 'widgets/theme_style_label.dart';

/// Карточка темы: образцы всего, что в ней можно перекрасить, палитра под
/// ними и кнопка, которая включает тему.
///
/// Экран нарисован самой этой темой, как и её плитка в настройках: тёмную
/// настраивают на чёрной коже, даже если включена светлая.
class ThemeScreen extends ConsumerStatefulWidget {
  const ThemeScreen({super.key, required this.style});

  final AppThemeStyle style;

  @override
  ConsumerState<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends ConsumerState<ThemeScreen> {
  /// С выходных начинают чаще всего: из-за них карточку и открывают.
  ThemeColorTarget _selected = const ThemeRoleTarget(AppColorRole.weekend);

  /// Цвета, пока ручку тянут. Тема всего приложения на каждом кадре не
  /// пересобирается: меняется только этот экран, а запоминается — по отпуску.
  AppThemeColors? _dragging;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final saved = ref.watch(appThemeDataProvider(widget.style));
    final schedules = ref.watch(shiftSchedulesControllerProvider);
    final active = ref.watch(appThemeControllerProvider) == widget.style;
    final selected = _target(schedules);
    final dragging = _dragging;
    final content = Theme.of(context).extension<AppContentTypography>();
    final theme = saved.copyWith(
      extensions: [
        ...saved.extensions.values,
        if (dragging != null) dragging,
        if (content != null) content,
      ],
    );

    final page = Scaffold(
      appBar: AppPageAppBar(
        fallbackLocation: '/settings',
        hint: strings.themePageHint,
        title: Text(themeStyleLabel(widget.style, isRu: isRu)),
      ),
      body: WarmGradientBackground(
        child: Column(
          children: [
            Expanded(
              child: ThemeColorPreviews(
                schedules: schedules,
                selected: selected,
                isRu: isRu,
                onSelect: (target) => setState(() => _selected = target),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ThemeColorPanel(
                    target: selected,
                    isRu: isRu,
                    onChanged: (color) => setState(
                      () => _dragging = selected.apply(_colors, color),
                    ),
                    onChangeEnd: _commit,
                    onReset: () => _save(selected.apply(_colors, null)),
                  ),
                  if (!active) ...[
                    const SizedBox(height: 10),
                    FilledButton(
                      key: const ValueKey('theme_enable'),
                      onPressed: _enable,
                      child: Text(
                        isRu ? 'Включить эту тему' : 'Use this theme',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Theme(
      data: theme,
      // Общий фон рисует оболочка, и он у включённой темы. Карточку другой
      // темы кладут на её собственную кожу, иначе тёмная лежала бы на серебре.
      child: active ? page : NotebookPaperFill(child: page),
    );
  }

  /// Цвета темы как сейчас на экране: с тем, что тянется под пальцем.
  AppThemeColors get _colors =>
      _dragging ?? ref.read(appThemeColorsControllerProvider)[widget.style]!;

  /// Выбранный образец. График, удалённый, пока экран открыт, — например,
  /// синхронизацией, — уступает место выходным.
  ThemeColorTarget _target(List<ShiftSchedule> schedules) {
    if (_selected case ThemeShiftTarget(:final schedule)) {
      for (final current in schedules) {
        if (current.id == schedule.id) return ThemeShiftTarget(current);
      }
      return const ThemeRoleTarget(AppColorRole.weekend);
    }
    return _selected;
  }

  void _commit() {
    final colors = _dragging;
    if (colors != null) _save(colors);
  }

  void _save(AppThemeColors colors) {
    setState(() => _dragging = null);
    unawaited(
      ref
          .read(appThemeColorsControllerProvider.notifier)
          .setColors(widget.style, colors),
    );
  }

  Future<void> _enable() async {
    try {
      await NotebookAssets.preloadCurrent(
        dark: brightnessOf(widget.style) == Brightness.dark,
      );
    } catch (_) {
      // Без картинок бумаги тема останется плоским цветом.
    }
    await ref.read(appThemeControllerProvider.notifier).setStyle(widget.style);
  }
}
