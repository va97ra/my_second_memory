import 'package:flutter/material.dart';

import 'electrician_symbol_art.dart';
import 'electrician_tool_art.dart';

/// Рисунок карточки по её имени: условное обозначение или инструмент.
///
/// Карточка хранит одно имя и не знает, из какого набора оно взято —
/// разбирается здесь, в одном месте.
class ElectricianArtView extends StatelessWidget {
  const ElectricianArtView({required this.name, this.size = 96, super.key});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final symbol = electricianSymbolByName(name);
    if (symbol != null) {
      return ElectricianSymbolArt(symbol: symbol, size: size);
    }
    final tool = electricianToolArtByName(name);
    if (tool != null) return ElectricianToolArtView(art: tool, size: size);
    return const SizedBox.shrink();
  }
}

/// Есть ли у имени рисунок.
bool hasElectricianArt(String name) =>
    electricianSymbolByName(name) != null ||
    electricianToolArtByName(name) != null;
