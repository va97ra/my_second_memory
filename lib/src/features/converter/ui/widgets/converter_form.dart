import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';
import 'converter_helpers.dart';
import 'saved_conversions.dart';

class ConverterForm extends ConsumerStatefulWidget {
  const ConverterForm({super.key});

  @override
  ConsumerState<ConverterForm> createState() => _ConverterFormState();
}

class _ConverterFormState extends ConsumerState<ConverterForm> {
  final _value = TextEditingController(text: '1');
  UnitCategory _category = UnitCategory.length;
  String _from = 'm';
  String _to = 'cm';

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final units = UnitConverter.units[_category]!;
    final input = parseToolNumber(_value.text);
    final output = input == null
        ? null
        : UnitConverter.convert(
            category: _category,
            fromUnitId: _from,
            toUnitId: _to,
            value: input,
          );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        DropdownButtonFormField<UnitCategory>(
          key: ValueKey(_category),
          initialValue: _category,
          isExpanded: true,
          decoration: InputDecoration(labelText: strings.category),
          items: [
            for (final category in UnitCategory.values)
              DropdownMenuItem(
                value: category,
                child: Text(categoryLabel(category, strings)),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            final nextUnits = UnitConverter.units[value]!;
            setState(() {
              _category = value;
              _from = nextUnits.first.id;
              _to = nextUnits.length > 1 ? nextUnits[1].id : nextUnits.first.id;
            });
          },
        ),
        const SizedBox(height: 12),
        ToolNumberField(
          controller: _value,
          label: strings.value,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final vertical = constraints.maxWidth < 420;
          final from =
              _unitSelector(strings.from, _from, units, (v) => _from = v);
          final swap = IconButton(
            tooltip: '${strings.from} / ${strings.to}',
            onPressed: () => setState(() {
              final previous = _from;
              _from = _to;
              _to = previous;
            }),
            icon: Icon(
                vertical ? Icons.swap_vert_rounded : Icons.swap_horiz_rounded),
          );
          final to = _unitSelector(strings.to, _to, units, (v) => _to = v);
          return vertical
              ? Column(children: [from, swap, to])
              : Row(
                  children: [Expanded(child: from), swap, Expanded(child: to)]);
        }),
        const SizedBox(height: 16),
        ToolResultCard(
          value: output == null
              ? strings.invalidNumber
              : '${formatToolNumber(output)} ${units.firstWhere((u) => u.id == _to).symbol}',
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: output == null
              ? null
              : () => saveConversion(
                    context,
                    ref,
                    category: _category,
                    from: _from,
                    to: _to,
                    value: input!,
                  ),
          icon: const Icon(Icons.bookmark_add_outlined),
          label: Text(strings.saveCalculation),
        ),
        const SizedBox(height: 20),
        SavedConversions(onLoad: _load),
      ],
    );
  }

  Widget _unitSelector(
    String label,
    String value,
    List<UnitDefinition> units,
    ValueChanged<String> assign,
  ) =>
      DropdownButtonFormField<String>(
        key: ValueKey('${_category.name}-$label-$value'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final unit in units)
            DropdownMenuItem(value: unit.id, child: Text(unit.symbol)),
        ],
        onChanged: (next) {
          if (next != null) setState(() => assign(next));
        },
      );

  void _load(SavedConversionPayload payload) => setState(() {
        _category = UnitCategory.values.byName(payload.category);
        _from = payload.fromUnit;
        _to = payload.toUnit;
        _value.text = formatToolNumber(payload.value);
      });
}
