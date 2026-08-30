import 'package:ez_design/ez_design.dart';
import 'package:flutter/widgets.dart';

/// Что странице известно про экран: её собственный размер, клавиатура за
/// вычетом нижней панели и без верхнего отступа, занятого шапкой инструментов.
///
/// Панели живут выше страницы и её место не занимают, поэтому «высота экрана»
/// для всего, что внутри, — это высота листа между панелями. Иначе лист,
/// заказавший себе долю экрана, вылезал бы за отведённое ему место.
///
/// Отдельный виджет здесь не ради порядка. Клавиатура выезжает кадрами, и на
/// каждом кадре пересобирается тот, кто её читает. Пока это делала оболочка,
/// вместе с ней заново собирались обе панели, фон и сама страница — два
/// десятка кнопок на каждый кадр выезда. Теперь читает один этот виджет, а
/// страницу он отдаёт вниз той же самой.
class PageMedia extends StatelessWidget {
  const PageMedia({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final navigationExtent =
        NavBarMetrics.bottomContentExtent + media.viewPadding.bottom;
    final bottomInset =
        (media.viewInsets.bottom - navigationExtent).clamp(0.0, double.infinity);
    return LayoutBuilder(
      builder: (context, constraints) => MediaQuery(
        data: media
            .copyWith(
              size: constraints.biggest,
              viewInsets: media.viewInsets.copyWith(bottom: bottomInset),
            )
            .removePadding(removeTop: true),
        child: child,
      ),
    );
  }
}
