#include "gvml_clipboard_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <vector>

static void SetGvmlClipboard(const std::vector<uint8_t>& zip_bytes,
                              std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  UINT format_id = RegisterClipboardFormatA("Art::GVML ClipFormat");
  if (format_id == 0) {
    result->Error("CLIPBOARD_ERROR", "Failed to register clipboard format");
    return;
  }

  if (!OpenClipboard(nullptr)) {
    result->Error("CLIPBOARD_ERROR", "Failed to open clipboard");
    return;
  }

  EmptyClipboard();

  HGLOBAL h_global = GlobalAlloc(GMEM_MOVEABLE, zip_bytes.size());
  if (h_global == nullptr) {
    CloseClipboard();
    result->Error("CLIPBOARD_ERROR", "Failed to allocate global memory");
    return;
  }

  void* p_data = GlobalLock(h_global);
  if (p_data == nullptr) {
    GlobalFree(h_global);
    CloseClipboard();
    result->Error("CLIPBOARD_ERROR", "Failed to lock global memory");
    return;
  }

  memcpy(p_data, zip_bytes.data(), zip_bytes.size());
  GlobalUnlock(h_global);

  HANDLE h_result = SetClipboardData(format_id, h_global);
  CloseClipboard();

  if (h_result == nullptr) {
    result->Error("CLIPBOARD_ERROR", "Failed to set clipboard data");
    return;
  }

  result->Success(flutter::EncodableValue(true));
}

void RegisterGvmlClipboardPlugin(flutter::FlutterEngine* engine) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      engine->messenger(), "palletier/clipboard",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "setGvmlClipboard") {
          const auto* args = std::get_if<std::vector<uint8_t>>(call.arguments());
          if (args == nullptr) {
            result->Error("INVALID_ARGUMENT", "Expected Uint8List argument");
            return;
          }
          SetGvmlClipboard(*args, std::move(result));
        } else {
          result->NotImplemented();
        }
      });

  // prevent channel from being destroyed
  // The prevent-destruction trick: store as static
  static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> s_channel;
  s_channel = std::move(channel);
}
