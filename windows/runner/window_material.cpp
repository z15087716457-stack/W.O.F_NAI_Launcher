#include "window_material.h"

#include <dwmapi.h>

namespace window_material {
namespace {
bool AllowsTransparency() {
  HIGHCONTRASTW contrast = {};
  contrast.cbSize = sizeof(contrast);
  if (!SystemParametersInfoW(SPI_GETHIGHCONTRAST, sizeof(contrast), &contrast, 0) ||
      (contrast.dwFlags & HCF_HIGHCONTRASTON) != 0) {
    return false;
  }
  DWORD transparent = 1;
  DWORD size = sizeof(transparent);
  const auto result = RegGetValueW(
      HKEY_CURRENT_USER,
      L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
      L"EnableTransparency", RRF_RT_REG_DWORD, nullptr, &transparent, &size);
  return result != ERROR_SUCCESS || transparent != 0;
}

void Disable(HWND window) {
  const auto type = DWMSBT_NONE;
  DwmSetWindowAttribute(window, DWMWA_SYSTEMBACKDROP_TYPE, &type, sizeof(type));
  const MARGINS margins = {0, 0, 0, 0};
  DwmExtendFrameIntoClientArea(window, &margins);
}
}  // namespace

bool Apply(HWND window, bool enabled, bool dark) {
  if (!IsWindow(window)) return false;
  BOOL composition = FALSE;
  if (!enabled || !AllowsTransparency() ||
      FAILED(DwmIsCompositionEnabled(&composition)) || !composition) {
    Disable(window);
    return false;
  }
  const BOOL use_dark = dark ? TRUE : FALSE;
  DwmSetWindowAttribute(window, DWMWA_USE_IMMERSIVE_DARK_MODE,
                        &use_dark, sizeof(use_dark));
  // Documented Windows 11 22H2+ API. Earlier systems fail without changing
  // their window styles; do not use the legacy drag-stalling acrylic API.
  const auto type = DWMSBT_TRANSIENTWINDOW;
  if (FAILED(DwmSetWindowAttribute(window, DWMWA_SYSTEMBACKDROP_TYPE,
                                  &type, sizeof(type)))) {
    Disable(window);
    return false;
  }
  const MARGINS margins = {-1, -1, -1, -1};
  if (FAILED(DwmExtendFrameIntoClientArea(window, &margins))) {
    Disable(window);
    return false;
  }
  return true;
}
}  // namespace window_material
