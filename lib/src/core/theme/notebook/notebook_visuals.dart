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
    required this.paperAsset,
    required this.leatherAsset,
    required this.cardSurface,
    required this.cardInk,
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

  /// Which grain this notebook wears. The dark book is the same object under
  /// different light, so it uses darker stock rather than a tinted copy.
  final String paperAsset;
  final String leatherAsset;

  /// Loose paper lying on the book: memory cards and calendar day cells stay
  /// light in both themes, so they carry their own surface and ink.
  final Color cardSurface;
  final Color cardInk;

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
    String? paperAsset,
    String? leatherAsset,
    Color? cardSurface,
    Color? cardInk,
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
      paperAsset: paperAsset ?? this.paperAsset,
      leatherAsset: leatherAsset ?? this.leatherAsset,
      cardSurface: cardSurface ?? this.cardSurface,
      cardInk: cardInk ?? this.cardInk,
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
      // A texture cannot be blended; it swaps at the halfway point.
      paperAsset: t < 0.5 ? paperAsset : other.paperAsset,
      leatherAsset: t < 0.5 ? leatherAsset : other.leatherAsset,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardInk: Color.lerp(cardInk, other.cardInk, t)!,
    );
  }
}
