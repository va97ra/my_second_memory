import 'package:ez_domain/ez_domain.dart';

/// Что стало с ответом на вопрос о деле.
enum TaskQuestionResult {
  /// Ответили — можно спрашивать дальше или записывать.
  answered,

  /// «Не надо» — дело не записывается.
  dropped,

  /// Не ответ, а новая просьба: начатое записывается как есть.
  newRequest,
}

/// Уточнения по новым делам: каким не хватает дня или времени, а в
/// подробной карточке — длительности, места, того, что сделать, и
/// срочности. Спрашивается по одному вопросу о первом деле в очереди;
/// готовые ждут, пока уточнятся остальные, и записываются вместе.
class JarvisTaskQuestions {
  JarvisTaskQuestions({required bool Function() detailed})
      : _detailed = detailed;

  final bool Function() _detailed;
  final _waiting = <ParsedTask>[];
  final _ready = <ParsedTask>[];

  /// Как дела были сказаны — для записей.
  String transcript = '';

  /// Ждёт ли Джарвис ответа о деле.
  bool get asking => _waiting.isNotEmpty;

  bool get hasReady => _ready.isNotEmpty;

  TaskNeed? _needOf(ParsedTask task) => task.needFor(detailed: _detailed());

  void add(List<ParsedTask> tasks, {required String transcript}) {
    this.transcript = transcript;
    for (final task in tasks) {
      (_needOf(task) == null ? _ready : _waiting).add(task);
    }
  }

  /// Следующий вопрос; null — спрашивать нечего.
  ({ParsedTask task, TaskNeed need})? get next {
    if (_waiting.isEmpty) return null;
    final task = _waiting.first;
    return (task: task, need: _needOf(task)!);
  }

  /// Забрать готовые к записи.
  List<ParsedTask> takeReady() {
    final tasks = [..._ready];
    _ready.clear();
    return tasks;
  }

  void clear() {
    _waiting.clear();
    _ready.clear();
  }

  /// Ответ на вопрос о первом деле. Брошенное — [dropped] вместе с самим
  /// делом, чтобы сказать, что именно не записано.
  ({TaskQuestionResult result, ParsedTask task}) answer(
      String said, DateTime now) {
    final task = _waiting.first;
    final need = _needOf(task) ?? TaskNeed.time;
    final asksMoment = need == TaskNeed.date || need == TaskNeed.time;
    switch (asksMoment
        ? readClarification(said, now, forDate: task.date)
        : readDetail(task, need, said, now)) {
      case ClarificationCancel():
        _waiting.removeAt(0);
        return (result: TaskQuestionResult.dropped, task: task);
      case ClarificationAnswer(:final answer):
        _waiting[0] = _answered(task, answer);
        if (_needOf(_waiting.first) == null || answer.noDate) {
          _ready.add(_waiting.removeAt(0));
        }
      case ClarificationDetail(task: final answered):
        _waiting[0] = answered;
        if (_needOf(answered) == null) _ready.add(_waiting.removeAt(0));
      case ClarificationNewRequest():
        // Заговорили о другом: начатое записывается как есть — без дня
        // запиской, без времени на весь день, без подробностей — как есть.
        for (final waiting in _waiting) {
          _ready.add(switch (waiting.need) {
            TaskNeed.time => waiting.copyWith(allDay: true),
            TaskNeed.date => waiting.copyWith(date: null),
            _ => waiting,
          });
        }
        _waiting.clear();
        return (result: TaskQuestionResult.newRequest, task: task);
    }
    return (result: TaskQuestionResult.answered, task: task);
  }

  ParsedTask _answered(ParsedTask task, TaskAnswer answer) {
    if (answer.noDate) {
      // «Не знаю» на вопрос о времени — день остаётся, время не важно.
      return task.need == TaskNeed.time
          ? task.copyWith(allDay: true)
          : task.copyWith(date: null);
    }
    var result = task;
    if (answer.date != null) result = result.copyWith(date: answer.date);
    if (answer.minutes != null) {
      result = result.copyWith(minutes: answer.minutes, allDay: false);
    }
    if (answer.allDay) result = result.copyWith(minutes: null, allDay: true);
    return result;
  }
}
