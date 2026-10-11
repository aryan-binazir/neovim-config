# neovim-config
The latest (refactored) version of my Neovim configuration. 

## AI editing

Copy `local.lua.example` to `local.lua`. Pi is the default agent; set `vim.g.ai.tool` to `codex`, `claude`, or `opencode` to override it. Only `local.lua` is loaded; the example is a setup template. If `vim.g.ai.tool` is omitted, it defaults to `pi`.

Press `Space cf` in normal mode for the current line and nearby context, or in visual mode for the selected lines. Enter your instruction at `LLM Message:`. The original buffer is saved, then only the file location, numbered snippet, and your message are pasted into the AI side pane, with no canned editing instructions. Focus moves there. Press Enter to submit, then continue the conversation in that agent.

If no AI pane is open, the configured agent is launched. An existing AI pane is reused, just like `Space cx`. Pane hosting uses tmux or Herdr. The former background-job modal (`Space cl`) is removed.

Via ssh:
```
git clone git@github.com:aryan-binazir/neovim-config.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
```

Via http:
```
git clone https://github.com/aryan-binazir/neovim-config.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
```

