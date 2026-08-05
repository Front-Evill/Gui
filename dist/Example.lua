-- Vanta — full usage example
-- Loads the library and the two add-ons, then builds a window that
-- exercises every element and feature the library offers.

local Library = loadstring(game:HttpGet("https://github.com/Front-Evill/Library/releases/latest/download/main.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://github.com/Front-Evill/Library/releases/latest/download/InterfaceManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://github.com/Front-Evill/Library/releases/latest/download/SaveManager.lua"))()

local Window = Library:Window({
	Title = "Vanta Demo",
	SubTitle = "by FrontEvill",
	Theme = "All",           -- preset name, "Random"/"All", or a custom { Accent = ... } table
	Size = UDim2.fromOffset(620, 420),
	Search = true,               -- searchable tab list
	Resize = true,                -- drag-to-resize from the corner
	Stats = true,                 -- FPS / ping popup, centered on the window
	Acrylic = false,               -- frosted-glass background blur (needs a stable camera)
	Animation = true,
	MinimizeKey = Enum.KeyCode.RightControl,
})

--------------------------------------------------------------------
-- Tabs (AddTapHover inserts a labeled divider between tab groups)
--------------------------------------------------------------------

local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local ToolsTab = Window:AddTab({ Name = "Tools", Icon = "wrench" })

Window:AddTapHover({ Name = "Extra" })

local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

--------------------------------------------------------------------
-- Main tab: every basic element
--------------------------------------------------------------------

local GeneralSection = MainTab:AddSection({ Name = "General", Icon = "star" })

GeneralSection:AddButton({
	Name = "Reapply last animation",
	Description = "Useful after dying or respawning",
	Icon = "refresh-cw",
	Callback = function()
		Window:Notify({ Title = "Applied", Content = "Last animation re-applied.", Duration = 4 })
	end,
})

-- Two AddButton calls back-to-back automatically share one row
GeneralSection:AddButton({
	Name = "Save preset",
	Icon = "save",
	Callback = function() end,
})
GeneralSection:AddButton({
	Name = "Delete preset",
	Icon = "trash",
	Confirm = {
		Title = "Delete preset?",
		Content = "This cannot be undone.",
		ConfirmText = "Delete",
		CancelText = "Cancel",
	},
	Callback = function()
		Window:Notify({ Title = "Deleted", Content = "Preset removed.", Duration = 4 })
	end,
})

GeneralSection:AddToggle({
	Name = "Auto reapply",
	Description = "Re-applies the animation automatically",
	Default = false,
	Icon = "toggle-left",
	Flag = "AutoReapply",
	Callback = function(value) end,
})

GeneralSection:AddSlider("WalkSpeed", {
	Title = "Walk speed",
	Default = 16,
	Min = 8,
	Max = 100,
	Rounding = 0,
	Flag = "WalkSpeed",
	Callback = function(value) end,
})

GeneralSection:AddDropdown({
	Name = "Animation set",
	Description = "Choose which pack to use",
	Options = { "Default", "Combat", "Dance", "Custom" },
	Default = "Default",
	Icon = "list",
	Flag = "AnimationSet",
	Callback = function(value) end,
})

GeneralSection:AddMultiDropdown({
	Name = "Enabled modules",
	Options = { "Combat", "Movement", "Utility", "Visuals" },
	Default = { "Movement" },
	Flag = "EnabledModules",
	Callback = function(values) end,
})

GeneralSection:AddColorPicker({
	Name = "Theme color",
	Description = "Interface color theme",
	Default = "Purple",
	Callback = function(presetName) end,
})

--------------------------------------------------------------------
-- Tools tab: input / keybind / paragraph / code / links / progress
--------------------------------------------------------------------

local InputSection = ToolsTab:AddSection({ Name = "Input", Icon = "keyboard" })

InputSection:AddInput("PlayerName", {
	Title = "Target player",
	Placeholder = "Enter a username",
	Default = "",
	Flag = "TargetPlayer",
	Callback = function(text) end,
})

InputSection:AddKeybind("ToggleUI", {
	Title = "Toggle UI",
	Default = Enum.KeyCode.RightShift,
	Flag = "ToggleUIKey",
	Callback = function() end,
})

local InfoSection = ToolsTab:AddSection({ Name = "Info", Icon = "info" })

InfoSection:AddParagraph({
	Title = "About this hub",
	Content = "This panel demonstrates every element Vanta ships with, laid out the way a real script hub would use them.",
})

InfoSection:AddCodeBlock({
	Title = "Quick snippet",
	Description = "Copy with the toolbar button",
	Code = 'print("Hello from Vanta")',
	Language = "lua",
})

InfoSection:AddLinks({
	Name = "Discord server",
	Description = "Get support and updates",
	Icon = "message-circle",
	Link = "https://discord.gg/example",
})

local progress = InfoSection:AddProgressBar({
	Name = "Loading cache",
	Default = 0,
})
progress:Set(0.65)

-- Card-style grid of quick actions
local Combat = ToolsTab:AddSectionsBox({ Name = "Combat", Image = "sword", Description = "Combat related tools" })
local Movement = ToolsTab:AddSectionsBox({ Name = "Movement", Image = "move", Description = "Speed and jump tweaks" })

Combat:AddButton({ Name = "Attack", Icon = "sword", Callback = function() end })
Movement:AddSlider("Speed", { Default = 16, Min = 8, Max = 100 })

--------------------------------------------------------------------
-- Settings tab: interface + config management add-ons
--------------------------------------------------------------------

InterfaceManager:SetLibrary(Window)
InterfaceManager:SetFolder("VantaDemo")
InterfaceManager:CreateInterfaceSection(SettingsTab)

SaveManager:SetLibrary(Window)
SaveManager:SetFolder("VantaDemo/configs")
SaveManager:CreateConfigSection(SettingsTab)

--------------------------------------------------------------------
-- Notifications and dialogs
--------------------------------------------------------------------

Window:Notify({
	Title = "Welcome",
	Content = "Vanta demo loaded successfully.",
	Duration = 5,
})

-- Window:Dialog({
-- 	Title = "Example dialog",
-- 	Content = "Dialogs render centered inside the window, not the whole screen.",
-- 	Buttons = {
-- 		{ Title = "Okay", Callback = function() end },
-- 	},
-- })
