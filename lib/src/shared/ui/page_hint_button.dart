import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Кнопка подсказки страницы: что здесь можно сделать.
///
/// Пояснение не занимает экран, а достаётся по нажатию и выпадает из самой
/// кнопки. Верх экрана принадлежит работе: раскрывающиеся блоки и плашки
/// съедали половину полезной площади, а прочитывались один раз.
///
/// Кнопка стоит в том же слоте шапки, что и остальные значки страницы, —
/// одинаково на всех страницах, чтобы её не приходилось искать заново.
class PageHintButton extends StatefulWidget {
  const PageHintButton({required this.hint, super.key});

  /// Что можно сделать на этой странице. Одна-две фразы: подсказка, а не
  /// учебник.
  final String hint;

  @override
  State<PageHintButton> createState() => _PageHintButtonState();
}

class _PageHintButtonState extends State<PageHintButton> {
  final _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;

    return MenuAnchor(
      controller: _controller,
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colors.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: colors.outlineVariant),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        ConstrainedBox(
          // Шире — и подсказка на телефоне вылезет за экран; уже — и она
          // растянется в столбик из одного слова.
          constraints: const BoxConstraints(maxWidth: 300),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Text(
              widget.hint,
              key: const ValueKey('page_hint_text'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
      builder: (context, controller, child) => SizedBox(
        width: notebookHeaderSlot,
        child: IconButton(
          key: const ValueKey('page_hint_button'),
          tooltip: strings.pageHintTooltip,
          icon: const Icon(Icons.help_outline_rounded),
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
    );
  }
}
