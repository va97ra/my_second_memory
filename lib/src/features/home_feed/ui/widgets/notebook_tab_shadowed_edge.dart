import 'package:flutter/material.dart';

/// Верх закладки, лежащей позади текущего листа: край листа и его тень.
///
/// У самой закладки верхнего края нет — она вырезана из листа над ней.
class NotebookTabShadowedEdge extends StatelessWidget {
  const NotebookTabShadowedEdge({super.key});

  static const _pageEdgeColor = Color(0xFF9A6034);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 1.2,
            child: ColoredBox(color: _pageEdgeColor),
          ),
        ],
      ),
    );
  }
}
