import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import '../../../shared/ui/screen_chrome.dart';
import 'package:ez_domain/ez_domain.dart';
import '../state/accounts_controller.dart';
import 'widgets/account_card.dart';
import 'widgets/account_editor.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final accounts = ref.watch(accountsControllerProvider);

    return Scaffold(
      body: WarmGradientBackground(
        child: CustomScrollView(
          slivers: [
            MainSliverAppBar(
              title: strings.accounts,
              backLocation: '/calendar',
              trailing: IconButton(
                key: const ValueKey('accounts_add'),
                tooltip: strings.addAccount,
                onPressed: () => _showAccountEditor(context, ref),
                icon: const Icon(Icons.add_rounded, size: 22),
                style: notebookIconButtonStyle(),
              ),
            ),
            SliverList.builder(
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return AccountCard(
                  account: account,
                  onEdit: () => _showAccountEditor(context, ref, account),
                  onDelete: () => _delete(context, ref, account),
                );
              },
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  /// Пароль может не храниться больше нигде, а удаление разъезжается по всем
  /// устройствам. Поэтому корзина спрашивает — тем же диалогом, что и операции.
  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AccountItem account,
  ) async {
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
    await ref.read(accountsControllerProvider.notifier).delete(account.id);
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
      builder: (context) => AccountEditor(account: account, ref: ref),
    );
  }
}

