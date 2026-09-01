import 'package:flutter/material.dart';

import 'tool_art_shapes.dart';

/// Рисунки инструмента.
///
/// Линия, а не фотография: рисунок живёт в обеих темах, ничего не весит и
/// не мылится при увеличении. Фотографии инструмента в приложении нет и не
/// будет, пока её не снимет владелец — чужие снимки сюда не годятся.
enum ElectricianToolArt {
  screwdriver,
  pliers,
  sideCutters,
  longNose,
  knife,
  stripper,
  crimper,
  meter,
  detector,
  clampMeter,
  insulationTester,
  rotaryHammer,
  holeSaw,
  insulatedSet,
  gloves,
  mat,
  goggles,
}

/// Рисунок по имени из карточки. `null` — у карточки нет рисунка.
ElectricianToolArt? electricianToolArtByName(String name) {
  for (final value in ElectricianToolArt.values) {
    if (value.name == name) return value;
  }
  return null;
}

class ElectricianToolArtView extends StatelessWidget {
  const ElectricianToolArtView({
    required this.art,
    this.size = 96,
    super.key,
  });

  final ElectricianToolArt art;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _ToolPainter(
            art: art,
            ink: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
}

class _ToolPainter extends CustomPainter {
  const _ToolPainter({required this.art, required this.ink});

  final ElectricianToolArt art;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = ToolPen(canvas: canvas, size: size, ink: ink);
    switch (art) {
      case ElectricianToolArt.screwdriver:
        drawScrewdriver(pen, marked: false);
      case ElectricianToolArt.insulatedSet:
        drawScrewdriver(pen, marked: true);
      case ElectricianToolArt.pliers:
        drawPliers(pen, jaw: PliersJaw.flat);
      case ElectricianToolArt.sideCutters:
        drawPliers(pen, jaw: PliersJaw.cutting);
      case ElectricianToolArt.longNose:
        drawPliers(pen, jaw: PliersJaw.long);
      case ElectricianToolArt.knife:
        drawKnife(pen);
      case ElectricianToolArt.stripper:
        drawStripper(pen);
      case ElectricianToolArt.crimper:
        drawCrimper(pen);
      case ElectricianToolArt.meter:
        drawMeter(pen, highVoltage: false);
      case ElectricianToolArt.insulationTester:
        drawMeter(pen, highVoltage: true);
      case ElectricianToolArt.detector:
        drawDetector(pen);
      case ElectricianToolArt.clampMeter:
        drawClampMeter(pen);
      case ElectricianToolArt.rotaryHammer:
        drawRotaryHammer(pen);
      case ElectricianToolArt.holeSaw:
        drawHoleSaw(pen);
      case ElectricianToolArt.gloves:
        drawGlove(pen);
      case ElectricianToolArt.mat:
        drawMat(pen);
      case ElectricianToolArt.goggles:
        drawGoggles(pen);
    }
  }

  @override
  bool shouldRepaint(_ToolPainter oldDelegate) =>
      oldDelegate.art != art || oldDelegate.ink != ink;
}
