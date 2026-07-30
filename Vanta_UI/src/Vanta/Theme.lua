local function ToColor3(value)
	if typeof(value) == "Color3" then
		return value
	end

	if typeof(value) == "string" then
		local hex = value:gsub("#", "")
		if #hex == 3 then
			local r = hex:sub(1, 1)
			local g = hex:sub(2, 2)
			local b = hex:sub(3, 3)
			hex = r .. r .. g .. g .. b .. b
		end
		local r = tonumber(hex:sub(1, 2), 16) or 255
		local g = tonumber(hex:sub(3, 4), 16) or 255
		local b = tonumber(hex:sub(5, 6), 16) or 255
		return Color3.fromRGB(r, g, b)
	end

	if typeof(value) == "table" then
		if value.R and value.G and value.B then
			return Color3.fromRGB(value.R, value.G, value.B)
		end
		if value[1] and value[2] and value[3] then
			return Color3.fromRGB(value[1], value[2], value[3])
		end
	end

	return Color3.fromRGB(255, 255, 255)
end

local function ResolveTheme(theme)
	local resolved = {}
	for key, value in pairs(theme) do
		if key == "Transparency" then
			resolved[key] = value
		else
			resolved[key] = ToColor3(value)
		end
	end
	return resolved
end

local function GenerateThemeFromAccent(accent)
	local h, s = accent:ToHSV()

	local background = Color3.fromHSV(h, math.clamp(s * 0.35, 0, 0.35), 0.085)
	local secondary = Color3.fromHSV(h, math.clamp(s * 0.35, 0, 0.35), 0.125)
	local descColor = Color3.fromHSV(h, math.clamp(s * 0.25, 0, 0.25), 0.68)

	return {
		Accent = accent,
		Background = background,
		Secondary = secondary,
		TitleColor = Color3.fromRGB(255, 255, 255),
		DescColor = descColor,
		SectionColor = accent,
		Transparency = 0.35,
	}
end

local Presets = {
	Dark = GenerateThemeFromAccent(Color3.fromRGB(130, 130, 140)),
	Purple = GenerateThemeFromAccent(Color3.fromRGB(150, 100, 255)),
	Rose = GenerateThemeFromAccent(Color3.fromRGB(255, 90, 130)),
	Blue = GenerateThemeFromAccent(Color3.fromRGB(80, 140, 255)),
	Green = GenerateThemeFromAccent(Color3.fromRGB(80, 220, 150)),
	Orange = GenerateThemeFromAccent(Color3.fromRGB(255, 150, 70)),
	Cyan = GenerateThemeFromAccent(Color3.fromRGB(70, 220, 220)),
	Gold = GenerateThemeFromAccent(Color3.fromRGB(230, 190, 90)),
}

Presets.Dark.SectionColor = Color3.fromRGB(255, 255, 255)


local function GetRandomPresetName()
	local names = {}
	for name in pairs(Presets) do
		table.insert(names, name)
	end
	return names[math.random(1, #names)]
end


return {
	ToColor3 = ToColor3,
	ResolveTheme = ResolveTheme,
	GenerateThemeFromAccent = GenerateThemeFromAccent,
	Presets = Presets,
	GetRandomPresetName = GetRandomPresetName,
}
