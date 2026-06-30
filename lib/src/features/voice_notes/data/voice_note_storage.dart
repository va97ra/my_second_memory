import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class VoiceNoteStorage {
  Future<String> buildNewPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
    return p.join(directory.path, fileName);
  }
}
