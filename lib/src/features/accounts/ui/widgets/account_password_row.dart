import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Пароль аккаунта: скрыт точками, показывается по кнопке и копируется.
///
/// Точек ровно столько, сколько знаков в пароле: по ним видно, что пароль
/// сохранён и какой он длины.
class AccountPasswordRow extends StatefulWidget {
  const AccountPasswordRow({super.key, required this.password});

  final String password;

  @override
  State<AccountPasswordRow> createState() => _AccountPasswordRowState();
}

class _AccountPasswordRowState extends State<AccountPasswordRow> {
  bool _visible = false;

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
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          children: [
            Icon(Icons.lock_rounded, size: 18, color: colors.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _visible ? widget.password : '•' * widget.password.length,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: strings.password,
              onPressed: () => setState(() => _visible = !_visible),
              icon: Icon(
                _visible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
            IconButton(
              tooltip: strings.copyPassword,
              onPressed: _copy,
              icon: const Icon(Icons.content_copy_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.password));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).passwordCopied)),
    );
  }
}
