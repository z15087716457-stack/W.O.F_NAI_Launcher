#include "flutter_window.h"
#include "studio_sandbox.h"

#include <optional>
#include <cmath>
#include <set>
#include <string>
#include <vector>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include "flutter/generated_plugin_registrant.h"
#include "desktop_multi_window/desktop_multi_window_plugin.h"
#include "resource_window.h"
#include "titlebar_region.h"
#include "window_material.h"

// Global set to store font names
static std::set<std::wstring> g_font_names;
// Callback is a C function pointer; keep the primary HWND on its platform thread.
static HWND g_resource_window_owner = nullptr;

// Font enumeration callback function
int CALLBACK EnumFontFamExProc(
    const LOGFONTW* lpelfe,
    const TEXTMETRICW* lpntme,
    DWORD FontType,
    LPARAM lParam) {
  // Skip vertical fonts (starting with @)
  if (lpelfe->lfFaceName[0] != L'@') {
    g_font_names.insert(lpelfe->lfFaceName);
  }
  return 1; // Continue enumeration
}

// Get system font list
std::vector<std::string> GetSystemFonts() {
  g_font_names.clear();

  HDC hdc = GetDC(NULL);
  if (hdc == NULL) {
    return {};
  }

  LOGFONTW lf = {};
  lf.lfCharSet = DEFAULT_CHARSET;
  lf.lfFaceName[0] = L'\0';

  EnumFontFamiliesExW(hdc, &lf, EnumFontFamExProc, 0, 0);
  ReleaseDC(NULL, hdc);

  std::vector<std::string> result;
  for (const auto& name : g_font_names) {
    // Convert without the terminating NUL so the destination buffer is exact.
    int name_length = static_cast<int>(name.length());
    int size = WideCharToMultiByte(
        CP_UTF8, 0, name.c_str(), name_length, NULL, 0, NULL, NULL);
    if (size > 0) {
      std::string utf8_name(size, '\0');
      int written = WideCharToMultiByte(
          CP_UTF8, 0, name.c_str(), name_length, utf8_name.data(), size,
          NULL, NULL);
      if (written > 0) {
        result.push_back(utf8_name);
      }
    }
  }

  return result;
}

constexpr const wchar_t kWakeUpMessageName[] =
    L"NAI_Launcher_WakeUp_Message";

static UINT GetWakeUpMessage() {
  static const UINT message = RegisterWindowMessageW(studio_sandbox::Identity(kWakeUpMessageName).c_str());
  return message;
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  g_resource_window_owner = GetHandle();
  RegisterResourceWindowHost(flutter_controller_->engine(), GetHandle());
  DesktopMultiWindowSetWindowCreatedCallback([](void* controller) {
    auto* child = reinterpret_cast<flutter::FlutterViewController*>(controller);
    RegisterResourceWindowPlugins(child, g_resource_window_owner);
  });
  clipboard_history_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.nailauncher/clipboard_history",
          &flutter::StandardMethodCodec::GetInstance());
  if (!SetChildContent(flutter_controller_->view()->GetNativeWindow())) {
    return false;
  }

  // Register system fonts MethodChannel
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "com.nailauncher/system_fonts",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "getSystemFonts") {
          auto fonts = GetSystemFonts();
          flutter::EncodableList font_list;
          for (const auto& font : fonts) {
            font_list.push_back(flutter::EncodableValue(font));
          }
          result->Success(flutter::EncodableValue(font_list));
        } else {
          result->NotImplemented();
        }
      });

  // Register window control MethodChannel (Dart -> native).
  // refreshFrame: 强制非客户区重绘。Windows 11 的 DWM 在托盘隐藏→显示后
  // 偶尔不重绘 caption 按钮（最小化/最大化按钮不可见，但命中测试仍生效）；
  // ±1px 双 SetWindowPos + SWP_FRAMECHANGED 是社区验证的恢复手段。
  auto window_control_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.nailauncher/window_control",
          &flutter::StandardMethodCodec::GetInstance());
  window_control_channel->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() == "refreshFrame") {
          HWND hwnd = GetHandle();
          if (hwnd != nullptr) {
            RECT rect;
            GetWindowRect(hwnd, &rect);
            SetWindowPos(hwnd, nullptr, rect.left, rect.top,
                         rect.right - rect.left + 1, rect.bottom - rect.top,
                         SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOMOVE |
                             SWP_FRAMECHANGED);
            SetWindowPos(hwnd, nullptr, rect.left, rect.top,
                         rect.right - rect.left, rect.bottom - rect.top,
                         SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOMOVE |
                             SWP_FRAMECHANGED);
          }
          UpdateWindowMaterial();
          result->Success();
        } else {
          result->NotImplemented();
        }
      });

  material_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.nailauncher/window_material",
          &flutter::StandardMethodCodec::GetInstance());
  material_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        if (call.method_name() != "configure") {
          result->NotImplemented();
          return;
        }
        const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
        if (args == nullptr) {
          result->Error("invalid_arguments", "Expected material settings.");
          return;
        }
        const auto enabled = args->find(flutter::EncodableValue("enabled"));
        const auto dark = args->find(flutter::EncodableValue("dark"));
        if (enabled == args->end() || dark == args->end() ||
            !std::holds_alternative<bool>(enabled->second) ||
            !std::holds_alternative<bool>(dark->second)) {
          result->Error("invalid_arguments", "Expected enabled and dark booleans.");
          return;
        }
        material_enabled_ = std::get<bool>(enabled->second);
        material_dark_ = std::get<bool>(dark->second);
        result->Success(flutter::EncodableValue(UpdateWindowMaterial()));
      });

  // Register integrated title bar MethodChannel (Dart -> native).
  // FEAT-23：Dart 侧把自绘标题栏的命中参数（栏高 + 右侧按钮保留宽，
  // 逻辑像素）上报给原生，由 titlebar_region 在 WM_NCHITTEST 里
  // 返回 HTCAPTION，恢复原生拖拽/双击最大化/Aero Snap。
  auto titlebar_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.nailauncher/titlebar",
          &flutter::StandardMethodCodec::GetInstance());
  titlebar_channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() == "setRegion") {
          const auto* args =
              std::get_if<flutter::EncodableMap>(call.arguments());
          double bar_height = 0.0;
          double reserved_right = 0.0;
          if (args != nullptr) {
            const auto height_it =
                args->find(flutter::EncodableValue("barHeight"));
            if (height_it != args->end()) {
              if (const auto* v = std::get_if<double>(&height_it->second)) {
                bar_height = *v;
              }
            }
            const auto reserved_it =
                args->find(flutter::EncodableValue("reservedRight"));
            if (reserved_it != args->end()) {
              if (const auto* v = std::get_if<double>(&reserved_it->second)) {
                reserved_right = *v;
              }
            }
          }
          titlebar_region::SetRegion(bar_height, reserved_right);
          result->Success();
        } else if (call.method_name() == "clear") {
          titlebar_region::Clear();
          result->Success();
        } else {
          result->NotImplemented();
        }
      });

  reveal_ = std::make_unique<WindowReveal>(
      GetHandle(), [this](int width) { SetContentWidthOverride(width); },
      [this](std::function<void()> callback) {
        flutter_controller_->engine()->SetNextFrameCallback(std::move(callback));
        flutter_controller_->ForceRedraw();
      });
  reveal_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.nailauncher/window_reveal", &flutter::StandardMethodCodec::GetInstance());
  reveal_channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() == "cancel") {
      reveal_->Cancel();
      result->Success();
      return;
    }
    if (call.method_name() != "grow") { result->NotImplemented(); return; }
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    auto number = [args](const char* key) -> double {
      if (args == nullptr) return NAN;
      const auto entry = args->find(flutter::EncodableValue(key));
      if (entry == args->end()) return NAN;
      if (const auto* value = std::get_if<double>(&entry->second)) return *value;
      return NAN;
    };
    const double ratio = number("pixelRatio"), left = number("left"),
        top = number("top"), width = number("width"), height = number("height"),
        target_width = number("targetWidth"), duration = number("durationMs");
    if (!std::isfinite(ratio) || ratio <= 0 || ratio > 8 ||
        !std::isfinite(left) || !std::isfinite(top) ||
        !std::isfinite(width) || width <= 0 ||
        !std::isfinite(height) || height <= 0 ||
        !std::isfinite(target_width) || target_width <= 0 || target_width * ratio > 100000 ||
        !std::isfinite(duration) || duration < 0 || duration > 1000 ||
        std::abs(left * ratio) > 100000 || std::abs(top * ratio) > 100000 ||
        width * ratio > 100000 || height * ratio > 100000) {
      result->Error("invalid_bounds", "Invalid reveal geometry.");
      return;
    }
    const RECT expected{
        static_cast<LONG>(std::lround(left * ratio)),
        static_cast<LONG>(std::lround(top * ratio)),
        static_cast<LONG>(std::lround((left + width) * ratio)),
        static_cast<LONG>(std::lround((top + height) * ratio))};
    auto reply = std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(std::move(result));
    if (!reveal_->Start(expected, static_cast<int>(std::lround(target_width * ratio)),
                        static_cast<int>(duration), [reply](bool completed) {
                          reply->Success(flutter::EncodableValue(completed));
                        })) reply->Success(flutter::EncodableValue(false));
  });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnClipboardHistoryPaste() {
  if (clipboard_history_channel_) {
    clipboard_history_channel_->InvokeMethod("paste", nullptr);
  }
}

void FlutterWindow::OnDestroy() {
  clipboard_history_channel_.reset();
  reveal_.reset();
  reveal_channel_.reset();
  material_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

bool FlutterWindow::UpdateWindowMaterial() {
  const bool available = window_material::Apply(
      GetHandle(), material_enabled_, material_dark_);
  if (available != material_available_) {
    material_available_ = available;
    if (material_channel_) {
      material_channel_->InvokeMethod(
          "availabilityChanged",
          std::make_unique<flutter::EncodableValue>(available));
    }
  }
  return available;
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (reveal_) {
    if (auto result = reveal_->HandleMessage(message, wparam)) return *result;
  }
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  const UINT wake_up_message = GetWakeUpMessage();
  if (wake_up_message != 0 && message == wake_up_message) {
    // 收到唤醒消息，通知 Flutter 侧显示窗口
    if (flutter_controller_ && flutter_controller_->engine()) {
      auto channel =
          std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
              flutter_controller_->engine()->messenger(),
              "com.nailauncher/window_control",
              &flutter::StandardMethodCodec::GetInstance());
      channel->InvokeMethod("wakeUp", nullptr);
    }
    return 0;
  }

  switch (message) {
    case WM_FONTCHANGE:
      if (flutter_controller_ && flutter_controller_->engine()) {
        flutter_controller_->engine()->ReloadSystemFonts();
      }
      break;
  }

  const auto handled = Win32Window::MessageHandler(hwnd, message, wparam, lparam);
  if (message == WM_SETTINGCHANGE || message == WM_THEMECHANGED ||
      message == WM_DWMCOMPOSITIONCHANGED ||
      message == WM_DWMCOLORIZATIONCOLORCHANGED) {
    UpdateWindowMaterial();
  }
  return handled;
}
