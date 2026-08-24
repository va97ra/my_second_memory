import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'account_info_line.dart';
import 'account_note_box.dart';
import 'account_password_row.dart';
import 'service_avatar.dart';

/// Карточка аккаунта: сервис, входы, скрытый пароль и заметка.
class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.account,
    required this.onEdit,
    required this.onDelete,
  });

  final AccountItem account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
          boxShadow: notebookSurfaceShadow(context, NotebookSurfaceDepth.card),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              // Пустое поле не занимает строку: у аккаунта их шесть, и
              // заполняют обычно два-три.
              if (account.login.isNotEmpty)
                AccountInfoLine(
                  icon: Icons.person_rounded,
                  text: account.login,
                ),
              if (account.email.isNotEmpty)
                AccountInfoLine(
                  icon: Icons.alternate_email_rounded,
                  text: account.email,
                ),
              const SizedBox(height: 8),
              AccountPasswordRow(password: account.password),
              if (account.website.isNotEmpty)
                AccountInfoLine(
                  icon: Icons.language_rounded,
                  text: account.website,
                ),
              if (account.note.isNotEmpty) ...[
                const SizedBox(height: 10),
                AccountNoteBox(text: account.note),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final strings = AppStrings.of(context);

    return Row(
      children: [
        ServiceAvatar(name: account.serviceName),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            account.serviceName,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          tooltip: strings.editAccount,
          onPressed: onEdit,
          icon: const Icon(Icons.edit_rounded),
        ),
        IconButton(
          tooltip: strings.delete,
          onPressed: onDelete,
          icon: const Icon(Icons.delete_rounded),
        ),
      ],
    );
  }
}
