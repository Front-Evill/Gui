math.randomseed(tick())

local Library = {}
Library.__index = Library

local ThemeModule = require(script.Theme)
local WindowMethods = require(script.Window)(Library)
local NotifyMethods = require(script.Notify)
local DialogMethods = require(script.Dialog)
local ConfigMethods = require(script.Config)

Library.Presets = ThemeModule.Presets

local function mix(methods)
	for name, fn in pairs(methods) do
		Library[name] = fn
	end
end

mix(WindowMethods)
mix(NotifyMethods)
mix(DialogMethods)
mix(ConfigMethods)

return Library
