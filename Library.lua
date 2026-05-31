--!nonstrict
--// Sentinel UI Library — a data-driven reimplementation of the "calcium.supply" menu chrome.
--// Interface framework only: components fire a user-supplied Callback and nothing else.

if getgenv and getgenv().Library and getgenv().Library.Unload then
	pcall(function()
		getgenv().Library:Unload()
	end)
end

--// Executor bootstrap \\--
local cloneref = cloneref or clonereference or function(instance)
	return instance
end
local Services = setmetatable({}, {
	__index = function(self, name)
		local success, result = pcall(game.GetService, game, name)
		if success then
			local service = cloneref(result)
			rawset(self, name, service)
			return service
		end
		warn("Invalid Service: " .. tostring(name))
	end,
})

local UserInputService = Services.UserInputService
local RunService = Services.RunService
local TweenService = Services.TweenService
local Players = Services.Players
local TextService = Services.TextService

local getgenv = getgenv or function()
	return shared
end
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function()
	return Services.CoreGui
end
local setclipboard = setclipboard or function() end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = cloneref(LocalPlayer:GetMouse())
local OriginalMouseIconEnabled = UserInputService.MouseIconEnabled

local FONT = Font.new("rbxassetid://12187371840", Enum.FontWeight.Regular, Enum.FontStyle.Normal)

--// Theme \\--
local Scheme = {
	Border = Color3.fromRGB(0, 0, 0),
	Outline = Color3.fromRGB(10, 10, 10),
	Accent = Color3.fromRGB(195, 33, 72),
	Body = Color3.fromRGB(20, 20, 20),
	Inline = Color3.fromRGB(30, 30, 30),
	FontColor = Color3.fromRGB(200, 200, 200),
	DimColor = Color3.fromRGB(170, 170, 170),
	Dark = Color3.fromRGB(8, 8, 8),
	DarkBorder = Color3.fromRGB(19, 19, 19),
	Element = Color3.fromRGB(38, 38, 38),
	ElementBorder = Color3.fromRGB(56, 56, 56),
	ElementFill = Color3.fromRGB(22, 22, 22),
	Pop = Color3.fromRGB(50, 50, 50),
	White = Color3.fromRGB(255, 255, 255),
	Divider = Color3.fromRGB(32, 32, 38),
}

local ColorProps = {
	BackgroundColor3 = true,
	TextColor3 = true,
	BorderColor3 = true,
	ScrollBarImageColor3 = true,
	ImageColor3 = true,
	PlaceholderColor3 = true,
	Color = true,
}

local Library = {
	Version = "1.0.0",
	Scheme = Scheme,
	Toggled = false,
	Unloaded = false,
	IsRobloxFocused = true,

	ToggleKeybind = Enum.KeyCode.RightControl,
	ShowCustomCursor = false,

	TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

	Toggles = {},
	Options = {},

	Registry = {},
	Signals = {},
	UnloadSignals = {},

	Tabs = {},
	ActiveTab = nil,

	KeybindRows = {},

	ScreenGui = nil,
	ShowCursorBinding = string.sub(tostring({}), 8),
}

--// Factory \\--
local Templates = {
	Frame = { BorderSizePixel = 0 },
	ScrollingFrame = { BorderSizePixel = 0 },
	ImageLabel = { BackgroundTransparency = 1, BorderSizePixel = 0 },
	TextLabel = { BorderSizePixel = 0, FontFace = FONT, RichText = false, TextSize = 12 },
	TextButton = { BorderSizePixel = 0, FontFace = FONT, AutoButtonColor = false, TextSize = 12 },
	TextBox = { BorderSizePixel = 0, FontFace = FONT, TextSize = 12, ClearTextOnFocus = false },
	UIListLayout = { SortOrder = Enum.SortOrder.LayoutOrder },
}

local function FillInstance(instance, props)
	local themeProps = Library.Registry[instance]
	for key, value in props do
		if key == "Parent" then
			continue
		end
		if ColorProps[key] and typeof(value) == "string" then
			themeProps = themeProps or {}
			themeProps[key] = value
			value = Scheme[value]
		end
		instance[key] = value
	end
	if themeProps then
		Library.Registry[instance] = themeProps
	end
end

local function New(class, props)
	local instance = Instance.new(class)
	if Templates[class] then
		FillInstance(instance, Templates[class])
	end
	if props then
		FillInstance(instance, props)
		if props.Parent then
			instance.Parent = props.Parent
		end
	end
	return instance
end

function Library:AddToRegistry(instance, properties)
	Library.Registry[instance] = properties
end

function Library:RemoveFromRegistry(instance)
	Library.Registry[instance] = nil
end

function Library:UpdateColorsUsingRegistry()
	for instance, properties in Library.Registry do
		for property, key in properties do
			local value = Scheme[key]
			if value ~= nil then
				pcall(function()
					instance[property] = value
				end)
			end
		end
	end
end

function Library:SetAccent(color)
	Scheme.Accent = color
	Library:UpdateColorsUsingRegistry()
end

--// Helpers \\--
local function IsMouseInput(input, includeM2)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or (includeM2 == true and input.UserInputType == Enum.UserInputType.MouseButton2)
		or input.UserInputType == Enum.UserInputType.Touch
end
local function IsClickInput(input, includeM2)
	return IsMouseInput(input, includeM2)
		and input.UserInputState == Enum.UserInputState.Begin
		and Library.IsRobloxFocused
end
local function IsHoverInput(input)
	return (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
		and input.UserInputState == Enum.UserInputState.Change
end
local function IsDragInput(input)
	return IsMouseInput(input)
		and (input.UserInputState == Enum.UserInputState.Begin or input.UserInputState == Enum.UserInputState.Change)
		and Library.IsRobloxFocused
end

local function Round(value, rounding)
	rounding = rounding or 0
	if rounding == 0 then
		return math.floor(value + 0.5)
	end
	local mult = 10 ^ rounding
	return math.floor(value * mult + 0.5) / mult
end

local function Trim(text)
	return text:match("^%s*(.-)%s*$")
end

function Library:GiveSignal(connection)
	local t = typeof(connection)
	if connection and (t == "RBXScriptConnection" or t == "RBXScriptSignal") then
		table.insert(Library.Signals, connection)
	end
	return connection
end

function Library:SafeCallback(func, ...)
	if typeof(func) ~= "function" then
		return
	end
	local args = { ... }
	local ok, err = pcall(function()
		return func(table.unpack(args))
	end)
	if not ok then
		warn("[Sentinel] callback error: " .. tostring(err))
	end
end

function Library:MouseIsOverFrame(frame, position)
	local pos, size = frame.AbsolutePosition, frame.AbsoluteSize
	return position.X >= pos.X
		and position.X <= pos.X + size.X
		and position.Y >= pos.Y
		and position.Y <= pos.Y + size.Y
end

function Library:Validate(table_, template)
	if typeof(table_) ~= "table" then
		table_ = {}
	end
	for key, value in template do
		if typeof(key) == "number" then
			continue
		end
		if typeof(value) == "table" then
			table_[key] = Library:Validate(table_[key], value)
		elseif table_[key] == nil then
			table_[key] = value
		end
	end
	return table_
end

local KeyShortNames = {
	[Enum.KeyCode.LeftControl] = "lc",
	[Enum.KeyCode.RightControl] = "rc",
	[Enum.KeyCode.LeftShift] = "ls",
	[Enum.KeyCode.RightShift] = "rs",
	[Enum.KeyCode.LeftAlt] = "la",
	[Enum.KeyCode.RightAlt] = "ra",
	[Enum.KeyCode.Space] = "space",
	[Enum.UserInputType.MouseButton1] = "mb1",
	[Enum.UserInputType.MouseButton2] = "mb2",
	[Enum.UserInputType.MouseButton3] = "mb3",
}
function Library:GetKeyString(key)
	if KeyShortNames[key] then
		return KeyShortNames[key]
	end
	if typeof(key) == "EnumItem" then
		return key.Name:lower()
	end
	return tostring(key):lower()
end

--// Layered builders \\--
-- Window idiom from the dump: outline(10,10,10) -> accent(crimson) -> translucent body(20,20,20 @0.76).
local function MakeWindowShell(parent, size, position, titleText)
	local Outline = New("Frame", {
		Parent = parent,
		BackgroundColor3 = "Outline",
		BorderColor3 = "Border",
		Position = position or UDim2.fromOffset(0, 0),
		Size = size,
	})
	local Accent = New("Frame", {
		Parent = Outline,
		BackgroundColor3 = "Accent",
		BorderColor3 = "Border",
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
	})
	local Body = New("Frame", {
		Parent = Accent,
		BackgroundColor3 = "Body",
		BorderColor3 = "Border",
		BackgroundTransparency = 0.76,
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
	})
	New("UIPadding", {
		Parent = Body,
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
	})
	local Title
	if titleText then
		Title = New("TextLabel", {
			Parent = Body,
			Name = "Title",
			Text = titleText,
			TextColor3 = "FontColor",
			TextStrokeTransparency = 0,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 12),
			Position = UDim2.fromOffset(0, 2),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Interactable = false,
		})
	end
	return { Outline = Outline, Accent = Accent, Body = Body, Title = Title }
end

-- Panel idiom from the dump: outline(10,10,10) -> inline(30,30,30) -> body(20,20,20).
local function MakePanel(parent, size, position)
	local Outline = New("Frame", {
		Parent = parent,
		BackgroundColor3 = "Outline",
		BorderColor3 = "Border",
		Size = size,
		Position = position or UDim2.fromOffset(0, 0),
	})
	local Inline = New("Frame", {
		Parent = Outline,
		BackgroundColor3 = "Inline",
		BorderColor3 = "Border",
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = 2,
	})
	local Body = New("Frame", {
		Parent = Inline,
		BackgroundColor3 = "Body",
		BorderColor3 = "Border",
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
	})
	return Outline, Inline, Body
end

-- Auto-height variant: the 1px insets are done with UIPadding (not scale-Y), so AutomaticSize.Y
-- propagates content -> body -> inline -> outline. Used by groupboxes/tabboxes so they end just
-- below their last element instead of filling the column.
local function MakeAutoPanel(parent)
	local function layer(host, color, zindex)
		local frame = New("Frame", {
			Parent = host,
			BackgroundColor3 = color,
			BorderColor3 = "Border",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = zindex,
		})
		New("UIPadding", {
			Parent = frame,
			PaddingTop = UDim.new(0, 1),
			PaddingBottom = UDim.new(0, 1),
			PaddingLeft = UDim.new(0, 1),
			PaddingRight = UDim.new(0, 1),
		})
		return frame
	end
	local Outline = layer(parent, "Outline", 1)
	local Inline = layer(Outline, "Inline", 2)
	local Body = New("Frame", {
		Parent = Inline,
		BackgroundColor3 = "Body",
		BorderColor3 = "Border",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	return Outline, Inline, Body
end

--// ScreenGui \\--
local function ParentUI(ui)
	pcall(protectgui, ui)
	local ok = pcall(function()
		ui.Parent = gethui()
	end)
	if not (ok and ui.Parent) then
		ui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
end

local ScreenGui = New("ScreenGui", {
	Name = "\0" .. string.rep(" ", 6),
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	ResetOnSpawn = false,
	DisplayOrder = 999,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui

ScreenGui.DescendantRemoving:Connect(function(instance)
	if Library.Registry[instance] then
		Library.Registry[instance] = nil
	end
end)

--// Custom cursor (crosshair) \\--
local Cursor
do
	Cursor = New("Frame", {
		Parent = ScreenGui,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "White",
		BorderColor3 = "Border",
		Size = UDim2.fromOffset(9, 1),
		Visible = false,
		ZIndex = 11000,
	})
	New("Frame", {
		Parent = Cursor,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "Border",
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 2, 1, 2),
		ZIndex = 10999,
	})
	local Vert = New("Frame", {
		Parent = Cursor,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "White",
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1, 9),
		ZIndex = 11000,
	})
	New("Frame", {
		Parent = Vert,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "Border",
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 2, 1, 2),
		ZIndex = 10999,
	})
end

--// Dragging \\--
function Library:MakeDraggable(ui, dragFrame, isMainWindow)
	local startPos, framePos
	local dragging = false
	local changed

	dragFrame.InputBegan:Connect(function(input)
		if not IsClickInput(input) then
			return
		end
		startPos = input.Position
		framePos = ui.Position
		dragging = true
		changed = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				if changed then
					changed:Disconnect()
					changed = nil
				end
			end
		end)
	end)

	Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
		if (isMainWindow and not Library.Toggled) or not (ScreenGui and ScreenGui.Parent) then
			dragging = false
			return
		end
		if dragging and IsHoverInput(input) then
			local delta = input.Position - startPos
			ui.Position = UDim2.new(
				framePos.X.Scale,
				framePos.X.Offset + delta.X,
				framePos.Y.Scale,
				framePos.Y.Offset + delta.Y
			)
		end
	end))
end

function Library:MakeResizable(ui, dragFrame, minSize, callback)
	local startPos, frameSize
	local dragging = false
	local changed

	dragFrame.InputBegan:Connect(function(input)
		if not IsClickInput(input) then
			return
		end
		startPos = input.Position
		frameSize = ui.Size
		dragging = true
		changed = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				if changed then
					changed:Disconnect()
					changed = nil
				end
			end
		end)
	end)

	Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
		if not ui.Visible or not (ScreenGui and ScreenGui.Parent) then
			dragging = false
			return
		end
		if dragging and IsHoverInput(input) then
			local delta = input.Position - startPos
			ui.Size = UDim2.new(
				frameSize.X.Scale,
				math.clamp(frameSize.X.Offset + delta.X, minSize.X, math.huge),
				frameSize.Y.Scale,
				math.clamp(frameSize.Y.Offset + delta.Y, minSize.Y, math.huge)
			)
			if callback then
				Library:SafeCallback(callback)
			end
		end
	end))
end

--// Context menus / popups (dropdown list, colorpicker, keypicker modes) \\--
local CurrentMenu
function Library:AddContextMenu(holder, size, offset, list)
	local Menu
	if list then
		Menu = New("ScrollingFrame", {
			Parent = ScreenGui,
			BackgroundTransparency = 1,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.fromOffset(0, 0),
			ScrollBarThickness = 0,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Size = typeof(size) == "function" and size() or size,
			Visible = false,
			ZIndex = 50,
		})
	else
		Menu = New("Frame", {
			Parent = ScreenGui,
			BackgroundTransparency = 1,
			Size = typeof(size) == "function" and size() or size,
			Visible = false,
			ZIndex = 50,
		})
	end

	local Table = { Active = false, Holder = holder, Menu = Menu, Signal = nil, Size = size }

	local function reposition()
		local o = typeof(offset) == "function" and offset() or offset
		Menu.Position = UDim2.fromOffset(
			math.floor(holder.AbsolutePosition.X + o[1]),
			math.floor(holder.AbsolutePosition.Y + o[2])
		)
	end

	function Table:Open()
		if CurrentMenu == Table then
			return
		elseif CurrentMenu then
			CurrentMenu:Close()
		end
		CurrentMenu = Table
		Table.Active = true
		Menu.Size = typeof(Table.Size) == "function" and Table.Size() or Table.Size
		reposition()
		Menu.Visible = true
		Table.Signal = holder:GetPropertyChangedSignal("AbsolutePosition"):Connect(reposition)
	end

	function Table:Close()
		if CurrentMenu ~= Table then
			return
		end
		Menu.Visible = false
		if Table.Signal then
			Table.Signal:Disconnect()
			Table.Signal = nil
		end
		Table.Active = false
		CurrentMenu = nil
	end

	function Table:Toggle()
		if Table.Active then
			Table:Close()
		else
			Table:Open()
		end
	end

	function Table:SetSize(newSize)
		Table.Size = newSize
		Menu.Size = typeof(newSize) == "function" and newSize() or newSize
	end

	return Table
end

Library:GiveSignal(UserInputService.InputBegan:Connect(function(input)
	if Library.Unloaded then
		return
	end
	if IsClickInput(input, true) and CurrentMenu then
		local pos = input.Position
		if
			not (
				Library:MouseIsOverFrame(CurrentMenu.Menu, pos)
				or Library:MouseIsOverFrame(CurrentMenu.Holder, pos)
			)
		then
			CurrentMenu:Close()
		end
	end
end))

--// Tooltip \\--
-- dump's Tooltip: outer(8,8,8) -> inner(38,38,38, 1px 56,56,56) -> label, auto-sized via a padding chain (no relative sizes, so it can't collapse)
local TooltipFrame = New("Frame", {
	Parent = ScreenGui,
	BackgroundColor3 = "Dark",
	BorderColor3 = "DarkBorder",
	AutomaticSize = Enum.AutomaticSize.XY,
	Size = UDim2.fromOffset(0, 0),
	Visible = false,
	ZIndex = 60,
})
New("UIPadding", {
	Parent = TooltipFrame,
	PaddingTop = UDim.new(0, 1),
	PaddingBottom = UDim.new(0, 1),
	PaddingLeft = UDim.new(0, 1),
	PaddingRight = UDim.new(0, 1),
})
local TooltipInner = New("Frame", {
	Parent = TooltipFrame,
	BackgroundColor3 = "Element",
	BorderColor3 = "ElementBorder",
	BorderSizePixel = 1,
	AutomaticSize = Enum.AutomaticSize.XY,
	Size = UDim2.fromOffset(0, 0),
	ZIndex = 60,
})
New("UIPadding", {
	Parent = TooltipInner,
	PaddingTop = UDim.new(0, 2),
	PaddingBottom = UDim.new(0, 4),
	PaddingLeft = UDim.new(0, 4),
	PaddingRight = UDim.new(0, 4),
})
local TooltipLabel = New("TextLabel", {
	Parent = TooltipInner,
	Text = "",
	TextColor3 = "FontColor",
	TextStrokeTransparency = 0,
	BackgroundTransparency = 1,
	AutomaticSize = Enum.AutomaticSize.XY,
	Size = UDim2.fromOffset(0, 14),
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 61,
})
local CurrentHover
function Library:AddTooltip(infoStr, hoverInstance)
	if typeof(infoStr) ~= "string" then
		return
	end
	local tip = { Signals = {} }
	local function doHover()
		if CurrentHover == hoverInstance or (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse)) then
			return
		end
		-- MouseEnter also fires when an element becomes visible under a stationary cursor (tab/section
		-- switch), so confirm the cursor is genuinely over the element before showing anything.
		if not (Library.Toggled and Library:MouseIsOverFrame(hoverInstance, Mouse)) then
			return
		end
		CurrentHover = hoverInstance
		TooltipLabel.Text = infoStr
		while
			Library.Toggled
			and Library:MouseIsOverFrame(hoverInstance, Mouse)
			and not (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
		do
			TooltipFrame.Visible = true
			TooltipFrame.Position = UDim2.fromOffset(Mouse.X + 14, Mouse.Y + 12)
			RunService.RenderStepped:Wait()
		end
		TooltipFrame.Visible = false
		CurrentHover = nil
	end
	table.insert(tip.Signals, hoverInstance.MouseEnter:Connect(doHover))
	table.insert(tip.Signals, hoverInstance.MouseMoved:Connect(doHover))
	table.insert(
		tip.Signals,
		hoverInstance.MouseLeave:Connect(function()
			if CurrentHover == hoverInstance then
				TooltipFrame.Visible = false
				CurrentHover = nil
			end
		end)
	)
	function tip:Destroy()
		for _, c in tip.Signals do
			if c.Connected then
				c:Disconnect()
			end
		end
	end
	Library:OnUnload(function()
		tip:Destroy()
	end)
	return tip
end

--===================================================================--
--// Component constructors (Funcs)                                  --
--===================================================================--
local Funcs = {}
local BaseAddons = {}

local function applyTooltip(handle, info, instance)
	if info.Tooltip then
		Library:AddTooltip(info.Tooltip, instance)
	end
end

function Funcs:AddLabel(info, doesWrap)
	if typeof(info) == "string" then
		info = { Text = info, DoesWrap = doesWrap }
	end
	info = Library:Validate(info, { Text = "Label", DoesWrap = false, Visible = true })

	-- full-width row so addons dock at the far right like a toggle; the text label sizes to its
	-- glyphs so the tooltip hover region ends with the text (not the whole row)
	local Holder = New("Frame", {
		Parent = self.Container,
		Name = "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 12),
		AutomaticSize = info.DoesWrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
		Visible = info.Visible,
	})
	local TextLabel = New("TextLabel", {
		Parent = Holder,
		Text = info.Text,
		TextColor3 = "DimColor",
		TextStrokeTransparency = 0.5,
		BackgroundTransparency = 1,
		Size = info.DoesWrap and UDim2.new(1, 0, 0, 12) or UDim2.fromOffset(0, 12),
		AutomaticSize = info.DoesWrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = info.DoesWrap,
	})

	local Label = { Text = info.Text, Type = "Label", TextLabel = TextLabel, AddonContainer = nil }

	-- fixed-height right strip (not fromScale, to avoid a circular size chain with the addon)
	local Right = New("Frame", {
		Parent = Holder,
		Name = "RightContainer",
		BackgroundTransparency = 1,
		Position = UDim2.new(1, 0, 0, 1),
		Size = UDim2.fromOffset(0, 12),
	})
	New("UIListLayout", {
		Parent = Right,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 3),
	})
	Label.AddonContainer = Right

	function Label:SetText(text)
		Label.Text = text
		TextLabel.Text = text
	end
	function Label:SetVisible(v)
		Holder.Visible = v
	end

	applyTooltip(Label, info, TextLabel)
	setmetatable(Label, { __index = BaseAddons })
	return Label
end

function Funcs:AddDivider()
	local Holder = New("Frame", {
		Parent = self.Container,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 5),
	})
	New("Frame", {
		Parent = Holder,
		BackgroundColor3 = "Divider",
		BorderColor3 = "Border",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 1),
	})
	return { Type = "Divider", Holder = Holder }
end

function Funcs:AddButton(info, func)
	if typeof(info) == "string" then
		info = { Text = info, Func = func }
	end
	info = Library:Validate(info, { Text = "Button", Func = function() end, DoubleClick = false, Disabled = false })

	-- Button row is a horizontal flex container so AddButton can append a second button side-by-side.
	local Holder = New("Frame", {
		Parent = self.Container,
		Name = "Button",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
	})
	New("UIListLayout", {
		Parent = Holder,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 3),
	})

	local Button = { Type = "Button", Holder = Holder }

	local function makeSub(subInfo)
		-- outer(0,0,0) wrapper + inner(38,38,38) button inset 2px with a 1px 56,56,56 border, per the dump
		local Wrapper = New("Frame", {
			Parent = Holder,
			BackgroundColor3 = "Border",
			BorderColor3 = "DarkBorder",
			Size = UDim2.fromScale(1, 1),
		})
		New("UIFlexItem", { Parent = Wrapper, FlexMode = Enum.UIFlexMode.Fill })
		local Base = New("TextButton", {
			Parent = Wrapper,
			Text = subInfo.Text,
			TextColor3 = "DimColor",
			TextStrokeTransparency = 0,
			BackgroundColor3 = "Element",
			BorderColor3 = "ElementBorder",
			BorderSizePixel = 1,
			Position = UDim2.fromOffset(2, 2),
			Size = UDim2.new(1, -4, 1, -4),
		})

		local Sub = { Text = subInfo.Text, Func = subInfo.Func, Base = Base }
		local lastClick = 0
		Base.MouseButton1Click:Connect(function()
			if subInfo.Disabled then
				return
			end
			if subInfo.DoubleClick then
				local now = os.clock()
				if now - lastClick > 0.4 then
					lastClick = now
					Base.Text = "are you sure?"
					return
				end
				Base.Text = subInfo.Text
			end
			Library:SafeCallback(Sub.Func)
		end)
		Base.MouseEnter:Connect(function()
			Base.BackgroundColor3 = Library.Scheme.ElementBorder
		end)
		Base.MouseLeave:Connect(function()
			Base.BackgroundColor3 = Library.Scheme.Element
			if subInfo.DoubleClick then
				Base.Text = subInfo.Text
			end
		end)
		function Sub:SetText(text)
			Sub.Text = text
			Base.Text = text
		end
		applyTooltip(Sub, subInfo, Base)
		return Sub
	end

	local main = makeSub(info)
	Button.SetText = function(_, text)
		main:SetText(text)
	end

	function Button:AddButton(subInfo, subFunc)
		if typeof(subInfo) == "string" then
			subInfo = { Text = subInfo, Func = subFunc }
		end
		subInfo = Library:Validate(subInfo, { Text = "Button", Func = function() end, DoubleClick = false, Disabled = false })
		return makeSub(subInfo)
	end

	return Button
end

function Funcs:AddToggle(idx, info)
	info = Library:Validate(info, {
		Text = "Toggle",
		Default = false,
		Callback = function() end,
		Changed = function() end,
		Disabled = false,
		Visible = true,
	})

	local Toggle = {
		Value = info.Default and true or false,
		Type = "Toggle",
		Text = info.Text,
		Callback = info.Callback,
		Changed = info.Changed,
		Addons = {},
		OnChangedFns = {},
	}

	local Holder = New("TextButton", {
		Parent = self.Container,
		Name = "Toggle",
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Visible = info.Visible,
	})

	local Box = New("TextButton", {
		Parent = Holder,
		Text = "",
		BackgroundColor3 = "Dark",
		BorderColor3 = "DarkBorder",
		Position = UDim2.fromOffset(0, 1),
		Size = UDim2.fromOffset(10, 10),
	})
	local Inner = New("Frame", {
		Parent = Box,
		BackgroundColor3 = "ElementFill",
		BorderColor3 = "ElementBorder",
		BorderSizePixel = 1,
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
	})
	local Fill = New("Frame", {
		Parent = Inner,
		BackgroundColor3 = "Accent",
		BorderColor3 = "Border",
		Size = UDim2.fromScale(1, 1),
		Visible = Toggle.Value,
	})

	local Label = New("TextLabel", {
		Parent = Holder,
		Name = "Text",
		Text = info.Text,
		TextColor3 = "DimColor",
		TextStrokeTransparency = 0.5,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -14, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.Y,
	})

	local Right = New("Frame", {
		Parent = Holder,
		Name = "RightContainer",
		BackgroundTransparency = 1,
		Position = UDim2.new(1, 0, 0, 1),
		Size = UDim2.fromScale(0, 1),
	})
	New("UIListLayout", {
		Parent = Right,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 3),
	})
	Toggle.AddonContainer = Right
	Toggle.TextLabel = Label

	function Toggle:Display()
		Fill.Visible = Toggle.Value
	end
	function Toggle:OnChanged(func)
		table.insert(Toggle.OnChangedFns, func)
		Library:SafeCallback(func, Toggle.Value)
	end
	function Toggle:SetValue(value)
		Toggle.Value = value and true or false
		Toggle:Display()
		Library:SafeCallback(Toggle.Changed, Toggle.Value)
		Library:SafeCallback(Toggle.Callback, Toggle.Value)
		for _, func in Toggle.OnChangedFns do
			Library:SafeCallback(func, Toggle.Value)
		end
	end
	function Toggle:GetValue()
		return Toggle.Value
	end
	function Toggle:SetText(text)
		Toggle.Text = text
		Label.Text = text
	end
	function Toggle:SetVisible(v)
		Holder.Visible = v
	end

	local function flip()
		Toggle:SetValue(not Toggle.Value)
	end
	Holder.MouseButton1Click:Connect(flip)
	Box.MouseButton1Click:Connect(flip)

	Toggle:Display()
	applyTooltip(Toggle, info, Holder)
	Library.Toggles[idx] = Toggle
	setmetatable(Toggle, { __index = BaseAddons })
	return Toggle
end

function Funcs:AddInput(idx, info)
	info = Library:Validate(info, {
		Text = "",
		Default = "",
		Placeholder = "type here...",
		Numeric = false,
		Finished = false,
		ClearTextOnFocus = false,
		Callback = function() end,
		Changed = function() end,
		Visible = true,
	})

	local Input = {
		Value = info.Default or "",
		Type = "Input",
		Callback = info.Callback,
		Changed = info.Changed,
		OnChangedFns = {},
	}

	if info.Text and info.Text ~= "" then
		Funcs.AddLabel(self, { Text = info.Text })
	end

	local Holder = New("Frame", {
		Parent = self.Container,
		Name = "Textbox",
		BackgroundColor3 = "Dark",
		BorderColor3 = "DarkBorder",
		Size = UDim2.new(1, 0, 0, 16),
		Visible = info.Visible,
	})
	local Box = New("TextBox", {
		Parent = Holder,
		Text = info.Default or "",
		PlaceholderText = info.Placeholder,
		PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
		TextColor3 = "FontColor",
		TextStrokeTransparency = 0.5,
		BackgroundColor3 = "Element",
		BorderColor3 = "ElementBorder",
		BorderSizePixel = 1,
		ClearTextOnFocus = info.ClearTextOnFocus,
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	New("UIPadding", { Parent = Box, PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) })

	Input.Holder = Holder
	Input.TextBox = Box

	function Input:OnChanged(func)
		table.insert(Input.OnChangedFns, func)
		Library:SafeCallback(func, Input.Value)
	end
	local function fire()
		Library:SafeCallback(Input.Changed, Input.Value)
		Library:SafeCallback(Input.Callback, Input.Value)
		for _, func in Input.OnChangedFns do
			Library:SafeCallback(func, Input.Value)
		end
	end
	function Input:SetValue(text)
		text = tostring(text)
		if info.Numeric then
			text = text:gsub("[^%d%.%-]", "")
		end
		Input.Value = text
		Box.Text = text
		fire()
	end
	function Input:GetValue()
		return Input.Value
	end

	Box:GetPropertyChangedSignal("Text"):Connect(function()
		if info.Numeric then
			local cleaned = Box.Text:gsub("[^%d%.%-]", "")
			if cleaned ~= Box.Text then
				Box.Text = cleaned
				return
			end
		end
		if not info.Finished then
			Input.Value = Box.Text
			fire()
		end
	end)
	Box.FocusLost:Connect(function()
		Input.Value = Box.Text
		fire()
	end)

	applyTooltip(Input, info, Holder)
	Library.Options[idx] = Input
	return Input
end

function Funcs:AddSlider(idx, info)
	info = Library:Validate(info, {
		Text = "Slider",
		Default = 0,
		Min = 0,
		Max = 100,
		Rounding = 0,
		Prefix = "",
		Suffix = "",
		Callback = function() end,
		Changed = function() end,
		Visible = true,
	})

	local Slider = {
		Value = info.Default,
		Min = info.Min,
		Max = info.Max,
		Rounding = info.Rounding,
		Prefix = info.Prefix,
		Suffix = info.Suffix,
		Type = "Slider",
		Text = info.Text,
		Callback = info.Callback,
		Changed = info.Changed,
		OnChangedFns = {},
	}

	local Holder = New("TextLabel", {
		Parent = self.Container,
		Name = "Slider",
		Text = info.Text,
		TextColor3 = "DimColor",
		TextStrokeTransparency = 0.5,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Visible = info.Visible,
	})

	-- bar is inset 13px each side so the - / + steppers have room outside it (dump uses -26 width)
	local Bar = New("TextButton", {
		Parent = Holder,
		Text = "",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = "Dark",
		BorderColor3 = "DarkBorder",
		Position = UDim2.new(0.5, 0, 0, 18),
		Size = UDim2.new(1, -26, 0, 8),
	})
	New("Frame", {
		Parent = Bar,
		BackgroundColor3 = "ElementFill",
		BorderColor3 = "ElementBorder",
		BorderSizePixel = 1,
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
	})
	local Fill = New("Frame", {
		Parent = Bar,
		BackgroundColor3 = "Accent",
		BorderColor3 = "Border",
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(0, 0, 1, -4),
		ZIndex = 2,
	})
	local ValueLabel = New("TextLabel", {
		Parent = Bar,
		Text = "0",
		TextColor3 = "DimColor",
		TextStrokeTransparency = 0,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
		TextSize = 12,
	})

	-- steppers live just outside the bar at -15 / +5 offsets, matching the dump
	local Minus = New("TextButton", {
		Parent = Bar,
		Text = "-",
		TextColor3 = "DimColor",
		TextStrokeTransparency = 0.5,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromOffset(-7, 4),
		Size = UDim2.fromOffset(8, 8),
	})
	local Plus = New("TextButton", {
		Parent = Bar,
		Text = "+",
		TextColor3 = "DimColor",
		TextStrokeTransparency = 0.5,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, 7, 0, 4),
		Size = UDim2.fromOffset(8, 8),
	})

	Slider.Holder = Holder

	function Slider:Display()
		local frac = (Slider.Max - Slider.Min) == 0 and 0 or (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
		frac = math.clamp(frac, 0, 1)
		Fill.Size = UDim2.new(frac, frac > 0 and -4 or 0, 1, -4)
		ValueLabel.Text = string.format("%s%s%s", Slider.Prefix, tostring(Slider.Value), Slider.Suffix)
	end
	function Slider:OnChanged(func)
		table.insert(Slider.OnChangedFns, func)
		Library:SafeCallback(func, Slider.Value)
	end
	function Slider:SetValue(value)
		value = math.clamp(Round(value, Slider.Rounding), Slider.Min, Slider.Max)
		Slider.Value = value
		Slider:Display()
		Library:SafeCallback(Slider.Changed, Slider.Value)
		Library:SafeCallback(Slider.Callback, Slider.Value)
		for _, func in Slider.OnChangedFns do
			Library:SafeCallback(func, Slider.Value)
		end
	end
	function Slider:GetValue()
		return Slider.Value
	end
	function Slider:SetMin(v)
		Slider.Min = v
		Slider:SetValue(Slider.Value)
	end
	function Slider:SetMax(v)
		Slider.Max = v
		Slider:SetValue(Slider.Value)
	end

	local step = Slider.Rounding == 0 and 1 or 10 ^ -Slider.Rounding
	Minus.MouseButton1Click:Connect(function()
		Slider:SetValue(Slider.Value - step)
	end)
	Plus.MouseButton1Click:Connect(function()
		Slider:SetValue(Slider.Value + step)
	end)

	local dragging = false
	local function moveTo(x)
		local rel = (x - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X
		Slider:SetValue(Slider.Min + math.clamp(rel, 0, 1) * (Slider.Max - Slider.Min))
	end
	Bar.InputBegan:Connect(function(input)
		if not IsClickInput(input) then
			return
		end
		dragging = true
		moveTo(input.Position.X)
	end)
	Bar.InputEnded:Connect(function(input)
		if IsMouseInput(input) then
			dragging = false
		end
	end)
	Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
		if dragging and IsHoverInput(input) then
			moveTo(input.Position.X)
		end
	end))

	Slider:Display()
	applyTooltip(Slider, info, Holder)
	Library.Options[idx] = Slider
	return Slider
end

function Funcs:AddDropdown(idx, info)
	info = Library:Validate(info, {
		Text = "Dropdown",
		Values = {},
		Default = nil,
		Multi = false,
		MaxVisibleDropdownItems = 8,
		Callback = function() end,
		Changed = function() end,
		Visible = true,
	})

	local Dropdown = {
		Values = info.Values,
		Value = info.Multi and {} or nil,
		Multi = info.Multi,
		Type = "Dropdown",
		Text = info.Text,
		Callback = info.Callback,
		Changed = info.Changed,
		MaxVisibleDropdownItems = info.MaxVisibleDropdownItems,
		OnChangedFns = {},
	}

	local Holder = New("Frame", {
		Parent = self.Container,
		Name = "Dropdown",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		Visible = info.Visible,
	})
	New("TextLabel", {
		Parent = Holder,
		Text = info.Text,
		TextColor3 = "DimColor",
		TextStrokeTransparency = 0,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 12),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local DisplayOuter = New("Frame", {
		Parent = Holder,
		BackgroundColor3 = "Dark",
		BorderColor3 = "DarkBorder",
		Position = UDim2.fromOffset(0, 14),
		Size = UDim2.new(1, 0, 0, 16),
	})
	local Button = New("TextButton", {
		Parent = DisplayOuter,
		Text = "---",
		TextColor3 = "DimColor",
		TextStrokeTransparency = 0.5,
		BackgroundColor3 = "Element",
		BorderColor3 = "ElementBorder",
		BorderSizePixel = 1,
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	New("UIPadding", { Parent = Button, PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 12) })
	New("TextLabel", {
		Parent = Button,
		Text = "+",
		TextColor3 = "DimColor",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 2, 0.5, 0),
		Size = UDim2.fromOffset(8, 12),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	Dropdown.Holder = Holder

	-- floating list (dump's Dropdown_1): outer(8,8,8) -> inner(38,38,38) -> items
	local Menu = Library:AddContextMenu(DisplayOuter, function()
		return UDim2.fromOffset(DisplayOuter.AbsoluteSize.X, 0)
	end, function()
		return { 0, DisplayOuter.AbsoluteSize.Y + 1 }
	end, 1)

	local ListOuter = New("Frame", {
		Parent = Menu.Menu,
		BackgroundColor3 = "Dark",
		BorderColor3 = "DarkBorder",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
	})
	local ListInner = New("Frame", {
		Parent = ListOuter,
		BackgroundColor3 = "Element",
		BorderColor3 = "ElementBorder",
		BorderSizePixel = 1,
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		ZIndex = 50,
	})
	local ItemList = New("Frame", {
		Parent = ListInner,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		ZIndex = 50,
	})
	New("UIListLayout", { Parent = ItemList, Padding = UDim.new(0, 2) })
	New("UIPadding", { Parent = ItemList, PaddingBottom = UDim.new(0, 4) })

	local ItemButtons = {}

	function Dropdown:GetActiveValues()
		if Dropdown.Multi then
			local out = {}
			for value, state in Dropdown.Value do
				if state then
					table.insert(out, value)
				end
			end
			table.sort(out)
			return out
		end
		return Dropdown.Value
	end

	function Dropdown:Display()
		local text
		if Dropdown.Multi then
			local active = Dropdown:GetActiveValues()
			text = #active > 0 and table.concat(active, ", ") or "---"
		else
			text = Dropdown.Value ~= nil and tostring(Dropdown.Value) or "---"
		end
		Button.Text = text
		for value, btn in ItemButtons do
			local selected
			if Dropdown.Multi then
				selected = Dropdown.Value[value] == true
			else
				selected = Dropdown.Value == value
			end
			btn.TextColor3 = selected and Library.Scheme.FontColor or Library.Scheme.DimColor
			btn.BackgroundTransparency = selected and 0 or 1
		end
	end

	function Dropdown:OnChanged(func)
		table.insert(Dropdown.OnChangedFns, func)
		Library:SafeCallback(func, Dropdown.Value)
	end
	local function fire()
		Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
		Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
		for _, func in Dropdown.OnChangedFns do
			Library:SafeCallback(func, Dropdown.Value)
		end
	end

	function Dropdown:RecalculateListSize()
		local count = #Dropdown.Values
		local visible = math.min(count, Dropdown.MaxVisibleDropdownItems)
		local height = visible * 16 + 8
		Menu:SetSize(UDim2.fromOffset(DisplayOuter.AbsoluteSize.X, height))
	end

	function Dropdown:BuildDropdownList()
		for _, btn in ItemButtons do
			btn:Destroy()
		end
		table.clear(ItemButtons)
		for _, value in Dropdown.Values do
			local Item = New("TextButton", {
				Parent = ItemList,
				Text = tostring(value),
				TextColor3 = "DimColor",
				TextStrokeTransparency = 0.5,
				BackgroundColor3 = "Pop",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 14),
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 51,
			})
			New("UIPadding", { Parent = Item, PaddingLeft = UDim.new(0, 5) })
			ItemButtons[value] = Item
			Item.MouseButton1Click:Connect(function()
				if Dropdown.Multi then
					Dropdown.Value[value] = not Dropdown.Value[value]
				else
					Dropdown.Value = value
					Menu:Close()
				end
				Dropdown:Display()
				fire()
			end)
		end
		Dropdown:RecalculateListSize()
	end

	function Dropdown:SetValue(value)
		if Dropdown.Multi then
			Dropdown.Value = {}
			if typeof(value) == "table" then
				for _, v in value do
					Dropdown.Value[v] = true
				end
			end
		else
			Dropdown.Value = value
		end
		Dropdown:Display()
		fire()
	end
	function Dropdown:GetValue()
		return Dropdown.Value
	end
	function Dropdown:SetValues(values)
		Dropdown.Values = values
		Dropdown:BuildDropdownList()
		Dropdown:Display()
	end

	Button.MouseButton1Click:Connect(function()
		Dropdown:RecalculateListSize()
		Menu:Toggle()
	end)

	Dropdown:BuildDropdownList()

	-- apply Default
	if info.Default ~= nil then
		if Dropdown.Multi then
			local def = typeof(info.Default) == "table" and info.Default or { info.Default }
			for _, v in def do
				local val = typeof(v) == "number" and Dropdown.Values[v] or v
				if val ~= nil then
					Dropdown.Value[val] = true
				end
			end
		else
			local val = typeof(info.Default) == "number" and Dropdown.Values[info.Default] or info.Default
			Dropdown.Value = val
		end
	end

	Dropdown:Display()
	applyTooltip(Dropdown, info, Holder)
	Library.Options[idx] = Dropdown
	return Dropdown
end

--===================================================================--
--// Addons (KeyPicker, ColorPicker)                                 --
--===================================================================--
local SpecialInputs = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.MouseButton2] = true,
	[Enum.UserInputType.MouseButton3] = true,
}
local MouseStrings = {
	MB1 = Enum.UserInputType.MouseButton1,
	MB2 = Enum.UserInputType.MouseButton2,
	MB3 = Enum.UserInputType.MouseButton3,
}
-- Enum.KeyCode[<invalid>] throws in Roblox, so resolve through pcall.
local function ResolveKey(key)
	if typeof(key) == "EnumItem" then
		return key
	end
	if type(key) == "string" then
		if MouseStrings[key] then
			return MouseStrings[key]
		end
		if key == "None" or key == "" then
			return nil
		end
		local ok, code = pcall(function()
			return Enum.KeyCode[key]
		end)
		if ok then
			return code
		end
	end
	return nil
end

function BaseAddons:AddKeyPicker(idx, info)
	info = Library:Validate(info, {
		Text = "KeyPicker",
		Default = "None",
		Mode = "Toggle",
		Modes = { "Always", "Toggle", "Hold" },
		SyncToggleState = false,
		Callback = function() end,
		ChangedCallback = function() end,
		Changed = function() end,
	})

	local container = self.AddonContainer
	assert(container, "KeyPicker can only be attached to a Toggle or Label.")

	local KeyPicker = {
		Value = info.Default,
		Mode = info.Mode,
		Toggled = false,
		Type = "KeyPicker",
		Text = info.Text ~= "KeyPicker" and info.Text or (self.Text or "KeyPicker"),
		Callback = info.Callback,
		ChangedCallback = info.ChangedCallback,
		Changed = info.Changed,
		OnChangedFns = {},
	}

	local function keyLabel()
		return "[" .. (KeyPicker.Value == "None" and "none" or Library:GetKeyString(KeyPicker.Bind or KeyPicker.Value)) .. "]"
	end

	local Picker = New("TextButton", {
		Parent = container,
		Name = "KeybindButton",
		Text = "[none]",
		TextColor3 = "DimColor",
		TextStrokeTransparency = 0.5,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 16, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	-- mode menu reusing the context-menu popup
	local ModeMenu = Library:AddContextMenu(Picker, UDim2.fromOffset(62, 0), function()
		return { Picker.AbsoluteSize.X + 2, 0 }
	end, 1)
	local ModeOuter = New("Frame", {
		Parent = ModeMenu.Menu,
		BackgroundColor3 = "Dark",
		BorderColor3 = "DarkBorder",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
	})
	local ModeInner = New("Frame", {
		Parent = ModeOuter,
		BackgroundColor3 = "Element",
		BorderColor3 = "ElementBorder",
		BorderSizePixel = 1,
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		ZIndex = 50,
	})
	New("UIListLayout", { Parent = ModeInner, Padding = UDim.new(0, 1) })
	KeyPicker.Bind = ResolveKey(info.Default)

	for _, mode in info.Modes do
		local btn = New("TextButton", {
			Parent = ModeInner,
			Text = mode,
			TextColor3 = "DimColor",
			TextStrokeTransparency = 0.5,
			BackgroundColor3 = "Pop",
			BackgroundTransparency = mode == KeyPicker.Mode and 0 or 1,
			Size = UDim2.new(1, 0, 0, 16),
			ZIndex = 51,
		})
		btn.MouseButton1Click:Connect(function()
			KeyPicker.Mode = mode
			for _, child in ModeInner:GetChildren() do
				if child:IsA("TextButton") then
					child.BackgroundTransparency = child.Text == mode and 0 or 1
				end
			end
			ModeMenu:Close()
			KeyPicker:Update()
		end)
	end

	function KeyPicker:Display()
		Picker.Text = keyLabel()
	end
	function KeyPicker:GetState()
		if KeyPicker.Value == "None" or not KeyPicker.Bind then
			return false
		end
		if KeyPicker.Mode == "Always" then
			return true
		elseif KeyPicker.Mode == "Toggle" then
			return KeyPicker.Toggled
		elseif KeyPicker.Mode == "Hold" then
			if SpecialInputs[KeyPicker.Bind] then
				return UserInputService:IsMouseButtonPressed(KeyPicker.Bind)
			end
			return UserInputService:IsKeyDown(KeyPicker.Bind)
		end
		return false
	end
	function KeyPicker:OnChanged(func)
		table.insert(KeyPicker.OnChangedFns, func)
	end
	function KeyPicker:SetValue(key)
		local bind = ResolveKey(key)
		KeyPicker.Bind = bind
		if bind == nil then
			KeyPicker.Value = "None"
		elseif type(key) == "string" then
			KeyPicker.Value = key
		else
			KeyPicker.Value = Library:GetKeyString(bind)
		end
		KeyPicker:Display()
		KeyPicker:Update()
	end

	local function fireState()
		local state = KeyPicker:GetState()
		Library:SafeCallback(KeyPicker.Callback, state)
		for _, func in KeyPicker.OnChangedFns do
			Library:SafeCallback(func, state)
		end
		Library:UpdateKeybindRow(KeyPicker)
	end

	function KeyPicker:Update()
		Library:UpdateKeybindRow(KeyPicker)
		if KeyPicker.Mode == "Always" then
			fireState()
		end
	end

	local picking = false
	Picker.MouseButton1Click:Connect(function()
		picking = true
		Picker.Text = "[...]"
	end)
	-- right-click the bind to open the mode menu
	Picker.MouseButton2Click:Connect(function()
		ModeMenu:Toggle()
	end)

	Library:GiveSignal(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if Library.Unloaded then
			return
		end
		if picking then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape then
					KeyPicker:SetValue("None")
				else
					KeyPicker:SetValue(input.KeyCode)
				end
				picking = false
			elseif SpecialInputs[input.UserInputType] then
				KeyPicker.Bind = input.UserInputType
				KeyPicker.Value = Library:GetKeyString(input.UserInputType)
				KeyPicker:Display()
				KeyPicker:Update()
				picking = false
			end
			return
		end

		if gameProcessed or not KeyPicker.Bind or KeyPicker.Value == "None" then
			return
		end
		local matched = (input.KeyCode == KeyPicker.Bind) or (input.UserInputType == KeyPicker.Bind)
		if not matched then
			return
		end
		if KeyPicker.Mode == "Toggle" then
			KeyPicker.Toggled = not KeyPicker.Toggled
			fireState()
		elseif KeyPicker.Mode == "Hold" then
			fireState()
		end
	end))
	Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
		if Library.Unloaded or KeyPicker.Mode ~= "Hold" or not KeyPicker.Bind then
			return
		end
		if (input.KeyCode == KeyPicker.Bind) or (input.UserInputType == KeyPicker.Bind) then
			fireState()
		end
	end))

	KeyPicker:SetValue(info.Default)
	Library.Options[idx] = KeyPicker
	Library:AddKeybindRow(KeyPicker)
	return self
end

local function HSVToColor(h, s, v)
	return Color3.fromHSV(h, s, v)
end

function BaseAddons:AddColorPicker(idx, info)
	info = Library:Validate(info, {
		Default = Color3.new(1, 1, 1),
		Transparency = 0,
		Title = "Color",
		Callback = function() end,
		Changed = function() end,
	})

	local container = self.AddonContainer
	assert(container, "ColorPicker can only be attached to a Toggle or Label.")

	local ColorPicker = {
		Value = info.Default,
		Transparency = info.Transparency,
		Title = info.Title,
		Type = "ColorPicker",
		Callback = info.Callback,
		Changed = info.Changed,
		OnChangedFns = {},
	}
	local H, S, V = info.Default:ToHSV()
	ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = H, S, V

	local Display = New("TextButton", {
		Parent = container,
		Name = "ColorpickerButton",
		Text = "",
		BackgroundColor3 = "Border",
		BorderColor3 = "DarkBorder",
		Size = UDim2.fromOffset(16, 10),
		ZIndex = 3,
	})
	local Swatch = New("Frame", {
		Parent = Display,
		BackgroundColor3 = info.Default,
		BorderColor3 = "Border",
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		ZIndex = 4,
	})

	-- popup window matches the dump's standalone Colorpicker (SV box + hue bar + alpha bar + rgba box)
	local Menu = Library:AddContextMenu(Display, UDim2.fromOffset(142, 146), function()
		return { -126, 14 }
	end, false)
	local Shell = MakeWindowShell(Menu.Menu, UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), info.Title)
	Shell.Outline.ZIndex = 50

	-- outer(10,10,10) + inner(1px 56,56,56) layering, matching the tracks and the dump's colorpicker frames
	local SatOuter = New("Frame", {
		Parent = Shell.Body,
		BackgroundColor3 = "Outline",
		BorderColor3 = "DarkBorder",
		Position = UDim2.fromOffset(0, 16),
		Size = UDim2.new(1, 0, 1, -50),
		ZIndex = 51,
	})
	local SatMap = New("TextButton", {
		Parent = SatOuter,
		Text = "",
		BackgroundColor3 = "White",
		BorderColor3 = "ElementBorder",
		BorderSizePixel = 1,
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		ZIndex = 51,
	})
	local SatGradientWhite = New("Frame", {
		Parent = SatMap,
		BackgroundColor3 = "White",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 51,
	})
	New("UIGradient", {
		Parent = SatGradientWhite,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	})
	local SatGradientBlack = New("Frame", {
		Parent = SatMap,
		BackgroundColor3 = Color3.new(0, 0, 0),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 51,
	})
	New("UIGradient", {
		Parent = SatGradientBlack,
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
	})
	local SatCursor = New("Frame", {
		Parent = SatMap,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "White",
		BorderColor3 = "Border",
		Size = UDim2.fromOffset(3, 3),
		ZIndex = 52,
	})

	local HueOuter = New("Frame", {
		Parent = Shell.Body,
		BackgroundColor3 = "Outline",
		BorderColor3 = "DarkBorder",
		Position = UDim2.new(0, 0, 1, -32),
		Size = UDim2.new(1, 0, 0, 10),
		ZIndex = 51,
	})
	local HueBar = New("TextButton", {
		Parent = HueOuter,
		Text = "",
		BackgroundColor3 = "White",
		BorderColor3 = "ElementBorder",
		BorderSizePixel = 1,
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		ZIndex = 51,
	})
	New("UIGradient", {
		Parent = HueBar,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}),
	})
	local HueCursor = New("Frame", {
		Parent = HueBar,
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(204, 41, 41),
		BorderColor3 = Color3.fromRGB(108, 22, 22),
		Size = UDim2.new(0, 1, 1, 0),
		ZIndex = 52,
	})

	local RgbaOuter = New("Frame", {
		Parent = Shell.Body,
		BackgroundColor3 = "Outline",
		BorderColor3 = "DarkBorder",
		Position = UDim2.new(0, 0, 1, -16),
		Size = UDim2.new(1, 0, 0, 14),
		ZIndex = 51,
	})
	local RgbaBox = New("TextBox", {
		Parent = RgbaOuter,
		Text = "",
		PlaceholderText = "r, g, b, a",
		PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
		TextColor3 = "DimColor",
		TextStrokeTransparency = 0.5,
		BackgroundColor3 = "Inline",
		BorderColor3 = "ElementBorder",
		BorderSizePixel = 1,
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		ZIndex = 51,
	})

	function ColorPicker:Display()
		ColorPicker.Value = HSVToColor(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)
		Swatch.BackgroundColor3 = ColorPicker.Value
		SatMap.BackgroundColor3 = HSVToColor(ColorPicker.Hue, 1, 1)
		SatCursor.Position = UDim2.fromScale(ColorPicker.Sat, 1 - ColorPicker.Vib)
		HueCursor.Position = UDim2.fromScale(ColorPicker.Hue, 0)
		local c = ColorPicker.Value
		RgbaBox.Text = string.format(
			"%d, %d, %d, %d",
			math.floor(c.R * 255 + 0.5),
			math.floor(c.G * 255 + 0.5),
			math.floor(c.B * 255 + 0.5),
			math.floor((1 - ColorPicker.Transparency) * 255 + 0.5)
		)
	end
	function ColorPicker:OnChanged(func)
		table.insert(ColorPicker.OnChangedFns, func)
		Library:SafeCallback(func, ColorPicker.Value)
	end
	local function fire()
		Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
		Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
		for _, func in ColorPicker.OnChangedFns do
			Library:SafeCallback(func, ColorPicker.Value)
		end
	end
	function ColorPicker:SetValueRGB(color, transparency)
		ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = color:ToHSV()
		ColorPicker.Transparency = transparency or ColorPicker.Transparency
		ColorPicker:Display()
		fire()
	end
	function ColorPicker:GetValue()
		return ColorPicker.Value
	end

	Display.MouseButton1Click:Connect(function()
		Menu:Toggle()
	end)

	local satDrag = false
	local function moveSat(pos)
		local rx = math.clamp((pos.X - SatMap.AbsolutePosition.X) / SatMap.AbsoluteSize.X, 0, 1)
		local ry = math.clamp((pos.Y - SatMap.AbsolutePosition.Y) / SatMap.AbsoluteSize.Y, 0, 1)
		ColorPicker.Sat = rx
		ColorPicker.Vib = 1 - ry
		ColorPicker:Display()
		fire()
	end
	SatMap.InputBegan:Connect(function(input)
		if IsClickInput(input) then
			satDrag = true
			moveSat(input.Position)
		end
	end)
	SatMap.InputEnded:Connect(function(input)
		if IsMouseInput(input) then
			satDrag = false
		end
	end)

	local hueDrag = false
	local function moveHue(pos)
		ColorPicker.Hue = math.clamp((pos.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
		ColorPicker:Display()
		fire()
	end
	HueBar.InputBegan:Connect(function(input)
		if IsClickInput(input) then
			hueDrag = true
			moveHue(input.Position)
		end
	end)
	HueBar.InputEnded:Connect(function(input)
		if IsMouseInput(input) then
			hueDrag = false
		end
	end)

	Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
		if not IsHoverInput(input) then
			return
		end
		if satDrag then
			moveSat(input.Position)
		elseif hueDrag then
			moveHue(input.Position)
		end
	end))

	RgbaBox.FocusLost:Connect(function()
		local nums = {}
		for token in RgbaBox.Text:gmatch("%-?%d+") do
			table.insert(nums, tonumber(token))
		end
		if #nums >= 3 then
			local color = Color3.fromRGB(
				math.clamp(nums[1], 0, 255),
				math.clamp(nums[2], 0, 255),
				math.clamp(nums[3], 0, 255)
			)
			local transparency = ColorPicker.Transparency
			if nums[4] then
				transparency = 1 - math.clamp(nums[4], 0, 255) / 255
			end
			ColorPicker:SetValueRGB(color, transparency)
		else
			ColorPicker:Display()
		end
	end)

	ColorPicker:Display()
	Library.Options[idx] = ColorPicker
	return self
end

--===================================================================--
--// Groupbox / Tabbox / Tab                                         --
--===================================================================--
local function MakeGroupbox(side, name)
	local Outline, Inline, Body = MakeAutoPanel(side)

	local Content = New("Frame", {
		Parent = Body,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	New("UIListLayout", { Parent = Content, Padding = UDim.new(0, 8) })
	New("UIPadding", {
		Parent = Content,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	if name then
		-- header cue is full FontColor brightness (vs the dimmer label color); underline is reserved
		-- for the active tabbox section, so titles are not underlined
		New("TextLabel", {
			Parent = Content,
			Text = name,
			TextColor3 = "FontColor",
			TextStrokeTransparency = 0,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 12),
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = -1,
		})
	end

	local Groupbox = { Container = Content, Holder = Outline, Type = "Groupbox" }
	return setmetatable(Groupbox, { __index = Funcs })
end

local function MakeTabbox(side)
	local Outline, Inline, Body = MakeAutoPanel(side)

	-- header row of section selectors (dump's Section1 / Section2)
	local Header = New("Frame", {
		Parent = Body,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
	})
	New("UIListLayout", {
		Parent = Header,
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	local Pages = New("Frame", {
		Parent = Body,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 16),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})

	local Tabbox = { Tabs = {}, ActiveTab = nil, Holder = Outline }

	function Tabbox:AddTab(name)
		-- underline is the active-section indicator only (the Underline frame below), so the text is plain
		local SelectButton = New("TextButton", {
			Parent = Header,
			Text = name,
			TextColor3 = "DimColor",
			TextStrokeTransparency = 0.5,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local Underline = New("Frame", {
			Parent = SelectButton,
			BackgroundColor3 = "Accent",
			BorderColor3 = "Border",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 1),
			Visible = false,
		})

		local Content = New("Frame", {
			Parent = Pages,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Visible = false,
		})
		New("UIListLayout", { Parent = Content, Padding = UDim.new(0, 8) })
		New("UIPadding", {
			Parent = Content,
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 8),
		})

		local SubTab = { Container = Content, Button = SelectButton }
		setmetatable(SubTab, { __index = Funcs })

		function SubTab:Show()
			for _, other in Tabbox.Tabs do
				other.Container.Visible = false
				other.Button.TextColor3 = Library.Scheme.DimColor
				other.Underline.Visible = false
			end
			Content.Visible = true
			SelectButton.TextColor3 = Library.Scheme.FontColor
			Underline.Visible = true
			Tabbox.ActiveTab = SubTab
		end
		SubTab.Underline = Underline

		SelectButton.MouseButton1Click:Connect(function()
			SubTab:Show()
		end)

		table.insert(Tabbox.Tabs, SubTab)
		if not Tabbox.ActiveTab then
			SubTab:Show()
		end
		return SubTab
	end

	return Tabbox
end

--===================================================================--
--// Window                                                          --
--===================================================================--
function Library:CreateWindow(windowInfo)
	windowInfo = Library:Validate(windowInfo, {
		Title = "Sentinel",
		Footer = "",
		Size = UDim2.fromOffset(582, 502),
		Position = UDim2.fromOffset(100, 100),
		ToggleKeybind = Enum.KeyCode.RightControl,
		ShowCustomCursor = false,
		Resizable = false,
		Center = false,
	})

	Library.ToggleKeybind = windowInfo.ToggleKeybind
	Library.ShowCustomCursor = windowInfo.ShowCustomCursor

	local Shell = MakeWindowShell(ScreenGui, windowInfo.Size, windowInfo.Position, windowInfo.Title)
	local MainOutline = Shell.Outline
	MainOutline.Visible = false

	if windowInfo.Center then
		local view = workspace.CurrentCamera.ViewportSize
		MainOutline.Position = UDim2.fromOffset(
			math.floor((view.X - windowInfo.Size.X.Offset) / 2),
			math.floor((view.Y - windowInfo.Size.Y.Offset) / 2)
		)
	end

	-- title bar drag handle
	local DragHandle = New("TextButton", {
		Parent = Shell.Body,
		Text = "",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 0, 16),
		ZIndex = 5,
	})
	Library:MakeDraggable(MainOutline, DragHandle, true)

	if windowInfo.Footer and windowInfo.Footer ~= "" then
		New("TextLabel", {
			Parent = Shell.Body,
			Text = windowInfo.Footer,
			TextColor3 = "DimColor",
			TextStrokeTransparency = 0.5,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 2),
			Size = UDim2.new(0, 100, 0, 12),
			TextXAlignment = Enum.TextXAlignment.Right,
			Interactable = false,
		})
	end

	-- accent strip + tab/content region (dump's Accent at y=18)
	local AccentRegion = New("Frame", {
		Parent = Shell.Body,
		BackgroundColor3 = "Accent",
		BorderColor3 = "Border",
		Position = UDim2.fromOffset(0, 18),
		Size = UDim2.new(1, 0, 1, -18),
	})
	local TabOutline = New("Frame", {
		Parent = AccentRegion,
		BackgroundColor3 = "Outline",
		BorderColor3 = "Border",
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
	})
	New("UIPadding", {
		Parent = TabOutline,
		PaddingTop = UDim.new(0, 1),
		PaddingBottom = UDim.new(0, 1),
		PaddingLeft = UDim.new(0, 1),
		PaddingRight = UDim.new(0, 1),
	})

	local TabStrip = New("Frame", {
		Parent = TabOutline,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 19),
	})
	New("UIListLayout", {
		Parent = TabStrip,
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 1),
	})

	local ContentArea = New("Frame", {
		Parent = TabOutline,
		BackgroundColor3 = "Inline",
		BorderColor3 = "Border",
		Position = UDim2.fromOffset(0, 20),
		Size = UDim2.new(1, 0, 1, -20),
	})

	local Window = { Tabs = {} }

	function Window:Toggle(value)
		if typeof(value) == "boolean" then
			Library.Toggled = value
		else
			Library.Toggled = not Library.Toggled
		end
		MainOutline.Visible = Library.Toggled

		if Library.Toggled then
			local binding = Library.ShowCursorBinding
			pcall(RunService.UnbindFromRenderStep, RunService, binding)
			RunService:BindToRenderStep(binding, Enum.RenderPriority.Last.Value, function()
				UserInputService.MouseIconEnabled = not Library.ShowCustomCursor
				Cursor.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
				Cursor.Visible = Library.ShowCustomCursor
				if not (Library.Toggled and ScreenGui and ScreenGui.Parent) then
					UserInputService.MouseIconEnabled = OriginalMouseIconEnabled
					Cursor.Visible = false
					RunService:UnbindFromRenderStep(binding)
				end
			end)
		else
			TooltipFrame.Visible = false
			if CurrentMenu then
				CurrentMenu:Close()
			end
		end
	end
	function Library:Toggle(value)
		Window:Toggle(value)
	end

	function Window:ChangeTitle(title)
		Shell.Title.Text = title
	end

	function Window:AddTab(name)
		local TabButtonHolder = New("Frame", {
			Parent = TabStrip,
			Name = "TabInline",
			BackgroundColor3 = "Inline",
			BorderColor3 = "Border",
			Size = UDim2.new(0, 100, 1, 0),
			ZIndex = -1, -- border frame sits behind so the button's translucency reveals the accent ring
		})
		New("UIFlexItem", { Parent = TabButtonHolder, FlexMode = Enum.UIFlexMode.Fill })
		local TabButton = New("TextButton", {
			Parent = TabButtonHolder,
			Name = "TabBackground",
			Text = name,
			TextColor3 = "FontColor",
			TextStrokeTransparency = 0,
			BackgroundColor3 = "Body",
			BorderColor3 = "Border",
			Position = UDim2.fromOffset(1, 1),
			Size = UDim2.new(1, -2, 1, -2),
			ZIndex = 2,
		})

		local Container = New("Frame", {
			Parent = ContentArea,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
		})
		New("UIPadding", {
			Parent = Container,
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
		})
		New("UIListLayout", {
			Parent = Container,
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
		})

		-- borderless scroll region: groupboxes (auto-height, bordered) stack and scroll when they
		-- overflow; the side itself has no border so a short groupbox ends below its last element
		local function makeSide()
			local Scroll = New("ScrollingFrame", {
				Parent = Container,
				BackgroundTransparency = 1,
				BorderColor3 = "Border",
				BorderSizePixel = 0,
				Size = UDim2.new(0.5, 0, 1, 0),
				CanvasSize = UDim2.fromOffset(0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = "Accent",
				TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
				BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			})
			New("UIFlexItem", { Parent = Scroll, FlexMode = Enum.UIFlexMode.Fill })
			New("UIListLayout", { Parent = Scroll, Padding = UDim.new(0, 8) })
			return Scroll
		end

		local LeftSide = makeSide()
		local RightSide = makeSide()

		local Tab = {
			Name = name,
			Container = Container,
			Button = TabButton,
			ButtonHolder = TabButtonHolder,
			LeftSide = LeftSide,
			RightSide = RightSide,
			Groupboxes = {},
		}

		function Tab:Show()
			for _, other in Window.Tabs do
				other.Container.Visible = false
				other.ButtonHolder.BackgroundColor3 = Library.Scheme.Inline
				other.Button.BackgroundTransparency = 0
			end
			Container.Visible = true
			-- active tab: inline turns crimson + button goes translucent so the accent ring shows
			TabButtonHolder.BackgroundColor3 = Library.Scheme.Accent
			TabButton.BackgroundTransparency = 0.76
			Library.ActiveTab = Tab
		end

		function Tab:AddLeftGroupbox(boxName)
			local box = MakeGroupbox(LeftSide, boxName)
			box.Tab = Tab
			return box
		end
		function Tab:AddRightGroupbox(boxName)
			local box = MakeGroupbox(RightSide, boxName)
			box.Tab = Tab
			return box
		end
		function Tab:AddLeftTabbox()
			return MakeTabbox(LeftSide)
		end
		function Tab:AddRightTabbox()
			return MakeTabbox(RightSide)
		end

		TabButton.MouseButton1Click:Connect(function()
			Tab:Show()
		end)

		table.insert(Window.Tabs, Tab)
		Library.Tabs[name] = Tab
		if #Window.Tabs == 1 then
			Tab:Show()
		end
		return Tab
	end

	Library.Window = Window
	return Window
end

--===================================================================--
--// Satellite windows (data-driven)                                 --
--===================================================================--
function Library:SetWatermarkVisibility(visible)
	if not Library.Watermark then
		local shell = MakeWindowShell(ScreenGui, UDim2.fromOffset(100, 24), UDim2.fromOffset(16, 16))
		shell.Outline.AutomaticSize = Enum.AutomaticSize.X
		shell.Body.AutomaticSize = Enum.AutomaticSize.X
		local label = New("TextLabel", {
			Parent = shell.Body,
			Text = "",
			TextColor3 = "FontColor",
			TextStrokeTransparency = 0,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 0, 12),
			Position = UDim2.fromOffset(0, 2),
			TextXAlignment = Enum.TextXAlignment.Left,
			Interactable = false,
		})
		Library.Watermark = shell.Outline
		Library.WatermarkLabel = label
		Library:MakeDraggable(shell.Outline, shell.Body)
	end
	Library.Watermark.Visible = visible
end
function Library:SetWatermark(text)
	Library:SetWatermarkVisibility(true)
	Library.WatermarkLabel.Text = text
end

function Library:CreatePlayerList()
	local shell = MakeWindowShell(ScreenGui, UDim2.fromOffset(354, 282), UDim2.fromOffset(620, 16), "playerlist")
	Library:MakeDraggable(shell.Outline, shell.Body)

	local _, _, body = MakePanel(shell.Body, UDim2.new(1, 0, 1, -18), UDim2.fromOffset(0, 18))
	local Scroll = New("ScrollingFrame", {
		Parent = body,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = "Accent",
	})
	New("UIListLayout", { Parent = Scroll, Padding = UDim.new(0, 4) })
	New("UIPadding", {
		Parent = Scroll,
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
	})

	local PlayerList = { Holder = shell.Outline, Rows = {} }

	function PlayerList:SetPlayers(entries)
		for _, row in PlayerList.Rows do
			row:Destroy()
		end
		table.clear(PlayerList.Rows)
		for _, entry in entries do
			local Row = New("Frame", {
				Parent = Scroll,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 14),
			})
			New("UIListLayout", {
				Parent = Row,
				FillDirection = Enum.FillDirection.Horizontal,
			})
			New("UIPadding", { Parent = Row, PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2) })
			local function col(text, withDivider)
				local lbl = New("TextLabel", {
					Parent = Row,
					Text = text,
					TextColor3 = Color3.fromRGB(180, 180, 180),
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(0, 1),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
				})
				New("UIStroke", { Parent = lbl })
				if withDivider then
					-- 1px vertical separator sitting in the gap before this column (dump's -10 offset)
					New("Frame", {
						Parent = lbl,
						BackgroundColor3 = "Divider",
						BorderColor3 = "Border",
						Position = UDim2.fromOffset(-10, 0),
						Size = UDim2.fromOffset(1, 12),
					})
				end
				New("UIFlexItem", { Parent = lbl, FlexMode = Enum.UIFlexMode.Fill })
			end
			col(entry.Name or "?")
			col(entry.Status or "None", true)
			col(entry.Team or "Neutral", true)
			table.insert(PlayerList.Rows, Row)
		end
	end

	function PlayerList:SetVisible(v)
		shell.Outline.Visible = v
	end

	-- populate from the real player list (sorted), refreshed on join/leave
	function PlayerList:Refresh()
		local players = Players:GetPlayers()
		table.sort(players, function(a, b)
			return a.Name:lower() < b.Name:lower()
		end)
		local entries = {}
		for _, player in players do
			table.insert(entries, {
				Name = player.Name,
				Status = "None",
				Team = (player.Team and player.Team.Name) or "Neutral",
			})
		end
		PlayerList:SetPlayers(entries)
	end

	-- PlayerRemoving fires before the player leaves GetPlayers, so defer the refresh a frame
	Library:GiveSignal(Players.PlayerAdded:Connect(function()
		PlayerList:Refresh()
	end))
	Library:GiveSignal(Players.PlayerRemoving:Connect(function()
		task.defer(function()
			PlayerList:Refresh()
		end)
	end))
	PlayerList:Refresh()

	Library.PlayerList = PlayerList
	return PlayerList
end

--// Keybind list (auto-populated by keypickers) \\--
local KeybindShell, KeybindScroll
local function ensureKeybindList()
	if KeybindShell then
		return
	end
	-- fixed-size contained shell (same layering as PlayerList) so the black body stays inside the accent ring
	KeybindShell = MakeWindowShell(ScreenGui, UDim2.fromOffset(240, 200), UDim2.fromOffset(16, 200), "binds")
	Library:MakeDraggable(KeybindShell.Outline, KeybindShell.Body)
	local _, _, body = MakePanel(KeybindShell.Body, UDim2.new(1, 0, 1, -18), UDim2.fromOffset(0, 18))
	KeybindScroll = New("ScrollingFrame", {
		Parent = body,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = "Accent",
	})
	New("UIListLayout", { Parent = KeybindScroll, Padding = UDim.new(0, 4) })
	New("UIPadding", {
		Parent = KeybindScroll,
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
	})
end

function Library:AddKeybindRow(keyPicker)
	ensureKeybindList()
	local Row = New("Frame", {
		Parent = KeybindScroll,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
	})
	New("UIListLayout", { Parent = Row, FillDirection = Enum.FillDirection.Horizontal })
	New("UIPadding", { Parent = Row, PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2) })
	local function col(text, divider)
		-- AutomaticSize.X keeps each column at least its text width so flex can't squeeze them into overlap
		local lbl = New("TextLabel", {
			Parent = Row,
			Text = text,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		New("UIStroke", { Parent = lbl })
		if divider then
			-- 1px column separator in the gap before this column (matches PlayerList / dump)
			New("Frame", {
				Parent = lbl,
				BackgroundColor3 = "Divider",
				BorderColor3 = "Border",
				Position = UDim2.fromOffset(-10, 0),
				Size = UDim2.fromOffset(1, 12),
			})
		end
		New("UIFlexItem", { Parent = lbl, FlexMode = Enum.UIFlexMode.Fill })
		return lbl
	end
	local nameCol = col(keyPicker.Text, false)
	local keyCol = col("", true)
	local modeCol = col("", true)
	local stateCol = col("", true)
	Library.KeybindRows[keyPicker] = { Name = nameCol, Key = keyCol, Mode = modeCol, State = stateCol }
	Library:UpdateKeybindRow(keyPicker)
end

function Library:UpdateKeybindRow(keyPicker)
	local row = Library.KeybindRows[keyPicker]
	if not row then
		return
	end
	row.Name.Text = keyPicker.Text
	row.Key.Text = keyPicker.Value == "None" and "none" or Library:GetKeyString(keyPicker.Bind or keyPicker.Value)
	row.Mode.Text = keyPicker.Mode:lower()
	row.State.Text = tostring(keyPicker:GetState())
end

--===================================================================--
--// Cleanup                                                         --
--===================================================================--
function Library:OnUnload(callback)
	table.insert(Library.UnloadSignals, callback)
end

function Library:Unload()
	if Library.Unloaded then
		return
	end

	for _, callback in Library.UnloadSignals do
		Library:SafeCallback(callback)
	end

	for index = #Library.Signals, 1, -1 do
		local connection = table.remove(Library.Signals, index)
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end

	pcall(function()
		RunService:UnbindFromRenderStep(Library.ShowCursorBinding)
	end)

	UserInputService.MouseIconEnabled = OriginalMouseIconEnabled

	if ScreenGui then
		ScreenGui:Destroy()
	end

	Library.Unloaded = true
	table.clear(Library.Toggles)
	table.clear(Library.Options)
	table.clear(Library.Registry)
	table.clear(Library.Tabs)
	table.clear(Library.KeybindRows)
	getgenv().Library = nil
end

--// Focus tracking + toggle keybind \\--
Library:GiveSignal(UserInputService.WindowFocused:Connect(function()
	Library.IsRobloxFocused = true
end))
Library:GiveSignal(UserInputService.WindowFocusReleased:Connect(function()
	Library.IsRobloxFocused = false
end))

Library:GiveSignal(UserInputService.InputBegan:Connect(function(input)
	if Library.Unloaded or UserInputService:GetFocusedTextBox() then
		return
	end
	if input.KeyCode == Library.ToggleKeybind and Library.Window then
		Library.Window:Toggle()
	end
end))

getgenv().Library = Library
return Library
