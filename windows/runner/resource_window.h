#ifndef RUNNER_RESOURCE_WINDOW_H_
#define RUNNER_RESOURCE_WINDOW_H_

#include <flutter/flutter_view_controller.h>
#include <windows.h>

// Deliberately excludes window_manager's process-global channel, the tray,
// storage/media plugins, and the primary runner's clipboard/titlebar subclasses.
void RegisterResourceWindowPlugins(flutter::FlutterViewController* controller,
                                   HWND owner);
void RegisterResourceWindowHost(flutter::FlutterEngine* engine, HWND owner);

#endif  // RUNNER_RESOURCE_WINDOW_H_
