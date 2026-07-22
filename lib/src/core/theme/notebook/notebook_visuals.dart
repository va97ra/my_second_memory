import 'package:flutter/material.dart';

@immutable
class NotebookVisuals extends ThemeExtension<NotebookVisuals> {
  const NotebookVisuals({
    required this.paper,
    required this.ink,
    required this.mutedInk,
    required this.line,
    required this.primaryTop,
    required this.primaryBottom,
    required this.primaryShadow,
    required this.blue,
    required this.green,
    required this.teal,
    required this.yellow,
  });

  final Color paper;
  final Color ink;
  final Color mutedInk;
  final Color line;
  final Color primaryTop;
  final Color primaryBottom;
  final Color primaryShadow;
  final Color blue;
  final Color green;
  final Color teal;
  final Color yellow;

  static NotebookVisuals? maybeOf(BuildContext context) {
    return Theme.of(context).extension<NotebookVisuals>();
  }

  @override
  NotebookVisuals copyWith({
    Color? paper,
    Color? ink,
    Color? mutedInk,
    Color? line,
    Color? primaryTop,
    Color? primaryBottom,
    Color? primaryShadow,
    Color? blue,
    Color? green,
    Color? teal,
    Color? yellow,
  }) {
    return NotebookVisuals(
      paper: paper ?? this.paper,
      ink: ink ?? this.ink,
      mutedInk: mutedInk ?? this.mutedInk,
      line: line ?? this.line,
      primaryTop: primaryTop ?? this.primaryTop,
      primaryBottom: primaryBottom ?? this.primaryBottom,
      primaryShadow: primaryShadow ?? this.primaryShadow,
      blue: blue ?? this.blue,
      green: green ?? this.green,
      teal: teal ?? this.teal,
      yellow: yellow ?? this.yellow,
    );
  }

  @override
  NotebookVisuals lerp(covariant NotebookVisuals? other, double t) {
    if (other == null) {
      return this;
    }
    return NotebookVisuals(
      paper: Color.lerp(paper, other.paper, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      mutedInk: Color.lerp(mutedInk, other.mutedInk, t)!,
      line: Color.lerp(line, other.line, t)!,
      primaryTop: Color.lerp(primaryTop, other.primaryTop, t)!,
      primaryBottom: Color.lerp(primaryBottom, other.primaryBottom, t)!,
      primaryShadow: Color.lerp(primaryShadow, other.primaryShadow, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      green: Color.lerp(green, other.green, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
    );
  }
}
