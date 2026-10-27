#include "resource_window.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <irondash_engine_context/irondash_engine_context_plugin_c_api.h>
#include <super_native_extensions/super_native_extensions_plugin_c_api.h>

#include <dwmapi.h>
#include <windowsx.h>
#include <cwchar>
#include <vector>
#include <cmath>
#include "studio_sandbox.h"
#include "resource_window_geometry.h"
#include <commctrl.h>
#include <algorithm>
#include <memory>
#include <string>

#pragma comment(lib, "comctl32.lib")
#pragma comment(lib, "dwmapi.lib")

namespace {
constexpr char kChannel[] = "com.nailauncher/resource_window_native";
using Value = flutter::EncodableValue;
using Map = flutter::EncodableMap;
using Channel = flutter::MethodChannel<Value>;

struct ResourceState {
  std::unique_ptr<Channel> channel;
  HWND view = nullptr;
  double bar_height = 0, reserved_right = 0;
  using Exclusion = resource_window_geometry::Exclusion;
  std::vector<Exclusion> exclusions;
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

bool IsWindows11() {
  using RtlGetVersionFn = LONG(WINAPI*)(OSVERSIONINFOW*);
  const auto fn = reinterpret_cast<RtlGetVersionFn>(GetProcAddress(GetModuleHandleW(L"ntdll.dll"), "RtlGetVersion"));
  OSVERSIONINFOW info{sizeof(info)};
  return fn && fn(&info) == 0 && info.dwBuildNumber >= 22000;
}

LRESULT HitTest(HWND hwnd, ResourceState* state, LPARAM lparam) {
  RECT outer{};
  GetWindowRect(hwnd, &outer);
  const int x = GET_X_LPARAM(lparam), y = GET_Y_LPARAM(lparam);
  const int edge = static_cast<int>(std::ceil(6 * GetDpiForWindow(hwnd) / 96.0));
  const auto border = resource_window_geometry::BorderHit(x - outer.left, y - outer.top,
      outer.right - outer.left, outer.bottom - outer.top, edge, IsZoomed(hwnd) != FALSE);
  if (border != HTCLIENT) return border;
  POINT point{x, y};
  ScreenToClient(hwnd, &point);
  const double scale = GetDpiForWindow(hwnd) / 96.0;
  const double lx = point.x / scale, ly = point.y / scale;
  RECT client{};
  GetClientRect(hwnd, &client);
  if (!resource_window_geometry::InTitle(lx, ly, client.right / scale,
      state->bar_height, state->reserved_right)) return HTCLIENT;
  for (const auto& rect : state->exclusions) {
    if (rect.Contains(lx, ly)) return HTCLIENT;
  }
  return HTCAPTION;
}

LRESULT CALLBACK ResourceViewProc(HWND view, UINT message, WPARAM wparam,
                                  LPARAM lparam, UINT_PTR id, DWORD_PTR data) {
  if (message == WM_NCHITTEST &&
      HitTest(GetAncestor(view, GA_ROOT), reinterpret_cast<ResourceState*>(data), lparam) != HTCLIENT) {
    return HTTRANSPARENT;
  }
  if (message == WM_NCDESTROY) RemoveWindowSubclass(view, ResourceViewProc, id);
  return DefSubclassProc(view, message, wparam, lparam);
}

LRESULT CALLBACK ResourceProc(HWND hwnd, UINT message, WPARAM wparam,
                              LPARAM lparam, UINT_PTR id, DWORD_PTR data) {
  auto* state = reinterpret_cast<ResourceState*>(data);
  if (message == WM_NCCALCSIZE) {
    auto* rect = wparam ? &reinterpret_cast<NCCALCSIZE_PARAMS*>(lparam)->rgrc[0]
                        : reinterpret_cast<RECT*>(lparam);
    MONITORINFO monitor{sizeof(monitor)};
    GetMonitorInfoW(MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST), &monitor);
    *rect = resource_window_geometry::ClientBounds(*rect, IsZoomed(hwnd) != FALSE,
        monitor.rcWork, IsWindows11());
    return 0;
  }
  if (message == WM_NCHITTEST) return HitTest(hwnd, state, lparam);
  if (message == WM_NCACTIVATE) return TRUE;
  if (message == WM_SIZE) {
    state->channel->InvokeMethod("maximizedChanged", std::make_unique<Value>(IsZoomed(hwnd) != FALSE));
  }
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
    if (IsWindow(state->view)) RemoveWindowSubclass(state->view, ResourceViewProc, 1);
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
      SetWindowTextW(hwnd, studio_sandbox::Title(wide).c_str());
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
  state->view = controller->view()->GetNativeWindow();
  SetWindowSubclass(hwnd, ResourceProc, 1, reinterpret_cast<DWORD_PTR>(state));
  SetWindowSubclass(state->view, ResourceViewProc, 1, reinterpret_cast<DWORD_PTR>(state));
  const MARGINS margins{1, 1, 1, 1};
  DwmExtendFrameIntoClientArea(hwnd, &margins);
  // DWMWA_WINDOW_CORNER_PREFERENCE / DWMWCP_ROUND (Win10 ignores it).
  const DWORD round = 2;
  DwmSetWindowAttribute(hwnd, 33, &round, sizeof(round));
  SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
      SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
  state->channel->SetMethodCallHandler([hwnd, state](const auto& call, auto result) {
    if (call.method_name() == "configure" || call.method_name() == "setTitle") {
      Map values;
      if (const auto* map = std::get_if<Map>(call.arguments())) values = *map;
      if (const auto* title = std::get_if<std::string>(call.arguments())) values[Value("title")] = Value(*title);
      Configure(hwnd, values);
      result->Success();
    } else if (call.method_name() == "setDragRegion") {
      const auto* args = std::get_if<Map>(call.arguments());
      if (!args) { result->Error("invalid_arguments", "Expected drag region."); return; }
      const double height = Number(*args, "height", 0);
      const double right = Number(*args, "reservedRight", 0);
      std::vector<ResourceState::Exclusion> exclusions;
      if (!std::isfinite(height) || height < 0 || !std::isfinite(right) || right < 0) {
        result->Error("invalid_arguments", "Invalid drag region."); return;
      }
      const auto it = args->find(Value("exclusions"));
      if (it != args->end()) {
        const auto* list = std::get_if<flutter::EncodableList>(&it->second);
        if (!list) { result->Error("invalid_arguments", "Expected rectangles."); return; }
        for (const auto& value : *list) {
          const auto* rect = std::get_if<Map>(&value);
          if (!rect) { result->Error("invalid_arguments", "Expected rectangle."); return; }
          ResourceState::Exclusion r{Number(*rect, "left", -1), Number(*rect, "top", -1),
                                    Number(*rect, "width", -1), Number(*rect, "height", -1)};
          if (!std::isfinite(r.left) || !std::isfinite(r.top) || !std::isfinite(r.width) || !std::isfinite(r.height) ||
              r.left < 0 || r.top < 0 || r.width < 0 || r.height < 0) {
            result->Error("invalid_arguments", "Invalid rectangle."); return;
          }
          exclusions.push_back(r);
        }
      }
      state->bar_height = height;
      state->reserved_right = right;
      state->exclusions = std::move(exclusions);
      result->Success();
    } else if (call.method_name() == "toggleMaximize") {
      ShowWindow(hwnd, IsZoomed(hwnd) ? SW_RESTORE : SW_MAXIMIZE);
      result->Success(Value(IsZoomed(hwnd) != FALSE));
    } else if (call.method_name() == "isMaximized") {
      result->Success(Value(IsZoomed(hwnd) != FALSE));
    } else if (call.method_name() == "startDrag") {
      ReleaseCapture();
      PostMessage(hwnd, WM_NCLBUTTONDOWN, HTCAPTION, GetMessagePos());
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
