import 'dart:async';

import 'package:ez_core/ez_core.dart';
import 'package:ez_data/ez_data.dart' show GigaChatClient, GigaChatException;
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
    final valid = GigaChatClient.looksLikeAuthKey(_key.text);
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
            // Сохранённый ключ не показывается и не правится: поле есть,
            // только пока ключа нет. Так его не затереть случайно — сменить
            // можно, лишь удалив.
            if (saved) ...[
              Text(strings.jarvisBrainSaved, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                key: const ValueKey('gigachat_check'),
                onPressed: _checking ? null : _check,
                child: Text(strings.jarvisBrainCheck),
              ),
              TextButton(
                key: const ValueKey('gigachat_remove'),
                onPressed: _checking ? null : _remove,
                child: Text(strings.jarvisBrainRemove),
              ),
            ] else ...[
              Text(strings.jarvisBrainHowTo),
              const SizedBox(height: 12),
              GigaChatKeyField(controller: _key, invalid: typed && !valid),
              const SizedBox(height: 12),
              FilledButton(
                key: const ValueKey('gigachat_save'),
                onPressed: valid && !_checking ? _save : null,
                child: Text(strings.jarvisBrainSave),
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

  /// Ключ сохраняется и сразу проверяется. Остаётся он, только если Сбер
  /// его принял (решение владельца 8 октября 2026): не принял или связи нет
  /// — ключ не хранится, поле остаётся с причиной.
  Future<void> _save() async {
    await ref.read(gigaChatKeyProvider.notifier).save(_key.text);
    final failure = await _check();
    if (failure != null) {
      await ref.read(gigaChatKeyProvider.notifier).remove();
      return;
    }
    _key.clear();
  }

  /// Проверка связи; возвращает отказ, если он был.
  Future<GigaChatException?> _check() async {
    final client = ref.read(gigaChatClientProvider);
    if (client == null) return null;
    final works = AppStrings.of(context).jarvisBrainWorks;
    setState(() {
      _checking = true;
      _result = null;
    });
    GigaChatException? failure;
    try {
      await client.check();
    } on GigaChatException catch (error) {
      failure = error;
    }
    if (mounted) {
      setState(() {
        _checking = false;
        _result = failure?.message ?? works;
      });
    }
    return failure;
  }

  Future<void> _remove() async {
    await ref.read(gigaChatKeyProvider.notifier).remove();
    if (mounted) setState(() => _result = null);
  }
}
