import 'dart:async';

import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../navigation/jarvis_locations.dart';
import '../state/jarvis_controller.dart';
import '../state/jarvis_message.dart';
import '../state/jarvis_talk_controller.dart';
import '../state/jarvis_wake_controller.dart';
import 'widgets/jarvis_answer_chips.dart';
import 'widgets/jarvis_conversation_view.dart';
import 'widgets/jarvis_empty_view.dart';
import 'widgets/jarvis_heard_line.dart';
import 'widgets/jarvis_input_bar.dart';
import 'widgets/jarvis_sheet_header.dart';

/// Открывает Джарвиса поверх страницы, на которой человек сейчас.
///
/// [host] — контекст навигатора: им же открываются страницы, о которых
/// попросили, когда сам лист уже закрыт. [call] — с чем позвали голосом:
/// тогда лист не слушает заново, а сразу отвечает.
Future<void> showJarvisSheet(BuildContext host, {String? call}) {
  // Лист собирается один раз: пока едет клавиатура, Flutter пересобирает
  // обёртку модального листа на каждом кадре.
  final sheet = JarvisSheet(host: host, call: call);
  // Отметка «лист открыт» ставится здесь и снимается, когда лист закрылся,
  // — не в жизненном цикле виджета, где менять состояние нельзя.
  final open = ProviderScope.containerOf(host, listen: false)
      .read(jarvisSheetOpenProvider.notifier);
  open.state = true;
  return showModalBottomSheet<void>(
    context: host,
    isScrollControlled: true,
    builder: (_) => sheet,
  ).whenComplete(() => open.state = false);
}

/// Панель Джарвиса: разговор, что слышно сейчас, готовые ответы и ввод.
/// Открывшись, сразу слушает — нажимать микрофон второй раз не нужно.
class JarvisSheet extends ConsumerStatefulWidget {
  const JarvisSheet({required this.host, this.call, super.key});

  final BuildContext host;

  /// Что сказали после имени, если лист открыт голосом.
  final String? call;

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
      final call = widget.call;
      if (call != null) {
        unawaited(talk.respond(call));
      } else if (talk.canListen) {
        unawaited(talk.listen());
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    // Открытый лист сам отвечает, когда Джарвиса зовут снова.
    ref.listen(jarvisWakeProvider, (_, call) {
      if (call != null) {
        unawaited(ref.read(jarvisTalkProvider.notifier).respond(call.command));
      }
    });
    ref.listen(
      jarvisControllerProvider.select((state) => state.navigation),
      (_, navigation) {
        if (navigation != null) _open(navigation.target);
      },
    );
    final conversation = ref.watch(jarvisControllerProvider);
    final talk = ref.watch(jarvisTalkProvider);
    final talkController = ref.read(jarvisTalkProvider.notifier);
    final asking = conversation.asking;
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
              Flexible(
                child: conversation.messages.isEmpty
                    ? SingleChildScrollView(
                        child: JarvisEmptyView(onExample: _send),
                      )
                    : JarvisConversationView(
                        conversation: conversation,
                        onUndo: _undo,
                        onShow: _show,
                      ),
              ),
              if (talk.listening || talk.problem != null)
                JarvisHeardLine(talk: talk),
              if (asking != null) ...[
                JarvisAnswerChips(asking: asking, onAnswer: _send),
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

  /// Лист закрывается, страница открывается тем же переворотом, что и с
  /// кнопок. Открывает её навигатор под листом — лист к этому моменту уже
  /// снят.
  void _open(OpenPlace target) {
    ref.read(jarvisControllerProvider.notifier).navigationHandled();
    Navigator.of(context).pop();
    unawaited(openJarvisPlace(widget.host, target));
  }
}
