# Pane owns ready-to-send delivery

Place pane opening, recovery, readiness and delivery in `ai.pane` so keymaps cannot skip or reorder that lifecycle; source context keeps reference preparation/saving and keymaps keep prompts and text suffixes. Keep tmux and Herdr as separate adapters because they use different readiness and transport policies. Preserve baseline timeout, focus and replacement behavior: tmux waits for a captured target and sends through current pane state, while Herdr cancels readiness when its target changes.
