import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Уводит с экрана записи, которой больше нет, после того как кадр дорисован.
///
/// Менять маршрут прямо во время построения нельзя. Уход идёт без
/// перелистывания: страницу, которой уже нет, не показывают уезжающей, а
/// перелистывание в этот момент бывает занято другим переходом и отменило бы
/// сам уход.
void leaveAfterFrame(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  });
}
