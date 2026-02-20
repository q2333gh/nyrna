# Per-Executable Auto Minimize Toggle Design (2026-02-15)

## Goal
- Add a persisted toggle in each card's three-dot menu (same level as `Kill process`) to control whether that executable uses "auto minimize on suspend + auto restore on resume".
- Scope is per executable name (`window.process.executable`), not per PID/window id.

## Context
- Current minimize/restore behavior is global (`SettingsState.minimizeWindows`).
- `AppsListCubit` enforces minimize/restore in `_minimize()` and `_restore()`.
- Per-card menu is implemented in `lib/apps_list/widgets/window_tile.dart` under `MenuAnchor` children.

## Approaches
1. Recommended: global default + per-executable override map
- Keep global `minimizeWindows` as fallback default.
- Add storage-backed map (or two explicit lists) for per-executable override.
- Runtime decision: for a given window, first check override, else use global default.
- Pros: backward compatible, least migration risk, allows mixed behavior by app.
- Cons: one more preference layer to reason about.

2. Pure per-executable only (remove global switch semantics)
- Replace global switch for list interactions with executable-level config only.
- Pros: simplest runtime rule.
- Cons: breaks current user expectation and settings UX, larger migration and docs impact.

3. Session-only per-executable cache (no persistence)
- Store map only in memory.
- Pros: easiest implementation.
- Cons: does not satisfy requirement (must persist).

Decision: choose Approach 1.

## Product Behavior
- In each card menu, add a toggle item:
  - Label: `Auto minimize and restore`
  - Checked: current executable resolves to enabled.
  - Unchecked: resolves to disabled.
- Toggle affects all cards with the same executable immediately and persists across restarts.
- The action remains at the same menu level as:
  - Details
  - Suspend/Resume all instances
  - Kill process
  - Hide process
- Existing global setting (`minimizeWindows`) continues to act as default when executable has no explicit override.

## Data Model and Persistence
- Add new settings field:
  - `Map<String, bool> minimizeWindowsByExecutable`
- Persist in storage key:
  - `minimizeWindowsByExecutable`
- Read path:
  - In `SettingsCubit.init`, load map from storage (default `{}`).
- Write path:
  - New method in `SettingsCubit`:
    - `Future<void> setExecutableMinimizePreference(String executable, bool enabled)`
  - Save updated map and emit new state.
- Resolve path:
  - New read helper in `SettingsCubit` (or extension):
    - `bool minimizeEnabledForExecutable(String executable)`:
      - return map[executable] ?? state.minimizeWindows

## Runtime Integration
- Update `AppsListCubit`:
  - `_minimize(Window window)` should use per-executable resolved value.
  - `_restore(Window window)` should use the same resolved value.
- Keep existing platform-specific timing behavior unchanged (e.g., Windows 500ms delay).
- No PID-based persistence is introduced.

## UI and UX Integration
- File target: `lib/apps_list/widgets/window_tile.dart`
- Add menu item as a checkable/toggle entry in `MenuAnchor.menuChildren`.
- Derive current value from `SettingsCubit` + `window.process.executable`.
- On click:
  - update setting via new `SettingsCubit` API,
  - optionally show snackbar: `Auto minimize enabled/disabled for <executable>`.
- Menu item should be available regardless of current suspend state.

## Error Handling
- If storage write fails:
  - keep prior in-memory state,
  - surface concise snackbar error.
- If executable string is empty:
  - disable toggle item and avoid write.
- If map payload is malformed in storage:
  - fallback to `{}` and continue with global default.

## Testing Strategy
- Unit tests (`settings`):
  - loads empty map by default.
  - persists and reloads `minimizeWindowsByExecutable`.
  - resolution logic honors override over global default.
- Unit tests (`apps_list_cubit`):
  - `_minimize/_restore` call native platform only when resolved setting is true.
  - behavior differs for two windows with different executables.
- Widget tests (`window_tile`):
  - menu renders new toggle item.
  - clicking toggle writes setting and updates checked state.
  - item exists in same menu group as `Kill process`.

## Acceptance Criteria
- A user can toggle `Auto minimize and restore` from a card's three-dot menu.
- The setting is persisted and restored after app restart.
- The setting applies to all windows/cards of the same executable.
- Global setting still works as fallback for executables without explicit override.
- Existing suspend/resume behavior is unchanged for apps without overrides.

## Files Expected to Change (Implementation)
- `lib/settings/cubit/settings_state.dart`
- `lib/settings/cubit/settings_cubit.dart`
- `lib/apps_list/cubit/apps_list_cubit.dart`
- `lib/apps_list/widgets/window_tile.dart`
- related tests under `test/`

