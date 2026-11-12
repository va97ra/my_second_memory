import 'package:ez_data/ez_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Местный журнал необработанных ошибок. В `main` подменяется тем же
/// экземпляром, который ловит ошибки, — пишет и читает одна очередь.
final errorJournalProvider = Provider<ErrorJournal>((ref) => ErrorJournal());
