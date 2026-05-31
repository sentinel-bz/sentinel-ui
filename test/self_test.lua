-- Self-test flow. Assumes mock globals + `Library` are already defined in this chunk.
local Lib = Library

local function mkInput(t)
	t.__rbxtype = "InputObject"
	t.Changed = Mock.Signal()
	return t
end

print("== construct ==")
local Window = Lib:CreateWindow({ Title = "calcium.supply", Footer = "DEV", Center = false })
local Tab = Window:AddTab("Aimbot")
local Tab2 = Window:AddTab("Visuals")
Window:AddTab("Settings")

local Box = Tab:AddLeftGroupbox("Section1")
local Toggle = Box:AddToggle("MyToggle", { Text = "Toggle With All", Default = false, Callback = function() end })
Toggle:AddKeyPicker("MyKey", { Default = "LeftControl", Mode = "Toggle", Callback = function() end })
Toggle:AddColorPicker("MyColor", { Default = Color3.new(1, 0, 0), Callback = function() end })

local Slider = Box:AddSlider("MySlider", { Text = "Slider", Default = 90, Min = 0, Max = 100, Rounding = 0 })
local Drop = Box:AddDropdown("MyDrop", { Values = { "Item1", "Item2", "Item3" }, Multi = true, Default = 1 })
local Drop2 = Box:AddDropdown("MyDrop2", { Values = { "A", "B" }, Multi = false, Default = "A" })
local Input = Box:AddInput("MyInput", { Placeholder = "type here...", Callback = function() end })
local Btn = Box:AddButton({ Text = "Button", Func = function() end })
Btn:AddButton({ Text = "Button2", Func = function() end })

local RBox = Tab:AddRightGroupbox("Right")
local Lbl = RBox:AddLabel("a label")
Lbl:AddKeyPicker("LKey", { Default = "MB2", Mode = "Hold" })
RBox:AddDivider()

local TBox = Tab2:AddLeftTabbox()
local S1 = TBox:AddTab("Section1")
S1:AddToggle("T1", { Text = "sub a" })
local S2 = TBox:AddTab("Section2")
S2:AddToggle("T2", { Text = "sub b" })

print("== satellites ==")
Lib:SetWatermark("CALCIUM.supply | DEV")
local PL = Lib:CreatePlayerList()
PL:SetPlayers({ { Name = "yatskivdenis", Status = "None", Team = "Neutral" }, { Name = "F9MX" } })

print("== toggle window on ==")
Window:Toggle(true)
assert(Lib.Toggled == true, "window should be toggled on")
Mock.MockRender()

print("== tab switching ==")
Tab2.Button.MouseButton1Click:Fire()
assert(Lib.ActiveTab.Name == "Visuals", "active tab should be Visuals")
Tab.Button.MouseButton1Click:Fire()
assert(Lib.ActiveTab.Name == "Aimbot", "active tab should be Aimbot")

print("== tabbox section switch ==")
S2.Button.MouseButton1Click:Fire()
assert(S2.Container.Visible == true and S1.Container.Visible == false, "section 2 should show")

print("== toggle interaction ==")
Toggle:SetValue(true)
assert(Lib.Toggles["MyToggle"]:GetValue() == true, "toggle value")

print("== slider drag ==")
local Bar
for _, child in Slider.Holder:GetChildren() do
	if child.ClassName == "TextButton" then
		Bar = child
		break
	end
end
assert(Bar, "slider bar found")
Bar.InputBegan:Fire(mkInput({ UserInputType = Enum.UserInputType.MouseButton1, UserInputState = Enum.UserInputState.Begin, Position = Vector2.new(70, 60) }))
UIS.InputChanged:Fire(mkInput({ UserInputType = Enum.UserInputType.MouseMovement, UserInputState = Enum.UserInputState.Change, Position = Vector2.new(70, 60) }))
Bar.InputEnded:Fire(mkInput({ UserInputType = Enum.UserInputType.MouseButton1, UserInputState = Enum.UserInputState.End }))
print("   slider value:", Slider:GetValue())
Slider:SetValue(50)
assert(Slider:GetValue() == 50, "slider set")

print("== dropdown ==")
Drop:SetValue({ "Item1", "Item3" })
local active = Drop:GetActiveValues()
assert(#active == 2, "multi dropdown 2 selected")
Drop2:SetValue("B")
assert(Drop2:GetValue() == "B", "single dropdown")

print("== input ==")
Input:SetValue("hello world")
assert(Input:GetValue() == "hello world", "input set")

print("== keypicker capture + activation ==")
local KP = Lib.Options["MyKey"]
UIS.InputBegan:Fire(
	mkInput({ UserInputType = Enum.UserInputType.Keyboard, UserInputState = Enum.UserInputState.Begin, KeyCode = Enum.KeyCode.LeftControl }),
	false
)
print("   keypicker state:", KP:GetState())

print("== colorpicker ==")
local CP = Lib.Options["MyColor"]
CP:SetValueRGB(Color3.fromRGB(0, 255, 0))
print("   colorpicker ok")

print("== accent swap ==")
Lib:SetAccent(Color3.fromRGB(0, 120, 255))

print("== unload ==")
Lib:Unload()
assert(Lib.Unloaded == true, "unloaded flag")
assert(getgenv().Library == nil, "global cleared")

print("== re-exec after clean unload ==")
local Lib2 = LoadLibrary()
assert(Lib2 ~= Lib, "fresh library instance")
assert(getgenv().Library == Lib2, "global points at fresh instance")
Lib2:CreateWindow({ Title = "again", Center = false }):AddTab("Tab"):AddLeftGroupbox("Box"):AddToggle("X", { Text = "x" })

print("== re-exec while live (guard auto-unloads prior) ==")
local Lib3 = LoadLibrary()
assert(Lib2.Unloaded == true, "guard unloaded the prior live instance")
assert(getgenv().Library == Lib3, "global points at newest instance")
Lib3:Unload()

print("\nALL SELF-TEST STEPS PASSED")
