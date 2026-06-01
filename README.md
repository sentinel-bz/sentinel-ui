# sentinel-ui

a luau ui library for roblox — crimson menu, dragging, tabs, the usual stuff.

## usage

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/sentinel-bz/sentinel-ui/main/Library.lua"))()

local Window = Library:CreateWindow({ Title = "sentinel", Footer = "DEV" })
local Tab    = Window:AddTab("tab")
local Box    = Tab:AddLeftGroupbox("section")

Box:AddToggle("MyToggle", { Text = "toggle", Default = false, Callback = function(v) end })
Box:AddSlider("MySlider", { Text = "slider", Default = 90, Min = 0, Max = 100, Callback = function(v) end })
Box:AddDropdown("MyDrop", { Values = { "a", "b" }, Multi = true, Callback = function(v) end })
Box:AddButton({ Text = "button", Func = function() end })
```

see [`example.lua`](example.lua) for every component.

## components

window · tabs · groupboxes · tabboxes · toggle · slider · dropdown · input · button · label · divider · keypicker · colorpicker · tooltip · watermark · playerlist · keybindlist.

## state & cleanup

- `Library.Toggles[idx]` / `Library.Options[idx]`; `:SetValue` / `:GetValue` / `:OnChanged` on each handle.
- one connection registry: `Library:GiveSignal` / `OnUnload` / `Unload`. unload disconnects everything, destroys the gui, clears `getgenv().Library`.
- re-running auto-unloads the previous instance.

## config + themes

obsidian's savemanager and thememanager work against it unmodified, vendored under [`dependencies/`](dependencies/). see [`example.lua`](example.lua).
