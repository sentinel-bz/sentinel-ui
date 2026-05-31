# sentinel-ui

A self-contained Luau UI library that recreates the "calcium.supply" cheat-menu *chrome* —
interface only, no gameplay logic. It reproduces the dump's exact layered-border visual style
(outline → accent → translucent fill, crimson accent `Color3.fromRGB(195, 33, 72)`, 12px stroked
font) while making everything data-driven.

## Usage

```lua
if getgenv().Library and getgenv().Library.Unload then
    pcall(function() getgenv().Library:Unload() end)
end

local Library = loadstring(game:HttpGet(".../Sentinel.lua"))()

local Window = Library:CreateWindow({ Title = "calcium.supply", Footer = "DEV" })
local Tab    = Window:AddTab("Aimbot")
local Box    = Tab:AddLeftGroupbox("Section1")

Box:AddToggle("MyToggle", { Text = "Toggle With All", Default = false, Callback = function(v) end })
Box:AddSlider("MySlider", { Text = "Slider", Default = 90, Min = 0, Max = 100, Callback = function(v) end })
Box:AddDropdown("MyDrop", { Values = { "Item1", "Item2" }, Multi = true, Callback = function(v) end })
Box:AddInput("MyInput", { Placeholder = "type here...", Callback = function(t) end })
Box:AddButton({ Text = "Button", Func = function() end })

local Tog = Box:AddToggle("WithAddons", { Text = "with addons" })
Tog:AddKeyPicker("MyKey", { Default = "LeftControl", Mode = "Toggle", Callback = function(s) end })
Tog:AddColorPicker("MyColor", { Default = Color3.fromRGB(195, 33, 72), Callback = function(c) end })
```

See [`example.lua`](example.lua) for every component type.

## Components

Window (drag, toggle keybind, optional custom cursor) · Tabs · Groupboxes · Tabboxes (section
switching) · Toggle · Slider · Dropdown (single/multi, floating list) · Input · Button · Label ·
Divider · KeyPicker (Always/Toggle/Hold) · ColorPicker (SV/hue/alpha, RGBA round-trip) · Tooltip ·
Watermark · PlayerList · KeybindList.

## State & cleanup

- `Library.Toggles[idx]`, `Library.Options[idx]` registries; `:SetValue`/`:GetValue`/`:OnChanged`
  on every handle.
- Single connection registry: `Library:GiveSignal`, `Library:OnUnload`, `Library:Unload`.
  `Unload()` runs teardown callbacks, disconnects all signals, unbinds the cursor render step,
  restores `MouseIconEnabled`, destroys the ScreenGui, and clears `getgenv().Library`.
- Re-running the script auto-unloads any prior instance.

Pure Luau, single file, no dependencies; runs as an executor script.
