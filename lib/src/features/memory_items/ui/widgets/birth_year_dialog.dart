import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

/// Спрашивает год рождения. Возвращает null, если год не назвали или назвали
/// невозможный.
Future<int?> askBirthYear(BuildContext context, {required int? initial}) {
  return showDialog<int>(
    context: context,
    builder: (context) => BirthYearDialog(initial: initial),
  );
}

/// Ввод года рождения.
class BirthYearDialog extends StatefulWidget {
  const BirthYearDialog({super.key, required this.initial});

  final int? initial;

  @override
  State<BirthYearDialog> createState() => _BirthYearDialogState();
}

class _BirthYearDialogState extends State<BirthYearDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial?.toString() ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';

    return AlertDialog(
      title: Text(ru ? 'Год рождения' : 'Birth year'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        maxLength: 4,
        decoration: const InputDecoration(hintText: '1985'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.of(context).cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_year()),
          child: const Text('OK'),
        ),
      ],
    );
  }

  /// Год, которого не бывает, — это отказ от ответа, а не ошибка ввода.
  int? _year() {
    final year = int.tryParse(_controller.text);
    if (year == null || year < 1900 || year > DateTime.now().year) return null;
    return year;
  }
}
