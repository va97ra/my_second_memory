import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/security_service.dart';

final securityServiceProvider = Provider<SecurityService>(
  (ref) => SecurityService(),
);
