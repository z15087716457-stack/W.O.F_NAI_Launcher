#include "titlebar_region.h"

#include <windowsx.h>

namespace titlebar_region {
namespace {

// Dart 上报的命中区参数（逻辑像素）。<=0 视为未启用。
double g_bar_height_logical = 0.0;
double g_reserved_right_logical = 0.0;

// 逻辑像素 → 物理像素（按窗口当前 DPI）。
int ToPixels(HWND hwnd, double logical) {
  const UINT dpi = GetDpiForWindow(hwnd);
  return static_cast<int>(logical * dpi / 96.0 + 0.5);
}

}  // namespace

void SetRegion(double bar_height, double reserved_right) {
  g_bar_height_logical = bar_height;
  g_reserved_right_logical = reserved_right;
}

void Clear() {
  g_bar_height_logical = 0.0;
  g_reserved_right_logical = 0.0;
}

std::optional<LRESULT> HandleNcHitTest(HWND hwnd, LPARAM lparam) {
  if (g_bar_height_logical <= 0.0) {
    return std::nullopt;
  }

  // lParam 是屏幕坐标，转成客户区坐标再判断。
  POINT pt{GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
  ScreenToClient(hwnd, &pt);

  // 非客户区（边框/标题带残留条）直接交给默认链，保证原生
  // 边缘缩放、最大化后的顶部 8px 补边命中不受影响。
  if (pt.x < 0 || pt.y < 0) {
    return std::nullopt;
  }

  RECT client{};
  if (!GetClientRect(hwnd, &client)) {
    return std::nullopt;
  }
  const int client_width = client.right - client.left;

  const int bar_px = ToPixels(hwnd, g_bar_height_logical);
  const int reserved_px = ToPixels(hwnd, g_reserved_right_logical);

  if (pt.y >= bar_px) {
    return std::nullopt;  // 标题栏以下，交给 Flutter/默认链。
  }
  if (pt.x >= client_width - reserved_px) {
    return std::nullopt;  // 按钮保留区保持 HTCLIENT。
  }
  return HTCAPTION;
}

}  // namespace titlebar_region
