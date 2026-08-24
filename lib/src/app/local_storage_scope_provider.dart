import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_data/ez_data.dart';

final localStorageScopeFactoryProvider =
    Provider<LocalStorageScope Function()>((ref) {
  return createLocalStorageScope;
});

final localStorageScopeProvider = Provider<LocalStorageScope>((ref) {
  final scope = ref.watch(localStorageScopeFactoryProvider)();
  ref.onDispose(() => unawaited(scope.close()));
  return scope;
});
