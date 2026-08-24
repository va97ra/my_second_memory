import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Спрашивает, откуда взять фотографию: из галереи или с камеры.
Future<ImageSource?> askImageSource(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => const ImageSourceSheet(),
  );
}

/// Выбор источника фотографии.
class ImageSourceSheet extends StatelessWidget {
  const ImageSourceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: Text(strings.gallery),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded),
            title: Text(strings.camera),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
        ],
      ),
    );
  }
}
