import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/foundation.dart';

import 'memory_editor_draft.dart';
import 'memory_editor_fields.dart';
import 'memory_editor_form.dart';
import 'memory_editor_save_coordinator.dart';
import 'memory_editor_saver.dart';

/// Состояние открытого редактора записи: форма, ход сохранения и всё, что
/// экран должен помнить между кадрами.
///
/// Здесь нет ни одного виджета и ни одного `BuildContext`: диалоги спрашивает
/// экран, а сюда приходит уже готовый ответ. Поэтому сценарий сохранения
/// проверяется без запуска редактора.
class MemoryEditorController extends ChangeNotifier {
  MemoryEditorController({
    required this.fields,
    required this.locale,
    required this.readItem,
    required this.validate,
    required this.saver,
    required this.onCreated,
    bool newlyCreated = false,
    MemoryEditorSaveCoordinator? coordinator,
  })  : refreshNewSeriesTemplate = newlyCreated,
        // У только что заведённой записи область правки уже выбрана: её и
        // спрашивать не о чем, серии у неё пока нет.
        scopeRequested = newlyCreated,
        _coordinator = coordinator ?? MemoryEditorSaveCoordinator();

  /// Поля ввода: текст записи и сумма.
  final MemoryEditorFields fields;

  /// Язык, на котором записи дают название.
  final String Function() locale;

  /// Запись в том виде, в каком её сейчас видит хранилище.
  final MemoryItem? Function() readItem;

  /// Проверка полей ввода. Форма с ошибкой не сохраняется.
  final bool Function() validate;

  final MemoryEditorSaver Function() saver;

  /// Первое сохранение завело запись: у неё появился адрес.
  final void Function(MemoryItem item) onCreated;

  /// Метка ещё не сохранённого черновика в [loadedItemId].
  static const newRecordKey = '__new__';

  final MemoryEditorSaveCoordinator _coordinator;

  MemoryEditorForm form = MemoryEditorForm.blank(
    date: DateTime.now(),
    isUndated: false,
  );

  String? loadedItemId;
  bool editFutureOccurrences = false;
  bool scopeRequested;
  bool refreshNewSeriesTemplate;
  bool isRecording = false;
  bool isSaving = false;
  bool hasSaveError = false;
  bool allowPop = false;
  bool isLeaving = false;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _coordinator.dispose();
    super.dispose();
  }

  /// Изменение, о котором экран должен узнать.
  void update(VoidCallback mutate) {
    mutate();
    _notify();
  }

  /// Правка формы: экран передаёт изменение, дальше оно само уходит в
  /// отложенное сохранение.
  void applyForm(MemoryEditorForm Function(MemoryEditorForm form) change) {
    update(() => form = change(form));
    scheduleAutosave();
  }

  /// Загружает запись в форму. Молча: вызывается во время построения кадра,
  /// когда сообщать об изменении ещё нельзя.
  ///
  /// Возвращает true, если запись загрузилась именно сейчас.
  bool initializeFrom(MemoryItem item, {required int? subscriptionTermMonths}) {
    if (loadedItemId == item.id) return false;
    loadedItemId = item.id;
    form = MemoryEditorForm.fromItem(
      item,
      subscriptionTermMonths: subscriptionTermMonths,
    );
    fields.loadFrom(item);
    return true;
  }

  /// Готовит форму новой записи. Тоже молча и по той же причине.
  bool initializeNew({required DateTime date, required bool isUndated}) {
    if (loadedItemId == newRecordKey) return false;
    loadedItemId = newRecordKey;
    form = MemoryEditorForm.blank(date: date, isUndated: isUndated);
    fields.clear();
    return true;
  }

  /// Запись, которую правят, или null, пока черновик не сохранён.
  String? get currentItemId =>
      loadedItemId == null || loadedItemId == newRecordKey
          ? null
          : loadedItemId;

  bool get _canSave =>
      !isRecording && (fields.hasContent(form) || readItem() != null);

  /// Откладывает сохранение: человек ещё печатает.
  void scheduleAutosave() {
    _coordinator.schedule(canSave: _canSave, save: save);
  }

  /// Досохраняет отложенное — перед уходом с экрана и при сворачивании
  /// приложения.
  Future<void> flushAutosave() {
    return _coordinator.flush(canSave: _canSave, save: save);
  }

  void discardPendingSave() => _coordinator.discardPending();

  Future<void> save() async {
    if (!validate()) return;
    if (!fields.hasContent(form) && readItem() == null) return;

    final snapshot = _draft();
    final revision = _coordinator.beginSave();
    update(() {
      isSaving = true;
      hasSaveError = false;
    });

    try {
      await _coordinator.enqueue(() => _persist(snapshot));
      if (_disposed || !_coordinator.isCurrent(revision)) return;
      update(() {
        isSaving = false;
        // Отметку «срок трогали» снимаем только если с начала сохранения
        // ничего из того, что попало в серию, не изменилось снова.
        if (_savedTermMatchesForm(snapshot)) {
          form = form.copyWith(subscriptionTermDirty: false);
        }
      });
    } catch (_) {
      if (_disposed || !_coordinator.isCurrent(revision)) return;
      update(() {
        isSaving = false;
        hasSaveError = true;
      });
    }
  }

  Future<void> _persist(MemoryEditorDraft snapshot) async {
    final outcome = await saver().persist(
      snapshot,
      existing: readItem(),
      refreshSeriesTemplate: refreshNewSeriesTemplate,
      editFutureOccurrences: editFutureOccurrences,
      originalOccurrenceDate: form.originalOccurrenceDate,
    );

    if (!outcome.created) return;
    // Первое сохранение превращает черновик в запись: дальше редактор правит
    // её по идентификатору, а не заводит вторую.
    loadedItemId = outcome.item.id;
    refreshNewSeriesTemplate = true;
    scopeRequested = true;
    onCreated(outcome.item);
  }

  bool _savedTermMatchesForm(MemoryEditorDraft snapshot) {
    if (!snapshot.subscriptionTermDirty) return false;
    final current = _draft();
    return snapshot.type == current.type &&
        snapshot.repeatRule == current.repeatRule &&
        snapshot.paymentCategory == current.paymentCategory &&
        snapshot.subscriptionTermMonths == current.subscriptionTermMonths;
  }

  MemoryEditorDraft _draft() => fields.buildDraft(form, locale: locale());

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }
}
