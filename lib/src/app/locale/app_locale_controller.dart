import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appLocaleControllerProvider =
    NotifierProvider<AppLocaleController, Locale>(AppLocaleController.new);

class AppLocaleController extends Notifier<Locale> {
  @override
  Locale build() => const Locale('ru');

  void setRussian() => state = const Locale('ru');

  void setEnglish() => state = const Locale('en');
}
