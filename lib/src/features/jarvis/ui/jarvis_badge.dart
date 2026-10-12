import 'dart:async';

import 'package:ez_design/ez_design.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/jarvis_controller.dart';
import '../state/jarvis_presence.dart';
import '../state/jarvis_talk_controller.dart';
import 'widgets/jarvis_badge_caption.dart';
import 'widgets/jarvis_badge_orb.dart';

/// Джарвис на странице — значок над его кнопкой в панели.
///
/// Перейдя на страницу или отозвавшись на имя, Джарвис не закрывает её
/// листом, а остаётся здесь: слушает, говорит, и видно, что он делает.
/// Рядом — услышанное или последний ответ и «Отменить». Нажали на значок —
/// раскрывается лист разговора. Разговор затих — значок уходит сам.
class JarvisBadge extends ConsumerStatefulWidget {
  const JarvisBadge({required this.onOpen, super.key});

  /// Раскрыть лист разговора.
  final VoidCallback onOpen;

  /// Сколько затихший разговор ещё держит значок.
  static const quiet = Duration(seconds: 3);

  @override
  ConsumerState<JarvisBadge> createState() => _JarvisBadgeState();
}

class _JarvisBadgeState extends ConsumerState<JarvisBadge>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  Timer? _leave;

  @override
  void initState() {
    super.initState();
    _follow();
  }

  @override
  void dispose() {
    _leave?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(jarvisTalkProvider, (_, __) => _follow());
    ref.listen(jarvisControllerProvider.select((state) => state.busy),
        (_, __) => _follow());
    final talk = ref.watch(jarvisTalkProvider);
    final conversation = ref.watch(jarvisControllerProvider);
    final last = conversation.messages.lastOrNull;
    final answer = last != null && last.fromJarvis ? last : null;
    final caption =
        talk.listening && talk.heard.isNotEmpty ? talk.heard : answer?.text;
    final undoable = answer != null && conversation.undoMessageId == answer.id;
    return Positioned(
      left: 48,
      right: 12,
      bottom: AppNavBar.heightOf(context) +
          MediaQuery.viewPaddingOf(context).bottom +
          12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (caption != null && caption.isNotEmpty) ...[
            JarvisBadgeCaption(
              text: caption,
              onUndo: undoable ? _undo : null,
            ),
            const SizedBox(height: 8),
          ],
          JarvisBadgeOrb(
            listening: talk.listening,
            thinking: conversation.busy,
            speaking: talk.speaking,
            pulse: _pulse,
            onTap: widget.onOpen,
          ),
        ],
      ),
    );
  }

  /// Идёт разговор — значок на месте и дышит; затих — уходит через
  /// [JarvisBadge.quiet].
  void _follow() {
    final active = ref.read(jarvisTalkProvider).busy ||
        ref.read(jarvisControllerProvider).busy;
    if (active) {
      _leave?.cancel();
      _leave = null;
      if (!_pulse.isAnimating) _pulse.repeat();
      return;
    }
    _pulse.stop();
    _leave ??= Timer(JarvisBadge.quiet, () {
      if (!mounted) return;
      final presence = ref.read(jarvisPresenceProvider.notifier);
      if (presence.state == JarvisPresence.badge) {
        presence.state = JarvisPresence.away;
      }
    });
  }

  void _undo() => unawaited(ref.read(jarvisControllerProvider.notifier).undo());
}
