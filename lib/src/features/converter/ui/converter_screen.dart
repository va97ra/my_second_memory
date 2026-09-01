import 'package:flutter/material.dart';

import '../../tool_data/tool_data.dart';
import 'widgets/converter_form.dart';

/// Конвертер величин.
///
/// Заголовка у страницы нет нарочно: её название написано во вкладке прямо
/// над ней, и второй раз то же слово занимало строку, ничего не сообщая.
/// Соседние инструменты — калькулятор и финансы — тоже начинаются с работы.
class ConverterScreen extends StatelessWidget {
  const ConverterScreen({super.key});

  @override
  Widget build(BuildContext context) => const ToolPageFrame(
        child: ConverterForm(key: ValueKey('converter_screen')),
      );
}
