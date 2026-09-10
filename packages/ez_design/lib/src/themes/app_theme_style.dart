/// Оформление приложения целиком: и цвета, и приёмы рисования.
///
/// Блокнотные темы рисуют бумагу и кожу, экранные — подсвеченные панели на
/// тёмном фоне. Новая тема добавляется значением здесь и своим набором
/// значений; выбор тем в настройках собирается по этому перечислению сам.
enum AppThemeStyle {
  notebookLight,
  notebookDark,
  cosmos,
  cyberpunk;

  /// Рисует ли тема бумагу. Всё остальное — экран.
  bool get isNotebook =>
      this == AppThemeStyle.notebookLight || this == AppThemeStyle.notebookDark;

  /// Reads a stored value, including the ones written before the app settled
  /// on the notebook: the flat light and dark themes are gone, and whoever was
  /// on them lands on the notebook of the same brightness.
  static AppThemeStyle? fromStorage(String? value) {
    return switch (value) {
      'notebookLight' || 'notebook' || 'light' => AppThemeStyle.notebookLight,
      'notebookDark' || 'dark' => AppThemeStyle.notebookDark,
      'cosmos' => AppThemeStyle.cosmos,
      'cyberpunk' => AppThemeStyle.cyberpunk,
      _ => null,
    };
  }
}
