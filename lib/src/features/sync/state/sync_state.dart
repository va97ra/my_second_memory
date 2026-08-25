import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';

enum SyncStatus {
  unconfigured,
  loading,
  signedOut,
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
