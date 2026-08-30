import 'package:ez_domain/ez_domain.dart';

abstract interface class ToolDataRepository {
  Future<ToolDataSnapshot> load();

  Future<void> replaceAll(ToolDataSnapshot snapshot);
}
