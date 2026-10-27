#include "resource_window.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <irondash_engine_context/irondash_engine_context_plugin_c_api.h>
#include <super_native_extensions/super_native_extensions_plugin_c_api.h>

#include <cwchar>

namespace {
constexpr char kChannel[] = "com.nailauncher/resource_window_native";

// WM_CLOSE is posted, not sent: disposing the engine inside its own method
// handler would destroy the messenger while it is still sending the reply.
BOOL CALLBACK CloseOwnedResource(HWND hwnd, LPARAM owner) {
  wchar_t class_name[128] = {};
  GetClassNameW(hwnd, class_name, 128);
  if (GetWindow(hwnd, GW_OWNER) == reinterpret_cast<HWND>(owner) &&
      std::wcscmp(class_name, L"FLUTTER_MULTI_WINDOW_WIN32_WINDOW") == 0) {
    PostMessage(hwnd, WM_CLOSE, 0, 0);
  }
  return TRUE;
}
}  // namespace

void RegisterResourceWindowHost(flutter::FlutterEngine* engine, HWND owner) {
  flutter::MethodChannel<flutter::EncodableValue> channel(
      engine->messenger(), kChannel,
      &flutter::StandardMethodCodec::GetInstance());
  channel.SetMethodCallHandler([owner](const auto& call, auto result) {
    if (call.method_name() == "closeAll") {
      EnumThreadWindows(GetCurrentThreadId(), CloseOwnedResource,
                        reinterpret_cast<LPARAM>(owner));
      result->Success();
    } else {
      result->NotImplemented();
    }
  });
}

void RegisterResourceWindowPlugins(flutter::FlutterViewController* controller,
                                   HWND owner) {
  auto* engine = controller->engine();
  // desktop_multi_window registers its per-window channel after this callback.
  // Its normal registrant guards against duplicate HWND attachment, but full
  // RegisterPlugins would still replace window_manager's process-global channel.
  IrondashEngineContextPluginCApiRegisterWithRegistrar(
      engine->GetRegistrarForPlugin("IrondashEngineContextPluginCApi"));
  SuperNativeExtensionsPluginCApiRegisterWithRegistrar(
      engine->GetRegistrarForPlugin("SuperNativeExtensionsPluginCApi"));

  HWND hwnd = GetAncestor(controller->view()->GetNativeWindow(), GA_ROOT);
  // An owned top-level window can leave the client area / move to another
  // monitor. Win32 hides it with its minimized owner and destroys it with
  // the owner. Tray-close explicitly posts closeAll before hiding the owner.
  // This is NOT a child (WS_CHILD) or runner subclass.
  SetWindowLongPtr(hwnd, GWLP_HWNDPARENT, reinterpret_cast<LONG_PTR>(owner));

  flutter::MethodChannel<flutter::EncodableValue> channel(
      engine->messenger(), kChannel,
      &flutter::StandardMethodCodec::GetInstance());
  channel.SetMethodCallHandler([hwnd](const auto& call, auto result) {
    if (call.method_name() == "setAlwaysOnTop") {
      const auto* enabled =
          std::get_if<bool>(call.arguments());
      if (enabled == nullptr) {
        result->Error("invalid_arguments", "Expected a boolean.");
        return;
      }
      if (!SetWindowPos(hwnd, *enabled ? HWND_TOPMOST : HWND_NOTOPMOST,
                        0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE)) {
        result->Error("window_operation_failed", "SetWindowPos failed.");
        return;
      }
      result->Success();
    } else if (call.method_name() == "close") {
      PostMessage(hwnd, WM_CLOSE, 0, 0);
      result->Success();
    } else {
      result->NotImplemented();
    }
  });
}
