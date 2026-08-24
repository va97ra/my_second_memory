import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../state/sync_controller.dart';

part 'sync_screen_sections.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  final _email = TextEditingController();
  final _accountPassword = TextEditingController();
  final _vaultPassword = TextEditingController();
  final _vaultConfirmation = TextEditingController();
  bool _registerMode = false;
  bool _obscureAccountPassword = true;
  bool _obscureVaultPassword = true;
  bool _recoveryMode = false;
  String? _formError;

  void _update(VoidCallback callback) => setState(callback);

  @override
  void dispose() {
    _email.dispose();
    _accountPassword.dispose();
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

  Future<void> _submitAccount() async {
    final strings = AppStrings.of(context);
    final email = _email.text.trim();
    final password = _accountPassword.text;
    if (!email.contains('@') || password.length < 6) {
      setState(() => _formError = strings.isRu
          ? 'Проверьте email и пароль (минимум 6 символов).'
          : 'Check the email and password (at least 6 characters).');
      return;
    }
    setState(() => _formError = null);
    final controller = ref.read(syncControllerProvider.notifier);
    if (_registerMode) {
      await controller.register(email, password);
    } else {
      await controller.signIn(email, password);
    }
  }

  Future<void> _connectVault(SyncState state) async {
    final strings = AppStrings.of(context);
    final password = _vaultPassword.text;
    if (_recoveryMode) {
      if (password.trim().isEmpty) {
        setState(() => _formError = strings.syncRecoveryCode);
        return;
      }
      setState(() => _formError = null);
      await ref
          .read(syncControllerProvider.notifier)
          .connectVaultWithRecoveryCode(password);
      _vaultPassword.clear();
      return;
    }
    if (password.length < 8) {
      setState(() => _formError = strings.isRu
          ? 'Используйте не менее 8 символов.'
          : 'Use at least 8 characters.');
      return;
    }
    if (!state.vaultExists && password != _vaultConfirmation.text) {
      setState(() => _formError = strings.backupPasswordsDoNotMatch);
      return;
    }
    setState(() => _formError = null);
    await ref.read(syncControllerProvider.notifier).connectVault(password);
    _vaultPassword.clear();
    _vaultConfirmation.clear();
  }
}
