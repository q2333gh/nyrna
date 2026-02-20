# Nyrna CLI 调研：第一性原理与系统调用映射（2026-02-08）

## 背景与边界
- 当前仓库没有独立的纯 CLI 可执行程序。
- 但主程序已支持命令行参数 `--toggle`，可在不进入 GUI 交互的情况下触发“挂起/恢复当前活动窗口”。
- 本文聚焦该能力的最小闭环，不讨论 UI 层。

## 第一性原理拆解
从目标出发，Nyrna 的核心目标只有一条：

- 让目标进程在 `Running` 和 `Suspended` 两态之间可逆切换。

为实现该目标，最小必要步骤是：

1. 找到目标进程（通常由活动窗口反查 PID）。
2. 对目标 PID 发出挂起或恢复动作。
3. 为了可逆切换，保存最少状态（如 PID / windowId）。
4. 可选地最小化/恢复窗口，优化用户体验。

其中第 2 步是核心，其余是支撑能力。

## 核心 syscall（按平台）

### Linux
- 挂起：`kill(pid, SIGSTOP)`
- 恢复：`kill(pid, SIGCONT)`

这是 Linux 路径的本体能力；其余命令（`ps`、`pgrep`、`readlink`、`xdotool`、`wmctrl`）本质上是辅助发现与窗口控制。

### Windows
- 挂起：`NtSuspendProcess(handle)`
- 恢复：`NtResumeProcess(handle)`
- 前置：`OpenProcess(...)` 获取目标进程句柄

这是 Windows 路径的本体能力；其余 Win32 API 主要用于目标发现与窗口操作。

## 支撑能力到 syscall 的映射

### 1) 目标发现（Window -> PID -> Executable）
- Linux:
  - `/proc/<pid>/exe` 查询：`readlink`（底层涉及 `open/read/close` 等）
  - 外部命令链路：`fork/execve/wait4`（由 `Process.run` 触发）
  - X11 工具通信：`xdotool` / `wmctrl`（本质为显示服务器 IPC）
- Windows:
  - 活动窗口句柄：`GetForegroundWindow`
  - 窗口到 PID：`GetWindowThreadProcessId`
  - 进程路径：`OpenProcess` + `GetModuleFileNameEx` + `CloseHandle`

### 2) 进程状态切换（核心）
- Linux: `kill(SIGSTOP/SIGCONT)`
- Windows: `NtSuspendProcess/NtResumeProcess`

### 3) 窗口状态（可选）
- Linux:
  - 最小化：`xdotool windowminimize`
  - 激活/恢复：`xdotool windowactivate`
- Windows:
  - `ShowWindow(SW_FORCEMINIMIZE)`
  - `ShowWindow(SW_RESTORE)`

### 4) 状态持久化（可选但实用）
- 保存 `pid` / `windowId` 到本地存储，底层为文件 I/O（`open/read/write/close` 等）。

## 对“CLI 版本”的结论
- 如果未来实现独立 CLI（例如 `nyrna suspend <pid|exe>`），其不可替代核心仍是：
  - Linux: `kill(SIGSTOP/SIGCONT)`
  - Windows: `NtSuspendProcess/NtResumeProcess`
- 其他能力（窗口识别、参数解析、日志、配置存储）都属于工程化配套，不是本体能力。

## 仓库实现对应（便于后续追踪）
- 入口参数与 `--toggle`: `lib/argument_parser/argument_parser.dart`
- 命令行分支与快速退出: `lib/main.dart`
- 活动窗口切换流程: `lib/active_window/src/active_window.dart`
- Linux 进程挂起/恢复实现: `lib/native_platform/src/process/repository/src/linux_process_repository.dart`
- Windows 进程挂起/恢复实现: `lib/native_platform/src/process/repository/src/win32_process_repository.dart`
- Linux 窗口发现/控制: `lib/native_platform/src/linux/linux.dart`
- Windows 窗口发现/控制: `lib/native_platform/src/win32/win32.dart`

