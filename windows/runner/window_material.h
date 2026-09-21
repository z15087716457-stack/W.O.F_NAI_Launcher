#ifndef RUNNER_WINDOW_MATERIAL_H_
#define RUNNER_WINDOW_MATERIAL_H_

#include <windows.h>

namespace window_material {
// Supported DWM acrylic only; unsupported systems or accessibility settings
// return false so Flutter draws the opaque glass finish instead.
bool Apply(HWND window, bool enabled, bool dark);
}  // namespace window_material

#endif  // RUNNER_WINDOW_MATERIAL_H_
