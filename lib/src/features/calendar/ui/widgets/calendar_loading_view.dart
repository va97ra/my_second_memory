import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Календарь, которому ещё нечего показать. Шапка остаётся на месте: месяц и
/// стрелки к записям отношения не имеют.
class CalendarLoadingView extends StatelessWidget {
  const CalendarLoadingView({
    super.key,
    required this.header,
    required this.isLoading,
  });

  final Widget header;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return WarmGradientBackground(
      child: Column(
        children: [
          header,
          Expanded(
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Text(AppStrings.of(context).loadFailed),
            ),
          ),
        ],
      ),
    );
  }
}
