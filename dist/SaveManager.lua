local SaveManager = {}
SaveManager.Folder = "DevlyxConfigs"
SaveManager.Window = nil

local function HasFileIO()
	return typeof(writefile) == "function"
		and typeof(readfile) == "function"
		and typeof(isfolder) == "function"
		and typeof(makefolder) == "function"
end

local function EnsureFolder()
	if not HasFileIO() then
		return
	end
	if not isfolder(SaveManager.Folder) then
		makefolder(SaveManager.Folder)
	end
end

local function SanitizeFileName(fileName)
	fileName = tostring(fileName or ""):gsub("[^%w%s%-_]", "")
	fileName = fileName:gsub("^%s+", ""):gsub("%s+$", "")
	return fileName
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

	table.sort(list)
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

	local section = tab:AddSection({ Name = "Config", Icon = "save" })
	local selectedConfig = nil

	local configDropdown
	local nameInput

	local function refreshList()
		local list = self:ListConfigs()
		if configDropdown then
			configDropdown:SetOptions(list)
		end
		return list
	end

	nameInput = section:AddInput("ConfigName", {
		Title = "Config Name",
		Placeholder = "MyConfig",
		Default = "",
		Icon = "type",
	})

	configDropdown = section:AddDropdown({
		Name = "Saved Configs",
		Description = "Choose an existing config to load",
		Options = self:ListConfigs(),
		Icon = "list",
		Callback = function(value)
			selectedConfig = value
		end,
	})

	section:AddButton({
		Name = "Save Config",
		Icon = "save",
		Callback = function()
			local fileName = SanitizeFileName(nameInput and nameInput:Get())
			if fileName == "" then
				fileName = SanitizeFileName(selectedConfig) ~= "" and selectedConfig or "DevlyxConfig"
			end
			local ok = self:Save(fileName)
			if ok then
				refreshList()
				selectedConfig = fileName
				configDropdown:Set(fileName)
			end
		end,
	})

	section:AddButton({
		Name = "Load Config",
		Icon = "folder-open",
		Callback = function()
			local typedName = SanitizeFileName(nameInput and nameInput:Get())
			local fileName = (typedName ~= "" and typedName) or selectedConfig or "DevlyxConfig"
			self:Load(fileName)
		end,
	})

	section:AddButton({
		Name = "Refresh List",
		Icon = "refresh-cw",
		Callback = function()
			refreshList()
		end,
	})

	return section
end

return SaveManager
