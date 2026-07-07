import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/app_shell.dart';
import '../../security/state/security_provider.dart';
import '../domain/account_item.dart';
import '../state/accounts_controller.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final session = ref.watch(securitySessionProvider);
    final accounts = ref.watch(accountsControllerProvider);

    return AppShell(
      currentIndex: 2,
      floatingActionButton: session.hasPin && session.cipher != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAccountEditor(context, ref),
              icon: const Icon(Icons.add),
              label: Text(strings.addAccount),
            )
          : null,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFBF3E8),
              Color(0xFFF7ECDB),
              Color(0xFFFCF7EF),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              backgroundColor: const Color(0xFFFBF3E8),
              surfaceTintColor: Colors.transparent,
              title: Text(
                strings.accounts,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF172033),
                    ),
              ),
            ),
            if (!session.hasPin || session.cipher == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _PinRequiredCard(
                  text: strings.pinRequiredForAccounts,
                  onOpenSettings: () => context.go('/security'),
                ),
              )
            else if (accounts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(strings.noAccounts)),
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
      builder: (context) => _AccountEditor(account: account, ref: ref),
    );
  }
}

class _PinRequiredCard extends StatelessWidget {
  const _PinRequiredCard({
    required this.text,
    required this.onOpenSettings,
  });

  final String text;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD6E2EF)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 34),
                const SizedBox(height: 12),
                Text(text, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onOpenSettings,
                  child: Text(AppStrings.of(context).pinSecurity),
                ),
              ],
            ),
          ),
        ),
      ),
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
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD6E2EF)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.key_outlined, color: Color(0xFF2563EB)),
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
              if (account.login.isNotEmpty) Text(account.login),
              const SizedBox(height: 8),
              Row(
                children: [
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
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
              if (account.website.isNotEmpty) Text(account.website),
              if (account.note.isNotEmpty) Text(account.note),
            ],
          ),
        ),
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
  final _website = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    if (account != null) {
      _service.text = account.serviceName;
      _login.text = account.login;
      _password.text = account.password;
      _website.text = account.website;
      _note.text = account.note;
    }
  }

  @override
  void dispose() {
    _service.dispose();
    _login.dispose();
    _password.dispose();
    _website.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.account == null ? strings.addAccount : strings.editAccount,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _service,
              decoration: InputDecoration(labelText: strings.serviceName),
            ),
            TextField(
              controller: _login,
              decoration: InputDecoration(labelText: strings.login),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(labelText: strings.password),
            ),
            TextField(
              controller: _website,
              decoration: InputDecoration(labelText: strings.website),
            ),
            TextField(
              controller: _note,
              decoration: InputDecoration(labelText: strings.note),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
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
            website: _website.text.trim(),
            note: _note.text.trim(),
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(
            serviceName: _service.text.trim(),
            login: _login.text.trim(),
            password: _password.text,
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
