part of 'sync_screen.dart';

extension _SyncScreenSections on _SyncScreenState {
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

    if (state.status == SyncStatus.awaitingEmailConfirmation ||
        state.status == SyncStatus.resendingEmailConfirmation) {
      final resending = state.status == SyncStatus.resendingEmailConfirmation;
      return _SyncCard(
        icon: Icons.mark_email_unread_rounded,
        title: strings.syncCheckEmail,
        children: [
          if (state.email != null) SelectableText(state.email!),
          const SizedBox(height: 12),
          Text(strings.syncCheckEmailHint),
          if (state.confirmationResent) ...[
            const SizedBox(height: 12),
            Text(
              strings.syncEmailResent,
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
            ),
          ],
          if (state.error != null) ...[
            const SizedBox(height: 12),
            _ErrorText(strings.syncErrorMessage(state.error!)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: resending
                  ? null
                  : ref
                      .read(syncControllerProvider.notifier)
                      .resendSignupConfirmation,
              icon: resending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.forward_to_inbox_rounded),
              label: Text(strings.syncResendEmail),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: resending
                  ? null
                  : () {
                      ref
                          .read(syncControllerProvider.notifier)
                          .returnToSignIn();
                      _update(() => _registerMode = false);
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
              onPressed: () => _update(
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
          _ErrorText(
            _formError ?? strings.syncErrorMessage(state.error!),
          ),
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
                : () => _update(() {
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
              onPressed: () => _update(
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
          _ErrorText(
            _formError ?? strings.syncErrorMessage(state.error!),
          ),
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
                  : () => _update(() {
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
              _ErrorText(strings.syncErrorMessage(state.error!)),
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
              child: OutlinedButton.icon(
                key: const ValueKey('sync_sign_out'),
                onPressed: ref.read(syncControllerProvider.notifier).signOut,
                icon: const Icon(Icons.logout_rounded),
                label: Text(strings.syncSignOut),
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
