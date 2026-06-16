--[[
	sentinel.bz · KeyHandler Primer (Rogue Lineage)

	KeyHandler won't load from inside an injected script — its anti-tamper checks
	the call stack and bails the moment it's required from a nested context. This
	primer runs as a clean top-level execution, slips past that, and caches the
	handler in getgenv() so Sentinel reuses it instantly (no G key-press, no crash).

	Usage:   1) run this      2) run Sentinel        (once per join)
]]

if getgenv().__sentinel_keyhandler then
	return print("[sentinel] KeyHandler already primed — run Sentinel")
end

-- verbatim lostic: do NOT wrap this require in pcall / a function — the anti-tamper reads the caller and any nesting trips it
oth.unhook(getrawmetatable(game).__index)
local oldIndex
oldIndex = oth.hook(getrawmetatable(game).__index, function(...)
	local args = { ... }
	if args[2] == "HttpGet" then
		return error()
	end
	return oldIndex(...)
end)

local KeyHandler = require(game:GetService("ReplicatedStorage").Assets.Modules.KeyHandler)()

getgenv().__sentinel_keyhandler = KeyHandler
getgenv().__sentinel_world = require(game:GetService("ReplicatedStorage").Info.RealmInfo).CurrentWorld

print("[sentinel] KeyHandler primed for " .. tostring(getgenv().__sentinel_world) .. " — now run Sentinel")
pcall(function()
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "sentinel.bz",
		Text = "KeyHandler primed — now run Sentinel",
		Duration = 6,
	})
end)
