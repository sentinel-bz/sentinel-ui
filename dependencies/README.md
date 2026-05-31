# dependencies

Third-party code vendored into sentinel-ui. Not authored here.

## SaveManager.lua

Config save/load addon, vendored **verbatim** from the
[Obsidian UI Library](https://github.com/deividcomsono/Obsidian) by deividcomsono
(`addons/SaveManager.lua`). It works against sentinel-ui unmodified because our library mirrors
Obsidian's API (`Library.Toggles`/`Library.Options` registries, `:SetValue`/`:SetValueRGB`, etc.).

Licensed under the MIT License (© 2025 deividcomsono) — see [`LICENSE`](LICENSE). That notice must
remain with this file per the license.

Usage:

```lua
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/sentinel-bz/sentinel-ui/main/dependencies/SaveManager.lua"
))()
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("sentinel/configs")
SaveManager:BuildConfigSection(SomeTab)
SaveManager:LoadAutoloadConfig()
```
