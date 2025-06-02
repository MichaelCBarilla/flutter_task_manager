#include "flutter_window.h"
#include <optional>
#include "flutter/generated_plugin_registrant.h"
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <tlhelp32.h>
#include <psapi.h>
#include <tchar.h>
#include <iostream>
#include <vector>
#include <string>

// Process information structure
struct ProcessInfo {
    DWORD pid;
    std::string name;
};

class WindowsProcessManager {
public:
    static std::vector<ProcessInfo> getRunningProcesses() {
        std::vector<ProcessInfo> processes;
        
        HANDLE hProcessSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
        if (hProcessSnap == INVALID_HANDLE_VALUE) {
            return processes;
        }

        PROCESSENTRY32 pe32;
        pe32.dwSize = sizeof(PROCESSENTRY32);

        if (!Process32First(hProcessSnap, &pe32)) {
            CloseHandle(hProcessSnap);
            return processes;
        }

        do {
            std::string processName = wideCharToString(pe32.szExeFile);
            
            if (hasVisibleWindow(pe32.th32ProcessID)) {
                ProcessInfo info;
                info.pid = pe32.th32ProcessID;
                info.name = processName;
                processes.push_back(info);
            }
        } while (Process32Next(hProcessSnap, &pe32));

        CloseHandle(hProcessSnap);
        return processes;
    }

    static bool terminateProcess(DWORD pid) {
        HANDLE hProcess = OpenProcess(PROCESS_TERMINATE, FALSE, pid);
        if (hProcess == NULL) {
            return false;
        }

        BOOL result = TerminateProcess(hProcess, 0);
        CloseHandle(hProcess);
        return result != 0;
    }

private:
    static std::string wideCharToString(const WCHAR* wstr) {
        if (wstr == nullptr) return "";
        
        int size_needed = WideCharToMultiByte(CP_UTF8, 0, wstr, -1, NULL, 0, NULL, NULL);
        if (size_needed <= 0) return "";
        
        std::string result(size_needed - 1, 0);
        WideCharToMultiByte(CP_UTF8, 0, wstr, -1, &result[0], size_needed, NULL, NULL);
        return result;
    }

    static bool hasVisibleWindow(DWORD processId) {
        struct EnumData {
            DWORD processId;
            bool hasVisibleWindow;
        };
        
        EnumData data = { processId, false };
        
        EnumWindows([](HWND hwnd, LPARAM lParam) -> BOOL {
            EnumData* pData = reinterpret_cast<EnumData*>(lParam);
            
            DWORD windowProcessId;
            GetWindowThreadProcessId(hwnd, &windowProcessId);
            
            if (windowProcessId == pData->processId) {
                // Check if window is visible and not minimized
                if (IsWindowVisible(hwnd) && !IsIconic(hwnd)) {
                    // Get window title to filter out empty or system windows
                    WCHAR title[256];
                    if (GetWindowTextW(hwnd, title, sizeof(title)/sizeof(WCHAR)) > 0) {
                        pData->hasVisibleWindow = true;
                        return FALSE; // Stop enumeration
                    }
                }
            }
            return TRUE; // Continue enumeration
        }, reinterpret_cast<LPARAM>(&data));
        
        return data.hasVisibleWindow;
    }
};

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

  // Set up method channel for process management
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "com.example.flutterTaskManager/process",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        
        if (call.method_name().compare("getProcesses") == 0) {
          auto processes = WindowsProcessManager::getRunningProcesses();
          
          flutter::EncodableList processList;
          for (const auto& process : processes) {
            flutter::EncodableMap processMap;
            processMap[flutter::EncodableValue("pid")] = flutter::EncodableValue(std::to_string(process.pid));
            processMap[flutter::EncodableValue("name")] = flutter::EncodableValue(process.name);
            processList.push_back(flutter::EncodableValue(processMap));
          }
          
          result->Success(flutter::EncodableValue(processList));
        }
        else if (call.method_name().compare("killProcess") == 0) {
          const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
          if (arguments) {
            auto pid_iter = arguments->find(flutter::EncodableValue("pid"));
            if (pid_iter != arguments->end()) {
              const auto* pid_string = std::get_if<std::string>(&pid_iter->second);
              if (pid_string) {
                try {
                  DWORD pid = std::stoul(*pid_string);
                  bool success = WindowsProcessManager::terminateProcess(pid);
                  result->Success(flutter::EncodableValue(success));
                } catch (const std::exception&) {
                  result->Error("INVALID_ARGUMENT", "Invalid PID format");
                }
              } else {
                result->Error("INVALID_ARGUMENT", "PID must be a string");
              }
            } else {
              result->Error("INVALID_ARGUMENT", "Missing PID argument");
            }
          } else {
            result->Error("INVALID_ARGUMENT", "Invalid arguments");
          }
        }
        else {
          result->NotImplemented();
        }
      });

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
