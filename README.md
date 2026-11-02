# neovim-config
The latest (refactored) version of my Neovim configuration. 

Copy `local.lua.example` to `local.lua` and edit it per machine.

## Agents

Agent integration comes from [herdr-nvim](https://github.com/ChmaraX/herdr-nvim). It works only inside a herdr session and needs the herdr plugin installed.

- `Space cc`: comment on the line or selection for the agent
- `Space cl`: list agent comments
- `Space cs`: paste comments to the agent
- `Space cS`: submit comments to the agent
- `Space ci`: reference the line or selection at the agent's cursor

Via ssh:
```
git clone git@github.com:aryan-binazir/neovim-config.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
```

Via http:
```
git clone https://github.com/aryan-binazir/neovim-config.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
```
