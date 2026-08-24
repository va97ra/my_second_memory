import 'package:flutter/material.dart';
import 'service_avatar.dart';
import 'account_info_line.dart';
import 'package:flutter/services.dart';
import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';

/// Карточка аккаунта со скрытым паролем и действиями.
class AccountCard extends StatefulWidget {
  const AccountCard({super.key, 
    required this.account,
    required this.onEdit,
    required this.onDelete,
  });

  final AccountItem account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final account = widget.account;
    final passwordText =
        _showPassword ? account.password : '•' * account.password.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          boxShadow: notebookSurfaceShadow(
            context,
            NotebookSurfaceDepth.card,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ServiceAvatar(name: account.serviceName),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      account.serviceName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: strings.editAccount,
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_rounded),
                  ),
                  IconButton(
                    tooltip: strings.delete,
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_rounded),
                  ),
                ],
              ),
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
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          passwordText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: strings.password,
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                      ),
                      IconButton(
                        tooltip: strings.copyPassword,
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: account.password),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(strings.passwordCopied)),
                            );
                          }
                        },
                        icon: const Icon(Icons.content_copy_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              if (account.website.isNotEmpty)
                AccountInfoLine(
                  icon: Icons.language_rounded,
                  text: account.website,
                ),
              if (account.note.isNotEmpty) ...[
                const SizedBox(height: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        account.note,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
