import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

class FinanceCategoryField extends StatelessWidget {
  const FinanceCategoryField({
    required this.initialValue,
    required this.categories,
    required this.onChanged,
    super.key,
  });

  final String initialValue;
  final List<String> categories;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => Autocomplete<String>(
        initialValue: TextEditingValue(text: initialValue),
        optionsBuilder: (value) {
          final query = value.text.trim().toLowerCase();
          if (query.isEmpty) return categories;
          return categories.where(
            (item) => item.toLowerCase().contains(query),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          final values = options.toList(growable: false);
          final scheme = Theme.of(context).colorScheme;
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              key: const ValueKey('finance_category_options'),
              color: scheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: scheme.outline),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: constraints.maxWidth,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: values.length,
                    itemBuilder: (context, index) {
                      final value = values[index];
                      return InkWell(
                        onTap: () => onSelected(value),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              value,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: scheme.onSurface),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
        onSelected: onChanged,
        fieldViewBuilder: (context, controller, focusNode, onSubmit) {
          return TextFormField(
            key: const ValueKey('finance_category'),
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(labelText: strings.category),
            onChanged: onChanged,
            validator: (value) =>
                value == null || value.trim().isEmpty ? strings.category : null,
          );
        },
      ),
    );
  }
}
