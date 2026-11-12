/// Запись журнала ошибок: время, тип, сообщение и начало стека.
///
/// Сообщение обрезается: в нём может оказаться кусок данных, а журналу
/// нужно узнать ошибку, а не пересказать запись человека.
String errorJournalEntry(Object error, StackTrace? stack, DateTime at) {
  final message = error.toString();
  final frames = (stack?.toString() ?? '')
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .take(_maxFrames);
  return [
    '=== ${at.toIso8601String()} ===',
    error.runtimeType.toString(),
    message.length > _maxMessage
        ? '${message.substring(0, _maxMessage)}…'
        : message,
    ...frames,
    '',
  ].join('\n');
}

const _maxMessage = 300;
const _maxFrames = 30;
