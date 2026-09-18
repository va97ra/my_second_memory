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

  /// Enabled choices. Cyberpunk is retained as a renderer for now, but is
  /// disabled in the product by the owner's decision on 2026-09-17.
  static const available = [notebookLight, notebookDark, cosmos];

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
      'cyberpunk' => AppThemeStyle.cosmos,
      _ => null,
    };
  }
}
