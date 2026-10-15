#include "win32_window.h"

#include <commctrl.h>
#include <dwmapi.h>
#include <flutter_windows.h>
#include <uiautomation.h>
#include <windowsx.h>

#include "resource.h"
#include "titlebar_region.h"

namespace {

/// Window attribute that enables dark mode window decorations.
///
/// Redefined in case the developer's machine has a Windows SDK older than
/// version 10.0.22000.0.
/// See: https://docs.microsoft.com/windows/win32/api/dwmapi/ne-dwmapi-dwmwindowattribute
#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif

constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

/// Registry key for app theme preference.
///
/// A value of 0 indicates apps should use dark mode. A non-zero or missing
/// value indicates apps should use light mode.
constexpr const wchar_t kGetPreferredBrightnessRegKey[] =
  L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize";
constexpr const wchar_t kGetPreferredBrightnessRegValue[] = L"AppsUseLightTheme";

// The number of Win32Window objects that currently exist.
static int g_active_window_count = 0;

constexpr UINT_PTR kFlutterAccessibilityCrashGuardSubclassId = 1;
constexpr UINT_PTR kTitleBarHitTestSubclassId = 2;

// FEAT-23：FlutterView 子窗口铺满整个客户区，鼠标落在其上时
// WM_NCHITTEST 只发给子窗口，父窗口的 HTCAPTION 分支永远收不到，
// 标题栏拖拽/双击最大化因此失效。
//
// 这里对子窗口再挂一个 subclass：命中标题栏拖拽区时返回
// HTTRANSPARENT，把命中测试透传给底下的父窗口；父窗口的
// WM_NCHITTEST（titlebar_region::HandleNcHitTest）再返回
// HTCAPTION，原生拖拽/双击/Aero Snap 恢复。按钮保留区与栏外
// 区域正常走 DefSubclassProc → 返回 HTCLIENT，Flutter 输入不受影响。
LRESULT CALLBACK TitleBarHitTestProc(HWND window,
                                     UINT message,
                                     WPARAM wparam,
                                     LPARAM lparam,
                                     UINT_PTR subclass_id,
                                     DWORD_PTR /* reference_data */) {
  if (message == WM_NCHITTEST) {
    if (HWND parent = GetParent(window)) {
      if (titlebar_region::IsInDragArea(parent, lparam)) {
        return HTTRANSPARENT;
      }
    }
  }

  if (message == WM_NCDESTROY) {
    RemoveWindowSubclass(window, TitleBarHitTestProc, subclass_id);
  }

  return DefSubclassProc(window, message, wparam, lparam);
}

bool IsFlutterAccessibilityRootRequest(LPARAM lparam) {
  const DWORD object_id =
      static_cast<DWORD>(static_cast<DWORD_PTR>(lparam));
  return object_id == static_cast<DWORD>(OBJID_CLIENT) ||
         object_id == static_cast<DWORD>(UiaRootObjectId);
}

LRESULT CALLBACK FlutterAccessibilityCrashGuardProc(
    HWND window,
    UINT message,
    WPARAM wparam,
    LPARAM lparam,
    UINT_PTR subclass_id,
    DWORD_PTR /* reference_data */) {
  // Flutter 3.44 can corrupt its accessibility tree when a Windows UIA client
  // remains attached during a resize. Block only the root accessibility
  // requests until https://github.com/flutter/flutter/issues/175041 is fixed.
  if (message == WM_GETOBJECT && IsFlutterAccessibilityRootRequest(lparam)) {
    return 0;
  }

  if (message == WM_NCDESTROY) {
    RemoveWindowSubclass(window, FlutterAccessibilityCrashGuardProc,
                         subclass_id);
  }

  return DefSubclassProc(window, message, wparam, lparam);
}

using EnableNonClientDpiScaling = BOOL __stdcall(HWND hwnd);

// Scale helper to convert logical scaler values to physical using passed in
// scale factor
int Scale(int source, double scale_factor) {
  return static_cast<int>(source * scale_factor);
}

// Dynamically loads the |EnableNonClientDpiScaling| from the User32 module.
// This API is only needed for PerMonitor V1 awareness mode.
void EnableFullDpiSupportIfAvailable(HWND hwnd) {
  HMODULE user32_module = LoadLibraryA("User32.dll");
  if (!user32_module) {
    return;
  }
  auto enable_non_client_dpi_scaling =
      reinterpret_cast<EnableNonClientDpiScaling*>(
          GetProcAddress(user32_module, "EnableNonClientDpiScaling"));
  if (enable_non_client_dpi_scaling != nullptr) {
    enable_non_client_dpi_scaling(hwnd);
  }
  FreeLibrary(user32_module);
}

}  // namespace

// Manages the Win32Window's window class registration.
class WindowClassRegistrar {
 public:
  ~WindowClassRegistrar() = default;

  // Returns the singleton registrar instance.
  static WindowClassRegistrar* GetInstance() {
    if (!instance_) {
      instance_ = new WindowClassRegistrar();
    }
    return instance_;
  }

  // Returns the name of the window class, registering the class if it hasn't
  // previously been registered.
  const wchar_t* GetWindowClass();

  // Unregisters the window class. Should only be called if there are no
  // instances of the window.
  void UnregisterWindowClass();

 private:
  WindowClassRegistrar() = default;

  static WindowClassRegistrar* instance_;

  bool class_registered_ = false;
};

WindowClassRegistrar* WindowClassRegistrar::instance_ = nullptr;

const wchar_t* WindowClassRegistrar::GetWindowClass() {
  if (!class_registered_) {
    WNDCLASS window_class{};
    window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
    window_class.lpszClassName = kWindowClassName;
    window_class.style = CS_HREDRAW | CS_VREDRAW;
    window_class.cbClsExtra = 0;
    window_class.cbWndExtra = 0;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.hIcon =
        LoadIcon(window_class.hInstance, MAKEINTRESOURCE(IDI_WINDOW_ICON));
    window_class.hbrBackground = 0;
    window_class.lpszMenuName = nullptr;
    window_class.lpfnWndProc = Win32Window::WndProc;
    RegisterClass(&window_class);
    class_registered_ = true;
  }
  return kWindowClassName;
}

void WindowClassRegistrar::UnregisterWindowClass() {
  UnregisterClass(kWindowClassName, nullptr);
  class_registered_ = false;
}

Win32Window::Win32Window() {
  ++g_active_window_count;
}

Win32Window::~Win32Window() {
  --g_active_window_count;
  Destroy();
}

bool Win32Window::Create(const std::wstring& title,
                         const Point& origin,
                         const Size& size) {
  Destroy();

  const wchar_t* window_class =
      WindowClassRegistrar::GetInstance()->GetWindowClass();

  const POINT target_point = {static_cast<LONG>(origin.x),
                              static_cast<LONG>(origin.y)};
  HMONITOR monitor = MonitorFromPoint(target_point, MONITOR_DEFAULTTONEAREST);
  UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  double scale_factor = dpi / 96.0;

  HWND window = CreateWindow(
      window_class, title.c_str(), WS_OVERLAPPEDWINDOW,
      Scale(origin.x, scale_factor), Scale(origin.y, scale_factor),
      Scale(size.width, scale_factor), Scale(size.height, scale_factor),
      nullptr, nullptr, GetModuleHandle(nullptr), this);

  if (!window) {
    return false;
  }

  UpdateWindowIcons(window, dpi);
  UpdateTheme(window);

  return OnCreate();
}

bool Win32Window::Show() {
  return ShowWindow(window_handle_, SW_SHOWNORMAL);
}

// static
LRESULT CALLBACK Win32Window::WndProc(HWND const window,
                                      UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto window_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));

    auto that = static_cast<Win32Window*>(window_struct->lpCreateParams);
    EnableFullDpiSupportIfAvailable(window);
    that->window_handle_ = window;
  } else if (Win32Window* that = GetThisFromHandle(window)) {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT
Win32Window::MessageHandler(HWND hwnd,
                            UINT const message,
                            WPARAM const wparam,
                            LPARAM const lparam) noexcept {
  switch (message) {
    case WM_DESTROY:
      window_handle_ = nullptr;
      Destroy();
      if (quit_on_close_) {
        PostQuitMessage(0);
      }
      return 0;

    case WM_DPICHANGED: {
      UpdateWindowIcons(hwnd, HIWORD(wparam));
      auto newRectSize = reinterpret_cast<RECT*>(lparam);
      LONG newWidth = newRectSize->right - newRectSize->left;
      LONG newHeight = newRectSize->bottom - newRectSize->top;

      SetWindowPos(hwnd, nullptr, newRectSize->left, newRectSize->top, newWidth,
                   newHeight, SWP_NOZORDER | SWP_NOACTIVATE);

      return 0;
    }
    case WM_SIZE: {
      RECT rect = GetClientArea();
      if (child_content_ != nullptr) {
        // Size and position the child window.
        MoveWindow(child_content_, rect.left, rect.top,
                   content_width_override_ > 0 ? content_width_override_ : rect.right - rect.left,
                   rect.bottom - rect.top, TRUE);
      }
      return 0;
    }

    case WM_ACTIVATE:
      if (child_content_ != nullptr) {
        SetFocus(child_content_);
      }
      return 0;

    case WM_DWMCOLORIZATIONCOLORCHANGED:
      UpdateTheme(hwnd);
      return 0;

    case WM_NCHITTEST:
      // FEAT-23：自绘标题栏命中区。命中返回 HTCAPTION（原生拖拽/
      // 双击最大化/Aero Snap），未命中返回 std::nullopt 继续走
      // DefWindowProc（边缘缩放/最大化补边由 window_manager 的
      // WM_NCCALCSIZE 保留的非客户边框承担）。
      if (auto result = titlebar_region::HandleNcHitTest(hwnd, lparam)) {
        return *result;
      }
      break;
  }

  return DefWindowProc(window_handle_, message, wparam, lparam);
}

void Win32Window::SetContentWidthOverride(int width) {
  content_width_override_ = width;
  if (child_content_ != nullptr) {
    const RECT rect = GetClientArea();
    MoveWindow(child_content_, rect.left, rect.top,
               width > 0 ? width : rect.right - rect.left,
               rect.bottom - rect.top, TRUE);
  }
}

void Win32Window::Destroy() {
  OnDestroy();

  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
  if (large_icon_) {
    DestroyIcon(large_icon_);
    large_icon_ = nullptr;
  }
  if (small_icon_) {
    DestroyIcon(small_icon_);
    small_icon_ = nullptr;
  }
  if (g_active_window_count == 0) {
    WindowClassRegistrar::GetInstance()->UnregisterWindowClass();
  }
}

Win32Window* Win32Window::GetThisFromHandle(HWND const window) noexcept {
  return reinterpret_cast<Win32Window*>(
      GetWindowLongPtr(window, GWLP_USERDATA));
}

bool Win32Window::SetChildContent(HWND content) {
  if (!SetWindowSubclass(content, FlutterAccessibilityCrashGuardProc,
                         kFlutterAccessibilityCrashGuardSubclassId, 0)) {
    return false;
  }
  // FEAT-23：标题栏命中透传 subclass。与上面的 CrashGuard 一样挂在
  // FlutterView 子窗口上，二者互不干扰。
  if (!SetWindowSubclass(content, TitleBarHitTestProc,
                         kTitleBarHitTestSubclassId, 0)) {
    return false;
  }

  child_content_ = content;
  SetParent(content, window_handle_);
  RECT frame = GetClientArea();

  MoveWindow(content, frame.left, frame.top, frame.right - frame.left,
             frame.bottom - frame.top, true);

  SetFocus(child_content_);
  return true;
}

RECT Win32Window::GetClientArea() {
  RECT frame;
  GetClientRect(window_handle_, &frame);
  return frame;
}

HWND Win32Window::GetHandle() {
  return window_handle_;
}

void Win32Window::SetQuitOnClose(bool quit_on_close) {
  quit_on_close_ = quit_on_close;
}

bool Win32Window::OnCreate() {
  // No-op; provided for subclasses.
  return true;
}

void Win32Window::OnDestroy() {
  // No-op; provided for subclasses.
}

void Win32Window::UpdateWindowIcons(HWND window, UINT dpi) {
  const auto replace_icon = [window, dpi](WPARAM kind, int metric_x,
                                         int metric_y, HICON& owned_icon) {
    // Do not use LR_SHARED: its resource cache can return the first size loaded
    // for both requests. Keep distinct small/large handles at the current DPI.
    HICON icon = static_cast<HICON>(LoadImageW(
        GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_WINDOW_ICON), IMAGE_ICON,
        GetSystemMetricsForDpi(metric_x, dpi),
        GetSystemMetricsForDpi(metric_y, dpi), LR_DEFAULTCOLOR));
    if (!icon) {
      return;  // Retain the existing icon or the class's square-W fallback.
    }
    SendMessageW(window, WM_SETICON, kind, reinterpret_cast<LPARAM>(icon));
    if (owned_icon) {
      DestroyIcon(owned_icon);
    }
    owned_icon = icon;
  };
  replace_icon(ICON_BIG, SM_CXICON, SM_CYICON, large_icon_);
  replace_icon(ICON_SMALL, SM_CXSMICON, SM_CYSMICON, small_icon_);
}

void Win32Window::UpdateTheme(HWND const window) {
  DWORD light_mode;
  DWORD light_mode_size = sizeof(light_mode);
  LSTATUS result = RegGetValue(HKEY_CURRENT_USER, kGetPreferredBrightnessRegKey,
                               kGetPreferredBrightnessRegValue,
                               RRF_RT_REG_DWORD, nullptr, &light_mode,
                               &light_mode_size);

  if (result == ERROR_SUCCESS) {
    BOOL enable_dark_mode = light_mode == 0;
    DwmSetWindowAttribute(window, DWMWA_USE_IMMERSIVE_DARK_MODE,
                          &enable_dark_mode, sizeof(enable_dark_mode));
  }
}
