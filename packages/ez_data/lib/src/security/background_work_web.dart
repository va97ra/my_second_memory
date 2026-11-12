import 'dart:async';

/// В вебе изолятов нет: работа идёт на месте, как и раньше.
Future<R> inBackground<R>(FutureOr<R> Function() work) async => work();
