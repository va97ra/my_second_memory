import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appLocaleControllerProvider =
    StateNotifierProvider<AppLocaleController, Locale>(
  (ref) => AppLocaleController(),
);

class AppLocaleController extends StateNotifier<Locale> {
  AppLocaleController() : super(const Locale('ru'));

  void setRussian() => state = const Locale('ru');

  void setEnglish() => state = const Locale('en');
}
