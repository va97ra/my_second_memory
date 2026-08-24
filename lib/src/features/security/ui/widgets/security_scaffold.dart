import 'package:flutter/material.dart';

/// Экран, закрывающий приложение до разблокировки.
///
/// Он живёт в собственном [Overlay], чтобы не зависеть от навигатора
/// приложения: замок показывается до того, как тот вообще построен.
class SecurityScaffold extends StatefulWidget {
  const SecurityScaffold({super.key, required this.child});

  final Widget child;

  @override
  State<SecurityScaffold> createState() => _SecurityScaffoldState();
}

class _SecurityScaffoldState extends State<SecurityScaffold> {
  late final OverlayEntry _entry = OverlayEntry(builder: _buildScaffold);

  @override
  void didUpdateWidget(covariant SecurityScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.markNeedsBuild();
  }

  @override
  void dispose() {
    if (_entry.mounted) {
      _entry.remove();
    }
    super.dispose();
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(initialEntries: [_entry]);
  }
}
