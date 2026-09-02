import 'package:flutter/material.dart';

/// Шеврон в конце строки настроек.
///
/// У переключателя и у рамки выбора языка краска доходит до края их коробки,
/// а у глифа шеврона внутри его квадрата остаётся собственный отступ. На глаз
/// он вставал левее соседей. Сдвиг возвращает видимый край на общую вертикаль
/// и не трогает раскладку строки.
class SettingsChevron extends StatelessWidget {
  const SettingsChevron({super.key});

  @override
  Widget build(BuildContext context) => Transform.translate(
        offset: const Offset(5, 0),
        child: const Icon(Icons.chevron_right_rounded),
      );
}
