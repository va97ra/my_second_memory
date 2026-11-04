import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../navigation/page_turn_navigation.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../state/account_form.dart';
import '../state/accounts_controller.dart';
import 'widgets/account_editor_fields.dart';

/// Окно создания и правки аккаунта, на весь экран.
///
/// Получает идентификатор и читает аккаунт сам. Без идентификатора — новый.
class AccountEditorScreen extends ConsumerStatefulWidget {
  const AccountEditorScreen({super.key, this.accountId});

  final String? accountId;

  @override
  ConsumerState<AccountEditorScreen> createState() =>
      _AccountEditorScreenState();
}

class _AccountEditorScreenState extends ConsumerState<AccountEditorScreen> {
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
    final id = widget.accountId;
    final account = id == null ? null : ref.read(accountByIdProvider(id));
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
    final isNew = widget.accountId == null;

    return Scaffold(
      body: WarmGradientBackground(
        child: Column(
          children: [
            MainPageHeader(
              title: isNew ? strings.addAccount : strings.editAccount,
              backLocation: '/accounts',
              trailing: [
                if (!isNew)
                  IconButton(
                    key: const ValueKey('account_delete'),
                    tooltip: strings.delete,
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_rounded, size: 22),
                    style: notebookIconButtonStyle(),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: WritingPaper(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
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
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  key: const ValueKey('account_save'),
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(strings.save),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final id = widget.accountId;
    final existing = id == null ? null : ref.read(accountByIdProvider(id));
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

    final controller = ref.read(accountsControllerProvider.notifier);
    if (existing == null) {
      await controller.add(account);
    } else {
      await controller.update(account);
    }
    if (mounted) await context.pageTurnPop();
  }

  /// Пароль может не храниться больше нигде, а удаление разъезжается по всем
  /// устройствам. Поэтому корзина спрашивает — тем же диалогом, что и операции.
  Future<void> _delete() async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(strings.deleteAccountQuestion),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(strings.delete),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await ref
        .read(accountsControllerProvider.notifier)
        .delete(widget.accountId!);
    if (mounted) await context.pageTurnPop();
  }
}
