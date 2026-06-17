--[[
loadstring(game:HttpGet("https://raw.githubusercontent.com/sentinel-bz/sentinel-ui/refs/heads/main/keyhandler.luau"))()
--]]

do
	local oth = oth or {}
	oth.hook = (oth and oth.hook) or hookfunction
	oth.unhook = oth.unhook or function() end

	if oth.hook and getrawmetatable and getgenv then
		oth.unhook(getrawmetatable(game).__index)
		local oldIndex
		oldIndex = oth.hook(getrawmetatable(game).__index, function(...)
			local args = { ... }
			if args[2] == "HttpGet" then
				return error()
			end
			return oldIndex(...)
		end)

		-- KeyHandler probes call-stack depth with error("",9)/error("",10) and BreakJoints-crashes when required from a wrapped caller (loadstring/module/CharacterAdded); strip position info on empty-message errors so the probe reads "" and the depth gate passes
		local oldError
		oldError = oth.hook(error, function(message, level)
			if message == "" then
				return oldError("", 0)
			end
			return oldError(message, level)
		end)

		local KeyHandler = require(game:GetService("ReplicatedStorage").Assets.Modules.KeyHandler)()

		oth.unhook(error)

		getgenv().__sentinel_keyhandler = KeyHandler
		getgenv().__sentinel_world = require(game:GetService("ReplicatedStorage").Info.RealmInfo).CurrentWorld

		print("[sentinel stasher] KeyHandler stashed (world=" .. tostring(getgenv().__sentinel_world) .. ")")
	end
end