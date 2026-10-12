import 'dart:async';

import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../navigation/jarvis_locations.dart';
import '../state/jarvis_controller.dart';
import '../state/jarvis_keep_awake.dart';
import '../state/jarvis_page.dart';
import '../state/jarvis_presence.dart';
import '../state/jarvis_talk_controller.dart';
import '../state/jarvis_wake_controller.dart';
import 'jarvis_badge.dart';
import 'jarvis_sheet.dart';

/// Джарвис для всего приложения: слух на имя, его место на экране и
/// переходы, о которых его попросили.
///
/// Стоит в оболочке, выше навигатора: пока приложение на экране, имя ждут
/// на любой странице. Свернули приложение — микрофон выключается. Позвали —
/// отвечает открытый лист, а без него Джарвис встаёт значком поверх
/// страницы, и её видно. Попросили страницу — лист сворачивается в значок,
/// и разговор идёт дальше уже на ней. Пока Джарвис на экране, экран телефона
/// не гаснет.
class JarvisWakeHost extends ConsumerStatefulWidget {
  const JarvisWakeHost({
    required this.navigatorContext,
    required this.child,
    super.key,
  });

  /// Контекст навигатора, в котором открываются лист и страницы.
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
    final presence = ref.watch(jarvisPresenceProvider);
    // Разговор жив, пока Джарвис на экране — листом или значком. Ушёл —
    // разговор кончается: микрофон и голос гаснут.
    if (presence != JarvisPresence.away) ref.watch(jarvisTalkProvider);
    // На погасшем экране Android не даёт микрофон: пока Джарвис здесь,
    // экран горит.
    ref.listen(
        jarvisPresenceProvider,
        (_, now) => unawaited(ref
            .read(jarvisKeepAwakeProvider)
            .keepOn(now != JarvisPresence.away)));
    ref.listen(jarvisWakeProvider, (_, call) {
      if (call != null) _answer(call.command);
    });
    ref.listen(
      jarvisControllerProvider.select((state) => state.navigation),
      (_, navigation) {
        if (navigation != null) _open(navigation.target);
      },
    );
    return Stack(
      children: [
        widget.child,
        if (presence == JarvisPresence.badge) JarvisBadge(onOpen: _expand),
      ],
    );
  }

  /// Позвали по имени. Отвечает открытый лист, а без него — значок.
  void _answer(String command) {
    final presence = ref.read(jarvisPresenceProvider.notifier);
    if (presence.state == JarvisPresence.away) {
      presence.state = JarvisPresence.badge;
    }
    // Разговор подхватывается кадром позже, когда его уже держит хост:
    // иначе он родился бы и тут же ушёл, никем не удержанный.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(jarvisTalkProvider.notifier).respond(command));
      }
    });
  }

  /// Страница, о которой попросили. Лист сворачивается в значок — разговор
  /// идёт дальше уже на ней.
  void _open(OpenPlace target) {
    final presence = ref.read(jarvisPresenceProvider.notifier);
    // Без Джарвиса на экране переходов нет: страницу, о которой попросили
    // за его спиной, он откроет, когда появится.
    if (presence.state == JarvisPresence.away) return;
    ref.read(jarvisControllerProvider.notifier).navigationHandled();
    presence.state = JarvisPresence.badge;
    final navigator = widget.navigatorContext();
    if (navigator == null) return;
    Navigator.of(navigator).popUntil((route) => route is! PopupRoute);
    // Страница уже на экране — лист убран, и её видно; переворачивать её
    // саму на себя незачем.
    if (!_onScreen(target)) unawaited(openJarvisPlace(navigator, target));
  }

  bool _onScreen(OpenPlace target) {
    final here = ref.read(jarvisPageProvider);
    if (here == null || here.place != target.place) return false;
    final day = target.date;
    final shown = here.date;
    return day == null ||
        (shown != null &&
            shown.year == day.year &&
            shown.month == day.month &&
            shown.day == day.day);
  }

  /// Значок нажали — раскрыть лист разговора.
  void _expand() {
    final navigator = widget.navigatorContext();
    if (navigator != null) unawaited(showJarvisSheet(navigator));
  }
}
