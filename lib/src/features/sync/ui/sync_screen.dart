import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/notebook/notebook_background.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../state/sync_controller.dart';

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

  Widget _body(AppStrings strings, SyncState state) {
    if (state.status == SyncStatus.unconfigured) {
      return _SyncCard(
        icon: Icons.cloud_off_rounded,
        title: strings.syncNotConfigured,
        children: [
          Text(strings.syncNotConfiguredHint),
          const SizedBox(height: 12),
          const SelectableText(
            '--dart-define=SUPABASE_URL=…\n'
            '--dart-define=SUPABASE_PUBLISHABLE_KEY=…',
          ),
        ],
      );
    }

    if (state.status == SyncStatus.awaitingEmailConfirmation) {
      return _SyncCard(
        icon: Icons.mark_email_unread_rounded,
        title: strings.syncCheckEmail,
        children: [
          if (state.email != null) SelectableText(state.email!),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ref.read(syncControllerProvider.notifier).returnToSignIn();
                setState(() => _registerMode = false);
              },
              child: Text(strings.syncSignIn),
            ),
          ),
        ],
      );
    }

    if (state.status == SyncStatus.needsVault) {
      return _vaultForm(strings, state);
    }

    if (state.isConnected) return _connected(strings, state);
    return _accountForm(strings, state);
  }

  Widget _accountForm(AppStrings strings, SyncState state) {
    final busy = state.status == SyncStatus.loading;
    return _SyncCard(
      icon: Icons.cloud_sync_rounded,
      title: _registerMode ? strings.syncCreateAccount : strings.syncSignIn,
      children: [
        Text(strings.synchronizationSubtitle),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            key: const ValueKey('sync_google_sign_in'),
            onPressed: busy
                ? null
                : ref.read(syncControllerProvider.notifier).signInWithGoogle,
            icon: const _GoogleMark(),
            label: Text(strings.syncContinueWithGoogle),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                strings.syncOrWithEmail,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('sync_email'),
          controller: _email,
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(labelText: strings.email),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('sync_account_password'),
          controller: _accountPassword,
          enabled: !busy,
          obscureText: _obscureAccountPassword,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: strings.syncAccountPassword,
            suffixIcon: IconButton(
              tooltip: _obscureAccountPassword
                  ? strings.showPassword
                  : strings.hidePassword,
              onPressed: () => setState(
                () => _obscureAccountPassword = !_obscureAccountPassword,
              ),
              icon: Icon(
                _obscureAccountPassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
            ),
          ),
          onSubmitted: (_) => _submitAccount(),
        ),
        if (_formError != null || state.error != null) ...[
          const SizedBox(height: 12),
          _ErrorText(_formError ?? state.error!),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            key: const ValueKey('sync_account_submit'),
            onPressed: busy ? null : _submitAccount,
            child: busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_registerMode
                    ? strings.syncCreateAccount
                    : strings.syncSignIn),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: busy
                ? null
                : () => setState(() {
                      _registerMode = !_registerMode;
                      _formError = null;
                    }),
            child: Text(
                _registerMode ? strings.syncSignIn : strings.syncCreateAccount),
          ),
        ),
      ],
    );
  }

  Widget _vaultForm(AppStrings strings, SyncState state) {
    final busy = state.status == SyncStatus.loading;
    return _SyncCard(
      icon: Icons.enhanced_encryption_rounded,
      title: strings.syncVaultPassword,
      children: [
        Text(state.vaultExists
            ? strings.syncExistingVault
            : strings.syncNewVault),
        const SizedBox(height: 8),
        Text(
          strings.syncVaultPasswordHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('sync_vault_password'),
          controller: _vaultPassword,
          enabled: !busy,
          obscureText: _obscureVaultPassword,
          decoration: InputDecoration(
            labelText: _recoveryMode
                ? strings.syncRecoveryCode
                : strings.syncVaultPassword,
            suffixIcon: IconButton(
              tooltip: _obscureVaultPassword
                  ? strings.showPassword
                  : strings.hidePassword,
              onPressed: () => setState(
                () => _obscureVaultPassword = !_obscureVaultPassword,
              ),
              icon: Icon(
                _obscureVaultPassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
            ),
          ),
        ),
        if (!state.vaultExists && !_recoveryMode) ...[
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('sync_vault_confirmation'),
            controller: _vaultConfirmation,
            enabled: !busy,
            obscureText: _obscureVaultPassword,
            decoration: InputDecoration(
              labelText: strings.syncRepeatVaultPassword,
            ),
            onSubmitted: (_) => _connectVault(state),
          ),
        ],
        if (_formError != null || state.error != null) ...[
          const SizedBox(height: 12),
          _ErrorText(_formError ?? state.error!),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            key: const ValueKey('sync_vault_submit'),
            onPressed: busy ? null : () => _connectVault(state),
            icon: const Icon(Icons.lock_open_rounded),
            label: Text(strings.syncConnect),
          ),
        ),
        if (state.vaultExists) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: busy
                  ? null
                  : () => setState(() {
                        _recoveryMode = !_recoveryMode;
                        _formError = null;
                        _vaultPassword.clear();
                      }),
              child: Text(_recoveryMode
                  ? strings.syncUsePassword
                  : strings.syncUseRecoveryCode),
            ),
          ),
        ],
      ],
    );
  }

  Widget _connected(AppStrings strings, SyncState state) {
    final syncing = state.status == SyncStatus.syncing;
    return Column(
      children: [
        _SyncCard(
          icon: syncing ? Icons.sync_rounded : Icons.cloud_done_rounded,
          title: syncing ? strings.syncInProgress : strings.syncReady,
          children: [
            if (state.email != null) Text(state.email!),
            const SizedBox(height: 8),
            Text(_lastSyncLabel(strings, state)),
            if (state.error != null) ...[
              const SizedBox(height: 12),
              _ErrorText(state.error!),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                key: const ValueKey('sync_now'),
                onPressed: syncing
                    ? null
                    : ref.read(syncControllerProvider.notifier).syncNow,
                icon: const Icon(Icons.sync_rounded),
                label: Text(strings.syncNow),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: ref.read(syncControllerProvider.notifier).signOut,
                child: Text(strings.syncSignOut),
              ),
            ),
          ],
        ),
        if (state.recoveryCode != null) ...[
          const SizedBox(height: 16),
          _SyncCard(
            icon: Icons.key_rounded,
            title: strings.syncRecoveryCode,
            children: [
              Text(strings.syncRecoveryWarning),
              const SizedBox(height: 12),
              SelectableText(
                state.recoveryCode!,
                key: const ValueKey('sync_recovery_code'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.filledTonal(
                  tooltip: strings.copyPassword,
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: state.recoveryCode!),
                  ),
                  icon: const Icon(Icons.copy_rounded),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _lastSyncLabel(AppStrings strings, SyncState state) {
    final time = state.lastSyncedAt;
    if (time == null) return strings.syncNever;
    final value = TimeOfDay.fromDateTime(time).format(context);
    final result = state.lastResult;
    if (result == null) return value;
    return '$value · ↓${result.downloaded} ↑${result.uploaded}';
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

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Google',
      child: Text(
        'G',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: notebookSurfaceShadow(context, NotebookSurfaceDepth.card),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox.square(
                    dimension: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: colors.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
