#include "resource_window.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <irondash_engine_context/irondash_engine_context_plugin_c_api.h>
#include <super_native_extensions/super_native_extensions_plugin_c_api.h>

#include <cwchar>
#include <commctrl.h>
#include <algorithm>
#include <memory>
#include <string>

#pragma comment(lib, "comctl32.lib")

namespace {
constexpr char kChannel[] = "com.nailauncher/resource_window_native";
using Value = flutter::EncodableValue;
using Map = flutter::EncodableMap;
using Channel = flutter::MethodChannel<Value>;

struct ResourceState {
  std::unique_ptr<Channel> channel;
};

double Number(const Map& values, const char* key, double fallback) {
  const auto it = values.find(Value(key));
  if (it == values.end()) return fallback;
  if (const auto* number = std::get_if<double>(&it->second)) return *number;
  if (const auto* number = std::get_if<int32_t>(&it->second)) return *number;
  return fallback;
}

Value Layout(HWND hwnd) {
  RECT rect{};
  GetWindowRect(hwnd, &rect);
  const double scale = GetDpiForWindow(hwnd) / 96.0;
  return Value(Map{{Value("left"), Value(rect.left / scale)},
                   {Value("top"), Value(rect.top / scale)},
                   {Value("width"), Value((rect.right - rect.left) / scale)},
                   {Value("height"), Value((rect.bottom - rect.top) / scale)},
                   {Value("dpiScale"), Value(scale)}});
}

LRESULT CALLBACK ResourceProc(HWND hwnd, UINT message, WPARAM wparam,
                              LPARAM lparam, UINT_PTR id, DWORD_PTR data) {
  auto* state = reinterpret_cast<ResourceState*>(data);
  if (message == WM_GETMINMAXINFO) {
    auto* bounds = reinterpret_cast<MINMAXINFO*>(lparam);
    const double scale = GetDpiForWindow(hwnd) / 96.0;
    bounds->ptMinTrackSize = {static_cast<LONG>(560 * scale),
                              static_cast<LONG>(420 * scale)};
    return 0;
  }
  if (message == WM_EXITSIZEMOVE && !IsIconic(hwnd) && !IsZoomed(hwnd)) {
    state->channel->InvokeMethod("layout", std::make_unique<Value>(Layout(hwnd)));
  }
  if (message == WM_NCDESTROY) {
    RemoveWindowSubclass(hwnd, ResourceProc, id);
    delete state;
  }
  return DefSubclassProc(hwnd, message, wparam, lparam);
}

void Configure(HWND hwnd, const Map& args) {
  const auto title_it = args.find(Value("title"));
  if (title_it != args.end()) {
    if (const auto* title = std::get_if<std::string>(&title_it->second)) {
      const int size = MultiByteToWideChar(CP_UTF8, 0, title->data(),
                                           static_cast<int>(title->size()), nullptr, 0);
      std::wstring wide(size, L'\0');
      MultiByteToWideChar(CP_UTF8, 0, title->data(), static_cast<int>(title->size()), wide.data(), size);
      SetWindowTextW(hwnd, wide.c_str());
    }
  }
  const auto rect_it = args.find(Value("rect"));
  if (rect_it == args.end()) return;  // setTitle does not move the window
  const auto* rect = std::get_if<Map>(&rect_it->second);
  const Map empty;
  const auto& values = rect ? *rect : empty;
  double scale = Number(values, "dpiScale", GetDpiForWindow(hwnd) / 96.0);
  RECT target{static_cast<LONG>(Number(values, "left", 100) * scale),
              static_cast<LONG>(Number(values, "top", 100) * scale), 0, 0};
  target.right = target.left + static_cast<LONG>(Number(values, "width", 1040) * scale);
  target.bottom = target.top + static_cast<LONG>(Number(values, "height", 680) * scale);
  MONITORINFO monitor{sizeof(MONITORINFO)};
  GetMonitorInfoW(MonitorFromRect(&target, MONITOR_DEFAULTTONEAREST), &monitor);
  const auto& work = monitor.rcWork;
  const LONG width = std::min(std::max(target.right - target.left, static_cast<LONG>(560 * scale)), work.right - work.left);
  const LONG height = std::min(std::max(target.bottom - target.top, static_cast<LONG>(420 * scale)), work.bottom - work.top);
  const LONG left = std::clamp(target.left, work.left, work.right - width);
  const LONG top = std::clamp(target.top, work.top, work.bottom - height);
  SetWindowPos(hwnd, nullptr, left, top, width, height, SWP_NOZORDER | SWP_NOACTIVATE);
  const auto top_it = args.find(Value("alwaysOnTop"));
  if (top_it != args.end()) {
    const auto* enabled = std::get_if<bool>(&top_it->second);
    if (enabled) SetWindowPos(hwnd, *enabled ? HWND_TOPMOST : HWND_NOTOPMOST,
      0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
  }
}

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

  auto* state = new ResourceState{std::make_unique<Channel>(
      engine->messenger(), kChannel, &flutter::StandardMethodCodec::GetInstance())};
  SetWindowSubclass(hwnd, ResourceProc, 1, reinterpret_cast<DWORD_PTR>(state));
  state->channel->SetMethodCallHandler([hwnd](const auto& call, auto result) {
    if (call.method_name() == "configure" || call.method_name() == "setTitle") {
      Map values;
      if (const auto* map = std::get_if<Map>(call.arguments())) values = *map;
      if (const auto* title = std::get_if<std::string>(call.arguments())) values[Value("title")] = Value(*title);
      Configure(hwnd, values);
      result->Success();
    } else if (call.method_name() == "getLayout") {
      result->Success(Layout(hwnd));
    } else if (call.method_name() == "focus") {
      if (IsIconic(hwnd)) ShowWindow(hwnd, SW_RESTORE);
      SetForegroundWindow(hwnd);
      result->Success();
    } else if (call.method_name() == "setAlwaysOnTop") {
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
