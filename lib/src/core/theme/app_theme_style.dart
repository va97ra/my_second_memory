enum AppThemeStyle {
  notebookLight,
  notebookDark;

  bool get isDark => this == AppThemeStyle.notebookDark;

  /// Reads a stored value, including the ones written before the app settled
  /// on the notebook: the flat light and dark themes are gone, and whoever was
  /// on them lands on the notebook of the same brightness.
  static AppThemeStyle? fromStorage(String? value) {
    return switch (value) {
      'notebookLight' || 'notebook' || 'light' => AppThemeStyle.notebookLight,
      'notebookDark' || 'dark' => AppThemeStyle.notebookDark,
      _ => null,
    };
  }
}
