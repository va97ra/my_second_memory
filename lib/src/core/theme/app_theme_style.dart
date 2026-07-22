enum AppThemeStyle {
  light,
  dark,
  notebook;

  static AppThemeStyle? fromStorage(String? value) {
    for (final style in values) {
      if (style.name == value) {
        return style;
      }
    }
    return null;
  }
}
