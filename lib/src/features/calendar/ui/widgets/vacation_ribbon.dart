import 'dart:math' as math;
import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';


/// Лента отпуска через ячейку дня.
class VacationRibbon extends StatelessWidget {
  const VacationRibbon({super.key});

  @override
  Widget build(BuildContext context) {
    final label = AppStrings.of(context).vacation.toUpperCase();

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final ribbonHeight = (height * 0.19).clamp(9.0, 13.0);
          // Extend the texture past both diagonal endpoints. The surrounding
          // ClipRect then cuts it exactly at the segment corners, so there are
          // no visually detached ribbon ends inside the calendar cell.
          final diagonal =
              math.sqrt(width * width + height * height) + ribbonHeight * 4;
          final angle = -math.atan2(height, width);

          return Center(
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Transform.rotate(
                angle: angle,
                child: SizedBox(
                  width: diagonal,
                  height: ribbonHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/textures/vacation_ribbon.webp',
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.medium,
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                color: Color(0xFFFFF2C7),
                                fontSize: 6.5,
                                fontWeight: FontWeight.w900,
                                height: 1,
                                letterSpacing: 0.35,
                                shadows: [
                                  Shadow(
                                    color: Color(0xCC3A0713),
                                    blurRadius: 1,
                                    offset: Offset(0, 0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
