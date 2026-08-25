import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/ui/screen_chrome.dart';
import '../state/sync_controller.dart';
import '../state/sync_form_rules.dart';
import 'sync_form_messages.dart';
import 'widgets/sync_account_form.dart';
import 'widgets/sync_connected_card.dart';
import 'widgets/sync_recovery_code_card.dart';
import 'widgets/sync_unconfigured_card.dart';
import 'widgets/sync_vault_form.dart';

/// Синхронизация: вход в облако, пароль хранилища и его состояние.
class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  final _vaultPassword = TextEditingController();
  final _vaultConfirmation = TextEditingController();
  bool _obscureVaultPassword = true;
  bool _recoveryMode = false;
  SyncFormProblem? _problem;

  @override
  void dispose() {
    _vaultPassword.dispose();
    _vaultConfirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final state = ref.watch(syncControllerProvider);

    return WarmGradientBackground(
      child: CustomScrollView(
        slivers: [
          MainSliverAppBar(
            title: strings.synchronization,
            backLocation: '/settings',
          ),
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  child: _body(strings, state),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(AppStrings strings, SyncState state) {
    final controller = ref.read(syncControllerProvider.notifier);
    final busy = state.status == SyncStatus.loading;

    if (state.status == SyncStatus.unconfigured) {
      return const SyncUnconfiguredCard();
    }

    if (state.status == SyncStatus.needsVault) {
      return SyncVaultForm(
        passwordController: _vaultPassword,
        confirmationController: _vaultConfirmation,
        busy: busy,
        vaultExists: state.vaultExists,
        recoveryMode: _recoveryMode,
        obscurePassword: _obscureVaultPassword,
        errorText: _errorText(strings, state),
        onToggleObscure: () => setState(
          () => _obscureVaultPassword = !_obscureVaultPassword,
        ),
        onToggleRecovery: () => setState(() {
          _recoveryMode = !_recoveryMode;
          _problem = null;
          _vaultPassword.clear();
        }),
        onSubmit: () => _connectVault(state),
      );
    }

    if (state.isConnected) return _connected(strings, state, controller);

    return SyncAccountForm(
      busy: busy,
      errorText: _errorText(strings, state),
      onGoogle: controller.signInWithGoogle,
    );
  }

  Widget _connected(
    AppStrings strings,
    SyncState state,
    SyncController controller,
  ) {
    final card = SyncConnectedCard(
      email: state.email,
      syncing: state.status == SyncStatus.syncing,
      lastSyncedAt: state.lastSyncedAt,
      lastResult: state.lastResult,
      errorText: _errorText(strings, state),
      onSyncNow: controller.syncNow,
      onSignOut: controller.signOut,
    );
    final code = state.recoveryCode;
    if (code == null) return card;

    return Column(
      children: [
        card,
        const SizedBox(height: 16),
        SyncRecoveryCodeCard(code: code),
      ],
    );
  }

  Future<void> _connectVault(SyncState state) async {
    final password = _vaultPassword.text;
    final problem = validateSyncVault(
      password: password,
      confirmation: _vaultConfirmation.text,
      vaultExists: state.vaultExists,
      recoveryMode: _recoveryMode,
    );
    setState(() => _problem = problem);
    if (problem != null) return;

    final controller = ref.read(syncControllerProvider.notifier);
    if (_recoveryMode) {
      await controller.connectVaultWithRecoveryCode(password);
      _vaultPassword.clear();
      return;
    }
    await controller.connectVault(password);
    _vaultPassword.clear();
    _vaultConfirmation.clear();
  }

  String? _errorText(AppStrings strings, SyncState state) =>
      syncErrorText(strings, problem: _problem, syncError: state.error);
}
