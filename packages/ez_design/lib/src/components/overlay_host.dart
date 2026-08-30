import 'package:flutter/material.dart';

/// Слой, который сам себе [Overlay].
///
/// Всплывающей подсказке, меню и подобным нужен `Overlay` над ними, а он
/// приходит вместе с навигатором. Тому, кто живёт выше навигатора — оболочке
/// с её панелями и замку, закрывающему приложение до разблокировки, — слой
/// приходится приносить с собой.
class OverlayHost extends StatefulWidget {
  const OverlayHost({required this.child, super.key});

  final Widget child;

  @override
  State<OverlayHost> createState() => _OverlayHostState();
}

class _OverlayHostState extends State<OverlayHost> {
  late final OverlayEntry _entry = OverlayEntry(builder: (_) => widget.child);

  @override
  void didUpdateWidget(covariant OverlayHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Запись построена один раз и держит виджет, который ей дали. Новый
    // ребёнок доходит до неё только так.
    if (!identical(oldWidget.child, widget.child)) _entry.markNeedsBuild();
  }

  @override
  void dispose() {
    if (_entry.mounted) _entry.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);
}
