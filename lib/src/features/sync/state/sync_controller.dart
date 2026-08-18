import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../security/data/app_cipher.dart';
import '../data/supabase_sync_remote_store.dart';
import '../data/sync_local_store.dart';
import '../data/sync_remote_store.dart';
import '../data/sync_vault_crypto.dart';
import '../domain/memory_sync_engine.dart';
import '../domain/sync_backend_config.dart';
import '../domain/sync_models.dart';

enum SyncStatus {
  unconfigured,
  loading,
  signedOut,
  awaitingEmailConfirmation,
  needsVault,
  ready,
  syncing,
  error,
}

class SyncState {
  const SyncState({
    required this.status,
    this.email,
    this.vaultExists = false,
    this.lastSyncedAt,
    this.lastResult,
    this.error,
    this.recoveryCode,
    this.cipher,
  });

  const SyncState.unconfigured() : this(status: SyncStatus.unconfigured);

  final SyncStatus status;
  final String? email;
  final bool vaultExists;
  final DateTime? lastSyncedAt;
  final SyncRunResult? lastResult;
  final String? error;
  final String? recoveryCode;
  final AppCipher? cipher;

  bool get isConnected => cipher != null;

  SyncState copyWith({
    SyncStatus? status,
    String? email,
    bool? vaultExists,
    DateTime? lastSyncedAt,
    SyncRunResult? lastResult,
    String? error,
    bool clearError = false,
    String? recoveryCode,
    bool clearRecoveryCode = false,
    AppCipher? cipher,
    bool clearCipher = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      email: email ?? this.email,
      vaultExists: vaultExists ?? this.vaultExists,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastResult: lastResult ?? this.lastResult,
      error: clearError ? null : error ?? this.error,
      recoveryCode:
          clearRecoveryCode ? null : recoveryCode ?? this.recoveryCode,
      cipher: clearCipher ? null : cipher ?? this.cipher,
    );
  }
}

final syncBackendConfigProvider = Provider<SyncBackendConfig>(
  (ref) => SyncBackendConfig.fromEnvironment(),
);

final syncRemoteStoreProvider = Provider<SyncRemoteStore?>((ref) {
  if (!ref.watch(syncBackendConfigProvider).isConfigured) return null;
  return SupabaseSyncRemoteStore(Supabase.instance.client);
});

final syncKeyStoreProvider = Provider<SyncKeyStore>((ref) => SyncKeyStore());
final syncTombstoneStoreProvider =
    Provider<SyncTombstoneStore>((ref) => const SyncTombstoneStore());

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncState>((ref) {
  return SyncController(
    remote: ref.watch(syncRemoteStoreProvider),
    keyStore: ref.watch(syncKeyStoreProvider),
    tombstones: ref.watch(syncTombstoneStoreProvider),
    readMemoryItems: () async {
      await ref.read(memoryItemsControllerProvider.notifier).load();
      return ref.read(memoryItemsControllerProvider);
    },
    replaceMemoryItems: (items) =>
        ref.read(memoryItemsControllerProvider.notifier).replaceAll(items),
  );
});

class SyncController extends StateNotifier<SyncState> {
  SyncController({
    required SyncRemoteStore? remote,
    required SyncKeyStore keyStore,
    required SyncTombstoneStore tombstones,
    required Future<List<MemoryItem>> Function() readMemoryItems,
    required Future<void> Function(List<MemoryItem>) replaceMemoryItems,
  })  : _remote = remote,
        _keyStore = keyStore,
        _tombstones = tombstones,
        _readMemoryItems = readMemoryItems,
        _replaceMemoryItems = replaceMemoryItems,
        super(remote == null
            ? const SyncState.unconfigured()
            : const SyncState(status: SyncStatus.loading));

  final SyncRemoteStore? _remote;
  final SyncKeyStore _keyStore;
  final SyncTombstoneStore _tombstones;
  final Future<List<MemoryItem>> Function() _readMemoryItems;
  final Future<void> Function(List<MemoryItem>) _replaceMemoryItems;
  final SyncVaultCrypto _vaultCrypto = const SyncVaultCrypto();
  StreamSubscription<void>? _remoteSubscription;
  StreamSubscription<void>? _authSubscription;
  Timer? _debounce;
  Timer? _periodic;
  Future<void>? _activeSync;
  Future<void>? _activeAuthTransition;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final remote = _remote;
    if (remote == null) return;
    try {
      final userId = remote.currentUserId;
      if (userId == null) {
        state = const SyncState(status: SyncStatus.signedOut);
      } else {
        final cipher = await _keyStore.read(userId);
        if (cipher == null) {
          final profile = await remote.fetchVaultProfile();
          state = SyncState(
            status: SyncStatus.needsVault,
            email: remote.currentUserEmail,
            vaultExists: profile != null,
          );
        } else {
          _setReady(cipher);
          schedule(const Duration(milliseconds: 100));
        }
      }
    } catch (error) {
      _setError(error);
    }
    _startAuthListener();
  }

  Future<bool> register(String email, String password) async {
    final remote = _requireRemote();
    state = state.copyWith(status: SyncStatus.loading, clearError: true);
    try {
      final result = await remote.signUp(email.trim(), password);
      if (!result.hasSession) {
        state = SyncState(
          status: SyncStatus.awaitingEmailConfirmation,
          email: email.trim(),
        );
        return false;
      }
      await _afterAuthentication();
      return true;
    } catch (error) {
      _setError(error);
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    final remote = _requireRemote();
    state = state.copyWith(status: SyncStatus.loading, clearError: true);
    try {
      await remote.signIn(email.trim(), password);
      await _afterAuthentication();
      return true;
    } catch (error) {
      _setError(error);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    final remote = _requireRemote();
    state = state.copyWith(status: SyncStatus.loading, clearError: true);
    try {
      final launched = await remote.signInWithGoogle();
      if (!launched) {
        throw StateError('Could not open Google sign in');
      }
      if (remote.currentUserId != null) {
        await _afterAuthentication();
      } else {
        state = const SyncState(status: SyncStatus.signedOut);
      }
      return true;
    } catch (error) {
      _setError(error);
      return false;
    }
  }

  Future<bool> connectVault(String password) async {
    final remote = _requireRemote();
    final userId = remote.currentUserId;
    if (userId == null) return false;
    state = state.copyWith(status: SyncStatus.loading, clearError: true);
    AppCipher? cipher;
    try {
      final profile = await remote.fetchVaultProfile();
      String? recoveryCode;
      if (profile == null) {
        final created = await _vaultCrypto.create(password);
        cipher = created.cipher;
        recoveryCode = created.recoveryCode;
        await remote.createVaultProfile(created.profile);
      } else {
        cipher = await _vaultCrypto.unlock(profile, password);
      }
      await _keyStore.save(userId, cipher);
      _setReady(cipher, recoveryCode: recoveryCode);
      await syncNow();
      return true;
    } catch (error) {
      cipher?.destroy();
      _setError(error, needsVault: true);
      return false;
    }
  }

  Future<bool> connectVaultWithRecoveryCode(String recoveryCode) async {
    final remote = _requireRemote();
    final userId = remote.currentUserId;
    if (userId == null) return false;
    state = state.copyWith(status: SyncStatus.loading, clearError: true);
    AppCipher? cipher;
    try {
      final profile = await remote.fetchVaultProfile();
      if (profile == null) {
        throw const FormatException('Synchronization vault does not exist');
      }
      cipher = await _vaultCrypto.unlockWithRecoveryCode(
        profile,
        recoveryCode,
      );
      await _keyStore.save(userId, cipher);
      _setReady(cipher);
      await syncNow();
      return true;
    } catch (error) {
      cipher?.destroy();
      _setError(error, needsVault: true);
      return false;
    }
  }

  void returnToSignIn() {
    if (_remote?.currentUserId != null) return;
    state = const SyncState(status: SyncStatus.signedOut);
  }

  Future<void> syncNow() {
    final active = _activeSync;
    if (active != null) return active;
    if (state.cipher == null || _remote?.currentUserId == null) {
      return Future.value();
    }
    final future = _runSync();
    _activeSync = future;
    return future.whenComplete(() => _activeSync = null);
  }

  Future<void> _runSync() async {
    final cipher = state.cipher!;
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      final local = await _readMemoryItems();
      final result = await MemorySyncEngine(
        remote: _remote!,
        cipher: cipher,
        tombstones: _tombstones,
      ).synchronize(
        localItems: local,
        replaceLocal: _replaceMemoryItems,
      );
      state = state.copyWith(
        status: SyncStatus.ready,
        lastSyncedAt: DateTime.now(),
        lastResult: result,
        clearError: true,
      );
    } catch (error) {
      _setError(error);
    }
  }

  void schedule([Duration delay = const Duration(milliseconds: 900)]) {
    if (!state.isConnected) return;
    _debounce?.cancel();
    _debounce = Timer(delay, syncNow);
  }

  Future<void> recordDeletion(String id, DateTime deletedAt) async {
    final userId = _remote?.currentUserId;
    if (userId == null || !state.isConnected) return;
    await _tombstones.markDeleted(userId, id, deletedAt);
    schedule();
  }

  Future<void> signOut() async {
    _stopAutomaticSync();
    final userId = _remote?.currentUserId;
    final previousCipher = state.cipher;
    try {
      await _remote?.signOut();
    } catch (error) {
      _setError(error);
      _startAutomaticSync();
      return;
    }
    if (userId != null) {
      try {
        await _keyStore.delete(userId);
      } catch (_) {
        // The remote session is already closed; never retain an active cipher.
      }
    }
    state = const SyncState(status: SyncStatus.signedOut);
    previousCipher?.destroy();
  }

  Future<void> _afterAuthentication() async {
    final remote = _requireRemote();
    final userId = remote.currentUserId!;
    final localCipher = await _keyStore.read(userId);
    if (localCipher != null) {
      _setReady(localCipher);
      schedule(const Duration(milliseconds: 100));
      return;
    }
    final profile = await remote.fetchVaultProfile();
    state = SyncState(
      status: SyncStatus.needsVault,
      email: remote.currentUserEmail,
      vaultExists: profile != null,
    );
  }

  void _startAuthListener() {
    _authSubscription ??= _remote?.watchAuthenticatedSession().listen(
          (_) => unawaited(_handleAuthenticatedSession()),
          onError: (Object error, StackTrace stackTrace) => _setError(error),
        );
  }

  Future<void> _handleAuthenticatedSession() {
    final active = _activeAuthTransition;
    if (active != null) return active;
    final future = _processAuthenticatedSession();
    _activeAuthTransition = future;
    return future.whenComplete(() => _activeAuthTransition = null);
  }

  Future<void> _processAuthenticatedSession() async {
    if (_remote?.currentUserId == null || state.isConnected) return;
    try {
      await _afterAuthentication();
    } catch (error) {
      _setError(error);
    }
  }

  void _setReady(AppCipher cipher, {String? recoveryCode}) {
    final previousCipher = state.cipher;
    state = SyncState(
      status: SyncStatus.ready,
      email: _remote?.currentUserEmail,
      cipher: cipher,
      recoveryCode: recoveryCode,
    );
    if (!identical(previousCipher, cipher)) previousCipher?.destroy();
    _startAutomaticSync();
  }

  void _startAutomaticSync() {
    _remoteSubscription?.cancel();
    _remoteSubscription = _remote?.watchChanges().listen(
          (_) => schedule(const Duration(milliseconds: 350)),
          onError: (_, __) {},
        );
    _periodic?.cancel();
    _periodic = Timer.periodic(
      const Duration(minutes: 2),
      (_) => schedule(Duration.zero),
    );
  }

  void _stopAutomaticSync() {
    _debounce?.cancel();
    _periodic?.cancel();
    _remoteSubscription?.cancel();
    _remoteSubscription = null;
  }

  void _setError(Object error, {bool needsVault = false}) {
    state = state.copyWith(
      status: needsVault ? SyncStatus.needsVault : SyncStatus.error,
      error: error.toString(),
    );
  }

  SyncRemoteStore _requireRemote() {
    final remote = _remote;
    if (remote == null) throw StateError('Supabase is not configured');
    return remote;
  }

  @override
  void dispose() {
    _stopAutomaticSync();
    _authSubscription?.cancel();
    state.cipher?.destroy();
    super.dispose();
  }
}
