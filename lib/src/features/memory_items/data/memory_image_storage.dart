import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MemoryImageStorage {
  Future<String> savePickedImage(XFile file) async {
    final directory = await getApplicationDocumentsDirectory();
    final extension = _safeExtension(file.name);
    final fileName = 'image_${DateTime.now().microsecondsSinceEpoch}$extension';
    final destinationPath = p.join(directory.path, fileName);
    await file.saveTo(destinationPath);
    return destinationPath;
  }

  String _safeExtension(String name) {
    final extension = p.extension(name).toLowerCase();
    return switch (extension) {
      '.jpg' || '.jpeg' || '.png' || '.gif' || '.webp' => extension,
      _ => '.jpg',
    };
  }
}
