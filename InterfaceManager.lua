
local HttpService = game:GetService("HttpService")

local InterfaceManager = {}
InterfaceManager.Folder = "DevlyxSettings"
InterfaceManager.Window = nil

local function HasFileIO()
	return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfolder) == "function"
end

local function EnsureFolder()
	if not HasFileIO() then
		return
	end
	if not isfolder(InterfaceManager.Folder) then
		makefolder(InterfaceManager.Folder)
	end
end

local function SettingsPath()
	return InterfaceManager.Folder .. "/interface.json"
end

function InterfaceManager:SetLibrary(window)
	self.Window = window
end

function InterfaceManager:SetFolder(folder)
	self.Folder = folder
	EnsureFolder()
end

function InterfaceManager:Save()
	if not HasFileIO() or not self.Window then
		return false
	end

	EnsureFolder()

	local data = {
		Theme = self.Window.CurrentThemeName,
		Search = self.Window.SearchRow ~= nil and self.Window.SearchRow.Visible,
		Resize = self.Window.ResizeHandle ~= nil,
		Stats = self.Window.StatsButton ~= nil and self.Window.StatsButton.Visible,
		Animation = self.Window.Animation ~= false,
	}

	local ok, json = pcall(function()
		return HttpService:JSONEncode(data)
	end)
	if not ok then
		return false
	end

	local ok2 = pcall(function()
		writefile(SettingsPath(), json)
	end)
	return ok2
end

function InterfaceManager:Load()
	if not HasFileIO() or not self.Window then
		return false
	end

	local ok, json = pcall(function()
		return readfile(SettingsPath())
	end)
	if not ok or not json then
		return false
	end

	local ok2, data = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	if not ok2 or type(data) ~= "table" then
		return false
	end

	if data.Theme and self.Window.Presets and self.Window.Presets[data.Theme] then
		self.Window:SetTheme(data.Theme)
	end

	if self.Window.SearchRow then
		self.Window.SearchRow.Visible = data.Search ~= false
	end

	if self.Window.StatsButton then
		self.Window.StatsButton.Visible = data.Stats ~= false
	end

	if data.Animation ~= nil then
		self.Window.Animation = data.Animation
	end

	return true
end

function InterfaceManager:CreateInterfaceSection(tab)
	if not tab then
		return
	end

	local section = tab:AddSection({ Name = "Interface" })

	local presetOrder = { "Dark", "Purple", "Rose", "Blue", "Green", "Orange", "Cyan", "Gold" }

	section:AddDropdown({
		Name = "Theme",
		Description = "Interface color theme",
		Options = presetOrder,
		Default = self.Window.CurrentThemeName,
		Callback = function(presetName)
			self.Window:SetTheme(presetName)
			self:Save()
		end,
	})

	section:AddToggle({
		Name = "Search",
		Description = "Show the tab search bar",
		Default = self.Window.SearchRow ~= nil and self.Window.SearchRow.Visible,
		Callback = function(state)
			if self.Window.SearchRow then
				self.Window.SearchRow.Visible = state
			end
			self:Save()
		end,
	})

	section:AddToggle({
		Name = "Resize",
		Description = "Allow the window to be resized",
		Default = self.Window.ResizeHandle ~= nil,
		Callback = function(state)
			if self.Window.ResizeHandle then
				self.Window.ResizeHandle.Visible = state
				self.Window.ResizeHandle.Active = state
			end
			self:Save()
		end,
	})

	section:AddToggle({
		Name = "Stats",
		Description = "Show the stats button",
		Default = self.Window.StatsButton ~= nil and self.Window.StatsButton.Visible,
		Callback = function(state)
			if self.Window.StatsButton then
				self.Window.StatsButton.Visible = state
			end
			self:Save()
		end,
	})

	section:AddToggle({
		Name = "Animation",
		Description = "Enable UI animations",
		Default = self.Window.Animation ~= false,
		Callback = function(state)
			self.Window.Animation = state
			self:Save()
		end,
	})

	return section
end

return InterfaceManager
