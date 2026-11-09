import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'account_field_icons.dart';
import 'account_info_line.dart';
import 'account_row_button.dart';

/// Пароль на карточке аккаунта: скрыт точками, показывается по кнопке.
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

    return AccountInfoLine(
      icon: AccountFieldIcons.password,
      text: _visible ? widget.password : '•' * widget.password.length,
      action: AccountRowButton(
        icon:
            _visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        tooltip: strings.password,
        onPressed: () => setState(() => _visible = !_visible),
      ),
    );
  }
}
