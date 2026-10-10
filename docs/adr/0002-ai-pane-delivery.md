# Pane owns ready-to-send delivery

`ai.pane` owns opening or recovering a pane, waiting under the existing 15-second readiness policy, sending text and warning on timeout. Keymaps request reference or block delivery and retain buffer writes and text suffixes. A private tmux adapter holds the original implementation alongside the existing Herdr adapter, so shell polling and startup grace remain distinct from Herdr agent readiness.

Readiness still captures a target while transport uses the adapter's current pane state. This refactor preserves the baseline replacement, routing, focus and failure behavior rather than changing concurrency policy. Lifecycle methods belong to the adapters and are absent from the public pane interface; callers use `deliver`, `deliver_block` or `toggle`.
