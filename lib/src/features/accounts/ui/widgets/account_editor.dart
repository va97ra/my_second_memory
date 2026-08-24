import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/account_form.dart';
import '../../state/accounts_controller.dart';
import 'account_editor_fields.dart';
import 'account_editor_header.dart';

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
    if (account == null) return;
    _service.text = account.serviceName;
    _login.text = account.login;
    _password.text = account.password;
    _email.text = account.email;
    _website.text = account.website;
    _note.text = account.note;
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

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.86,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          14 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            AccountEditorHeader(
              title: widget.account == null
                  ? strings.addAccount
                  : strings.editAccount,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: AccountEditorFields(
                  service: _service,
                  login: _login,
                  email: _email,
                  password: _password,
                  website: _website,
                  note: _note,
                  showPassword: _showPassword,
                  onTogglePassword: () =>
                      setState(() => _showPassword = !_showPassword),
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
    final existing = widget.account;
    final account = accountFromForm(
      existing: existing,
      serviceName: _service.text,
      login: _login.text,
      password: _password.text,
      email: _email.text,
      website: _website.text,
      note: _note.text,
      now: DateTime.now(),
    );

    final controller = widget.ref.read(accountsControllerProvider.notifier);
    if (existing == null) {
      await controller.add(account);
    } else {
      await controller.update(account);
    }
    if (mounted) Navigator.of(context).pop();
  }
}
