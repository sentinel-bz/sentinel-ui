oth.unhook(getrawmetatable(game).__index)
local oldIndex
oldIndex = oth.hook(getrawmetatable(game).__index, function(...)
    local args = {...}
    if args[2] == "HttpGet" then
        return error()
    end
    return oldIndex(...)
end)

local IDENTITY = 2

local setIdentity = setthreadidentity or setidentity or setthreadcontext
local getIdentity = getthreadidentity or getidentity or getthreadcontext

local savedIdentity
local function enterGameContext()
    savedIdentity = getIdentity and getIdentity()
    if setIdentity then setIdentity(IDENTITY) end
    oth.unhook(getrenv().getfenv)
    oth.hook(getrenv().getfenv, function(level)
        return getsenv(game:GetService("Players").LocalPlayer.PlayerScripts.ClientManage)
    end)
end
local function exitGameContext()
    oth.unhook(getrenv().getfenv)
    if setIdentity and savedIdentity then setIdentity(savedIdentity) end
end

enterGameContext()
local KeyHandler = require(game:GetService("ReplicatedStorage").Assets.Modules.KeyHandler)()
exitGameContext()
print(KeyHandler)
local remotes = {
    Gaia = {
        ["PostDialogue"] = 404.5041892976703,
        ["SetManaChargeState"] = 27.81839265298673,
        ["ApplyFallDamage"] = 90.32503962905011,
        ["Tango"] = 30195.341357415226,
        ["Dodges"] = 398.00010021400533,
        ["SetCurrentArea"] = "SetCurrentArea",
        ["PlaceTool"] = "PlaceTool",
        ["PlaceMoney"] = "PlaceMoney",
        ["Theodora"] = "Theodora",
        ["InvisIngredient"] = "InvisIngredient",
        ["HideOre"] = "HideOre",
    },
    Khei = {
        ["Charge"] = "Charge",
        ["FallDamage"] = "FallDamage",
        ["SendDialogue"] = "SendDialogue",
        ["Dolorosa"] = "Dolorosa",
        ["HideIngredient"] = "HideIngredient",
        ["HideOre"] = "HideOre",
        ["AddClimbing"] = "AddClimbing",
        ["ClientFall"] = "ClientFall",
        ["ClientSprint"] = "ClientSprint",
        ["MoneyBag"] = "MoneyBag",
        ["ToolBag"] = "ToolBag",
        ["UpdateArea"] = "UpdateArea",
        ["Drop"] = "Drop",
    },
}

local function GetRemote(remoteName: string)
    local CurrentWorld = require(game:GetService("ReplicatedStorage").Info.RealmInfo).CurrentWorld
    local password = remotes[CurrentWorld][remoteName]
    assert(password, `{remoteName} is not valid`)

    local key = (CurrentWorld == "Gaia" and "plum") or (CurrentWorld == "Khei" and "apricot")
    assert(key, `Invalid Key, check PlaceId/Realm`)

    enterGameContext()
    local remote = (CurrentWorld == "Gaia" and KeyHandler[1](password, key)) or (CurrentWorld == "Khei" and KeyHandler.getKey(password, key))
    exitGameContext()
    assert(remote, `Failed to grab {remoteName}`)
    return remote
end

--local Charge = GetRemote("Charge")
--Charge:FireServer(true)

for i,v in pairs(remotes["Gaia"]) do
    print(i, GetRemote(i))
end
