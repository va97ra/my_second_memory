import 'dart:async';

import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../navigation/page_turn_navigation.dart';

/// Клавиша «назад». Одна на всё приложение, поэтому и размер у неё
/// везде один.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    this.fallbackLocation,
    this.onPressed,
    super.key,
  }) : assert(fallbackLocation != null || onPressed != null);

  final String? fallbackLocation;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('app_back'),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
          return;
        }
        if (context.canPop()) {
          unawaited(context.pageTurnPop());
          return;
        }
        unawaited(
          context.pageTurnGo(
            fallbackLocation!,
            direction: PageTurnDirection.backward,
          ),
        );
      },
      icon: const Icon(Icons.arrow_back_rounded, size: 22),
      style: notebookIconButtonStyle(),
    );
  }
}
