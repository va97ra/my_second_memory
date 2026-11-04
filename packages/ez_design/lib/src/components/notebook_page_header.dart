import 'package:flutter/material.dart';

import '../themes/notebook/notebook_background.dart';

/// Ширина, которую шапка занимает под кнопку с каждой стороны заголовка.
///
/// Это слот AppBar внутренних страниц. Пока их было два разных, кнопка «назад»
/// на разных экранах выходила разного размера.
const double notebookHeaderSlot = 48;

/// Зазор между шапкой и панелью над ней.
///
/// Шапка — продолжение верхней панели, а не плашка посреди страницы: она
/// держится к панели вплотную.
const double notebookHeaderTopSpacing = 2;

/// Высота шапки. Одна на всех страницах: всё, что страница хочет сообщить,
/// пишется мелко в несколько строк, а карточка не растёт.
const double notebookHeaderHeight = 56;

/// Сколько в карточке занимает одна кнопка. Сама кнопка обычного размера,
/// слот только сокращает пустоту вокруг неё.
const double notebookHeaderButtonSlot = 38;

/// Шапка страницы: кнопки по краям карточки, сведения посередине.
///
/// Посередине карточки сведения стоят при любом числе кнопок: за более короткий
/// край отвечают пустые слоты.
class NotebookPageHeader extends StatelessWidget {
  const NotebookPageHeader({
    required this.child,
    this.leading = const [],
    this.trailing = const [],
    this.cardKey,
    super.key,
  });

  final Widget child;
  final List<Widget> leading;
  final List<Widget> trailing;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    final difference = leading.length - trailing.length;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          10,
          notebookHeaderTopSpacing,
          10,
          6,
        ),
        child: NotebookCardSurface(
          key: cardKey,
          depth: NotebookSurfaceDepth.card,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            height: notebookHeaderHeight,
            child: Row(
              children: [
                for (final button in leading) _slot(button),
                for (var i = 0; i < -difference; i++) _slot(null),
                Expanded(child: child),
                for (var i = 0; i < difference; i++) _slot(null),
                for (final button in trailing) _slot(button),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _slot(Widget? button) => SizedBox(
        width: notebookHeaderButtonSlot,
        // Отпускает кнопку: растянутая на слот, она стала бы шире обычной.
        child: button == null ? null : Center(child: button),
      );
}

/// Сведения шапки: заголовок и под ним мелкие подробности в любое число строк.
///
/// Если строк больше, чем вмещает карточка, или шрифт в системе крупный, всё
/// вместе ужимается, а шапка остаётся своего размера.
class NotebookHeaderTitle extends StatelessWidget {
  const NotebookHeaderTitle({required this.title, this.details, super.key});

  final Widget title;
  final Widget? details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, box) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: box.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultTextStyle.merge(
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                  child: title,
                ),
                if (details case final details?) ...[
                  const SizedBox(height: 2),
                  DefaultTextStyle.merge(
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                    child: details,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
