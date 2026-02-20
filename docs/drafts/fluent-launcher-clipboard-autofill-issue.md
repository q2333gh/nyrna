# Feature Request: Auto-fill search box from clipboard on activation

## Summary

Request support for **automatically filling the search box with the current clipboard content** when Fluent Launcher is activated or its search/filter input is focused. Optionally, run the search/filter automatically so the user sees results for the copied text without typing or pasting manually.

## Use case

- User copies a word, phrase, or identifier (e.g. mod name, version, instance name from browser, editor, or another app).
- User opens Fluent Launcher or focuses the search/filter box.
- **Desired:** Search box is pre-filled with the clipboard content and (optionally) search/filter runs immediately.
- **Current:** User has to manually paste (Ctrl+V) after opening or focusing the input.

This reduces steps and matches “copy then search” workflows (e.g. paste a mod name to find an instance or resource). Similar behavior exists in tools like uTools (auto-paste recent clipboard into the search box when invoked).

## Proposed behavior

1. **On activation** (e.g. when the main window opens or when the search/filter input is focused):
   - Read current clipboard content (plain text).
   - If non-empty, fill the search box with it.
   - Optionally: run search/filter automatically so results show right away.

2. **Settings** (suggested, for user control):
   - Toggle: “Fill search box from clipboard on open” (default: off or on, per preference).
   - Toggle: “Run search automatically when filled from clipboard” (default: optional).

3. **Edge cases:**
   - Empty clipboard: leave search box empty as today.
   - Very long clipboard content: optionally truncate or only use first line for the search field.
   - Clipboard format: treat as plain text; ignore rich text/HTML for the search field.

## References

- [Fluent Launcher repository](https://github.com/Xcube-Studio/Natsurainko.FluentLauncher)
- [Fluent Launcher issues](https://github.com/Xcube-Studio/Natsurainko.FluentLauncher/issues)

---

If this is feasible, I’d be happy to help refine behavior or defaults. Thanks for considering it.
