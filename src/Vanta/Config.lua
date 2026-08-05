local M = {}

local function HasFileIO()
	return typeof(writefile) == "function" and typeof(readfile) == "function"
end

function M:SaveConfig(fileName)
	fileName = fileName or "VantaConfig"

	if not HasFileIO() then
		self:Notify({
			Title = "Save Not Supported",
			Content = "This environment does not support file saving (writefile/readfile)",
			Duration = 5,
			icone = true,
		})
		return false
	end

	local data = {}
	for flag, element in pairs(self.Flags) do
		local ok, value = pcall(function()
			if element.GetString then
				return element.GetString()
			end
			if element.Get then
				local v = element:Get()
				if typeof(v) == "Color3" then
					return {
						__color = true,
						R = math.floor(v.R * 255 + 0.5),
						G = math.floor(v.G * 255 + 0.5),
						B = math.floor(v.B * 255 + 0.5),
					}
				end
				return v
			end
			return nil
		end)
		if ok and value ~= nil then
			data[flag] = value
		end
	end

	local ok2, json = pcall(function()
		return game:GetService("HttpService"):JSONEncode(data)
	end)

	if not ok2 then
		self:Notify({
			Title = "Save Error",
			Content = "Failed to encode settings",
			Duration = 5,
			icone = true,
		})
		return false
	end

	local ok3 = pcall(function()
		if not isfolder("VantaConfigs") then
			makefolder("VantaConfigs")
		end
		writefile("VantaConfigs/" .. fileName .. ".json", json)
	end)

	if not ok3 then
		self:Notify({
			Title = "Save Error",
			Content = "Failed to write file",
			Duration = 5,
			icone = true,
		})
		return false
	end

	self:Notify({
		Title = "Saved",
		Content = "Your settings were saved successfully",
		Duration = 3,
		icone = true,
	})
	return true
end

function M:LoadConfig(fileName)
	fileName = fileName or "VantaConfig"

	if not HasFileIO() then
		self:Notify({
			Title = "Load Not Supported",
			Content = "This environment does not support file reading",
			Duration = 5,
			icone = true,
		})
		return false
	end

	local ok, json = pcall(function()
		return readfile("VantaConfigs/" .. fileName .. ".json")
	end)

	if not ok or not json then
		self:Notify({
			Title = "No Saved Config",
			Content = 'No file found named "' .. fileName .. '"',
			Duration = 5,
			icone = true,
		})
		return false
	end

	local ok2, data = pcall(function()
		return game:GetService("HttpService"):JSONDecode(json)
	end)

	if not ok2 or type(data) ~= "table" then
		self:Notify({
			Title = "Load Error",
			Content = "Config file is corrupted or invalid",
			Duration = 5,
			icone = true,
		})
		return false
	end

	local loadedCount = 0
	for flag, value in pairs(data) do
		local element = self.Flags[flag]
		if element and element.Set then
			local ok3 = pcall(function()
				if typeof(value) == "table" and value.__color then
					element:Set(Color3.fromRGB(value.R, value.G, value.B))
				else
					element:Set(value)
				end
			end)
			if ok3 then
				loadedCount = loadedCount + 1
			end
		end
	end

	self:Notify({
		Title = "Loaded",
		Content = "Successfully loaded " .. loadedCount .. " setting(s)",
		Duration = 3,
		icone = true,
	})
	return true
end


return M
