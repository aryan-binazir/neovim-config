"""Run the source preparation checks without loading the user's config."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

repo = Path(__file__).resolve().parents[1]
nvim = shutil.which("nvim")
if nvim is None:
    raise SystemExit("nvim is required")
with tempfile.TemporaryDirectory(prefix="nvim-source-preparation-") as tmp:
    env = os.environ.copy()
    fakebin = Path(tmp) / "bin"
    fakebin.mkdir()
    for tool in ("claude", "codex", "opencode", "pi", "tmux", "herdr"):
        fixture = fakebin / tool
        fixture.write_text("#!/bin/sh\necho 'Unexpected external tool in source preparation test' >&2\nexit 99\n")
        fixture.chmod(0o700)
    env["PATH"] = str(fakebin) + ":/usr/bin:/bin"
    for name in ("TMUX", "TMUX_PANE", "HERDR_ENV", "NVIM", "NVIM_LISTEN_ADDRESS"):
        env.pop(name, None)
    (Path(tmp) / ".git").mkdir()
    for name in ("XDG_CACHE_HOME", "XDG_DATA_HOME", "XDG_STATE_HOME", "XDG_CONFIG_HOME"):
        env[name] = str(Path(tmp) / name.lower())
    runtime = Path(tmp) / "runtime"
    runtime.mkdir(mode=0o700)
    env["XDG_RUNTIME_DIR"] = str(runtime)
    env["AI_TEST_TMP"] = tmp
    env["NVIM_LOG_FILE"] = str(Path(tmp) / "nvim.log")
    result = subprocess.run(
        [nvim, "--headless", "-u", "NONE", "-i", "NONE", "-l", str(repo / "tests/source_preparation.lua")],
        cwd=repo, env=env, stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=40,
    )
    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)
    complete = "source preparation checks passed" in result.stdout + result.stderr
    if not complete:
        print("Source preparation suite did not complete", file=sys.stderr)
    raise SystemExit(result.returncode or (0 if complete else 1))
