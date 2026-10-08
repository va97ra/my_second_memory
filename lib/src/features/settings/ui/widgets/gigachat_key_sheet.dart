import 'dart:async';

import 'package:ez_core/ez_core.dart';
import 'package:ez_data/ez_data.dart' show GigaChatException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../jarvis/jarvis.dart';
import 'gigachat_key_field.dart';

Future<void> showGigaChatKeySheet(BuildContext context) {
  // Лист собирается один раз: пока едет клавиатура, обёртку модального
  // листа Flutter пересобирает на каждом кадре.
  const sheet = GigaChatKeySheet();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => sheet,
  );
}

/// Ключ GigaChat: вставить, проверить, удалить.
///
/// Ключ — секрет владельца: поле его не показывает, а хранится он только на
/// этом устройстве. Проверка связи отвечает строкой под кнопками — это
/// ответ на нажатие, а не предупреждение.
class GigaChatKeySheet extends ConsumerStatefulWidget {
  const GigaChatKeySheet({super.key});

  @override
  ConsumerState<GigaChatKeySheet> createState() => _GigaChatKeySheetState();
}

class _GigaChatKeySheetState extends ConsumerState<GigaChatKeySheet> {
  final _key = TextEditingController();
  String? _result;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _key.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final saved = ref.watch(gigaChatKeyProvider).valueOrNull != null;
    final typed = _key.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.jarvisBrain,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(strings.jarvisBrainHowTo),
            const SizedBox(height: 12),
            GigaChatKeyField(controller: _key),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('gigachat_save'),
              onPressed: typed ? _save : null,
              child: Text(strings.jarvisBrainSave),
            ),
            if (saved) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                key: const ValueKey('gigachat_check'),
                onPressed: _checking ? null : _check,
                child: Text(strings.jarvisBrainCheck),
              ),
              TextButton(
                key: const ValueKey('gigachat_remove'),
                onPressed: _remove,
                child: Text(strings.jarvisBrainRemove),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 8),
              Text(_result!,
                  key: const ValueKey('gigachat_result'),
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await ref.read(gigaChatKeyProvider.notifier).save(_key.text);
    _key.clear();
    await _check();
  }

  Future<void> _check() async {
    final client = ref.read(gigaChatClientProvider);
    if (client == null) return;
    final works = AppStrings.of(context).jarvisBrainWorks;
    setState(() {
      _checking = true;
      _result = null;
    });
    String result;
    try {
      await client.check();
      result = works;
    } on GigaChatException catch (failure) {
      result = failure.message;
    }
    if (!mounted) return;
    setState(() {
      _checking = false;
      _result = result;
    });
  }

  Future<void> _remove() async {
    await ref.read(gigaChatKeyProvider.notifier).remove();
    if (mounted) setState(() => _result = null);
  }
}
