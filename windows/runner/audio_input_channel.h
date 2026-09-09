#ifndef RUNNER_AUDIO_INPUT_CHANNEL_H_
#define RUNNER_AUDIO_INPUT_CHANNEL_H_

#include <flutter/binary_messenger.h>

// Канал, по которому Dart спрашивает у Windows выбранный микрофон.
//
// Плагин записи такого не отдаёт, а без явного указания устройства Media
// Foundation берёт *коммуникационное* устройство — в Windows это отдельная
// настройка, и указывать она может на другой микрофон, чем тот, что выбран
// в параметрах звука.
void RegisterAudioInputChannel(flutter::BinaryMessenger* messenger);

#endif  // RUNNER_AUDIO_INPUT_CHANNEL_H_
