import 'package:flutter/material.dart';

/// Оформление приложения: светлая и тёмная темы (решение владельца 4 ноября 2026).
enum AppThemeStyle {
  notebookLight,
  notebookDark;

  static const available = values;

  /// Читает сохранённое значение, в том числе из прошлых версий: кто был на
  /// удалённой теме, попадает на тему той же светлоты, а с «Космоса» и «Киберпанка»
  /// на тёмную.
  static AppThemeStyle? fromStorage(String? value) {
    return switch (value) {
      'notebookLight' || 'notebook' || 'light' => AppThemeStyle.notebookLight,
      'notebookDark' || 'dark' || 'cosmos' || 'cyberpunk' =>
        AppThemeStyle.notebookDark,
      _ => null,
    };
  }
}

/// Светлота темы.
Brightness brightnessOf(AppThemeStyle style) =>
    style == AppThemeStyle.notebookDark ? Brightness.dark : Brightness.light;
