-- Vanta SaveManager
-- Standalone add-on. Load it, call SetLibrary(Window), then CreateConfigSection(Tab).

local SaveManager = {}
SaveManager.Folder = "VantaConfigs"
SaveManager.Window = nil

local function HasFileIO()
	return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfolder) == "function"
end

local function EnsureFolder()
	if not HasFileIO() then
		return
	end
	if not isfolder(SaveManager.Folder) then
		makefolder(SaveManager.Folder)
	end
end

function SaveManager:SetLibrary(window)
	self.Window = window
end

function SaveManager:SetFolder(folder)
	self.Folder = folder
	EnsureFolder()
end

function SaveManager:ListConfigs()
	local list = {}
	if not HasFileIO() then
		return list
	end

	EnsureFolder()

	local ok, files = pcall(function()
		return listfiles(self.Folder)
	end)
	if not ok or not files then
		return list
	end

	for _, path in ipairs(files) do
		local name = path:match("([^\\/]+)%.json$")
		if name then
			table.insert(list, name)
		end
	end

	return list
end

function SaveManager:Save(fileName)
	if not self.Window then
		return false
	end
	return self.Window:SaveConfig(fileName)
end

function SaveManager:Load(fileName)
	if not self.Window then
		return false
	end
	return self.Window:LoadConfig(fileName)
end

function SaveManager:CreateConfigSection(tab)
	if not tab then
		return
	end

	EnsureFolder()

	local section = tab:AddSection({ Name = "Config" })
	local selectedConfig = nil

	local configDropdown
	local nameInput

	local function refreshList()
		local list = self:ListConfigs()
		if configDropdown then
			configDropdown:Set(nil)
		end
		return list
	end

	nameInput = section:AddInput("ConfigName", {
		Title = "Config Name",
		Placeholder = "MyConfig",
		Default = "",
	})

	configDropdown = section:AddDropdown({
		Name = "Saved Configs",
		Description = "Choose an existing config to load",
		Options = self:ListConfigs(),
		Placeholder = "None",
		Callback = function(value)
			selectedConfig = value
		end,
	})

	section:AddButton({
		Name = "Save Config",
		Callback = function()
			local fileName = (nameInput and nameInput:Get()) or ""
			if fileName == "" then
				fileName = selectedConfig or "VantaConfig"
			end
			self:Save(fileName)
			configDropdown:Set(nil)
		end,
	})

	section:AddButton({
		Name = "Load Config",
		Callback = function()
			local fileName = selectedConfig or ((nameInput and nameInput:Get()) ~= "" and nameInput:Get()) or "VantaConfig"
			self:Load(fileName)
		end,
	})

	section:AddButton({
		Name = "Refresh List",
		Callback = function()
			refreshList()
		end,
	})

	return section
end

return SaveManager
