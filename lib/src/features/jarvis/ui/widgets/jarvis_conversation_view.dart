import 'package:flutter/material.dart';

import '../../state/jarvis_message.dart';
import 'jarvis_message_bubble.dart';

/// Разговор снизу вверх: новая реплика всегда у строки ввода, а прокрутка
/// уводит в прошлое. Список ленивый — длинный разговор не строится целиком.
class JarvisConversationView extends StatelessWidget {
  const JarvisConversationView({
    required this.conversation,
    required this.onUndo,
    required this.onShow,
    super.key,
  });

  final JarvisConversation conversation;
  final VoidCallback onUndo;
  final ValueChanged<JarvisMessage> onShow;

  @override
  Widget build(BuildContext context) {
    final messages = conversation.messages;
    return ListView.separated(
      key: const ValueKey('jarvis_conversation'),
      reverse: true,
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return JarvisMessageBubble(
          key: ValueKey('jarvis_message_${message.id}'),
          message: message,
          undoable: message.id == conversation.undoMessageId,
          onUndo: onUndo,
          onShow: () => onShow(message),
        );
      },
    );
  }
}
