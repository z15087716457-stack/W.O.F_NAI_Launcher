#ifndef RUNNER_TITLEBAR_REGION_H_
#define RUNNER_TITLEBAR_REGION_H_

#include <windows.h>

#include <optional>

// FEAT-23 内置一体标题栏：原生命中区。
//
// window_manager 的 TitleBarStyle.hidden 只处理 WM_NCCALCSIZE
// （保留 8px 非客户边框做原生边缘缩放、最大化补边），不处理
// WM_NCHITTEST —— 标题栏区域会命中 HTCLIENT，即失去原生拖拽、
// 双击最大化、Aero Snap。
//
// 本模块维护「标题栏命中矩形」（逻辑像素，由 Dart 侧通过
// com.nailauncher/titlebar MethodChannel 上报），在
// Win32Window::MessageHandler 中对 WM_NCHITTEST 命中该矩形的
// 点返回 HTCAPTION，把原生窗口行为（拖拽/双击/Snap）交还给
// 自绘 Flutter 标题栏。
//
// 约定：
// - 标题栏高度 + 右侧按钮保留宽度由 Dart 以逻辑像素上报；
// - 像素换算统一在原生侧按 GetDpiForWindow 完成，避免 DPI 漂移；
// - 右侧保留区内（最小化/最大化/关闭按钮）不返回 HTCAPTION，
//   保持 HTCLIENT，让按钮走 Flutter 点击路径；
// - 命中区之外的点返回 std::nullopt，由 DefWindowProc 继续
//   处理（边缘缩放/最小化按钮命中等原生逻辑不受影响）。

namespace titlebar_region {

// Dart 侧上报：bar_height / reserved_right（逻辑像素，double）。
// 任意一侧为非正值时清除命中区（等价 Clear()）。
void SetRegion(double bar_height, double reserved_right);
void Clear();

// 仅做命中判断：lparam 为屏幕坐标点，hwnd 为「拥有该命中区的窗口」
// （即顶层父窗口；子窗口 subclass 透传命中测试时同样按父客户区
// 判断，保证两处坐标系一致）。命中标题栏拖拽区返回 true。
bool IsInDragArea(HWND hwnd, LPARAM lparam);

// WM_NCHITTEST 处理。lParam 与 DefWindowProc 收到的原始值相同
// （坐标为屏幕坐标）。命中标题栏区（且不在按钮保留区）时返回
// HTCAPTION，否则返回 std::nullopt 表示「不处理，交给默认链」。
std::optional<LRESULT> HandleNcHitTest(HWND hwnd, LPARAM lparam);

}  // namespace titlebar_region

#endif  // RUNNER_TITLEBAR_REGION_H_
