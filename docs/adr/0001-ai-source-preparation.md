# Prepare AI source context in ai.context

Keep reference preparation, scoped-fix capture and diagnostic settling in ai.context so mappings bind operations, collect input and dispatch, while jobs retain their distinct validation/save precondition.

Preserve reference save-before-range and the later save check, file-path capture before saving, and scoped-fix capture of the original buffer before input and save, even when formatting leaves that context stale.

Diagnostics retain subscription-before-save, 300 ms quiet and a 1-second cap, with cleanup before rethrowing a failure message; yank.selection, clipboard formatting, prompts and pane delivery retain their owners.
