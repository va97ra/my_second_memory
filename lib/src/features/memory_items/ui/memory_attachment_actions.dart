import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import '../state/memory_attachment_service.dart';
import '../state/memory_editor_controller.dart';
import 'widgets/image_source_sheet.dart';

/// Вложения записи: фотографии и голос.
class MemoryAttachmentActions {
  const MemoryAttachmentActions({
    required this.context,
    required this.controller,
    required this.attachments,
    required this.imagePicker,
  });

  final BuildContext context;
  final MemoryEditorController controller;
  final MemoryAttachmentService attachments;
  final ImagePicker imagePicker;

  Future<void> pickImage() async {
    final file = kIsWeb ? await _pickImageForWeb() : await _pickImageForIo();
    if (file == null) return;
    final stored = await attachments.importImage(file);
    controller.applyForm(
      (form) => form.copyWith(imagePaths: [...form.imagePaths, stored]),
    );
  }

  /// В вебе камеры нет, а выбор файла идёт системным диалогом.
  Future<XFile?> _pickImageForWeb() {
    const imageGroup = file_selector.XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );
    return file_selector.openFile(acceptedTypeGroups: [imageGroup]);
  }

  Future<XFile?> _pickImageForIo() async {
    final source = await askImageSource(context);
    if (source == null) return null;
    return imagePicker.pickImage(source: source, imageQuality: 92);
  }

  Future<void> startVoice() async {
    if (!await attachments.startVoice()) return;
    controller.update(() => controller.isRecording = true);
  }

  Future<void> stopAndSaveVoice() async {
    final recording = await attachments.stopVoice();
    controller.update(() {
      controller.isRecording = false;
      if (recording != null) {
        controller.form = controller.form.copyWith(
          audioPath: recording.path,
          audioDurationSeconds: recording.durationSeconds,
        );
      }
    });
    controller.scheduleAutosave();
  }
}
