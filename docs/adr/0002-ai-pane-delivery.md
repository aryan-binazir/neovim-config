# Pane owns ready-to-send delivery

`ai.pane` owns opening or recovering a pane, waiting for readiness and dispatching text so callers cannot omit or reorder those steps. The tmux and Herdr adapters retain their readiness, recovery and transport policies because sharing those policies would change behavior. Moving tmux intact into a private adapter lets the existing pane module own the common delivery ordering without duplicating it in both adapters.

A failed readiness result keeps the existing warning, whether caused by timeout or Herdr pane replacement. Tmux waits on a captured target and sends through current pane state, including replacement during startup grace; Herdr aborts the wait when its target changes. This refactor preserves those distinct replacement contracts and the existing 15-second policy.
