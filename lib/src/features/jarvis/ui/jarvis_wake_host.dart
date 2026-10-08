import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/jarvis_wake_controller.dart';
import 'jarvis_sheet.dart';

/// Слух на имя «Джарвис» для всего приложения.
///
/// Стоит в оболочке, выше навигатора: пока приложение на экране, имя ждут
/// на любой странице. Свернули приложение — микрофон выключается. Позвали
/// при закрытом листе — лист открывается и отвечает; открытый лист отвечает
/// сам.
class JarvisWakeHost extends ConsumerStatefulWidget {
  const JarvisWakeHost({
    required this.navigatorContext,
    required this.child,
    super.key,
  });

  /// Контекст навигатора, в котором открывается лист.
  final BuildContext? Function() navigatorContext;
  final Widget child;

  @override
  ConsumerState<JarvisWakeHost> createState() => _JarvisWakeHostState();
}

class _JarvisWakeHostState extends ConsumerState<JarvisWakeHost> {
  late final AppLifecycleListener _lifecycle;
  late final JarvisWakeController _wake;

  @override
  void initState() {
    super.initState();
    _wake = ref.read(jarvisWakeProvider.notifier);
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) =>
          _wake.setForeground(state == AppLifecycleState.resumed),
    );
    _wake.setForeground(true);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _wake.setForeground(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(jarvisWakeProvider, (_, call) {
      if (call == null || ref.read(jarvisSheetOpenProvider)) return;
      final navigator = widget.navigatorContext();
      if (navigator != null) showJarvisSheet(navigator, call: call.command);
    });
    return widget.child;
  }
}
