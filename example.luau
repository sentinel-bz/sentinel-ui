--// Sentinel usage example — demonstrates every component type.
--// Point the URL at wherever Library.luau is hosted, or require it locally.

-- Re-execution guard: kill any prior instance before re-running.
if getgenv().Library and getgenv().Library.Unload then
	pcall(function()
		getgenv().Library:Unload()
	end)
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/sentinel-cx/sentinel-ui/main/Library.luau"))()

local Window = Library:CreateWindow({
	Title = "calcium.supply",
	Footer = "DEV",
	Center = true,
	ShowCustomCursor = false,
	ToggleKeybind = Enum.KeyCode.RightControl,
})

local Aimbot = Window:AddTab("Aimbot")
local Visuals = Window:AddTab("Visuals")
Window:AddTab("Settings")

--// Left column groupbox \\--
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

--// Right column: label with addons, divider \\--
local Right = Aimbot:AddRightGroupbox("Section2")
local Info = Right:AddLabel("hover me", true)
Info:AddKeyPicker("AimKey", { Default = "MB2", Mode = "Hold" })
Right:AddDivider()
Right:AddToggle("AnotherToggle", { Text = "another toggle", Default = true })

--// Tabbox with switchable sections (Section1 / Section2) \\--
local Tabbox = Visuals:AddLeftTabbox()
local SecA = Tabbox:AddTab("Section1")
SecA:AddToggle("SecAToggle", { Text = "esp" })
SecA:AddSlider("SecASlider", { Text = "distance", Default = 500, Min = 0, Max = 2000 })
local SecB = Tabbox:AddTab("Section2")
SecB:AddToggle("SecBToggle", { Text = "tracers" })

--// Satellite windows (data-driven) \\--
Library:SetWatermark("CALCIUM.supply | DEV")

local PlayerList = Library:CreatePlayerList()
PlayerList:SetPlayers({
	{ Name = "yatskivdenis", Status = "None", Team = "Neutral" },
	{ Name = "F9MX", Status = "None", Team = "Neutral" },
})

--// Drive state programmatically \\--
Library.Toggles["MyToggle"]:SetValue(true)
Library.Options["MySlider"]:OnChanged(function(value)
	print("MySlider observed:", value)
end)

print("Sentinel example loaded. Press RightControl to toggle the menu.")
