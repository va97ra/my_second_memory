/// Как Джарвис обращается к владельцу.
const jarvisAddress = 'сэр';

/// Голос Джарвиса — владелец выбрал его в MemoryVoice: мужской, тон чуть
/// ниже обычного, темп на 30 % быстрее. Один на всё: им говорит лист
/// Джарвиса и им же звучат напоминания, когда приложение закрыто.
abstract final class JarvisTone {
  /// Мужские русские голоса Google в порядке предпочтения; нет их — голос
  /// по умолчанию.
  static const voices = ['ru-ru-x-rud-local', 'ru-ru-x-ruf-local'];
  static const pitch = 0.85;

  /// Темп в мерке flutter_tts: 0,5 — обычная речь.
  static const rate = 0.585;
}

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
    // вопроса, а не в середину подсказки. Двоеточие времени («10:30») — не
    // разделитель: иначе выходило «с 10, сэр:30 утра».
    final colon = trimmed.indexOf(RegExp(r':(\s|$)'));
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
