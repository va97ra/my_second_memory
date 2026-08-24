import 'package:flutter/material.dart';
import 'account_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import '../../state/accounts_controller.dart';

/// Лист создания и правки аккаунта.
class AccountEditor extends StatefulWidget {
  const AccountEditor({super.key, required this.ref, this.account});

  final WidgetRef ref;
  final AccountItem? account;

  @override
  State<AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends State<AccountEditor> {
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
                      Icons.vpn_key_rounded,
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
                  icon: const Icon(Icons.close_rounded),
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
                    AccountTextField(
                      controller: _service,
                      label: strings.serviceName,
                      icon: Icons.apps_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                    AccountTextField(
                      controller: _login,
                      label: strings.login,
                      icon: Icons.person_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                    AccountTextField(
                      controller: _email,
                      label: strings.email,
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    AccountTextField(
                      controller: _password,
                      label: strings.password,
                      icon: Icons.lock_rounded,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.next,
                      suffixIcon: IconButton(
                        tooltip: strings.password,
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                      ),
                    ),
                    AccountTextField(
                      controller: _website,
                      label: strings.website,
                      icon: Icons.language_rounded,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                    ),
                    AccountTextField(
                      controller: _note,
                      label: strings.note,
                      icon: Icons.sticky_note_2_rounded,
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
                icon: const Icon(Icons.save_rounded),
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
