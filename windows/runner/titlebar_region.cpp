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

bool IsInDragArea(HWND hwnd, LPARAM lparam) {
  if (g_bar_height_logical <= 0.0) {
    return false;
  }

  // lParam 是屏幕坐标，转成 hwnd 的客户区坐标再判断。
  // 调用方传父窗口 hwnd：子窗口 subclass 里也把命中测试按父客户区
  // 判定，两处逻辑保持一致。
  POINT pt{GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
  ScreenToClient(hwnd, &pt);

  // 非客户区（边框/标题带残留条）不算命中。
  if (pt.x < 0 || pt.y < 0) {
    return false;
  }

  RECT client{};
  if (!GetClientRect(hwnd, &client)) {
    return false;
  }
  const int client_width = client.right - client.left;

  const int bar_px = ToPixels(hwnd, g_bar_height_logical);
  const int reserved_px = ToPixels(hwnd, g_reserved_right_logical);

  // 栏高以下（正文）与右侧按钮保留区都不命中拖拽区。
  return (pt.y < bar_px) && (pt.x < client_width - reserved_px);
}

std::optional<LRESULT> HandleNcHitTest(HWND hwnd, LPARAM lparam) {
  if (!IsInDragArea(hwnd, lparam)) {
    return std::nullopt;
  }
  return HTCAPTION;
}

}  // namespace titlebar_region
