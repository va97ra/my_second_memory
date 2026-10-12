import 'dart:async';

import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/jarvis_controller.dart';
import '../state/jarvis_message.dart';
import '../state/jarvis_presence.dart';
import '../state/jarvis_talk_controller.dart';
import 'widgets/jarvis_answer_chips.dart';
import 'widgets/jarvis_conversation_view.dart';
import 'widgets/jarvis_empty_view.dart';
import 'widgets/jarvis_heard_line.dart';
import 'widgets/jarvis_input_bar.dart';
import 'widgets/jarvis_limit_bar.dart';
import 'widgets/jarvis_sheet_header.dart';

/// Открывает лист разговора с Джарвисом поверх страницы, на которой
/// человек сейчас; [host] — контекст навигатора.
Future<void> showJarvisSheet(BuildContext host) {
  // Лист собирается один раз: пока едет клавиатура, Flutter пересобирает
  // обёртку модального листа на каждом кадре.
  const sheet = JarvisSheet();
  // Где Джарвис, отмечается здесь и снимается, когда лист закрылся, — не в
  // жизненном цикле виджета, где менять состояние нельзя. Свернулся лист в
  // значок — Джарвис остаётся на странице.
  final presence = ProviderScope.containerOf(host, listen: false)
      .read(jarvisPresenceProvider.notifier);
  presence.state = JarvisPresence.sheet;
  return showModalBottomSheet<void>(
    context: host,
    isScrollControlled: true,
    builder: (_) => sheet,
  ).whenComplete(() {
    if (presence.state == JarvisPresence.sheet) {
      presence.state = JarvisPresence.away;
    }
  });
}

/// Панель Джарвиса: разговор, что слышно сейчас, готовые ответы и ввод.
/// Открывшись, сразу слушает — нажимать микрофон второй раз не нужно. На
/// имя и на просьбу открыть страницу отвечает хост Джарвиса в оболочке.
class JarvisSheet extends ConsumerStatefulWidget {
  const JarvisSheet({super.key});

  @override
  ConsumerState<JarvisSheet> createState() => _JarvisSheetState();
}

class _JarvisSheetState extends ConsumerState<JarvisSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final talk = ref.read(jarvisTalkProvider.notifier);
      // Раскрыли значок посреди разговора — не перебивать его.
      if (talk.canListen && !ref.read(jarvisTalkProvider).busy) {
        unawaited(talk.listen());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(jarvisControllerProvider);
    final talk = ref.watch(jarvisTalkProvider);
    final talkController = ref.read(jarvisTalkProvider.notifier);
    final asking = conversation.askingNeed;
    return KeyboardInsetPadding(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              JarvisSheetHeader(
                onClear: conversation.messages.isEmpty ? null : _clear,
              ),
              const JarvisLimitBar(),
              Flexible(
                child: conversation.messages.isEmpty
                    ? const SingleChildScrollView(child: JarvisEmptyView())
                    : JarvisConversationView(
                        conversation: conversation,
                        onUndo: _undo,
                        onShow: _show,
                      ),
              ),
              if (talk.listening || talk.problem != null)
                JarvisHeardLine(talk: talk),
              if (asking != null) ...[
                JarvisAnswerChips(need: asking, onAnswer: _send),
                const SizedBox(height: 8),
              ],
              JarvisInputBar(
                listening: talk.listening,
                enabled: !conversation.busy,
                onSend: _send,
                onListen: talkController.canListen
                    ? () => unawaited(talkController.listen())
                    : null,
                onStopListening: () => unawaited(talkController.stop()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _send(String text) {
    ref.read(jarvisTalkProvider.notifier).forgetProblem();
    unawaited(ref.read(jarvisControllerProvider.notifier).send(text));
  }

  /// Необратимое — с подтверждением (`docs/layout.md`).
  Future<void> _clear() async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text(strings.jarvisClearQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            key: const ValueKey('jarvis_clear_confirm'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(strings.jarvisClearConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(jarvisControllerProvider.notifier).clear();
    }
  }

  void _undo() => unawaited(ref.read(jarvisControllerProvider.notifier).undo());

  void _show(JarvisMessage message) {
    final link = message.link;
    if (link != null) ref.read(jarvisControllerProvider.notifier).show(link);
  }
}
