import 'dart:async';

import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../navigation/jarvis_locations.dart';
import '../state/jarvis_controller.dart';
import '../state/jarvis_message.dart';
import '../state/jarvis_talk_controller.dart';
import 'widgets/jarvis_answer_chips.dart';
import 'widgets/jarvis_conversation_view.dart';
import 'widgets/jarvis_empty_view.dart';
import 'widgets/jarvis_heard_line.dart';
import 'widgets/jarvis_input_bar.dart';
import 'widgets/jarvis_sheet_header.dart';

/// Открывает Джарвиса поверх страницы, на которой человек сейчас.
///
/// [host] — контекст навигатора: им же открываются страницы, о которых
/// попросили, когда сам лист уже закрыт.
Future<void> showJarvisSheet(BuildContext host) {
  // Лист собирается один раз: пока едет клавиатура, Flutter пересобирает
  // обёртку модального листа на каждом кадре.
  final sheet = JarvisSheet(host: host);
  return showModalBottomSheet<void>(
    context: host,
    isScrollControlled: true,
    builder: (_) => sheet,
  );
}

/// Панель Джарвиса: разговор, что слышно сейчас, готовые ответы и ввод.
/// Открывшись, сразу слушает — нажимать микрофон второй раз не нужно.
class JarvisSheet extends ConsumerStatefulWidget {
  const JarvisSheet({required this.host, super.key});

  final BuildContext host;

  @override
  ConsumerState<JarvisSheet> createState() => _JarvisSheetState();
}

class _JarvisSheetState extends ConsumerState<JarvisSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final talk = ref.read(jarvisTalkProvider.notifier);
      if (mounted && talk.canListen) unawaited(talk.listen());
    });
  }

  @override
  Widget build(BuildContext context) {
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
              const JarvisSheetHeader(),
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

  void _send(String text) =>
      unawaited(ref.read(jarvisControllerProvider.notifier).send(text));

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
