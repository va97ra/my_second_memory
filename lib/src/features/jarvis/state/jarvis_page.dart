import 'dart:async';

import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'jarvis_controller.dart';

/// Какая страница сейчас на экране, с днём, если он у неё есть; null — та,
/// которой у Джарвиса нет названия. Её отмечает оболочка при каждой смене
/// адреса.
///
/// По ней Джарвис понимает «что здесь» и видно ли калькулятор или
/// конвертер, которые он заполняет.
final jarvisPageProvider = StateProvider<OpenPlace?>((ref) => null);

/// Дойти до страницы тем же путём, что «Показать», и дождаться её: Джарвис
/// сначала приходит на калькулятор или конвертер, потом набирает, и это
/// видно.
Future<void> comeToPage(Ref ref, OpenPlace place) async {
  bool here() => ref.read(jarvisPageProvider)?.place == place.place;
  if (here()) return;
  ref.read(jarvisControllerProvider.notifier).show(place);
  final arrived = Completer<void>();
  final watch = ref.listen(jarvisPageProvider, (_, page) {
    if (page?.place == place.place && !arrived.isCompleted) arrived.complete();
  });
  try {
    await arrived.future.timeout(_arrival, onTimeout: () {});
  } finally {
    watch.close();
  }
  // Переворот листа доигрывает уже на новой странице.
  if (here()) await Future<void>.delayed(_settle);
}

/// Сколько ждать страницу и пока доиграет переворот.
const _arrival = Duration(seconds: 3);
const _settle = Duration(milliseconds: 450);
