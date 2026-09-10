import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Лист, на котором лежит запись: форма, фон и граница.
///
/// Лист бумажный во всех темах — и в тёмных тоже: см. `PaperSheet` и правило
/// в `docs/layout.md`. Меняется от темы только форма: в блокноте лист вырван
/// из тетради и рисует рваный край сам, в остальных это ровный прямоугольник,
/// и границу ему кладут сверху.
class MemoryCardPaper extends StatelessWidget {
  const MemoryCardPaper({
    super.key,
    required this.cardKey,
    required this.variantKey,
    required this.tint,
    required this.borderColor,
    required this.height,
    required this.margin,
    required this.child,
  });

  final Key cardKey;

  /// Ключ, по которому выбирается рисунок разрыва: у одной записи он всегда
  /// один и тот же.
  final String variantKey;

  /// Подкраска бумаги или null у обычной записи.
  final Color? tint;
  final Color borderColor;
  final double height;
  final EdgeInsetsGeometry margin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roundedBorder = BorderRadius.circular(8);

    return PaperSheet(
      child: Padding(
        padding: margin,
        child: Material(
          color: paper,
          elevation: 6,
          shadowColor:
              _shadowColor(isNotebook: notebook != null, isDark: isDark),
          surfaceTintColor: Colors.transparent,
          shape: notebook == null
              ? RoundedRectangleBorder(borderRadius: roundedBorder)
              : TornPaperShapeBorder(
                  variant: TornPaperShapeBorder.stableVariant(variantKey),
                  side: BorderSide(color: borderColor, width: 1),
                ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            key: cardKey,
            height: height,
            child: Ink(
              decoration: _surface(context, roundedBorder),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child,
                  if (notebook == null)
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: roundedBorder,
                          border: Border.all(color: borderColor),
                        ),
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

  Color _shadowColor({required bool isNotebook, required bool isDark}) {
    if (isNotebook) return const Color(0xFF3B1D0E).withValues(alpha: 0.45);
    return isDark
        ? Colors.black.withValues(alpha: 0.68)
        : const Color(0xFF536575).withValues(alpha: 0.34);
  }

  /// Цвет листа: бумага, подкрашенная тем, что передала карточка.
  ///
  /// Бумага одна на все темы, а оттенок — состояние записи: выполненная
  /// зеленеет. Поэтому карточка передаёт подкраску, а не готовый цвет: иначе
  /// в тёмной теме она передала бы тёмную поверхность.
  Color get paper => tint == null
      ? notebookCardSurface
      : Color.alphaBlend(tint!, notebookCardSurface);

  /// Фон листка: зерно бумаги, одно во всех темах.
  BoxDecoration _surface(BuildContext context, BorderRadius roundedBorder) {
    return BoxDecoration(
      color: paper,
      image: const DecorationImage(
        image: AssetImage(NotebookAssets.paper),
        fit: BoxFit.cover,
        opacity: 0.5,
      ),
      borderRadius:
          PaperSheet.pageIsNotebook(context) ? null : roundedBorder,
    );
  }
}
