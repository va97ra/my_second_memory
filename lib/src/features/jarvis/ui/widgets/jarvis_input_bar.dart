import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

/// Строка ввода: написать Джарвису или нажать микрофон.
///
/// Справа одна кнопка, а не две: пока поле пустое — микрофон, как только в
/// нём есть текст — «отправить». Так большая кнопка всегда делает то, чего
/// сейчас ждут, и не теснит поле на узком экране.
class JarvisInputBar extends StatefulWidget {
  const JarvisInputBar({
    required this.onSend,
    required this.listening,
    this.onListen,
    this.onStopListening,
    this.enabled = true,
    super.key,
  });

  final ValueChanged<String> onSend;
  final bool listening;

  /// Null — слушать нечем (веб): микрофона нет совсем.
  final VoidCallback? onListen;
  final VoidCallback? onStopListening;
  final bool enabled;

  @override
  State<JarvisInputBar> createState() => _JarvisInputBarState();
}

class _JarvisInputBarState extends State<JarvisInputBar> {
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    final said = _text.text.trim();
    if (said.isEmpty || !widget.enabled) return;
    _text.clear();
    widget.onSend(said);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final typing = _text.text.trim().isNotEmpty;
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('jarvis_input'),
            controller: _text,
            enabled: widget.enabled,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: widget.listening
                  ? strings.jarvisListening
                  : strings.jarvisInputHint,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (typing || widget.onListen == null)
          IconButton.filled(
            key: const ValueKey('jarvis_send'),
            tooltip: strings.jarvisSend,
            iconSize: 28,
            onPressed: typing && widget.enabled ? _send : null,
            icon: const Icon(Icons.send_rounded),
          )
        else
          IconButton.filled(
            key: const ValueKey('jarvis_mic'),
            tooltip: widget.listening
                ? strings.jarvisStopListening
                : strings.jarvisListen,
            iconSize: 28,
            onPressed: widget.listening
                ? widget.onStopListening
                : (widget.enabled ? widget.onListen : null),
            icon: Icon(
              widget.listening ? Icons.stop_rounded : Icons.mic_rounded,
            ),
          ),
      ],
    );
  }
}
