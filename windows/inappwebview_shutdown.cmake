# Compile a patched copy of the locked WebView manager. Keep the shared Pub
# cache intact and fail configuration if a dependency update changes the hooks.
set(webview_plugin flutter_inappwebview_windows_plugin)
set(webview_manager "in_app_webview/in_app_webview_manager.cpp")
get_target_property(webview_source_dir ${webview_plugin} SOURCE_DIR)
get_target_property(webview_sources ${webview_plugin} SOURCES)
set(webview_original "${webview_source_dir}/${webview_manager}")
set(webview_patched "${CMAKE_CURRENT_BINARY_DIR}/in_app_webview_manager_studio.cpp")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${webview_original}")
file(READ "${webview_original}" webview_code)

set(webview_dispose [=[    else if (string_equals(methodName, "dispose"))]=])
set(webview_create [=[if (plugin && webViewEnv && webViewController && webViewCompositionController)]=])
string(FIND "${webview_code}" "${webview_dispose}" webview_dispose_at)
string(FIND "${webview_code}" "${webview_create}" webview_create_at)
if(NOT webview_manager IN_LIST webview_sources OR
   webview_dispose_at EQUAL -1 OR webview_create_at EQUAL -1)
  message(FATAL_ERROR "Recheck the Studio WebView shutdown hooks for this plugin version")
endif()

set(webview_shutdown [=[
    else if (string_equals(methodName, "studioReleaseComposition")) {
      // Run on the platform thread before ExitProcess tears down CoreMessaging.
      valid_ = false;
      for (const auto& entry : webViews) {
        entry.second->UnregisterMethodCallHandler();
      }
      for (const auto& entry : keepAliveWebViews) {
        entry.second->UnregisterMethodCallHandler();
      }
      webViews.clear();
      keepAliveWebViews.clear();
      windowWebViews.clear();
      compositor_ = nullptr;
      graphics_context_.reset();

      using namespace ABI::Windows::Foundation;
      const auto finish = [reply = std::shared_ptr(std::move(result))](HRESULT hr) {
        dispatcher_queue_controller_ = nullptr;
        rohelper_.reset();
        if (FAILED(hr)) {
          reply->Error("dispatcher_shutdown", "WebView dispatcher queue shutdown failed.");
        } else {
          reply->Success();
        }
      };
      if (!dispatcher_queue_controller_) {
        finish(S_OK);
        return;
      }

      // Keep pumping the UI thread until the plugin-owned queue has drained.
      winrt::com_ptr<IAsyncAction> shutdown;
      const HRESULT started = dispatcher_queue_controller_->ShutdownQueueAsync(shutdown.put());
      if (FAILED(started)) {
        finish(started);
        return;
      }
      const auto completion = Microsoft::WRL::Callback<IAsyncActionCompletedHandler>(
          [finish](IAsyncAction* action, AsyncStatus) -> HRESULT {
            finish(action->GetResults());
            return S_OK;
          });
      const HRESULT registered = shutdown->put_Completed(completion.Get());
      if (FAILED(registered)) finish(registered);
    }
]=])
string(REPLACE "${webview_dispose}" "${webview_shutdown}${webview_dispose}" webview_code "${webview_code}")
string(REPLACE "${webview_create}" [=[if (isSupported() && plugin && webViewEnv && webViewController && webViewCompositionController)]=] webview_code "${webview_code}")
string(PREPEND webview_code "#include <wrl/event.h>\n")
file(GENERATE OUTPUT "${webview_patched}" CONTENT "${webview_code}")

list(REMOVE_ITEM webview_sources "${webview_manager}")
set_property(TARGET ${webview_plugin} PROPERTY SOURCES "${webview_sources};${webview_patched}")
target_include_directories(${webview_plugin} PRIVATE "${webview_source_dir}/in_app_webview")
