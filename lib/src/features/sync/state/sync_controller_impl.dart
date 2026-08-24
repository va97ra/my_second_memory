import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_domain/ez_domain.dart';
import 'package:ez_data/ez_data.dart';
import 'sync_state.dart';

class SyncController extends StateNotifier<SyncState> {
  SyncController({
    required SyncRemoteStore? remote,
    required SyncKeyStore keyStore,
    required SyncTombstoneStore tombstones,
    bool Function()? canAccessLocalData,
    required Future<List<MemoryItem>> Function() readMemoryItems,
    required Future<void> Function(List<MemoryItem>) replaceMemoryItems,
    Future<void> Function(List<MemoryItem>, List<MemoryItem>)? mergeMemoryItems,
    Future<List<ShiftSchedule>> Function()? readShiftSchedules,
    Future<void> Function(List<ShiftSchedule>)? replaceShiftSchedules,
    Future<List<AccountItem>> Function()? readAccounts,
    Future<void> Function(List<AccountItem>)? replaceAccounts,
    Future<List<RecurrenceSeries>> Function()? readRecurrenceSeries,
    Future<void> Function(List<RecurrenceSeries>)? replaceRecurrenceSeries,
    Future<void> Function(List<RecurrenceSeries>, List<RecurrenceSeries>)?
        mergeRecurrenceSeries,
    Future<List<RecurrenceOccurrenceException>> Function()?
        readRecurrenceExceptions,
    Future<void> Function(List<RecurrenceOccurrenceException>)?
        replaceRecurrenceExceptions,
    Future<void> Function(
      List<RecurrenceOccurrenceException>,
      List<RecurrenceOccurrenceException>,
    )? mergeRecurrenceExceptions,
  })  : _remote = remote,
        _keyStore = keyStore,
        _tombstones = tombstones,
        _canAccessLocalData = canAccessLocalData ?? _alwaysAccessible,
        _readMemoryItems = readMemoryItems,
        _mergeMemoryItems = mergeMemoryItems ??
            ((items, _) => replaceMemoryItems(items)),
        _readShiftSchedules = readShiftSchedules ?? _readNoShiftSchedules,
        _replaceShiftSchedules =
            replaceShiftSchedules ?? _replaceNoShiftSchedules,
        _readAccounts = readAccounts ?? _readNoAccounts,
        _replaceAccounts = replaceAccounts ?? _replaceNoAccounts,
        _readRecurrenceSeries = readRecurrenceSeries ?? _readNoRecurrenceSeries,
        _mergeRecurrenceSeries = mergeRecurrenceSeries ??
            ((items, _) => (replaceRecurrenceSeries ??
                _replaceNoRecurrenceSeries)(items)),
        _readRecurrenceExceptions =
            readRecurrenceExceptions ?? _readNoRecurrenceExceptions,
        _mergeRecurrenceExceptions = mergeRecurrenceExceptions ??
            ((items, _) => (replaceRecurrenceExceptions ??
                _replaceNoRecurrenceExceptions)(items)),
        super(remote == null
            ? const SyncState.unconfigured()
            : const SyncState(status: SyncStatus.loading));

  final SyncRemoteStore? _remote;
  final SyncKeyStore _keyStore;
  final SyncTombstoneStore _tombstones;
  final bool Function() _canAccessLocalData;
  final Future<List<MemoryItem>> Function() _readMemoryItems;
  final Future<void> Function(List<MemoryItem>, List<MemoryItem>)
      _mergeMemoryItems;
  final Future<List<ShiftSchedule>> Function() _readShiftSchedules;
  final Future<void> Function(List<ShiftSchedule>) _replaceShiftSchedules;
  final Future<List<AccountItem>> Function() _readAccounts;
  final Future<void> Function(List<AccountItem>) _replaceAccounts;
  final Future<List<RecurrenceSeries>> Function() _readRecurrenceSeries;
  final Future<void> Function(List<RecurrenceSeries>, List<RecurrenceSeries>)
      _mergeRecurrenceSeries;
  final Future<List<RecurrenceOccurrenceException>> Function()
      _readRecurrenceExceptions;
  final Future<void> Function(
    List<RecurrenceOccurrenceException>,
    List<RecurrenceOccurrenceException>,
  ) _mergeRecurrenceExceptions;
  final SyncVaultCrypto _vaultCrypto = const SyncVaultCrypto();
  StreamSubscription<void>? _remoteSubscription;
  StreamSubscription<void>? _authSubscription;
  Timer? _debounce;
  Timer? _periodic;
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

  Future<bool> register(String email, String password) {
    return _attemptSignIn((remote) async {
      final result = await remote.signUp(email.trim(), password);
      if (!result.hasSession) {
        // Учётная запись создана, но письмо ещё не подтверждено: это не
        // ошибка, а ожидание, и экран должен показать именно его.
        state = SyncState(
          status: SyncStatus.awaitingEmailConfirmation,
          email: email.trim(),
        );
        return false;
      }
      await _afterAuthentication();
      return true;
    });
  }

  Future<bool> resendSignupConfirmation() async {
    final remote = _requireRemote();
    final email = state.email;
    if (email == null || email.isEmpty) return false;
    state = state.copyWith(
      status: SyncStatus.resendingEmailConfirmation,
      confirmationResent: false,
      clearError: true,
    );
    try {
      await remote.resendSignupConfirmation(email);
      state = state.copyWith(
        status: SyncStatus.awaitingEmailConfirmation,
        confirmationResent: true,
        clearError: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        status: SyncStatus.awaitingEmailConfirmation,
        confirmationResent: false,
        error: error.toString(),
      );
      return false;
    }
  }

  Future<bool> signIn(String email, String password) {
    return _attemptSignIn((remote) async {
      await remote.signIn(email.trim(), password);
      await _afterAuthentication();
      return true;
    });
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

  void returnToSignIn() {
    if (_remote?.currentUserId != null) return;
    state = const SyncState(status: SyncStatus.signedOut);
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
    final cipher = state.cipher!;
    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      final memoryItems = await _readMemoryItems();
      final shiftSchedules = await _readShiftSchedules();
      final accounts = await _readAccounts();
      final recurrenceSeries = await _readRecurrenceSeries();
      final recurrenceExceptions = await _readRecurrenceExceptions();
      final result = await AppSyncEngine(
        remote: _remote!,
        cipher: cipher,
        tombstones: _tombstones,
      ).synchronize(
        memoryItems: memoryItems,
        replaceMemoryItems: (items) =>
            _mergeMemoryItems(items, memoryItems),
        shiftSchedules: shiftSchedules,
        replaceShiftSchedules: _replaceShiftSchedules,
        accounts: accounts,
        replaceAccounts: _replaceAccounts,
        recurrenceSeries: recurrenceSeries,
        replaceRecurrenceSeries: (items) =>
            _mergeRecurrenceSeries(items, recurrenceSeries),
        recurrenceExceptions: recurrenceExceptions,
        replaceRecurrenceExceptions: (items) =>
            _mergeRecurrenceExceptions(items, recurrenceExceptions),
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
    if (!state.isConnected || !_canAccessLocalData()) return;
    _debounce?.cancel();
    _debounce = Timer(delay, syncNow);
  }

  void localDataAvailabilityChanged(bool isAvailable) {
    if (!isAvailable) {
      _debounce?.cancel();
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

bool _alwaysAccessible() => true;

Future<List<ShiftSchedule>> _readNoShiftSchedules() async => const [];

Future<void> _replaceNoShiftSchedules(List<ShiftSchedule> _) async {}

Future<List<AccountItem>> _readNoAccounts() async => const [];

Future<void> _replaceNoAccounts(List<AccountItem> _) async {}

Future<List<RecurrenceSeries>> _readNoRecurrenceSeries() async => const [];

Future<void> _replaceNoRecurrenceSeries(List<RecurrenceSeries> _) async {}

Future<List<RecurrenceOccurrenceException>>
    _readNoRecurrenceExceptions() async => const [];

Future<void> _replaceNoRecurrenceExceptions(
  List<RecurrenceOccurrenceException> _,
) async {}
