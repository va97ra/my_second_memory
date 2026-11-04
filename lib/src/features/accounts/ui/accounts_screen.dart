import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import '../../../navigation/page_turn_navigation.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../state/accounts_controller.dart';
import 'widgets/account_grid.dart';

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
              hint: strings.accountsPageHint,
              trailing: IconButton(
                key: const ValueKey('accounts_add'),
                tooltip: strings.addAccount,
                onPressed: () => context.pageTurnPush('/accounts/new'),
                icon: const Icon(Icons.add_rounded, size: 22),
                style: notebookIconButtonStyle(),
              ),
            ),
            AccountGrid(
              accountIds: [for (final account in accounts) account.id],
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }
}
