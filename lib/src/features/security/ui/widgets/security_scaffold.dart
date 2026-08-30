import 'package:ez_design/ez_design.dart';
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
  Widget _buildScaffold(BuildContext context) {
    // Замок стоит выше оболочки, а бумагу рисует она. Здесь фон свой, иначе
    // экран с PIN остался бы на пустом цвете темы.
    return AppBackground(
      child: Scaffold(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OverlayHost(child: Builder(builder: _buildScaffold));
  }
}
