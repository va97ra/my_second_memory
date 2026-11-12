/// В вебе файлов нет: журнал ошибок молчит, ошибки видны в консоли браузера.
class ErrorJournal {
  ErrorJournal({String? directory, this.maxBytes = 256 * 1024});

  static const fileName = 'error_journal.log';

  final int maxBytes;

  Future<void> record(Object error, StackTrace? stack, {DateTime? at}) async {}

  Future<String> read() async => '';
}
