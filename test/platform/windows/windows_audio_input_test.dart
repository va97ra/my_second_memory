import 'package:ezhednevnik_v2/src/platform/windows/windows_audio_input.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('ezhednevnik/audio_input');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('the identifier is taken from the shell', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'defaultCaptureDeviceId');
      return '{0.0.1.00000000}.{микрофон}';
    });

    expect(
      await const WindowsAudioInput().defaultCaptureDeviceId(),
      '{0.0.1.00000000}.{микрофон}',
    );
  });

  test('without the channel the choice stays with the system', () async {
    // Так это выглядит на телефоне: канала нет, и назвать устройство нечем.
    expect(await const WindowsAudioInput().defaultCaptureDeviceId(), isNull);
  });

  test('a failure on the shell side is not fatal', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'unavailable');
    });

    expect(await const WindowsAudioInput().defaultCaptureDeviceId(), isNull);
  });
}
