import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/notebook/notebook_background.dart';
import '../../../shared/ui/empty_state.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../domain/account_item.dart';
import '../state/accounts_controller.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final accounts = ref.watch(accountsControllerProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAccountEditor(context, ref),
        icon: const Icon(Icons.add),
        label: Text(strings.addAccount),
      ),
      body: WarmGradientBackground(
        child: CustomScrollView(
          slivers: [
            MainSliverAppBar(title: strings.accounts, backLocation: '/'),
            if (accounts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: AppEmptyState(
                    icon: Icons.key_outlined,
                    title: strings.noAccounts,
                    actionLabel: strings.addAccount,
                    onAction: () => _showAccountEditor(context, ref),
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  return _AccountCard(
                    account: account,
                    onEdit: () => _showAccountEditor(context, ref, account),
                    onDelete: () => ref
                        .read(accountsControllerProvider.notifier)
                        .delete(account.id),
                  );
                },
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 92)),
          ],
        ),
      ),
    );
  }

  Future<void> _showAccountEditor(
    BuildContext context,
    WidgetRef ref, [
    AccountItem? account,
  ]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _AccountEditor(account: account, ref: ref),
    );
  }
}

class _AccountCard extends StatefulWidget {
  const _AccountCard({
    required this.account,
    required this.onEdit,
    required this.onDelete,
  });

  final AccountItem account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard> {
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
                  _ServiceAvatar(name: account.serviceName),
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
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: strings.delete,
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              if (account.login.isNotEmpty)
                _AccountInfoLine(
                  icon: Icons.person_outline,
                  text: account.login,
                ),
              if (account.email.isNotEmpty)
                _AccountInfoLine(
                  icon: Icons.alternate_email,
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
                        Icons.lock_outline,
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
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
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
                        icon: const Icon(Icons.copy, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              if (account.website.isNotEmpty)
                _AccountInfoLine(
                  icon: Icons.language_outlined,
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

class _ServiceAvatar extends StatelessWidget {
  const _ServiceAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter =
        trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Center(
          child: Text(
            letter,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}

class _AccountInfoLine extends StatelessWidget {
  const _AccountInfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon,
              size: 17, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountEditor extends StatefulWidget {
  const _AccountEditor({required this.ref, this.account});

  final WidgetRef ref;
  final AccountItem? account;

  @override
  State<_AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends State<_AccountEditor> {
  final _service = TextEditingController();
  final _login = TextEditingController();
  final _password = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();
  final _note = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    if (account != null) {
      _service.text = account.serviceName;
      _login.text = account.login;
      _password.text = account.password;
      _email.text = account.email;
      _website.text = account.website;
      _note.text = account.note;
    }
  }

  @override
  void dispose() {
    _service.dispose();
    _login.dispose();
    _password.dispose();
    _email.dispose();
    _website.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.86,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.fromLTRB(16, 0, 16, 14 + bottomInset),
        child: Column(
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.key_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.account == null
                        ? strings.addAccount
                        : strings.editAccount,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    _AccountTextField(
                      controller: _service,
                      label: strings.serviceName,
                      icon: Icons.apps_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                    _AccountTextField(
                      controller: _login,
                      label: strings.login,
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                    ),
                    _AccountTextField(
                      controller: _email,
                      label: strings.email,
                      icon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    _AccountTextField(
                      controller: _password,
                      label: strings.password,
                      icon: Icons.lock_outline,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.next,
                      suffixIcon: IconButton(
                        tooltip: strings.password,
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    _AccountTextField(
                      controller: _website,
                      label: strings.website,
                      icon: Icons.language_outlined,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                    ),
                    _AccountTextField(
                      controller: _note,
                      label: strings.note,
                      icon: Icons.notes_outlined,
                      minLines: 4,
                      maxLines: 6,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(strings.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final existing = widget.account;
    final account = existing == null
        ? AccountItem(
            id: now.microsecondsSinceEpoch.toString(),
            serviceName: _service.text.trim(),
            login: _login.text.trim(),
            password: _password.text,
            email: _email.text.trim(),
            website: _website.text.trim(),
            note: _note.text.trim(),
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(
            serviceName: _service.text.trim(),
            login: _login.text.trim(),
            password: _password.text,
            email: _email.text.trim(),
            website: _website.text.trim(),
            note: _note.text.trim(),
            updatedAt: now,
          );

    final controller = widget.ref.read(accountsControllerProvider.notifier);
    if (existing == null) {
      await controller.add(account);
    } else {
      await controller.update(account);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _AccountTextField extends StatelessWidget {
  const _AccountTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.minLines,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        minLines: obscureText ? 1 : minLines,
        maxLines: obscureText ? 1 : maxLines,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: (maxLines ?? 1) > 1,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}
