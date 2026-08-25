import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_domain/ez_domain.dart';
import 'package:ez_data/ez_data.dart';
import 'sync_data_sources.dart';
import 'sync_runner.dart';
import 'sync_scheduler.dart';
import 'sync_state.dart';

class SyncController extends StateNotifier<SyncState> {
  SyncController({
    required SyncRemoteStore? remote,
    required SyncKeyStore keyStore,
    required SyncTombstoneStore tombstones,
    required SyncDataSources data,
    bool Function()? canAccessLocalData,
  })  : _remote = remote,
        _keyStore = keyStore,
        _tombstones = tombstones,
        _data = data,
        _canAccessLocalData = canAccessLocalData ?? _alwaysAccessible,
        super(remote == null
            ? const SyncState.unconfigured()
            : const SyncState(status: SyncStatus.loading)) {
    _scheduler = SyncScheduler(
      run: syncNow,
      canRun: () => state.isConnected && _canAccessLocalData(),
    );
  }

  final SyncRemoteStore? _remote;
  final SyncKeyStore _keyStore;
  final SyncTombstoneStore _tombstones;
  final SyncDataSources _data;
  final bool Function() _canAccessLocalData;
  late final SyncScheduler _scheduler;
  final SyncVaultCrypto _vaultCrypto = const SyncVaultCrypto();
  StreamSubscription<void>? _authSubscription;
  Future<void>? _activeSync;
  Future<void>? _activeAuthTransition;
  bool _loaded = false;
  bool _syncAgain = false;

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

  Future<bool> signInWithGoogle() {
    return _attemptSignIn((remote) async {
      final launched = await remote.signInWithGoogle();
      if (!launched) {
        throw StateError('Could not open Google sign in');
      }
      if (remote.currentUserId != null) {
        await _afterAuthentication();
      } else {
        // Браузер открылся, но вернулся без сессии: ждём, пока человек
        // закончит вход, и не показываем это ошибкой.
        state = const SyncState(status: SyncStatus.signedOut);
      }
      return true;
    });
  }

  /// Общий ход входа: пометить ожидание, выполнить шаг, свернуть любую
  /// неудачу в состояние ошибки.
  Future<bool> _attemptSignIn(
    Future<bool> Function(SyncRemoteStore remote) step,
  ) async {
    final remote = _requireRemote();
    state = state.copyWith(status: SyncStatus.loading, clearError: true);
    try {
      return await step(remote);
    } catch (error) {
      _setError(error);
      return false;
    }
  }

  Future<bool> connectVault(String password) {
    return _openVault((remote, hold) async {
      final profile = await remote.fetchVaultProfile();
      if (profile != null) {
        hold(await _vaultCrypto.unlock(profile, password));
        return null;
      }
      final created = await _vaultCrypto.create(password);
      hold(created.cipher);
      await remote.createVaultProfile(created.profile);
      return created.recoveryCode;
    });
  }

  Future<bool> connectVaultWithRecoveryCode(String recoveryCode) {
    return _openVault((remote, hold) async {
      final profile = await remote.fetchVaultProfile();
      if (profile == null) {
        throw const FormatException('Synchronization vault does not exist');
      }
      hold(await _vaultCrypto.unlockWithRecoveryCode(profile, recoveryCode));
      return null;
    });
  }

  /// Общий ход подключения хранилища.
  ///
  /// [open] сообщает готовый ключ через `hold` сразу, как только тот создан:
  /// если следующий шаг сорвётся, ключ нужно уничтожить, а не оставить
  /// лежать в памяти. Возвращённый код восстановления показывается один раз.
  Future<bool> _openVault(
    Future<String?> Function(
      SyncRemoteStore remote,
      void Function(AppCipher cipher) hold,
    ) open,
  ) async {
    final remote = _requireRemote();
    final userId = remote.currentUserId;
    if (userId == null) return false;
    state = state.copyWith(status: SyncStatus.loading, clearError: true);
    AppCipher? cipher;
    try {
      final recoveryCode = await open(remote, (opened) => cipher = opened);
      await _keyStore.save(userId, cipher!);
      _setReady(cipher!, recoveryCode: recoveryCode);
      await syncNow();
      return true;
    } catch (error) {
      cipher?.destroy();
      _setError(error, needsVault: true);
      return false;
    }
  }

  Future<void> syncNow() {
    final active = _activeSync;
    if (active != null) {
      _syncAgain = true;
      return active;
    }
    if (!_canAccessLocalData() ||
        state.cipher == null ||
        _remote?.currentUserId == null) {
      return Future.value();
    }
    final future = _runSyncUntilIdle();
    _activeSync = future;
    return future.whenComplete(() => _activeSync = null);
  }

  Future<void> _runSyncUntilIdle() async {
    do {
      _syncAgain = false;
      await _runSync();
    } while (_syncAgain &&
        _canAccessLocalData() &&
        state.cipher != null &&
        _remote?.currentUserId != null);
  }

  Future<void> _runSync() async {
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      final result = await SyncRunner(
        remote: _remote!,
        tombstones: _tombstones,
        data: _data,
      ).run(state.cipher!);
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

  void schedule([Duration delay = const Duration(milliseconds: 900)]) =>
      _scheduler.schedule(delay);

  /// Пока данные заперты PIN-ом, читать их нечем: ждём разблокировки.
  void localDataAvailabilityChanged(bool isAvailable) {
    if (!isAvailable) {
      _scheduler.cancelPending();
      return;
    }
    schedule(Duration.zero);
  }

  Future<void> recordDeletion(
    SyncEntityKind kind,
    String id,
    DateTime deletedAt,
  ) async {
    final userId = _remote?.currentUserId;
    if (userId == null) return;
    await _tombstones.markDeleted(userId, id, deletedAt, kind: kind);
    if (state.isConnected) schedule();
  }

  Future<DateTime?> deletionTime(SyncEntityKind kind, String id) async {
    final userId = _remote?.currentUserId;
    if (userId == null) return null;
    return (await _tombstones.read(userId, kind: kind))[id];
  }

  Future<Map<String, DateTime>> deletionTimes(SyncEntityKind kind) async {
    final userId = _remote?.currentUserId;
    if (userId == null) return const {};
    return _tombstones.read(userId, kind: kind);
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

  void _startAutomaticSync() => _scheduler.start(_remote?.watchChanges());

  void _stopAutomaticSync() => _scheduler.stop();

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

bool _alwaysAccessible() => true;
