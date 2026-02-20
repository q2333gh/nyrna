# Feature Request: Auto-trigger search and autofill query from clipboard on activation

## Summary

Request support for **automatically filling the main search box with the current clipboard content** when Fluent Search is activated (e.g. by hotkey). Optionally, automatically run the search so the user sees results for the copied text without typing or pasting manually.

## Use case

- User copies a word, phrase, or URL (e.g. from browser, editor, or another app).
- User invokes Fluent Search (hotkey or other activation).
- **Desired:** Search box is pre-filled with the clipboard content and (optionally) search runs immediately.
- **Current:** User has to manually paste (Ctrl+V) after opening Fluent Search.

This reduces steps and matches workflows where “copy then search” is common (lookup, translate, open URL, etc.).

## Proposed behavior

1. **On activation** (e.g. when the main window opens via hotkey):
   - Read current clipboard content (plain text).
   - If non-empty, fill the main search box with it.
   - Optionally: run search automatically so results show right away.

2. **Settings** (suggested, for user control):
   - Toggle: “Fill search box from clipboard on open” (default: off or on, per preference).
   - Toggle: “Run search automatically when filled from clipboard” (default: optional).

3. **Edge cases:**
   - Empty clipboard: leave search box empty as today.
   - Very long clipboard content: optionally truncate or only use first line for search box.
   - Clipboard format: treat as plain text; ignore rich text/HTML for the search field.

## Relation to existing clipboard features

- The **clipboard tag / Clipboard.Fluent.Plugin** provide **clipboard history search** (search within past copies). That is separate and valuable.
- This request is about **pre-filling the main search box with the *current* clipboard** when the launcher opens, so the user can immediately search for what they just copied, without an extra paste step.

## References

- [Clipboard wiki](https://github.com/adirh3/Fluent-Search/wiki/3.3-Clipboard)
- [Clipboard plugin](https://github.com/adirh3/Clipboard.Fluent.Plugin)

---

If this is feasible, I’d be happy to help refine behavior or defaults. Thanks for considering it.
