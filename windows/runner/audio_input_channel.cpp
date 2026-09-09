#include "audio_input_channel.h"

#include <windows.h>

#include <mmdeviceapi.h>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <optional>
#include <string>

namespace {

// Идентификатор микрофона, который в параметрах звука значится «устройством
// по умолчанию», — это роль eConsole. Роль eCommunications там же может
// указывать на другое устройство, и именно её берёт Media Foundation, когда
// устройство не названо.
std::optional<std::string> DefaultCaptureDeviceId() {
  IMMDeviceEnumerator* enumerator = nullptr;
  HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr,
                                CLSCTX_ALL, IID_PPV_ARGS(&enumerator));
  if (FAILED(hr) || enumerator == nullptr) {
    return std::nullopt;
  }

  IMMDevice* device = nullptr;
  hr = enumerator->GetDefaultAudioEndpoint(eCapture, eConsole, &device);
  enumerator->Release();
  if (FAILED(hr) || device == nullptr) {
    return std::nullopt;
  }

  LPWSTR wide_id = nullptr;
  hr = device->GetId(&wide_id);
  device->Release();
  if (FAILED(hr) || wide_id == nullptr) {
    return std::nullopt;
  }

  const int size = ::WideCharToMultiByte(CP_UTF8, 0, wide_id, -1, nullptr, 0,
                                         nullptr, nullptr);
  std::optional<std::string> result;
  if (size > 1) {
    std::string id(static_cast<size_t>(size) - 1, '\0');
    ::WideCharToMultiByte(CP_UTF8, 0, wide_id, -1, id.data(), size, nullptr,
                          nullptr);
    result = id;
  }
  ::CoTaskMemFree(wide_id);
  return result;
}

// Канал должен жить всё время работы приложения, поэтому хранится здесь, а не
// на стеке вызова.
std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel;

}  // namespace

void RegisterAudioInputChannel(flutter::BinaryMessenger* messenger) {
  channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "ezhednevnik/audio_input",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() != "defaultCaptureDeviceId") {
          result->NotImplemented();
          return;
        }
        const std::optional<std::string> id = DefaultCaptureDeviceId();
        if (id.has_value()) {
          result->Success(flutter::EncodableValue(*id));
        } else {
          // Спросить систему не удалось — пусть выбирает сама, как и раньше.
          result->Success(flutter::EncodableValue());
        }
      });
}
