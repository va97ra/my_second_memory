import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'account_field_icons.dart';
import 'account_text_field.dart';

/// Поля аккаунта: сервис, вход, почта, пароль, сайт и заметка.
class AccountEditorFields extends StatelessWidget {
  const AccountEditorFields({
    super.key,
    required this.service,
    required this.login,
    required this.email,
    required this.password,
    required this.website,
    required this.note,
    required this.showPassword,
    required this.onTogglePassword,
  });

  final TextEditingController service;
  final TextEditingController login;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController website;
  final TextEditingController note;
  final bool showPassword;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      children: [
        AccountTextField(
          controller: service,
          label: strings.serviceName,
          icon: AccountFieldIcons.service,
          textInputAction: TextInputAction.next,
        ),
        AccountTextField(
          controller: login,
          label: strings.login,
          icon: AccountFieldIcons.login,
          textInputAction: TextInputAction.next,
        ),
        AccountTextField(
          controller: email,
          label: strings.email,
          icon: AccountFieldIcons.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        AccountTextField(
          controller: password,
          label: strings.password,
          icon: AccountFieldIcons.password,
          obscureText: !showPassword,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            tooltip: strings.password,
            onPressed: onTogglePassword,
            icon: Icon(
              showPassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
            ),
          ),
        ),
        AccountTextField(
          controller: website,
          label: strings.website,
          icon: AccountFieldIcons.website,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
        ),
        AccountTextField(
          controller: note,
          label: strings.note,
          icon: AccountFieldIcons.note,
          minLines: 4,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
        ),
      ],
    );
  }
}
