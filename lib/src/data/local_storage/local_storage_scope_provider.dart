import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_storage_scope.dart';
import 'local_storage_scope_factory.dart';

final localStorageScopeFactoryProvider =
    Provider<LocalStorageScope Function()>((ref) {
  return createLocalStorageScope;
});

final localStorageScopeProvider = Provider<LocalStorageScope>((ref) {
  final scope = ref.watch(localStorageScopeFactoryProvider)();
  ref.onDispose(() => unawaited(scope.close()));
  return scope;
});
