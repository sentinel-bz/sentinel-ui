-- Minimal Roblox API mock so the Sentinel library can be executed under luau.exe.
-- Not shipped; lives in the git-ignored reference/ dir.

local RBX = {}

local function Signal()
	local s = { __rbxtype = "RBXScriptSignal", handlers = {} }
	function s:Connect(fn)
		local conn = { __rbxtype = "RBXScriptConnection", Connected = true }
		conn.fn = fn
		function conn:Disconnect()
			conn.Connected = false
			for i, c in ipairs(s.handlers) do
				if c == conn then
					table.remove(s.handlers, i)
					break
				end
			end
		end
		table.insert(s.handlers, conn)
		return conn
	end
	s.Once = s.Connect
	function s:Wait()
		return
	end
	function s:Fire(...)
		for _, c in ipairs({ table.unpack(s.handlers) }) do
			if c.Connected then
				c.fn(...)
			end
		end
	end
	return s
end
RBX.Signal = Signal

local SIGNAL_NAMES = {
	MouseButton1Click = true,
	MouseButton2Click = true,
	MouseButton1Down = true,
	MouseEnter = true,
	MouseLeave = true,
	MouseMoved = true,
	InputBegan = true,
	InputEnded = true,
	InputChanged = true,
	FocusLost = true,
	Focused = true,
	DescendantRemoving = true,
	ChildAdded = true,
	Changed = true,
	WindowFocused = true,
	WindowFocusReleased = true,
	RenderStepped = true,
}

local function makeVec2(x, y)
	return { __rbxtype = "Vector2", X = x or 0, Y = y or 0 }
end

local Instance = {}
local function newInstance(className)
	local self
	local props = {
		ClassName = className,
		Name = className,
		Parent = nil,
		Visible = true,
		ZIndex = 1,
		Text = "",
		AbsolutePosition = makeVec2(10, 10),
		AbsoluteSize = makeVec2(120, 120),
	}
	local signals = {}
	local children = {}

	local methods = {}
	function methods:Destroy()
		props.Parent = nil
	end
	function methods:GetChildren()
		return { table.unpack(children) }
	end
	function methods:GetDescendants()
		return {}
	end
	function methods:IsA(name)
		return props.ClassName == name
	end
	function methods:FindFirstAncestorOfClass(name)
		local p = props.Parent
		while p do
			if p.ClassName == name then
				return p
			end
			p = p.Parent
		end
		return nil
	end
	function methods:GetPropertyChangedSignal(_)
		signals.__pc = signals.__pc or Signal()
		return signals.__pc
	end

	self = setmetatable({ __rbxtype = "Instance", __children = children }, {
		__index = function(_, key)
			if SIGNAL_NAMES[key] then
				signals[key] = signals[key] or Signal()
				return signals[key]
			end
			if methods[key] then
				return methods[key]
			end
			return props[key]
		end,
		__newindex = function(_, key, value)
			props[key] = value
			if key == "Parent" and value and value.__children then
				table.insert(value.__children, self)
			end
		end,
		__tostring = function()
			return "Instance(" .. tostring(props.ClassName) .. ")"
		end,
	})
	return self
end
Instance.new = function(className)
	return newInstance(className)
end

-- Enum: every access returns a unique stable token
local enumCache = {}
local Enum = setmetatable({}, {
	__index = function(_, category)
		if not enumCache[category] then
			enumCache[category] = setmetatable({}, {
				__index = function(t, item)
					local token =
						{ __rbxtype = "EnumItem", Name = item, Value = 0, EnumType = category }
					rawset(t, item, token)
					return token
				end,
			})
		end
		return enumCache[category]
	end,
})

local function udim2(...)
	local a = { ... }
	return { __rbxtype = "UDim2", X = { Scale = a[1] or 0, Offset = a[2] or 0 }, Y = { Scale = a[3] or 0, Offset = a[4] or 0 } }
end
local UDim2 = {
	new = udim2,
	fromOffset = function(x, y)
		return udim2(0, x, 0, y)
	end,
	fromScale = function(x, y)
		return udim2(x, 0, y, 0)
	end,
}
local UDim = {
	new = function(s, o)
		return { __rbxtype = "UDim", Scale = s or 0, Offset = o or 0 }
	end,
}
local Vector2 = {
	new = makeVec2,
	zero = makeVec2(0, 0),
}
setmetatable(Vector2, {
	__index = function(_, k)
		if k == "zero" then
			return makeVec2(0, 0)
		end
	end,
})

local Color3 = {}
Color3.fromRGB = function(r, g, b)
	return { __rbxtype = "Color3", R = (r or 0) / 255, G = (g or 0) / 255, B = (b or 0) / 255, ToHSV = nil }
end
Color3.new = function(r, g, b)
	return { __rbxtype = "Color3", R = r or 0, G = g or 0, B = b or 0 }
end
Color3.fromHSV = function(h, s, v)
	return { __rbxtype = "Color3", R = v, G = v, B = v, H = h, S = s, V = v }
end
local function color3ToHSV(self)
	return self.H or 0, self.S or 0, self.V or self.R or 0
end
-- attach ToHSV via metatable on color tables
local origFromRGB = Color3.fromRGB
Color3.fromRGB = function(r, g, b)
	local c = origFromRGB(r, g, b)
	c.ToHSV = color3ToHSV
	return c
end
local origNew = Color3.new
Color3.new = function(r, g, b)
	local c = origNew(r, g, b)
	c.ToHSV = color3ToHSV
	return c
end
local origHSV = Color3.fromHSV
Color3.fromHSV = function(h, s, v)
	local c = origHSV(h, s, v)
	c.ToHSV = color3ToHSV
	return c
end

local Font = {
	new = function(...)
		return { __rbxtype = "Font" }
	end,
	fromEnum = function(...)
		return { __rbxtype = "Font" }
	end,
}
local TweenInfo = {
	new = function(...)
		return { __rbxtype = "TweenInfo" }
	end,
}
local Rect = {
	new = function(...)
		return { __rbxtype = "Rect" }
	end,
}
local NumberSequence = {
	new = function(...)
		return { __rbxtype = "NumberSequence" }
	end,
}
local NumberSequenceKeypoint = {
	new = function(...)
		return { __rbxtype = "NumberSequenceKeypoint" }
	end,
}
local ColorSequence = {
	new = function(...)
		return { __rbxtype = "ColorSequence" }
	end,
}
local ColorSequenceKeypoint = {
	new = function(...)
		return { __rbxtype = "ColorSequenceKeypoint" }
	end,
}

-- typeof
local function rbxtypeof(v)
	local t = type(v)
	if t == "table" and v.__rbxtype then
		return v.__rbxtype
	end
	return t
end

-- Services
local services = {}
local function svc(name, extra)
	local inst = newInstance(name)
	if extra then
		for k, v in pairs(extra) do
			rawset(getmetatable(inst), "__svc_" .. k, v)
		end
	end
	return inst
end

local UIS = newInstance("UserInputService")
UIS.MouseIconEnabled = true
rawset(UIS, "GetFocusedTextBox", function()
	return nil
end)
rawset(UIS, "IsKeyDown", function()
	return false
end)
rawset(UIS, "IsMouseButtonPressed", function()
	return false
end)
-- expose methods through __index override
local function attachMethod(inst, name, fn)
	local mt = getmetatable(inst)
	local oldIndex = mt.__index
	mt.__index = function(t, k)
		if k == name then
			return fn
		end
		return oldIndex(t, k)
	end
end
attachMethod(UIS, "GetFocusedTextBox", function()
	return nil
end)
attachMethod(UIS, "IsKeyDown", function()
	return false
end)
attachMethod(UIS, "IsMouseButtonPressed", function()
	return false
end)

local RS = newInstance("RunService")
attachMethod(RS, "BindToRenderStep", function(_, name, prio, fn)
	RBX._renderFn = fn
end)
attachMethod(RS, "UnbindFromRenderStep", function(_, name)
	RBX._renderFn = nil
end)
attachMethod(RS, "IsStudio", function()
	return true
end)

local TS = newInstance("TweenService")
attachMethod(TS, "Create", function()
	return { Play = function() end, Cancel = function() end }
end)

local Plr = newInstance("Player")
attachMethod(Plr, "GetMouse", function()
	return { X = 60, Y = 60 }
end)
attachMethod(Plr, "WaitForChild", function()
	return newInstance("PlayerGui")
end)

local PlayersSvc = newInstance("Players")
rawset(getmetatable(PlayersSvc), "__plr", Plr)
attachMethod(PlayersSvc, "GetPlayers", function()
	return { Plr }
end)
-- LocalPlayer property
do
	local mt = getmetatable(PlayersSvc)
	local oldIndex = mt.__index
	mt.__index = function(t, k)
		if k == "LocalPlayer" then
			return Plr
		end
		if k == "GetPlayers" then
			return function()
				return { Plr }
			end
		end
		return oldIndex(t, k)
	end
end

local TextServiceSvc = newInstance("TextService")
local CoreGuiSvc = newInstance("CoreGui")

services.UserInputService = UIS
services.RunService = RS
services.TweenService = TS
services.Players = PlayersSvc
services.TextService = TextServiceSvc
services.CoreGui = CoreGuiSvc

local game = newInstance("DataModel")
attachMethod(game, "GetService", function(_, name)
	return services[name] or newInstance(name)
end)
attachMethod(game, "HttpGet", function(_, url)
	return RBX._httpGet and RBX._httpGet(url) or ""
end)
RBX.SetHttpGet = function(fn)
	RBX._httpGet = fn
end

local workspace = newInstance("Workspace")
do
	local cam = newInstance("Camera")
	cam.ViewportSize = makeVec2(1920, 1080)
	workspace.CurrentCamera = cam
end

-- Install globals
RBX.install = function(env)
	env.Instance = Instance
	env.Enum = Enum
	env.UDim2 = UDim2
	env.UDim = UDim
	env.Vector2 = Vector2
	env.Color3 = Color3
	env.Font = Font
	env.TweenInfo = TweenInfo
	env.Rect = Rect
	env.NumberSequence = NumberSequence
	env.NumberSequenceKeypoint = NumberSequenceKeypoint
	env.ColorSequence = ColorSequence
	env.ColorSequenceKeypoint = ColorSequenceKeypoint
	env.typeof = rbxtypeof
	env.game = game
	env.workspace = workspace
	env.task = { spawn = function(f, ...) f(...) end, delay = function() end, wait = function() end }
	env.warn = function(...) print("[warn]", ...) end
	env.tick = os.clock
	env.UIS = UIS
	env.MockRender = function()
		if RBX._renderFn then
			RBX._renderFn()
		end
	end
end

RBX.MockRender = function()
	if RBX._renderFn then
		RBX._renderFn()
	end
end

return RBX
