import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/foundation.dart';

/// Кто сказал реплику.
enum JarvisAuthor { person, jarvis }

/// Одна реплика разговора.
@immutable
class JarvisMessage {
  const JarvisMessage({
    required this.id,
    required this.author,
    required this.text,
    this.link,
  });

  final int id;
  final JarvisAuthor author;
  final String text;

  /// Страница, которую ответ предлагает открыть кнопкой.
  final OpenPlace? link;

  bool get fromJarvis => author == JarvisAuthor.jarvis;
}

/// Разговор с Джарвисом.
@immutable
class JarvisConversation {
  const JarvisConversation({
    this.messages = const [],
    this.busy = false,
    this.asking,
    this.undoMessageId,
    this.navigation,
  });

  /// Реплики по порядку, последняя — внизу.
  final List<JarvisMessage> messages;

  /// Джарвис выполняет команду: второй раз просить нельзя.
  final bool busy;

  /// Дело, по которому Джарвис ждёт ответа: день или время.
  final ParsedTask? asking;

  /// Реплика, под которой стоит «Отменить». Отменить можно только последнее
  /// действие — так человек не отменит вслепую то, чего уже не видит.
  final int? undoMessageId;

  /// Страница, которую нужно открыть прямо сейчас. Её забирает экран и
  /// сразу сообщает, что забрал.
  final JarvisNavigation? navigation;

  JarvisConversation copyWith({
    List<JarvisMessage>? messages,
    bool? busy,
    ParsedTask? asking,
    bool clearAsking = false,
    int? undoMessageId,
    bool clearUndo = false,
    JarvisNavigation? navigation,
    bool clearNavigation = false,
  }) {
    return JarvisConversation(
      messages: messages ?? this.messages,
      busy: busy ?? this.busy,
      asking: clearAsking ? null : asking ?? this.asking,
      undoMessageId: clearUndo ? null : undoMessageId ?? this.undoMessageId,
      navigation: clearNavigation ? null : navigation ?? this.navigation,
    );
  }
}

/// Просьба открыть страницу. Каждая — новый объект: та же страница,
/// запрошенная дважды, открывается дважды.
class JarvisNavigation {
  JarvisNavigation(this.target);

  final OpenPlace target;
}
