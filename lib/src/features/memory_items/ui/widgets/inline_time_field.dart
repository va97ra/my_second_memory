import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Время записи прямо в листе: часы и минуты двумя полями.
///
/// Раньше время выбирали в отдельном диалоге поверх листа — два окна одно на
/// другом ради одного значения. Здесь оно правится на месте.
class InlineTimeField extends StatefulWidget {
  const InlineTimeField({
    super.key,
    required this.minutes,
    required this.onChanged,
    required this.onClear,
  });

  /// Время от полуночи, или null, когда его нет.
  final int? minutes;

  final ValueChanged<int> onChanged;

  /// Null, когда убирать нечего.
  final VoidCallback? onClear;

  @override
  State<InlineTimeField> createState() => _InlineTimeFieldState();
}

class _InlineTimeFieldState extends State<InlineTimeField> {
  late final TextEditingController _hours;
  late final TextEditingController _minutes;

  @override
  void initState() {
    super.initState();
    final value = widget.minutes;
    _hours = TextEditingController(text: _two(value == null ? null : value ~/ 60));
    _minutes = TextEditingController(text: _two(value == null ? null : value % 60));
  }

  @override
  void didUpdateWidget(InlineTimeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Время сняли крестиком — поля пустеют вслед за ним.
    if (widget.minutes == null && oldWidget.minutes != null) {
      _hours.clear();
      _minutes.clear();
    }
  }

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  static String _two(int? value) =>
      value == null ? '' : value.toString().padLeft(2, '0');

  /// Пока введено не всё, время не меняется: половина значения — не время.
  void _report() {
    final hours = int.tryParse(_hours.text);
    final minutes = int.tryParse(_minutes.text);
    if (hours == null || minutes == null) return;
    widget.onChanged(hours.clamp(0, 23) * 60 + minutes.clamp(0, 59));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded, color: Color(0xFF218CFF)),
            const SizedBox(width: 10),
            Expanded(child: Text(strings.time)),
            _box(_hours, 23),
            Text(
              ':',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            _box(_minutes, 59),
            if (widget.onClear != null)
              IconButton(
                tooltip: strings.delete,
                onPressed: widget.onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _box(TextEditingController controller, int limit) {
    return SizedBox(
      width: 44,
      child: TextField(
        key: ValueKey('inline_time_${limit == 23 ? 'hours' : 'minutes'}'),
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 2,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
        onChanged: (_) => _report(),
      ),
    );
  }
}
