import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Полоса шапки со строкой поиска. Стоит на месте периода: найденное не
/// делится на страницы, листать нечего, и полоса отдана запросу.
class FeedSearchRow extends StatefulWidget {
  const FeedSearchRow({
    super.key,
    required this.query,
    required this.hint,
    required this.onChanged,
  });

  /// Запрос, с которым строка появилась. Дальше строка ведёт его сама.
  final String query;

  /// Где ищут — подсказка в пустой строке.
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<FeedSearchRow> createState() => _FeedSearchRowState();
}

class _FeedSearchRowState extends State<FeedSearchRow> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.query);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final style = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.08,
    );

    return Row(
      children: [
        SizedBox(
          width: notebookHeaderSlot,
          child: Icon(
            Icons.search_rounded,
            size: 22,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: TextField(
            key: const ValueKey('feed_search_field'),
            controller: _controller,
            // Строку открыли затем, чтобы набрать запрос. Уже набранный
            // запрос клавиатуру не поднимает: человек смотрит найденное.
            autofocus: widget.query.isEmpty,
            textInputAction: TextInputAction.search,
            maxLines: 1,
            style: style,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: style?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              isDense: true,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        SizedBox(
          width: notebookHeaderSlot,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    key: const ValueKey('feed_search_clear'),
                    tooltip: strings.clearSearch,
                    onPressed: _clear,
                    icon: const Icon(Icons.close_rounded, size: 22),
                    style: notebookIconButtonStyle(),
                  ),
          ),
        ),
      ],
    );
  }
}
