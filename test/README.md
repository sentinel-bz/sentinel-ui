# test

Headless validation for the library. `mock.lua` is a minimal Roblox API stub so `Sentinel.lua`
can run under the standalone [`luau`](https://github.com/luau-lang/luau) CLI with no engine.

- `run.ps1` — stitches mock + library + `self_test.lua` into one chunk and runs the full flow
  (construct every component → toggle → tab/section switch → slider drag → dropdown → keypicker →
  colorpicker → unload → re-exec guard).
- `run_example.ps1` — runs `../example.lua` through the real `loadstring(game:HttpGet(...))()` path.

Needs `luau` on `PATH` (or at `~/.luau-bin/luau.exe`). The `_combined*.lua` files are generated.
