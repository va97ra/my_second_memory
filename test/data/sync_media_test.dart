import 'dart:typed_data';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sync_test_support.dart';

void main() {
  final vault = AppCipher.fromKeyBytes(List.filled(32, 7));
  final atRest = AppCipher.fromKeyBytes(List.filled(32, 9));

  MemoryItem itemWith({
    String id = 'record',
    List<String> images = const [],
    String? audio,
  }) {
    return MemoryItem(
      id: id,
      type: MemoryType.note,
      memoryDate: DateTime.utc(2026, 9, 9),
      title: 'Запись',
      createdAt: DateTime.utc(2026, 9, 9),
      updatedAt: DateTime.utc(2026, 9, 9),
      imagePaths: images,
      voiceNotes: [
        if (audio != null)
          VoiceNote(reference: audio, durationSeconds: 4),
      ],
    );
  }

  test('a file present here and missing in the cloud is uploaded', () async {
    final remote = SyncRemote();
    final storage = FakeMediaStorage({'image_1.jpg': _bytes([1, 2, 3])});

    final result = await MediaSyncEngine(
      remote: remote,
      storage: storage,
      vault: vault,
      atRest: null,
    ).synchronize([itemWith(images: ['image_1.jpg'])]);

    expect(result.mediaUploaded, 1);
    expect(result.mediaDownloaded, 0);
    expect(remote.storedMedia.keys, ['image_1.jpg']);
    // В облаке лежит шифротекст, а не сам снимок.
    expect(remote.storedMedia['image_1.jpg'], isNot(_bytes([1, 2, 3])));
    expect(
      await vault.decryptBytes(remote.storedMedia['image_1.jpg']!),
      _bytes([1, 2, 3]),
    );
  });

  test('a file present in the cloud and missing here is downloaded', () async {
    final remote = SyncRemote();
    remote.storedMedia['voice_2.m4a'] = await vault.encryptBytes([4, 5]);
    final storage = FakeMediaStorage({});

    final result = await MediaSyncEngine(
      remote: remote,
      storage: storage,
      vault: vault,
      atRest: null,
    ).synchronize([itemWith(audio: 'voice_2.m4a')]);

    expect(result.mediaDownloaded, 1);
    expect(result.mediaUploaded, 0);
    expect(storage.files['voice_2.m4a'], _bytes([4, 5]));
  });

  test('a device with a PIN keeps the incoming file encrypted', () async {
    final remote = SyncRemote();
    remote.storedMedia['image_3.jpg'] = await vault.encryptBytes([6]);
    final storage = FakeMediaStorage({});

    await MediaSyncEngine(
      remote: remote,
      storage: storage,
      vault: vault,
      atRest: atRest,
    ).synchronize([itemWith(images: ['image_3.jpg'])]);

    expect(storage.atRestUsed, isTrue);
    expect(storage.files['image_3.jpg'], _bytes([6]));
  });

  test('what no record refers to leaves the cloud', () async {
    final remote = SyncRemote();
    remote.storedMedia['image_kept.jpg'] = await vault.encryptBytes([1]);
    remote.storedMedia['image_orphan.jpg'] = await vault.encryptBytes([2]);
    final storage = FakeMediaStorage({'image_kept.jpg': _bytes([1])});

    await MediaSyncEngine(
      remote: remote,
      storage: storage,
      vault: vault,
      atRest: null,
    ).synchronize([itemWith(images: ['image_kept.jpg'])]);

    expect(remote.storedMedia.keys, ['image_kept.jpg']);
  });

  test('a record keeps the plain name whatever the path it arrived with',
      () async {
    final remote = SyncRemote();
    final storage = FakeMediaStorage({'image_4.jpg': _bytes([8])});

    // Запись со старого устройства: абсолютный путь и хвост шифрования.
    await MediaSyncEngine(
      remote: remote,
      storage: storage,
      vault: vault,
      atRest: null,
    ).synchronize([
      itemWith(images: ['/data/user/0/app/files/image_4.jpg.ezm']),
    ]);

    expect(remote.storedMedia.keys, ['image_4.jpg']);
  });

  test('a photo living inside the record is not a file', () async {
    final remote = SyncRemote();
    final storage = FakeMediaStorage({});

    final result = await MediaSyncEngine(
      remote: remote,
      storage: storage,
      vault: vault,
      atRest: null,
    ).synchronize([
      itemWith(images: ['data:image/png;base64,AAAA']),
    ]);

    expect(result.mediaUploaded, 0);
    expect(remote.storedMedia, isEmpty);
  });

  test('one failed file does not stop the rest', () async {
    final remote = FailingUploadRemote(failFor: 'image_bad.jpg');
    final storage = FakeMediaStorage({
      'image_bad.jpg': _bytes([1]),
      'image_good.jpg': _bytes([2]),
    });

    final result = await MediaSyncEngine(
      remote: remote,
      storage: storage,
      vault: vault,
      atRest: null,
    ).synchronize([
      itemWith(images: ['image_bad.jpg', 'image_good.jpg']),
    ]);

    expect(result.mediaFailed, 1);
    expect(result.mediaUploaded, 1);
    expect(remote.storedMedia.keys, ['image_good.jpg']);
  });
}

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

/// Вложения в памяти: настоящему хранилищу нужен каталог документов, которого
/// в тесте нет.
class FakeMediaStorage extends MediaStorage {
  FakeMediaStorage(this.files);

  final Map<String, Uint8List> files;
  bool atRestUsed = false;

  @override
  Future<bool> exists(String reference) async =>
      files.containsKey(MediaStorage.referenceFor(reference));

  @override
  Future<Uint8List> readPlainBytes(String reference, AppCipher? atRest) async {
    final bytes = files[MediaStorage.referenceFor(reference)];
    if (bytes == null) throw StateError('No file $reference');
    return bytes;
  }

  @override
  Future<void> writePlainBytes(
    String reference,
    Uint8List bytes,
    AppCipher? atRest,
  ) async {
    if (atRest != null) atRestUsed = true;
    files[MediaStorage.referenceFor(reference)] = bytes;
  }
}

class FailingUploadRemote extends SyncRemote {
  FailingUploadRemote({required this.failFor});

  final String failFor;

  @override
  Future<void> uploadMedia(String name, Uint8List bytes) async {
    if (name == failFor) throw StateError('network is gone');
    return super.uploadMedia(name, bytes);
  }
}
