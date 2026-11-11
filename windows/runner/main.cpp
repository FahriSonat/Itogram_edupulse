#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);

  // EduPulse mobil öncelikli tasarlandı: pencere telefon oranında, çalışma
  // alanının ortasında açılır. Değerler mantıksal pikseldir (Create DPI'a
  // göre ölçekler); küçük ekranlarda yükseklik çalışma alanına sığdırılır.
  RECT work_area{};
  ::SystemParametersInfo(SPI_GETWORKAREA, 0, &work_area, 0);
  const double dpi_scale = ::GetDpiForSystem() / 96.0;
  const int work_width = static_cast<int>((work_area.right - work_area.left) / dpi_scale);
  const int work_height = static_cast<int>((work_area.bottom - work_area.top) / dpi_scale);
  const int width = 430;
  const int height = work_height - 60 < 900 ? work_height - 60 : 900;
  const int x = (work_width - width) / 2 > 0 ? (work_width - width) / 2 : 0;
  const int y = (work_height - height) / 2 > 0 ? (work_height - height) / 2 : 0;
  Win32Window::Point origin(static_cast<unsigned int>(x), static_cast<unsigned int>(y));
  Win32Window::Size size(width, static_cast<unsigned int>(height > 480 ? height : 480));
  if (!window.Create(L"EduPulse", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
