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

## ThemeManager.lua

Theme preset/save/load addon, vendored **verbatim** from the same
[Obsidian UI Library](https://github.com/deividcomsono/Obsidian) (`addons/ThemeManager.lua`). It
drives 5 master colors (`FontColor`/`MainColor`/`AccentColor`/`BackgroundColor`/`OutlineColor`);
sentinel-ui derives its 15 layered shades from those masters (`deriveScheme` in `Library.lua`), so
the addon runs unmodified. Inject a `"Sentinel"` built-in palette and set `DefaultTheme` from the
caller side to keep the out-of-box look. Same MIT License (© 2025 deividcomsono) — see
[`LICENSE`](LICENSE).

```lua
local ThemeManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/sentinel-bz/sentinel-ui/main/dependencies/ThemeManager.lua"
))()
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("sentinel/configs")
ThemeManager.BuiltInThemes["Sentinel"] =
    { 0, { FontColor = "c8c8c8", MainColor = "262626", AccentColor = "c32148", BackgroundColor = "141414", OutlineColor = "383838" } }
ThemeManager.DefaultTheme = "Sentinel"
ThemeManager:ApplyToTab(SomeTab)
```
