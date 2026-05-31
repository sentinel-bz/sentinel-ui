# Runs the self-test flow against Sentinel.lua under luau.exe using the Roblox API mock.
$here = $PSScriptRoot
$repo = Split-Path $here -Parent
function ReadNoBom($p) { return [System.IO.File]::ReadAllText($p).TrimStart([char]0xFEFF) }
$luau = if (Get-Command luau -ErrorAction SilentlyContinue) { "luau" } else { "$env:USERPROFILE\.luau-bin\luau.exe" }

$mock = ReadNoBom "$here\mock.lua"
$lib  = ReadNoBom "$repo\Sentinel.lua"
$test = ReadNoBom "$here\self_test.lua"

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
function LoadLibrary()
__LIB__
end
local Library = LoadLibrary()
__TEST__
'@

$combined = $prelude.Replace("__MOCK__", $mock).Replace("__LIB__", $lib).Replace("__TEST__", $test)
$out = "$here\_combined.lua"
[System.IO.File]::WriteAllText($out, $combined, (New-Object System.Text.UTF8Encoding($false)))
& $luau $out
