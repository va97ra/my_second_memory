import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_hints_provider.dart';

/// Кнопка подсказки страницы: что здесь можно сделать.
///
/// Пояснение не занимает экран, а достаётся по нажатию и выпадает из самой
/// кнопки. Верх экрана принадлежит работе: раскрывающиеся блоки и плашки
/// съедали половину полезной площади, а прочитывались один раз.
///
/// Кнопка стоит в том же слоте шапки, что и остальные значки страницы, —
/// одинаково на всех страницах, чтобы её не приходилось искать заново.
///
/// Настройка «Показывать подсказки» убирает кнопку совсем: освоившему
/// приложение она больше ничего не сообщает, а место занимает. Место при
/// этом не остаётся пустым — кнопка исчезает из раскладки, а не прячется.
class PageHintButton extends ConsumerStatefulWidget {
  const PageHintButton({required this.hint, super.key});

  /// Что можно сделать на этой странице. Одна-две фразы: подсказка, а не
  /// учебник.
  final String hint;

  @override
  ConsumerState<PageHintButton> createState() => _PageHintButtonState();
}

class _PageHintButtonState extends ConsumerState<PageHintButton> {
  final _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(appHintsProvider)) return const SizedBox.shrink();

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
          // Тот же размер, что у стрелки «назад» и у кнопок действий: в шапке
          // все клавиши одного роста, иначе ряд рассыпается.
          style: notebookIconButtonStyle(),
          icon: const Icon(Icons.help_outline_rounded, size: 22),
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
    );
  }
}
