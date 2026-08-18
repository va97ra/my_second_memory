part of 'security_gate.dart';

class _SecurityScaffold extends StatefulWidget {
  const _SecurityScaffold({required this.child});

  final Widget child;

  @override
  State<_SecurityScaffold> createState() => _SecurityScaffoldState();
}

class _SecurityScaffoldState extends State<_SecurityScaffold> {
  late final OverlayEntry _entry = OverlayEntry(builder: _buildScaffold);

  @override
  void didUpdateWidget(covariant _SecurityScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.markNeedsBuild();
  }

  @override
  void dispose() {
    if (_entry.mounted) {
      _entry.remove();
    }
    super.dispose();
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(
      initialEntries: [
        _entry,
      ],
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: notebookSurfaceShadow(
          context,
          NotebookSurfaceDepth.panel,
        ).isNotEmpty
            ? notebookSurfaceShadow(context, NotebookSurfaceDepth.panel)
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _SetupPinCard extends StatelessWidget {
  const _SetupPinCard({
    required this.controller,
    required this.busy,
    required this.error,
    required this.onCreatePin,
  });

  final TextEditingController controller;
  final bool busy;
  final String? error;
  final VoidCallback onCreatePin;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _SecurityCard(
      children: [
        Icon(
          Icons.shield_rounded,
          size: 42,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          strings.setupPinTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          strings.setupPinSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 18),
        _PinField(controller: controller, onSubmitted: onCreatePin),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : onCreatePin,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_rounded),
            label: Text(strings.createPin),
          ),
        ),
        if (error != null) _ErrorText(error!),
      ],
    );
  }
}

class _BiometricUnlockCard extends StatelessWidget {
  const _BiometricUnlockCard({
    required this.busy,
    required this.error,
    required this.onRetry,
    required this.onShowPin,
  });

  final bool busy;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onShowPin;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _SecurityCard(
      children: [
        Icon(
          Icons.fingerprint_rounded,
          size: 52,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          strings.appTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : onRetry,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fingerprint_rounded),
            label: Text(strings.tryBiometricsAgain),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onShowPin,
            icon: const Icon(Icons.password_rounded),
            label: Text(strings.unlockWithPin),
          ),
        ),
        if (error != null) _ErrorText(error!),
      ],
    );
  }
}

class _EnableBiometricsCard extends StatelessWidget {
  const _EnableBiometricsCard({
    required this.busy,
    required this.onEnable,
    required this.onSkip,
  });

  final bool busy;
  final VoidCallback onEnable;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _SecurityCard(
      children: [
        Icon(
          Icons.fingerprint_rounded,
          size: 52,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          strings.enableBiometricsQuestion,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : onEnable,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fingerprint_rounded),
            label: Text(strings.biometrics),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: busy ? null : onSkip,
            child: Text(strings.maybeLater),
          ),
        ),
      ],
    );
  }
}

class _PinUnlockCard extends StatelessWidget {
  const _PinUnlockCard({
    required this.controller,
    required this.busy,
    required this.error,
    required this.onUnlock,
    this.onBiometrics,
  });

  final TextEditingController controller;
  final bool busy;
  final String? error;
  final VoidCallback onUnlock;
  final VoidCallback? onBiometrics;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _SecurityCard(
      children: [
        Icon(
          Icons.lock_rounded,
          size: 42,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          strings.appTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        _PinField(
          controller: controller,
          enabled: !busy,
          onSubmitted: onUnlock,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : onUnlock,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_open_rounded),
            label: Text(strings.unlock),
          ),
        ),
        if (onBiometrics != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onBiometrics,
              icon: const Icon(Icons.fingerprint_rounded),
              label: Text(strings.biometrics),
            ),
          ),
        ],
        if (error != null) _ErrorText(error!),
      ],
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      obscureText: true,
      maxLength: 8,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      autofillHints: const <String>[],
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 6),
      decoration: const InputDecoration(labelText: 'PIN', counterText: ''),
      onSubmitted: (_) => onSubmitted(),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
