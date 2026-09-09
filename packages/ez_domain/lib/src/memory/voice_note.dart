/// Голосовая заметка внутри записи.
///
/// Ссылка — имя файла, одно на все устройства; где он лежит и в каком виде,
/// знает хранилище. Длительность хранится рядом, потому что показать её нужно
/// до того, как файл откроют, а на чужом устройстве файла может ещё не быть.
class VoiceNote {
  const VoiceNote({required this.reference, required this.durationSeconds});

  final String reference;
  final int durationSeconds;

  Map<String, Object?> toJson() => {
        'reference': reference,
        'durationSeconds': durationSeconds,
      };

  factory VoiceNote.fromJson(Map<String, Object?> json) => VoiceNote(
        reference: json['reference'] as String,
        durationSeconds: json['durationSeconds'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is VoiceNote &&
      other.reference == reference &&
      other.durationSeconds == durationSeconds;

  @override
  int get hashCode => Object.hash(reference, durationSeconds);
}
