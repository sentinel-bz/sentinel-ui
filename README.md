# sentinel-ui

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
