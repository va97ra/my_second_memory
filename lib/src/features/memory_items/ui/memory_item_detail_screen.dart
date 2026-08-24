import 'dart:async';

import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../calendar/calendar.dart';
import '../../recurrence/recurrence.dart';
import '../state/memory_attachment_service.dart';
import '../state/memory_editor_controller.dart';
import '../state/memory_editor_fields.dart';
import '../state/memory_editor_saver.dart';
import '../state/memory_item_selectors.dart';
import '../state/memory_items_controller.dart';
import 'memory_editor_actions.dart';
import 'widgets/editor_load_gate.dart';
import 'widgets/memory_editor_app_bar.dart';
import 'widgets/memory_editor_body_view.dart';
import 'widgets/missing_record_view.dart';

/// Редактор записи. Всё, что человек выбрал, живёт в [MemoryEditorController],
/// сценарии — в [MemoryEditorActions], поля ввода — в [MemoryEditorFields];
/// экран собирает их вместе.
class MemoryItemDetailScreen extends ConsumerStatefulWidget {
  const MemoryItemDetailScreen({
    super.key,
    this.itemId,
    this.initialDate,
    this.createUndated = false,
    this.newlyCreated = false,
  });

  final String? itemId;
  final DateTime? initialDate;
  final bool createUndated;
  final bool newlyCreated;

  @override
  ConsumerState<MemoryItemDetailScreen> createState() =>
      _MemoryItemDetailScreenState();
}

class _MemoryItemDetailScreenState extends ConsumerState<MemoryItemDetailScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _fields = MemoryEditorFields();
  final _attachments = MemoryAttachmentService();
  final _imagePicker = ImagePicker();
  late final MemoryEditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MemoryEditorController(
      fields: _fields,
      locale: () => Localizations.localeOf(context).languageCode,
      readItem: _readItem,
      validate: () => _formKey.currentState?.validate() != false,
      saver: () => MemoryEditorSaver(
        items: ref.read(memoryItemsControllerProvider.notifier),
        series: ref.read(recurrenceSeriesControllerProvider.notifier),
      ),
      onCreated: _onRecordCreated,
      newlyCreated: widget.newlyCreated,
    )..addListener(() {
        if (mounted) setState(() {});
      });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _fields.dispose();
    _attachments.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_controller.flushAutosave());
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _watchItem();
    final loading = editorLoadingView(
      context,
      items: ref.watch(memoryItemsLoadProvider),
      series: ref.watch(recurrenceLoadProvider),
      needsSeries: editorNeedsSeries(item, hasItemId: widget.itemId != null),
    );
    if (loading != null) return loading;

    final actions = MemoryEditorActions(
      context: context,
      ref: ref,
      controller: _controller,
      attachments: _attachments,
      imagePicker: _imagePicker,
    );

    if (item == null && widget.itemId != null) {
      return _missingRecord(actions);
    }
    _initialize(item, actions);

    return PopScope(
      canPop: _controller.allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(actions.goBack());
      },
      child: Scaffold(
        appBar: MemoryEditorAppBar(
          controller: _controller,
          item: item,
          onBack: () => unawaited(actions.goBack()),
          onAction: (action) => actions.runMenuAction(action, item),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: MemoryEditorBodyView(
              controller: _controller,
              actions: actions,
              bodyController: _fields.body,
              amountController: _fields.amount,
              item: item,
              showHints: ref.watch(appHintsProvider),
            ),
          ),
        ),
      ),
    );
  }

  Widget _missingRecord(MemoryEditorActions actions) {
    // Запись, исчезнувшую при открытом редакторе (её удалили здесь или на
    // другом устройстве), править больше нечем: экран уходит назад сам.
    if (_controller.currentItemId != null) {
      actions.leaveAfterFrame();
      return const Scaffold(body: SizedBox.shrink());
    }
    return MissingRecordView(onBack: () => unawaited(actions.goBack()));
  }

  void _initialize(MemoryItem? item, MemoryEditorActions actions) {
    if (item == null) {
      _controller.initializeNew(
        date: widget.initialDate ?? DateTime.now(),
        isUndated: widget.createUndated,
      );
      return;
    }

    final loaded = _controller.initializeFrom(
      item,
      subscriptionTermMonths: subscriptionTermMonthsFor(
        ref.read(recurrenceSeriesControllerProvider),
        item,
      ),
    );
    if (!loaded) return;

    if (item.seriesId != null && !_controller.scopeRequested) {
      _controller.scopeRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(actions.askScope());
      });
    }
  }

  void _onRecordCreated(MemoryItem item) {
    if (!mounted || widget.itemId != null) return;
    // Записку заводят с панели, поэтому новый адрес несёт её пункт: иначе
    // панель исчезнет в тот момент, когда автосохранение сменит адрес.
    final panel = widget.createUndated ? '&panel=add_note' : '';
    context.replace('/memory/item/${Uri.encodeComponent(item.id)}?new=1$panel');
  }

  MemoryItem? _watchItem() {
    final id = _currentItemId();
    return id == null ? null : ref.watch(memoryItemByIdProvider(id));
  }

  MemoryItem? _readItem() {
    final id = _currentItemId();
    return id == null ? null : ref.read(memoryItemByIdProvider(id));
  }

  String? _currentItemId() => widget.itemId ?? _controller.currentItemId;
}
