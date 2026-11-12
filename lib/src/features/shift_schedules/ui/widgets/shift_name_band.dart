import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Полоса цвета графика, в которой пишут его название.
class ShiftNameBand extends StatelessWidget {
  const ShiftNameBand({
    super.key,
    required this.controller,
    required this.color,
  });

  final TextEditingController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ink = readableInkOn(color);
    const noBorder = OutlineInputBorder(borderSide: BorderSide.none);

    return AnimatedContainer(
      key: const ValueKey('shift_color_preview'),
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        textInputAction: TextInputAction.done,
        cursorColor: ink,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ink,
              fontWeight: FontWeight.w800,
            ),
        decoration: InputDecoration(
          hintText: AppStrings.of(context).organization,
          hintStyle: TextStyle(color: ink.withValues(alpha: 0.7)),
          prefixIcon: Icon(Icons.business_rounded, color: ink),
          filled: false,
          border: noBorder,
          enabledBorder: noBorder,
          focusedBorder: noBorder,
        ),
      ),
    );
  }
}
