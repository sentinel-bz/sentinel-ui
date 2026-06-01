--// sentinel ui usage example - should show every component

-- execute guard
if getgenv().Library and getgenv().Library.Unload then
	pcall(function()
		getgenv().Library:Unload()
	end)
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/sentinel-bz/sentinel-ui/main/Library.lua"))()

local Window = Library:CreateWindow({
	Title = "sentinel.bz",
	Footer = "DEV",
	Center = true,
	ShowCustomCursor = true,
	NotifySide = "Left",
	ToggleKeybind = Enum.KeyCode.RightControl,
})

local Aimbot = Window:AddTab("Aimbot")
local Visuals = Window:AddTab("Visuals")
Window:AddTab("Settings")

--// left column groupbox
local Box = Aimbot:AddLeftGroupbox("Section1")

local MyToggle = Box:AddToggle("MyToggle", {
	Text = "Toggle With All",
	Default = false,
	Callback = function(value)
		print("toggle:", value)
	end,
})
MyToggle:AddKeyPicker("MyKey", {
	Default = "LeftControl",
	Mode = "Toggle",
	Callback = function(state)
		print("keypicker state:", state)
	end,
})
MyToggle:AddColorPicker("MyColor", {
	Default = Color3.fromRGB(195, 33, 72),
	Callback = function(color)
		print("color:", color)
	end,
})

Box:AddSlider("MySlider", {
	Text = "Slider",
	Default = 90,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
	Callback = function(value)
		print("slider:", value)
	end,
})

Box:AddDropdown("MyMultiDrop", {
	Values = { "Item1", "Item2", "Item3" },
	Multi = true,
	Default = 1,
	Callback = function(value)
		print("multi dropdown changed")
	end,
})

Box:AddDropdown("MySingleDrop", {
	Text = "Mode",
	Values = { "Normal", "UPPERCASE", "lowercase" },
	Multi = false,
	Default = "Normal",
	Callback = function(value)
		print("single dropdown:", value)
	end,
})

Box:AddInput("MyInput", {
	Text = "Name",
	Placeholder = "type here...",
	Callback = function(text)
		print("input:", text)
	end,
})

local MyButton = Box:AddButton({
	Text = "Button",
	Func = function()
		print("button clicked")
	end,
})
MyButton:AddButton({
	Text = "Button2",
	Func = function()
		print("button 2 clicked")
	end,
})

--// right column: label with addons, divider
local Right = Aimbot:AddRightGroupbox("Section2")
local Info = Right:AddLabel({ Text = "Hover Me", Tooltip = "This is a tooltip" })
Info:AddKeyPicker("AimKey", { Default = "MB2", Mode = "Hold" })
Right:AddDivider()
Right:AddToggle("AnotherToggle", { Text = "another toggle", Default = true })

local Tabbox = Visuals:AddLeftTabbox()
local SecA = Tabbox:AddTab("Section1")
SecA:AddToggle("SecAToggle", { Text = "esp" })
SecA:AddSlider("SecASlider", { Text = "distance", Default = 500, Min = 0, Max = 2000 })
local SecB = Tabbox:AddTab("Section2")
SecB:AddToggle("SecBToggle", { Text = "tracers" })

-- windows
Library:SetWatermark("SENTINEL.bz | DEV")
local PlayerList = Library:CreatePlayerList()

--// theming
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/sentinel-bz/sentinel-ui/main/dependencies/ThemeManager.lua"))()
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("sentinel")
ThemeManager.BuiltInThemes["Sentinel"] =
	{ 0, { FontColor = "c8c8c8", MainColor = "262626", AccentColor = "c32148", BackgroundColor = "141414", OutlineColor = "383838" } }
ThemeManager.DefaultTheme = "Sentinel"
local ThemesTab = Window:AddTab("Themes")
ThemeManager:ApplyToTab(ThemesTab)

local InterfaceBox = ThemesTab:AddRightGroupbox("Interface")
InterfaceBox:AddSlider("FontSize", {
	Text = "Font size",
	Default = 12,
	Min = 8,
	Max = 24,
	Rounding = 0,
	Callback = function(value)
		Library:SetFontSize(value)
	end,
})

--// config save/load
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/sentinel-bz/sentinel-ui/main/dependencies/SaveManager.lua"))()
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("sentinel")

local ConfigTab = Window:AddTab("Config")
SaveManager:BuildConfigSection(ConfigTab)
SaveManager:LoadAutoloadConfig()

--// drive state
Library.Toggles["MyToggle"]:SetValue(true)
Library.Options["MySlider"]:OnChanged(function(value)
	print("MySlider observed:", value)
end)

-- Unload on End
local UserInputService = game:GetService("UserInputService")
Library:GiveSignal(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.End then
		Library:Unload()
	end
end))

Library:Notify({ Title = "Sentinel UI", Description = "loaded on the left side now" })
Library:Notify({ Title = "Keybinds", Description = "RightControl toggles · End unloads" })
Library:Notify("plain one-liner still works")
Library:Notify({ Title = "Watch the drain", Description = "empties toward the left edge", Time = 6 })

print("rightctrl = toggle, end unload")
