# Nyrna 当前 C/C++ 代码功能清单（2026-02-08）

## 结论先行
当前项目的 C/C++ 代码主要承担两类职责：

1. Flutter 桌面宿主（Windows/Linux）启动、窗口与消息循环管理。
2. Windows 下一个小型原生动态库能力：判断进程是否处于 suspended 状态。

真正的“挂起/恢复进程”核心行为并不在 C/C++ 中实现，而是在 Dart FFI + Win32 API / Linux 命令链中完成。

## 一、业务相关 C/C++（手写/自定义）

### A. Windows Runner（宿主启动与窗口承载）
- `windows/runner/main.cpp`
  - 进程入口 `wWinMain`。
  - 处理控制台附着逻辑（含隐藏控制台 workaround）。
  - 初始化 COM（`CoInitializeEx`）。
  - 创建 Flutter 窗口、注入命令行参数、运行 Win32 消息循环。

- `windows/runner/flutter_window.cpp`
  - 创建 `FlutterViewController`，注册插件，绑定 Flutter 子窗口。
  - 转发顶层窗口消息给 Flutter 引擎处理。
  - 处理字体变更消息（`WM_FONTCHANGE`）。

- `windows/runner/win32_window.cpp`
  - Win32 窗口类注册与生命周期管理（创建/销毁/注销）。
  - DPI 缩放支持、窗口尺寸变化处理、焦点管理。
  - 实现 `WndProc` 与常见消息分发（`WM_SIZE`、`WM_DPICHANGED` 等）。

- `windows/runner/utils.cpp`
  - 创建并附着控制台（调试输出场景）。
  - 将 Windows UTF-16 命令行参数转为 UTF-8，传递给 Flutter/Dart。

### B. Linux Runner（GTK/Flutter 宿主）
- `linux/main.cc`
  - Linux 程序入口，启动 `GtkApplication`。

- `linux/my_application.cc`
  - 初始化 GTK 窗口与 Flutter view。
  - 注册 Linux 插件。
  - 处理本地命令行参数并转给 Dart 入口。
  - 启动后先隐藏窗口，交由 Dart 侧按时机展示。
  - 设置应用 ID（Wayland 桌面映射需要）。

### C. Windows NativeLibrary（C++/CLI 动态库）
- `lib/native_platform/src/process/repository/src/win32/NativeLibrary/NativeLibrary/NativeLibrary.cpp`
- `lib/native_platform/src/process/repository/src/win32/NativeLibrary/NativeLibrary/NativeLibrary.h`
  - 对外导出 `IsProcessSuspended(int pid)`。
  - 内部通过 .NET `System.Diagnostics.Process` 枚举线程状态，若线程处于 `Wait + Suspended`，则认为进程被挂起。
  - 该函数被 Dart 侧 FFI 调用，用于判断进程状态显示/逻辑分支。

## 二、自动生成或第三方镜像 C/C++（不建议当作项目业务代码）

以下目录里的 C/C++ 主要是 Flutter 生成文件、插件镜像或构建产物，不是项目手写业务逻辑：

- `windows/flutter/ephemeral/**`
- `linux/flutter/**`（含 `generated_plugin_registrant.cc`）
- `windows/flutter/generated_plugin_registrant.cc`
- `build/**`

它们的作用主要是：
- 插件注册胶水代码。
- Flutter Windows/Linux embedding wrapper。
- 示例插件代码与构建中间产物。

## 三、与“Nyrna核心能力”的关系

与暂停/恢复能力直接相关的 C/C++ 只有一小块：

- `IsProcessSuspended(pid)`（Windows NativeLibrary）

而真正执行 suspend/resume 的动作：
- Windows: Dart 侧调用 `NtSuspendProcess` / `NtResumeProcess`。
- Linux: Dart 侧通过 `kill(SIGSTOP/SIGCONT)` 路径完成。

所以从系统边界看，当前项目是“Dart 为主，C/C++ 宿主与补充能力为辅”的架构。

