/// Манера Джарвиса — учтивый дворецкий: обращение («сэр») вставляется в
/// готовые фразы. «Записал: …» → «Записал, сэр: …»; «Не понял. Скажите…» →
/// «Не понял, сэр. Скажите…».
class ButlerPersona {
  const ButlerPersona(this.address);

  /// Как обращаться: «сэр», имя или пусто — без обращения.
  final String address;

  /// Вставляет обращение, если его во фразе ещё нет.
  String apply(String text) {
    final name = address.trim();
    final trimmed = text.trim();
    if (name.isEmpty || trimmed.isEmpty) return text;
    if (trimmed.toLowerCase().contains(name.toLowerCase())) return text;

    // «Записал: …» — обращение перед двоеточием, если оно близко к началу
    // и первая фраза не кончилась раньше: «Что вы хотите? …: …» — в конец
    // вопроса, а не в середину подсказки.
    final colon = trimmed.indexOf(':');
    final end = RegExp(r'[.?!…](\s|$)').firstMatch(trimmed);
    if (colon > 0 && colon < 60 && (end == null || colon < end.start)) {
      return '${trimmed.substring(0, colon)}, $name${trimmed.substring(colon)}';
    }
    if (end != null) {
      return '${trimmed.substring(0, end.start)}, $name'
          '${trimmed.substring(end.start)}';
    }
    return '$trimmed, $name';
  }
}
