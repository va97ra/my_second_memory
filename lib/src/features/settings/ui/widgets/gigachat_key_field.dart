import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Поле ключа GigaChat. Ключ длинный и набирать его руками никто не будет,
/// поэтому справа — «Вставить» из буфера. Сам ключ не показывается: это
/// секрет владельца.
class GigaChatKeyField extends StatelessWidget {
  const GigaChatKeyField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return TextField(
      key: const ValueKey('gigachat_key'),
      controller: controller,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: strings.jarvisBrainKey,
        suffixIcon: IconButton(
          tooltip: strings.jarvisBrainPaste,
          icon: const Icon(Icons.content_paste_rounded),
          onPressed: _paste,
        ),
      ),
    );
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) controller.text = text;
  }
}
