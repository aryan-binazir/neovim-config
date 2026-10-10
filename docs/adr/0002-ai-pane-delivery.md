# Pane owns ready-to-send delivery

Review the stack in order: source preparation in PR #11 at `ebf2b9b8e1f217fe3475b44abc496cd0c2a6fe75`, then pane delivery in PR #10. Source context owns reference preparation and saving, including both baseline update checks. Keymaps retain the inherited source capture and prompt order, append a space to references or a newline to blocks, and dispatch through `ai.pane`.

`ai.pane` owns opening or recovering a pane, waiting for readiness and dispatching text so callers cannot omit or reorder those steps. The tmux and Herdr adapters retain their readiness, recovery and transport policies because sharing those policies would change behavior. The tmux implementation moves into a private adapter with runtime behavior preserved.

A failed readiness result keeps the existing warning, whether caused by timeout or Herdr pane replacement. Tmux waits on a captured target and sends through current pane state, including replacement during startup grace; Herdr aborts the wait when its target changes. This refactor preserves those distinct replacement contracts and the existing 15-second policy.
