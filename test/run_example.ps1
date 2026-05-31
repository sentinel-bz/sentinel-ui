# Runs example.lua through the real loadstring(game:HttpGet(...))() path under luau.exe.
$here = $PSScriptRoot
$repo = Split-Path $here -Parent
function ReadNoBom($p) { return [System.IO.File]::ReadAllText($p).TrimStart([char]0xFEFF) }
$luau = if (Get-Command luau -ErrorAction SilentlyContinue) { "luau" } else { "$env:USERPROFILE\.luau-bin\luau.exe" }

$mock = ReadNoBom "$here\mock.lua"
$lib  = ReadNoBom "$repo\Sentinel.lua"
$ex   = ReadNoBom "$repo\example.lua"

$prelude = @'
local Mock = (function()
__MOCK__
end)()
local E = {}
Mock.install(E)
Instance = E.Instance
Enum = E.Enum
UDim2 = E.UDim2
UDim = E.UDim
Vector2 = E.Vector2
Color3 = E.Color3
Font = E.Font
TweenInfo = E.TweenInfo
Rect = E.Rect
NumberSequence = E.NumberSequence
NumberSequenceKeypoint = E.NumberSequenceKeypoint
ColorSequence = E.ColorSequence
ColorSequenceKeypoint = E.ColorSequenceKeypoint
typeof = E.typeof
game = E.game
workspace = E.workspace
task = E.task
warn = E.warn
UIS = E.UIS
shared = {}
getgenv = function() return shared end
local SENTINEL_SRC = [==[
__LIB__
]==]
Mock.SetHttpGet(function() return SENTINEL_SRC end)
__EXAMPLE__
print("\nEXAMPLE RAN CLEANLY")
'@

$combined = $prelude.Replace("__MOCK__", $mock).Replace("__LIB__", $lib).Replace("__EXAMPLE__", $ex)
$out = "$here\_combined_example.lua"
[System.IO.File]::WriteAllText($out, $combined, (New-Object System.Text.UTF8Encoding($false)))
& $luau $out
