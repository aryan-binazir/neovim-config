# Testing

Use the existing Lua test harness running in headless Neovim. Do not use Python for testing.

Run the relevant suites through `tests/run.sh`:

```sh
bash tests/run.sh source_preparation
bash tests/run.sh pane_delivery
```

# Languages

Do not introduce programming languages other than Lua and Bash.
