import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/converter_controller.dart';
import 'converter_helpers.dart';
import 'converter_inputs.dart';
import 'saved_conversions.dart';

class ConverterForm extends ConsumerStatefulWidget {
  const ConverterForm({super.key});

  @override
  ConsumerState<ConverterForm> createState() => _ConverterFormState();
}

class _ConverterFormState extends ConsumerState<ConverterForm> {
  final _left = TextEditingController();
  final _right = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sync(ref.read(converterControllerProvider));
  }

  @override
  void dispose() {
    _left.dispose();
    _right.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(converterControllerProvider, (_, next) => _sync(next));
    final state = ref.watch(converterControllerProvider);
    final controller = ref.read(converterControllerProvider.notifier);
    final strings = AppStrings.of(context);
    return KeyboardInsetPadding(
      child: ListView(
        key: const ValueKey('converter_scroll'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ConverterInputs(
            state: state,
            left: _left,
            right: _right,
            onCategory: controller.setCategory,
            onUnit: controller.setUnit,
            onSwap: controller.swap,
            onValue: controller.setValue,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const ValueKey('converter_save'),
            onPressed: state.typed == null
                ? null
                : () => saveConversion(context, ref, state),
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(strings.saveCalculation),
          ),
          const SizedBox(height: 16),
          SavedConversions(onLoad: controller.load),
        ],
      ),
    );
  }

  /// Поле, в которое набирают, показывает набранное слово в слово; второе —
  /// пересчитанное число. Кто из них какой, решает состояние, поэтому здесь
  /// только сверка текста: совпал — не трогаем, и курсор остаётся на месте.
  void _sync(ConverterState state) {
    _write(_left, _textOf(state, ConverterSide.left));
    _write(_right, _textOf(state, ConverterSide.right));
  }

  String _textOf(ConverterState state, ConverterSide side) =>
      side == state.entry ? state.raw : state.reading(side)?.number ?? '';

  void _write(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
