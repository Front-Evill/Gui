local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local Utils = require(script.Parent.Utils)
local CreateInstance = Utils.CreateInstance
local AttachTooltip = Utils.AttachTooltip
local FadeTransparency = Utils.FadeTransparency
local PlayTween = Utils.PlayTween

local IconsModule = require(script.Parent.Icons)
local ResolveIcon = IconsModule.ResolveIcon

local KeybindsModule = require(script.Parent.Keybinds)
local ResolveKeybind = KeybindsModule.ResolveKeybind
local KeybindDisplayName = KeybindsModule.KeybindDisplayName

local ThemeModule = require(script.Parent.Theme)
local Presets = ThemeModule.Presets

local CODE_FONT = Enum.Font.Code
local CODE_TEXT_SIZE = 12
local CODE_LINE_HEIGHT = TextService:GetTextSize("Ag", CODE_TEXT_SIZE, CODE_FONT, Vector2.new(1000, 1000)).Y
local CODE_FALLBACK_BG = Color3.fromRGB(28, 28, 30)
local FIXED_TITLE_COLOR = Color3.fromRGB(255, 255, 255)
local FIXED_DESC_COLOR = Color3.fromRGB(158, 158, 158)

local LOCALE_COUNTRY_NAMES = {
	iq = "Iraq", sa = "Saudi Arabia", ae = "United Arab Emirates", eg = "Egypt",
	kw = "Kuwait", jo = "Jordan", sy = "Syria", lb = "Lebanon", ps = "Palestine",
	ye = "Yemen", om = "Oman", qa = "Qatar", bh = "Bahrain", ma = "Morocco",
	dz = "Algeria", tn = "Tunisia", ly = "Libya", sd = "Sudan",
	us = "United States", gb = "United Kingdom", ca = "Canada", au = "Australia",
	de = "Germany", fr = "France", es = "Spain", it = "Italy", nl = "Netherlands",
	pt = "Portugal", pl = "Poland", se = "Sweden", no = "Norway", dk = "Denmark",
	fi = "Finland", gr = "Greece", ua = "Ukraine", ru = "Russia", tr = "Turkey",
	["in"] = "India", pk = "Pakistan", cn = "China", jp = "Japan", kr = "South Korea",
	id = "Indonesia", ph = "Philippines", vn = "Vietnam", th = "Thailand",
	mx = "Mexico", br = "Brazil", za = "South Africa", ng = "Nigeria", ke = "Kenya",
}

local function ResolveCountryFromLocale(player)
	if not player then
		return "Unknown"
	end

	local ok, localeId = pcall(function()
		return player.LocaleId
	end)

	if not ok or not localeId or localeId == "" then
		return "Unknown"
	end

	local region = localeId:match("%-(%a+)$")
	if not region then
		return "Unknown"
	end

	region = region:lower()
	return LOCALE_COUNTRY_NAMES[region] or region:upper()
end

local function FormatJoinDate(player)
	if not player then
		return "—"
	end

	local ok, result = pcall(function()
		local ageDays = player.AccountAge
		local createdAt = os.time() - (ageDays * 86400)
		return os.date("!%Y-%m-%d", createdAt)
	end)

	if ok and result then
		return result
	end

	return "—"
end

local function BuildTitleDivider(parent, theme, text, layoutOrder)
	local row = CreateInstance("Frame", {
		Name = "TitleDivider",
		Parent = parent,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = layoutOrder,
	})

	local label = CreateInstance("TextLabel", {
		Name = "Label",
		Parent = row,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = theme.DescColor,
		TextSize = 11,
	})

	CreateInstance("UIPadding", {
		Parent = label,
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	local leftLine = CreateInstance("Frame", {
		Name = "LeftLine",
		Parent = row,
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0.5, 0, 0, 1),
	})

	local rightLine = CreateInstance("Frame", {
		Name = "RightLine",
		Parent = row,
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0.5, 0, 0, 1),
	})

	local function reflow()
		local half = label.AbsoluteSize.X / 2
		leftLine.Size = UDim2.new(0.5, -half, 0, 1)
		rightLine.Size = UDim2.new(0.5, -half, 0, 1)
	end

	label:GetPropertyChangedSignal("AbsoluteSize"):Connect(reflow)
	row:GetPropertyChangedSignal("AbsoluteSize"):Connect(reflow)
	reflow()

	return { Row = row, Label = label, LeftLine = leftLine, RightLine = rightLine }
end

local function DeriveCodeBoxColor(accent)
	local ok, h, s = pcall(function()
		return accent:ToHSV()
	end)
	if not ok then
		return CODE_FALLBACK_BG
	end
	return Color3.fromHSV(h, math.clamp(s * 0.4, 0, 0.22), 0.105)
end

local CODE_COLORS = {
	Keyword = "#569CD6",
	Builtin = "#4EC9B0",
	String = "#CE9178",
	Number = "#B5CEA8",
	Comment = "#6A9955",
	Call = "#DCDCAA",
	Text = "#D4D4D4",
}

local CODE_KEYWORDS = {
	["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true, ["elseif"] = true,
	["end"] = true, ["false"] = true, ["for"] = true, ["function"] = true, ["if"] = true,
	["in"] = true, ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true,
	["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
	["while"] = true, ["continue"] = true, ["export"] = true, ["type"] = true, ["self"] = true,
}

local CODE_BUILTINS = {
	["game"] = true, ["workspace"] = true, ["script"] = true, ["require"] = true,
	["print"] = true, ["warn"] = true, ["error"] = true, ["assert"] = true,
	["pairs"] = true, ["ipairs"] = true, ["pcall"] = true, ["xpcall"] = true,
	["typeof"] = true, ["type"] = true, ["tostring"] = true, ["tonumber"] = true,
	["table"] = true, ["string"] = true, ["math"] = true, ["task"] = true, ["os"] = true,
	["coroutine"] = true, ["select"] = true, ["unpack"] = true, ["next"] = true,
	["rawget"] = true, ["rawset"] = true, ["rawequal"] = true, ["setmetatable"] = true,
	["getmetatable"] = true, ["Instance"] = true, ["Enum"] = true, ["Vector2"] = true,
	["Vector3"] = true, ["Color3"] = true, ["UDim2"] = true, ["UDim"] = true, ["CFrame"] = true,
}

local function EscapeRichText(text)
	text = text:gsub("&", "&amp;")
	text = text:gsub("<", "&lt;")
	text = text:gsub(">", "&gt;")
	text = text:gsub("\"", "&quot;")
	return text
end

local function TokenizeCode(code)
	local tokens = {}
	local i = 1
	local len = #code

	while i <= len do
		local c = code:sub(i, i)

		if c == "-" and code:sub(i + 1, i + 1) == "-" then
			local k = i + 2
			local eq = 0
			local isLong = false

			if code:sub(k, k) == "[" then
				local m = k + 1
				while code:sub(m, m) == "=" do
					eq = eq + 1
					m = m + 1
				end
				if code:sub(m, m) == "[" then
					isLong = true
					k = m + 1
				end
			end

			if isLong then
				local closePattern = "%]" .. string.rep("=", eq) .. "%]"
				local _, e = code:find(closePattern, k)
				local endPos = e or len
				table.insert(tokens, { text = code:sub(i, endPos), color = CODE_COLORS.Comment })
				i = endPos + 1
			else
				local nl = code:find("\n", i, true) or (len + 1)
				table.insert(tokens, { text = code:sub(i, nl - 1), color = CODE_COLORS.Comment })
				i = nl
			end

		elseif c == "\"" or c == "'" then
			local quote = c
			local j = i + 1
			while j <= len do
				local cj = code:sub(j, j)
				if cj == "\\" then
					j = j + 2
				elseif cj == quote or cj == "\n" then
					j = j + 1
					break
				else
					j = j + 1
				end
			end
			table.insert(tokens, { text = code:sub(i, j - 1), color = CODE_COLORS.String })
			i = j

		elseif c == "[" and code:sub(i + 1, i + 1):match("[%[=]") then
			local k = i + 1
			local eq = 0
			while code:sub(k, k) == "=" do
				eq = eq + 1
				k = k + 1
			end
			if code:sub(k, k) == "[" then
				local closePattern = "%]" .. string.rep("=", eq) .. "%]"
				local _, e = code:find(closePattern, k + 1)
				local endPos = e or len
				table.insert(tokens, { text = code:sub(i, endPos), color = CODE_COLORS.String })
				i = endPos + 1
			else
				table.insert(tokens, { text = c, color = nil })
				i = i + 1
			end

		elseif c:match("%d") then
			local j = i
			while j <= len and code:sub(j, j):match("[%w%.]") do
				j = j + 1
			end
			table.insert(tokens, { text = code:sub(i, j - 1), color = CODE_COLORS.Number })
			i = j

		elseif c:match("[%a_]") then
			local j = i
			while j <= len and code:sub(j, j):match("[%w_]") do
				j = j + 1
			end
			local word = code:sub(i, j - 1)
			local color
			if CODE_KEYWORDS[word] then
				color = CODE_COLORS.Keyword
			elseif code:sub(j, j) == "(" then
				color = CODE_COLORS.Call
			elseif CODE_BUILTINS[word] then
				color = CODE_COLORS.Builtin
			end
			table.insert(tokens, { text = word, color = color })
			i = j

		else
			table.insert(tokens, { text = c, color = nil })
			i = i + 1
		end
	end

	return tokens
end

local function BuildColoredLines(code)
	local tokens = TokenizeCode(code)
	local lines = {}
	local current = {}

	local function pushPiece(text, color)
		if text == "" then
			return
		end
		local escaped = EscapeRichText(text)
		if color then
			table.insert(current, ('<font color="%s">%s</font>'):format(color, escaped))
		else
			table.insert(current, escaped)
		end
	end

	for _, token in ipairs(tokens) do
		local text = token.text
		local start = 1
		while true do
			local nl = text:find("\n", start, true)
			if nl then
				pushPiece(text:sub(start, nl - 1), token.color)
				table.insert(lines, table.concat(current))
				current = {}
				start = nl + 1
			else
				pushPiece(text:sub(start), token.color)
				break
			end
		end
	end
	table.insert(lines, table.concat(current))

	return lines
end

local Section = {}
Section.__index = Section

local function ResolvePairSlot(self, elementType)
	local layoutOrder = #self.Container:GetChildren()

	if self._lastPairRow and self._lastPairInstance and self._lastPairRow.Parent then
		local previousInstance = self._lastPairInstance
		local previousType = self._lastPairType
		local parent = self._lastPairRow

		previousInstance.Size = UDim2.new(0.5, -4, 0, 0)

		local order
		if previousType == "Button" and elementType == "Toggle" then
			previousInstance.LayoutOrder = 2
			order = 1
		else
			previousInstance.LayoutOrder = 1
			order = 2
		end

		self._lastPairRow = nil
		self._lastPairInstance = nil
		self._lastPairType = nil

		return parent, UDim2.new(0.5, -4, 0, 0), order, true
	end

	local pairRow = CreateInstance("Frame", {
		Name = "PairRow",
		Parent = self.Container,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = layoutOrder,
	})

	CreateInstance("UIListLayout", {
		Parent = pairRow,
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	})

	return pairRow, UDim2.new(1, 0, 0, 0), 1, false
end

local function RememberPairSlot(self, parent, instance, elementType)
	self._lastPairRow = parent
	self._lastPairInstance = instance
	self._lastPairType = elementType
end

function Section:AddButton(config)
	config = config or {}
	local theme = self.Window.Theme

	local parent, rowSize, layoutOrder, isPaired = ResolvePairSlot(self, "Button")

	local row = CreateInstance("TextButton", {
		Name = "Button",
		Parent = parent,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = theme.Transparency,
		Size = rowSize,
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = layoutOrder,
	})

	if not isPaired then
		RememberPairSlot(self, parent, row, "Button")
	end

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 8),
	})

	local stroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	local iconId = ResolveIcon(config.Icon or "mouse-pointer")
	local textOffset = 32

	local iconChip = CreateInstance("Frame", {
		Name = "IconChip",
		Parent = row,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 22, 0, 22),
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
	})

	CreateInstance("UICorner", {
		Parent = iconChip,
		CornerRadius = UDim.new(0, 6),
	})

	local iconImage = CreateInstance("ImageLabel", {
		Name = "Icon",
		Parent = iconChip,
		BackgroundTransparency = 1,
		Image = iconId,
		ImageColor3 = theme.Accent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 13, 0, 13),
	})

	local hasDescription = config.Description and config.Description ~= ""

	local textBlock = CreateInstance("Frame", {
		Name = "TextBlock",
		Parent = row,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, textOffset, 0.5, 0),
		Size = UDim2.new(1, -textOffset, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})

	CreateInstance("UIListLayout", {
		Parent = textBlock,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
	})

	local title = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = textBlock,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.GothamMedium,
		Text = config.Name or "Button",
		TextColor3 = theme.TitleColor,
		TextSize = 12,
		TextWrapped = true,
		TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	})

	local descLabel
	if hasDescription then
		descLabel = CreateInstance("TextLabel", {
			Name = "Description",
			Parent = textBlock,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.Gotham,
			Text = config.Description,
			TextColor3 = theme.DescColor,
			TextSize = 10,
			TextWrapped = true,
			TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 2,
		})
	end

	local hoverTween = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	row.MouseEnter:Connect(function()
		PlayTween(self.Window, row, hoverTween, {
			BackgroundColor3 = self.Window.Theme.Secondary,
			BackgroundTransparency = 0.25,
		})
		PlayTween(self.Window, stroke, hoverTween, { Transparency = 0.15 })
	end)

	row.MouseLeave:Connect(function()
		PlayTween(self.Window, row, hoverTween, {
			BackgroundColor3 = self.Window.Theme.Background,
			BackgroundTransparency = self.Window.Theme.Transparency,
		})
		PlayTween(self.Window, stroke, hoverTween, { Transparency = 0.5 })
	end)

	row.MouseButton1Down:Connect(function()
		PlayTween(self.Window, row, hoverTween, {
			BackgroundColor3 = self.Window.Theme.Accent,
			BackgroundTransparency = 0.7,
		})
	end)

	row.MouseButton1Up:Connect(function()
		PlayTween(self.Window, row, hoverTween, {
			BackgroundColor3 = self.Window.Theme.Secondary,
			BackgroundTransparency = 0.25,
		})
	end)

	row.MouseButton1Click:Connect(function()
		local function runCallback()
			if config.Callback then
				local ok, err = pcall(config.Callback)
				if not ok then
					warn("Devlyx Button Callback Error: " .. tostring(err))
				end
			end
		end

		if config.Confirm then
			local dialogButtons = config.Confirm.Buttons

			if not dialogButtons then
				dialogButtons = {
					{
						Title = config.Confirm.ConfirmText or "Confirm",
						Callback = runCallback,
					},
					{
						Title = config.Confirm.CancelText or "Cancel",
						Callback = config.Confirm.CancelCallback,
					},
				}
			end

			self.Window:Dialog({
				Title = config.Confirm.Title or "Confirm",
				Content = config.Confirm.Content or ('Are you sure you want to do "' .. (config.Name or "this action") .. '"?'),
				Buttons = dialogButtons,
			})
		else
			runCallback()
		end
	end)

	if config.Tooltip then
		AttachTooltip(self.Window, row, config.Tooltip)
	end

	table.insert(self.Window.Controls, function(theme2)
		row.BackgroundColor3 = theme2.Background
		row.BackgroundTransparency = theme2.Transparency
		stroke.Color = theme2.Accent
		title.TextColor3 = theme2.TitleColor
		if descLabel then
			descLabel.TextColor3 = theme2.DescColor
		end
		iconChip.BackgroundColor3 = theme2.Accent
		iconImage.ImageColor3 = theme2.Accent
	end)

	return {
		Frame = row,
		Name = config.Name,
	}
end

function Section:AddToggle(config)
	config = config or {}
	local theme = self.Window.Theme
	local value = config.Default == true

	local parent, rowSize, layoutOrder, isPaired = ResolvePairSlot(self, "Toggle")

	local row = CreateInstance("Frame", {
		Name = "Toggle",
		Parent = parent,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = theme.Transparency,
		Size = rowSize,
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = layoutOrder,
	})

	if not isPaired then
		RememberPairSlot(self, parent, row, "Toggle")
	end

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 8),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.5,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	local hasDescription = config.Description and config.Description ~= ""
	local iconId = ResolveIcon(config.Icon or "toggle-left")
	local textOffset = 32

	local iconChip = CreateInstance("Frame", {
		Name = "IconChip",
		Parent = row,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 22, 0, 22),
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
	})

	CreateInstance("UICorner", {
		Parent = iconChip,
		CornerRadius = UDim.new(0, 6),
	})

	local iconImage = CreateInstance("ImageLabel", {
		Name = "Icon",
		Parent = iconChip,
		BackgroundTransparency = 1,
		Image = iconId,
		ImageColor3 = theme.Accent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 13, 0, 13),
	})

	local textContainer = CreateInstance("Frame", {
		Name = "TextContainer",
		Parent = row,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, textOffset, 0.5, 0),
		Size = UDim2.new(1, -50 - textOffset, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})

	CreateInstance("UIListLayout", {
		Parent = textContainer,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
	})

	local title = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = textContainer,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.Gotham,
		Text = config.Name or "Toggle",
		TextColor3 = theme.TitleColor,
		TextSize = 12,
		TextWrapped = true,
		TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	})

	local descLabel
	if hasDescription then
		descLabel = CreateInstance("TextLabel", {
			Name = "Description",
			Parent = textContainer,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.Gotham,
			Text = config.Description,
			TextColor3 = theme.DescColor,
			TextSize = 10,
			TextWrapped = true,
			TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 2,
		})
	end

	local switchBg = CreateInstance("Frame", {
		Name = "Switch",
		Parent = row,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 36, 0, 20),
		BackgroundColor3 = value and theme.Accent or theme.Secondary,
		BackgroundTransparency = value and 0 or 0.25,
		BorderSizePixel = 0,
	})

	CreateInstance("UICorner", {
		Parent = switchBg,
		CornerRadius = UDim.new(1, 0),
	})

	local knob = CreateInstance("Frame", {
		Name = "Knob",
		Parent = switchBg,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.new(0, 16, 0, 16),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	})

	CreateInstance("UICorner", {
		Parent = knob,
		CornerRadius = UDim.new(1, 0),
	})

	local clickArea = CreateInstance("TextButton", {
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		AutoButtonColor = false,
	})

	local function setValue(newValue, fireCallback)
		value = newValue
		local currentTheme = self.Window.Theme

		local targetPos = value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
		local targetColor = value and currentTheme.Accent or currentTheme.Secondary
		local targetTransparency = value and 0 or 0.25

		PlayTween(self.Window, knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = targetPos,
		})

		PlayTween(self.Window, switchBg, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = targetColor,
			BackgroundTransparency = targetTransparency,
		})

		if fireCallback and config.Callback then
			local ok, err = pcall(config.Callback, value)
			if not ok then
				warn("Devlyx Toggle Callback Error: " .. tostring(err))
			end
		end
	end

	clickArea.MouseButton1Click:Connect(function()
		setValue(not value, true)
	end)

	row.MouseEnter:Connect(function()
		PlayTween(self.Window, row, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = self.Window.Theme.Secondary,
		})
	end)

	row.MouseLeave:Connect(function()
		PlayTween(self.Window, row, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = self.Window.Theme.Background,
		})
	end)

	if config.Tooltip then
		AttachTooltip(self.Window, row, config.Tooltip)
	end

	table.insert(self.Window.Controls, function(theme2)
		row.BackgroundColor3 = theme2.Background
		row.BackgroundTransparency = theme2.Transparency
		rowStroke.Color = theme2.Accent
		title.TextColor3 = theme2.TitleColor
		if descLabel then
			descLabel.TextColor3 = theme2.DescColor
		end
		switchBg.BackgroundColor3 = value and theme2.Accent or theme2.Secondary
		switchBg.BackgroundTransparency = value and 0 or 0.25
		iconChip.BackgroundColor3 = theme2.Accent
		if iconImage then
			iconImage.ImageColor3 = theme2.Accent
		end
	end)

	local toggleObject = {
		Frame = row,
		Name = config.Name,
		Set = function(_, newValue)
			setValue(newValue, false)
		end,
		Get = function()
			return value
		end,
	}

	if config.Flag then
		self.Window.Flags[config.Flag] = toggleObject
	end

	return toggleObject
end

function Section:AddDivider()
	self._lastPairRow = nil
	local theme = self.Window.Theme

	local divider = CreateInstance("Frame", {
		Name = "Divider",
		Parent = self.Container,
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		LayoutOrder = #self.Container:GetChildren(),
	})

	table.insert(self.Window.Controls, function(theme2)
		divider.BackgroundColor3 = theme2.Accent
	end)

	return {
		Frame = divider,
	}
end

function Section:AddParagraph(config)
	config = config or {}
	self._lastPairRow = nil
	local theme = self.Window.Theme

	local row = CreateInstance("Frame", {
		Name = "Paragraph",
		Parent = self.Container,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = theme.Transparency,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 8),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.5,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	local hasTitle = config.Title and config.Title ~= ""

	local titleLabel
	if hasTitle then
		titleLabel = CreateInstance("TextLabel", {
			Name = "Title",
			Parent = row,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			Font = Enum.Font.GothamBold,
			Text = config.Title,
			TextColor3 = theme.TitleColor,
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
		})
	end

	local contentLabel = CreateInstance("TextLabel", {
		Name = "Content",
		Parent = row,
		BackgroundTransparency = 1,
		Position = hasTitle and UDim2.new(0, 0, 0, 18) or UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.Gotham,
		Text = config.Content or "",
		TextColor3 = theme.DescColor,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	})

	if config.Tooltip then
		AttachTooltip(self.Window, row, config.Tooltip)
	end

	table.insert(self.Window.Controls, function(theme2)
		row.BackgroundColor3 = theme2.Background
		row.BackgroundTransparency = theme2.Transparency
		rowStroke.Color = theme2.Accent
		if titleLabel then
			titleLabel.TextColor3 = theme2.TitleColor
		end
		contentLabel.TextColor3 = theme2.DescColor
	end)

	return {
		Frame = row,
		Set = function(_, newText)
			contentLabel.Text = newText
		end,
	}
end

function Section:AddCodeBlock(config)
	config = config or {}
	self._lastPairRow = nil
	local theme = self.Window.Theme
	local code = config.Code or ""
	local collapsedLines = config.CollapsedLines or 8
	if collapsedLines < 1 then
		collapsedLines = 1
	end

	local codeLines = BuildColoredLines(code)
	local totalLines = #codeLines
	local canCollapse = totalLines > collapsedLines
	local isExpanded = not canCollapse or (config.Collapsed ~= true)

	local HEADER_GAP = 6
	local BOX_PADDING = 14

	local row = CreateInstance("Frame", {
		Name = "CodeBlock",
		Parent = self.Container,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = theme.Transparency,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 8),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.5,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	local hasTitle = config.Title and config.Title ~= ""
	local hasDescription = config.Description and config.Description ~= ""
	local titleReserve = canCollapse and 50 or 26

	local toolbar = CreateInstance("Frame", {
		Name = "Toolbar",
		Parent = row,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 1),
		Size = UDim2.new(0, canCollapse and 38 or 16, 0, 16),
	})

	CreateInstance("UIListLayout", {
		Parent = toolbar,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local titleLabel, descLabel
	local textY = 2

	if hasTitle then
		titleLabel = CreateInstance("TextLabel", {
			Name = "Title",
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, textY),
			Size = UDim2.new(1, -titleReserve, 0, 15),
			Font = Enum.Font.GothamBold,
			Text = config.Title,
			TextColor3 = FIXED_TITLE_COLOR,
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		textY = textY + 15 + 1
	end

	if hasDescription then
		descLabel = CreateInstance("TextLabel", {
			Name = "Description",
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, textY),
			Size = UDim2.new(1, -titleReserve, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.Gotham,
			Text = config.Description,
			TextColor3 = FIXED_DESC_COLOR,
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		textY = textY + 13
	end

	local HEADER_HEIGHT = math.max(20, textY + 2)

	local copyButton = CreateInstance("ImageButton", {
		Name = "CopyButton",
		Parent = toolbar,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 14, 0, 14),
		Image = ResolveIcon("clipboard-copy"),
		ImageColor3 = theme.DescColor,
		LayoutOrder = 1,
	})

	local chevronButton
	if canCollapse then
		chevronButton = CreateInstance("ImageButton", {
			Name = "ToggleButton",
			Parent = toolbar,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 14, 0, 14),
			Image = ResolveIcon("chevron-down"),
			ImageColor3 = theme.DescColor,
			Rotation = isExpanded and 180 or 0,
			LayoutOrder = 2,
		})
	end

	local codeBoxColor = DeriveCodeBoxColor(theme.Accent)

	local codeBox = CreateInstance("Frame", {
		Name = "CodeBox",
		Parent = row,
		BackgroundColor3 = codeBoxColor,
		BackgroundTransparency = 0,
		Position = UDim2.new(0, 0, 0, HEADER_HEIGHT + HEADER_GAP),
		Size = UDim2.new(1, 0, 0, 0),
		ClipsDescendants = true,
	})

	CreateInstance("UICorner", {
		Parent = codeBox,
		CornerRadius = UDim.new(0, 5),
	})

	CreateInstance("UIPadding", {
		Parent = codeBox,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	local contentLabel = CreateInstance("TextLabel", {
		Name = "Code",
		Parent = codeBox,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = CODE_FONT,
		RichText = true,
		Text = table.concat(codeLines, "\n"),
		TextColor3 = Color3.fromRGB(212, 212, 212),
		TextSize = CODE_TEXT_SIZE,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = false,
	})

	local fadeOverlay
	if canCollapse then
		local fadeHeight = math.min(18, (collapsedLines * CODE_LINE_HEIGHT) * 0.35)

		fadeOverlay = CreateInstance("Frame", {
			Name = "FadeOverlay",
			Parent = codeBox,
			BackgroundColor3 = codeBoxColor,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, fadeHeight),
			ZIndex = 2,
			Visible = not isExpanded,
		})

		CreateInstance("UIGradient", {
			Parent = fadeOverlay,
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
		})
	end

	local function applyCollapse(expanded, animate)
		expanded = expanded or not canCollapse
		isExpanded = expanded

		if chevronButton then
			PlayTween(self.Window, chevronButton, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Rotation = expanded and 180 or 0,
			})
		end

		if fadeOverlay then
			fadeOverlay.Visible = not expanded
		end

		local visibleLines = expanded and totalLines or math.min(totalLines, collapsedLines)
		local targetHeight = (math.max(visibleLines, 1) * CODE_LINE_HEIGHT) + BOX_PADDING

		if animate then
			PlayTween(self.Window, codeBox, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, targetHeight),
			})
		else
			codeBox.Size = UDim2.new(1, 0, 0, targetHeight)
		end
	end

	applyCollapse(isExpanded, false)

	if chevronButton then
		chevronButton.MouseButton1Click:Connect(function()
			applyCollapse(not isExpanded, true)
		end)

		chevronButton.MouseEnter:Connect(function()
			chevronButton.ImageColor3 = self.Window.Theme.TitleColor
		end)
		chevronButton.MouseLeave:Connect(function()
			chevronButton.ImageColor3 = self.Window.Theme.DescColor
		end)
	end

	copyButton.MouseEnter:Connect(function()
		copyButton.ImageColor3 = self.Window.Theme.TitleColor
	end)
	copyButton.MouseLeave:Connect(function()
		copyButton.ImageColor3 = self.Window.Theme.DescColor
	end)

	copyButton.MouseButton1Click:Connect(function()
		local copied = false
		if typeof(setclipboard) == "function" then
			copied = pcall(setclipboard, code)
		end

		if copied then
			copyButton.Image = ResolveIcon("check")
			task.delay(1, function()
				copyButton.Image = ResolveIcon("clipboard-copy")
			end)
		end

		if self.Window.Notify then
			self.Window:Notify({
				Title = copied and "Copied" or "Copy Failed",
				Content = copied and "Code copied to clipboard" or "Clipboard is not supported in this environment",
				Duration = 2,
			})
		end
	end)

	if config.Tooltip then
		AttachTooltip(self.Window, row, config.Tooltip)
	end

	table.insert(self.Window.Controls, function(theme2)
		row.BackgroundColor3 = theme2.Background
		row.BackgroundTransparency = theme2.Transparency
		rowStroke.Color = theme2.Accent

		codeBoxColor = DeriveCodeBoxColor(theme2.Accent)
		codeBox.BackgroundColor3 = codeBoxColor
		if fadeOverlay then
			fadeOverlay.BackgroundColor3 = codeBoxColor
		end

		copyButton.ImageColor3 = theme2.DescColor
		if chevronButton then
			chevronButton.ImageColor3 = theme2.DescColor
		end
	end)

	return {
		Frame = row,
		IsExpanded = function()
			return isExpanded
		end,
		SetExpanded = function(_, expanded)
			applyCollapse(expanded, true)
		end,
		SetCollapsed = function(_, collapsed)
			applyCollapse(not collapsed, true)
		end,
		Set = function(_, newCode)
			code = newCode or ""
			codeLines = BuildColoredLines(code)
			totalLines = #codeLines
			canCollapse = totalLines > collapsedLines
			contentLabel.Text = table.concat(codeLines, "\n")
			applyCollapse(isExpanded, false)
		end,
	}
end

function Section:AddLinks(config)
	config = config or {}
	self._lastPairRow = nil
	local theme = self.Window.Theme
	local link = config.Link or config.Url or ""

	local hasIcon = config.Icon and config.Icon ~= ""
	local hasDescription = config.Description and config.Description ~= ""

	local ICON_SIZE = 30
	local ICON_GAP = 10
	local TITLE_HEIGHT = 15
	local DESC_HEIGHT = 13
	local TEXT_GAP = 4
	local COPY_SIZE = 16
	local PAD = 8

	local textOffset = hasIcon and (ICON_SIZE + ICON_GAP) or 0
	local textBlockHeight = hasDescription and (TITLE_HEIGHT + TEXT_GAP + DESC_HEIGHT) or TITLE_HEIGHT
	local contentHeight = math.max(hasIcon and ICON_SIZE or 0, textBlockHeight, COPY_SIZE)
	local rowHeight = contentHeight + (PAD * 2)

	local row = CreateInstance("Frame", {
		Name = "Links",
		Parent = self.Container,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = theme.Transparency,
		Size = UDim2.new(1, 0, 0, rowHeight),
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 8),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.5,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, PAD),
		PaddingBottom = UDim.new(0, PAD),
		PaddingLeft = UDim.new(0, PAD),
		PaddingRight = UDim.new(0, PAD),
	})

	local iconBadge, iconImage
	if hasIcon then
		iconBadge = CreateInstance("Frame", {
			Name = "IconBadge",
			Parent = row,
			BackgroundColor3 = theme.Accent,
			BackgroundTransparency = 0.85,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, math.max(0, math.floor((contentHeight - ICON_SIZE) / 2))),
			Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE),
		})

		CreateInstance("UICorner", {
			Parent = iconBadge,
			CornerRadius = UDim.new(0, 10),
		})

		iconImage = CreateInstance("ImageLabel", {
			Name = "Icon",
			Parent = iconBadge,
			BackgroundTransparency = 1,
			Image = ResolveIcon(config.Icon),
			ImageColor3 = theme.Accent,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 16, 0, 16),
		})
	end

	local titleTop = math.max(0, math.floor((contentHeight - textBlockHeight) / 2))
	local textWidth = UDim.new(1, -(textOffset + COPY_SIZE + 14))

	local titleLabel = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, textOffset, 0, titleTop),
		Size = UDim2.new(textWidth.Scale, textWidth.Offset, 0, TITLE_HEIGHT),
		Font = Enum.Font.GothamBold,
		Text = config.Title or "Link",
		TextColor3 = FIXED_TITLE_COLOR,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local descLabel
	if hasDescription then
		descLabel = CreateInstance("TextLabel", {
			Name = "Description",
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, textOffset, 0, titleTop + TITLE_HEIGHT + TEXT_GAP),
			Size = UDim2.new(textWidth.Scale, textWidth.Offset, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.Gotham,
			Text = config.Description,
			TextColor3 = FIXED_DESC_COLOR,
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
	end

	local copyButton = CreateInstance("ImageButton", {
		Name = "CopyButton",
		Parent = row,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, math.max(0, math.floor((contentHeight - COPY_SIZE) / 2))),
		Size = UDim2.new(0, COPY_SIZE, 0, COPY_SIZE),
		Image = ResolveIcon("link-2"),
		ImageColor3 = theme.DescColor,
	})

	copyButton.MouseEnter:Connect(function()
		copyButton.ImageColor3 = self.Window.Theme.TitleColor
	end)
	copyButton.MouseLeave:Connect(function()
		copyButton.ImageColor3 = self.Window.Theme.DescColor
	end)

	copyButton.MouseButton1Click:Connect(function()
		local copied = false
		if typeof(setclipboard) == "function" then
			copied = pcall(setclipboard, link)
		end

		if copied then
			copyButton.Image = ResolveIcon("check")
			task.delay(1, function()
				copyButton.Image = ResolveIcon("link-2")
			end)
		end

		if self.Window.Notify then
			self.Window:Notify({
				Title = copied and "Copied" or "Copy Failed",
				Content = copied and "Link copied to clipboard" or "Clipboard is not supported in this environment",
				Duration = 2,
			})
		end
	end)

	if config.Tooltip then
		AttachTooltip(self.Window, row, config.Tooltip)
	end

	table.insert(self.Window.Controls, function(theme2)
		row.BackgroundColor3 = theme2.Background
		row.BackgroundTransparency = theme2.Transparency
		rowStroke.Color = theme2.Accent
		if iconBadge then
			iconBadge.BackgroundColor3 = theme2.Accent
		end
		if iconImage then
			iconImage.ImageColor3 = theme2.Accent
		end
		copyButton.ImageColor3 = theme2.DescColor
	end)

	return {
		Frame = row,
		Set = function(_, newLink)
			link = newLink or ""
		end,
		SetTitle = function(_, newTitle)
			titleLabel.Text = newTitle or ""
		end,
		SetDescription = function(_, newDescription)
			if descLabel then
				descLabel.Text = newDescription or ""
			end
		end,
	}
end

function Section:AddColorPicker(config)
	config = config or {}

	local presetOrder = { "Dark", "Purple", "Rose", "Blue", "Green", "Orange", "Cyan", "Gold" }
	local options = {}
	for _, presetName in ipairs(presetOrder) do
		if Presets[presetName] then
			table.insert(options, presetName)
		end
	end

	local defaultValue = (config.Default and Presets[config.Default]) and config.Default or self.Window.CurrentThemeName

	local dropdownObject = self:_BuildDropdown({
		Name = config.Name or "Theme Color",
		Description = config.Description,
		Options = options,
		Default = defaultValue,
		Tooltip = config.Tooltip,
		Callback = function(presetName)
			if Presets[presetName] then
				self.Window:SetTheme(presetName)
			end
			if config.Callback then
				local ok, err = pcall(config.Callback, presetName)
				if not ok then
					warn("Devlyx ColorPicker Callback Error: " .. tostring(err))
				end
			end
		end,
	}, false)

	if defaultValue and Presets[defaultValue] then
		self.Window:SetTheme(defaultValue)
	end

	if config.Flag then
		self.Window.Flags[config.Flag] = dropdownObject
	end

	return dropdownObject
end

function Section:AddProgressBar(config)
	config = config or {}
	self._lastPairRow = nil
	local theme = self.Window.Theme

	local title = config.Title or config.Name or "Progress"
	local min = config.Min or 0
	local max = config.Max or 100
	local value = math.clamp(config.Default or min, min, max)
	local showPercent = config.ShowPercent ~= false

	local row = CreateInstance("Frame", {
		Name = "ProgressBar",
		Parent = self.Container,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = theme.Transparency,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 8),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.5,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	local titleLabel = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -50, 0, 16),
		Font = Enum.Font.Gotham,
		Text = title,
		TextColor3 = theme.TitleColor,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local valueLabel = CreateInstance("TextLabel", {
		Name = "Value",
		Parent = row,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 50, 0, 16),
		Font = Enum.Font.GothamBold,
		Text = "",
		TextColor3 = theme.Accent,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local track = CreateInstance("Frame", {
		Name = "Track",
		Parent = row,
		Position = UDim2.new(0, 0, 0, 22),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = theme.Secondary,
		BorderSizePixel = 0,
	})

	CreateInstance("UICorner", {
		Parent = track,
		CornerRadius = UDim.new(1, 0),
	})

	local fill = CreateInstance("Frame", {
		Name = "Fill",
		Parent = track,
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
	})

	CreateInstance("UICorner", {
		Parent = fill,
		CornerRadius = UDim.new(1, 0),
	})

	local function updateVisual(animate)
		local ratio = math.clamp((value - min) / math.max(max - min, 0.0001), 0, 1)
		valueLabel.Text = showPercent and (tostring(math.floor(ratio * 100 + 0.5)) .. "%") or tostring(value)

		if animate then
			PlayTween(self.Window, fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(ratio, 0, 1, 0),
			})
		else
			fill.Size = UDim2.new(ratio, 0, 1, 0)
		end
	end

	updateVisual(false)

	if config.Tooltip then
		AttachTooltip(self.Window, row, config.Tooltip)
	end

	table.insert(self.Window.Controls, function(theme2)
		row.BackgroundColor3 = theme2.Background
		row.BackgroundTransparency = theme2.Transparency
		rowStroke.Color = theme2.Accent
		titleLabel.TextColor3 = theme2.TitleColor
		valueLabel.TextColor3 = theme2.Accent
		track.BackgroundColor3 = theme2.Secondary
		fill.BackgroundColor3 = theme2.Accent
	end)

	local progressObject = {
		Frame = row,
		Set = function(_, newValue, animate)
			value = math.clamp(newValue, min, max)
			updateVisual(animate ~= false)
		end,
		Get = function()
			return value
		end,
	}

	if config.Flag then
		self.Window.Flags[config.Flag] = progressObject
	end

	return progressObject
end

function Section:AddSlider(name, config)
	config = config or {}
	self._lastPairRow = nil
	local theme = self.Window.Theme

	local title = config.Title or name or "Slider"
	local min = config.Min or 0
	local max = config.Max or 100
	local rounding = config.Rounding or 0

	local function roundValue(v)
		local mult = 10 ^ rounding
		return math.floor(v * mult + 0.5) / mult
	end

	local value = roundValue(math.clamp(config.Default or min, min, max))

	local row = CreateInstance("Frame", {
		Name = "Slider",
		Parent = self.Container,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = theme.Transparency,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 8),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.5,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	local titleLabel = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -50, 0, 16),
		Font = Enum.Font.Gotham,
		Text = title,
		TextColor3 = theme.TitleColor,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local valueLabel = CreateInstance("TextLabel", {
		Name = "Value",
		Parent = row,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 50, 0, 16),
		Font = Enum.Font.GothamBold,
		Text = tostring(value),
		TextColor3 = theme.Accent,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local hasDescription = config.Description and config.Description ~= ""
	local trackYOffset = 24

	local descLabel
	if hasDescription then
		descLabel = CreateInstance("TextLabel", {
			Name = "Description",
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 20),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.Gotham,
			Text = config.Description,
			TextColor3 = theme.DescColor,
			TextSize = 10,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		trackYOffset = 40
	end

	local track = CreateInstance("Frame", {
		Name = "Track",
		Parent = row,
		Position = UDim2.new(0, 0, 0, trackYOffset),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = theme.Secondary,
		BorderSizePixel = 0,
	})

	CreateInstance("UICorner", {
		Parent = track,
		CornerRadius = UDim.new(1, 0),
	})

	local fill = CreateInstance("Frame", {
		Name = "Fill",
		Parent = track,
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
	})

	CreateInstance("UICorner", {
		Parent = fill,
		CornerRadius = UDim.new(1, 0),
	})

	local knob = CreateInstance("Frame", {
		Name = "Knob",
		Parent = track,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 14),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 2,
	})

	CreateInstance("UICorner", {
		Parent = knob,
		CornerRadius = UDim.new(1, 0),
	})

	local hitArea = CreateInstance("Frame", {
		Name = "HitArea",
		Parent = track,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 12, 0, 28),
		BackgroundTransparency = 1,
		ZIndex = 3,
	})

	local function updateVisual()
		local ratio = (value - min) / math.max(max - min, 0.0001)
		fill.Size = UDim2.new(ratio, 0, 1, 0)
		knob.Position = UDim2.new(ratio, 0, 0.5, 0)
		valueLabel.Text = tostring(value)
	end
	updateVisual()

	local dragging = false
	local activeInputConnection

	local function setFromInputX(inputX, fireCallback)
		local absPos = track.AbsolutePosition.X
		local absSize = math.max(track.AbsoluteSize.X, 1)
		local ratio = math.clamp((inputX - absPos) / absSize, 0, 1)
		local raw = min + (max - min) * ratio
		local newValue = math.clamp(roundValue(raw), min, max)

		if newValue ~= value then
			value = newValue
			updateVisual()
			if fireCallback and config.Callback then
				local ok, err = pcall(config.Callback, value)
				if not ok then
					warn("Devlyx Slider Callback Error: " .. tostring(err))
				end
			end
		end
	end

	local function stopDragging()
		dragging = false
		if activeInputConnection then
			activeInputConnection:Disconnect()
			activeInputConnection = nil
		end
	end

	local function beginDragging(input)
		dragging = true
		setFromInputX(input.Position.X, true)

		if activeInputConnection then
			activeInputConnection:Disconnect()
		end

		activeInputConnection = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
				stopDragging()
			end
		end)
	end

	hitArea.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginDragging(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromInputX(input.Position.X, true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			stopDragging()
		end
	end)

	if config.Tooltip then
		AttachTooltip(self.Window, row, config.Tooltip)
	end

	table.insert(self.Window.Controls, function(theme2)
		row.BackgroundColor3 = theme2.Background
		row.BackgroundTransparency = theme2.Transparency
		rowStroke.Color = theme2.Accent
		titleLabel.TextColor3 = theme2.TitleColor
		valueLabel.TextColor3 = theme2.Accent
		if descLabel then
			descLabel.TextColor3 = theme2.DescColor
		end
		track.BackgroundColor3 = theme2.Secondary
		fill.BackgroundColor3 = theme2.Accent
	end)

	local sliderObject = {
		Frame = row,
		Name = title,
		Set = function(_, newValue)
			value = math.clamp(roundValue(newValue), min, max)
			updateVisual()
		end,
		Get = function()
			return value
		end,
	}

	if config.Flag then
		self.Window.Flags[config.Flag] = sliderObject
	end

	return sliderObject
end

function Section:_BuildDropdown(config, isMulti)
	config = config or {}
	self._lastPairRow = nil
	local theme = self.Window.Theme
	local options = config.Options or {}
	local placeholder = config.Placeholder or "Select..."

	local selectedSet = {}
	local selectedSingle = nil

	if isMulti then
		if typeof(config.Default) == "table" then
			for _, v in ipairs(config.Default) do
				selectedSet[v] = true
			end
		end
	else
		selectedSingle = config.Default
	end

	local row = CreateInstance("Frame", {
		Name = isMulti and "MultiDropdown" or "Dropdown",
		Parent = self.Container,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = theme.Transparency,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 8),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.5,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	local hasDescription = config.Description and config.Description ~= ""
	local headerHeight = hasDescription and 31 or 15
	local iconId = ResolveIcon(config.Icon or "list")
	local textOffset = 32

	local header = CreateInstance("TextButton", {
		Name = "Header",
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, headerHeight),
		Text = "",
		AutoButtonColor = false,
	})

	local iconChip = CreateInstance("Frame", {
		Name = "IconChip",
		Parent = header,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 22, 0, 22),
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
	})

	CreateInstance("UICorner", {
		Parent = iconChip,
		CornerRadius = UDim.new(0, 6),
	})

	local iconImage = CreateInstance("ImageLabel", {
		Name = "Icon",
		Parent = iconChip,
		BackgroundTransparency = 1,
		Image = iconId,
		ImageColor3 = theme.Accent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 13, 0, 13),
	})

	local titleLabel = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, textOffset, 0, 0),
		Size = UDim2.new(1, -100 - textOffset, 0, 16),
		Font = Enum.Font.Gotham,
		Text = config.Name or "Dropdown",
		TextColor3 = theme.TitleColor,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local descLabel
	if hasDescription then
		descLabel = CreateInstance("TextLabel", {
			Name = "Description",
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, textOffset, 0, 20),
			Size = UDim2.new(1, -100 - textOffset, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.Gotham,
			Text = config.Description,
			TextColor3 = theme.DescColor,
			TextSize = 10,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	local chevron = CreateInstance("ImageLabel", {
		Name = "Chevron",
		Parent = row,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 1),
		Size = UDim2.new(0, 14, 0, 14),
		Image = ResolveIcon("chevron-down"),
		ImageColor3 = theme.DescColor,
	})

	local valueLabel = CreateInstance("TextLabel", {
		Name = "Value",
		Parent = row,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -20, 0, 0),
		Size = UDim2.new(0, 80, 0, 16),
		Font = Enum.Font.Gotham,
		Text = placeholder,
		TextColor3 = theme.Accent,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local optionsContainer = CreateInstance("Frame", {
		Name = "Options",
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, headerHeight + 8),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
	})

	CreateInstance("UIListLayout", {
		Parent = optionsContainer,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local optionRows = {}

	local function updateDisplay()
		if isMulti then
			local list = {}
			for _, optionName in ipairs(options) do
				if selectedSet[optionName] then
					table.insert(list, optionName)
				end
			end
			valueLabel.Text = (#list == 0) and placeholder or table.concat(list, ", ")
		else
			valueLabel.Text = (selectedSingle == nil or selectedSingle == "") and placeholder or tostring(selectedSingle)
		end
	end

	local isOpen = false
	local function setOpen(open)
		isOpen = open

		PlayTween(self.Window, chevron, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Rotation = open and 180 or 0,
		})

		if open then
			optionsContainer.Visible = true

			local openEntries = {}
			for _, opt in ipairs(optionRows) do
				opt.Frame.BackgroundTransparency = 1
				opt.Label.TextTransparency = 1
				table.insert(openEntries, { instance = opt.Frame, prop = "BackgroundTransparency", target = 0 })
				table.insert(openEntries, { instance = opt.Label, prop = "TextTransparency", target = 0 })

				if opt.Check then
					opt.Check.ImageTransparency = 1
					table.insert(openEntries, {
						instance = opt.Check,
						prop = "ImageTransparency",
						target = selectedSet[opt.Name] and 0 or 1,
					})
				end
			end

			FadeTransparency(openEntries, 0.15, Enum.EasingDirection.Out, self.Window)
		else
			local closeEntries = {}
			for _, opt in ipairs(optionRows) do
				table.insert(closeEntries, { instance = opt.Frame, prop = "BackgroundTransparency", target = 1 })
				table.insert(closeEntries, { instance = opt.Label, prop = "TextTransparency", target = 1 })

				if opt.Check then
					table.insert(closeEntries, { instance = opt.Check, prop = "ImageTransparency", target = 1 })
				end
			end

			FadeTransparency(closeEntries, 0.12, Enum.EasingDirection.In, self.Window)

			task.delay(0.12, function()
				if not isOpen then
					optionsContainer.Visible = false
				end
			end)
		end
	end

	local dropdownHoverTween = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	header.MouseEnter:Connect(function()
		PlayTween(self.Window, row, dropdownHoverTween, {
			BackgroundColor3 = self.Window.Theme.Secondary,
			BackgroundTransparency = 0.25,
		})
		PlayTween(self.Window, rowStroke, dropdownHoverTween, { Transparency = 0.15 })
	end)

	header.MouseLeave:Connect(function()
		if not isOpen then
			PlayTween(self.Window, row, dropdownHoverTween, {
				BackgroundColor3 = self.Window.Theme.Background,
				BackgroundTransparency = self.Window.Theme.Transparency,
			})
			PlayTween(self.Window, rowStroke, dropdownHoverTween, { Transparency = 0.5 })
		end
	end)

	header.MouseButton1Click:Connect(function()
		setOpen(not isOpen)
	end)

	local function rebuildOptions()
		for _, opt in ipairs(optionRows) do
			opt.Frame:Destroy()
		end
		optionRows = {}

		for _, optionName in ipairs(options) do
			local optionRow = CreateInstance("TextButton", {
				Name = "Option",
				Parent = optionsContainer,
				BackgroundColor3 = theme.Secondary,
				BackgroundTransparency = 0,
				Size = UDim2.new(1, 0, 0, 25),
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = #optionsContainer:GetChildren(),
			})

			CreateInstance("UICorner", {
				Parent = optionRow,
				CornerRadius = UDim.new(0, 5),
			})

			local optionLabel = CreateInstance("TextLabel", {
				Parent = optionRow,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -34, 1, 0),
				Font = Enum.Font.Gotham,
				Text = optionName,
				TextColor3 = theme.TitleColor,
				TextSize = 11,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			local checkIcon
			if isMulti then
				checkIcon = CreateInstance("ImageLabel", {
					Parent = optionRow,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -8, 0.5, 0),
					Size = UDim2.new(0, 16, 0, 16),
					Image = ResolveIcon("check"),
					ImageColor3 = theme.Accent,
					ImageTransparency = selectedSet[optionName] and 0 or 1,
				})
			end

			optionRow.MouseEnter:Connect(function()
				optionRow.BackgroundColor3 = self.Window.Theme.Background
			end)

			optionRow.MouseLeave:Connect(function()
				optionRow.BackgroundColor3 = self.Window.Theme.Secondary
			end)

			optionRow.MouseButton1Click:Connect(function()
				if isMulti then
					selectedSet[optionName] = not selectedSet[optionName]
					checkIcon.ImageTransparency = selectedSet[optionName] and 0 or 1
					updateDisplay()

					if config.Callback then
						local list = {}
						for _, name in ipairs(options) do
							if selectedSet[name] then
								table.insert(list, name)
							end
						end
						local ok, err = pcall(config.Callback, list)
						if not ok then
							warn("Devlyx Dropdown Callback Error: " .. tostring(err))
						end
					end
				else
					selectedSingle = optionName
					updateDisplay()
					setOpen(false)

					if config.Callback then
						local ok, err = pcall(config.Callback, selectedSingle)
						if not ok then
							warn("Devlyx Dropdown Callback Error: " .. tostring(err))
						end
					end
				end
			end)

			table.insert(optionRows, { Frame = optionRow, Label = optionLabel, Check = checkIcon, Name = optionName })
		end
	end

	rebuildOptions()
	updateDisplay()

	if config.Tooltip then
		AttachTooltip(self.Window, row, config.Tooltip)
	end

	table.insert(self.Window.Controls, function(theme2)
		row.BackgroundColor3 = theme2.Background
		row.BackgroundTransparency = theme2.Transparency
		rowStroke.Color = theme2.Accent
		titleLabel.TextColor3 = theme2.TitleColor
		valueLabel.TextColor3 = theme2.Accent
		chevron.ImageColor3 = theme2.DescColor
		iconChip.BackgroundColor3 = theme2.Accent
		if iconImage then
			iconImage.ImageColor3 = theme2.Accent
		end
		if descLabel then
			descLabel.TextColor3 = theme2.DescColor
		end
		for _, opt in ipairs(optionRows) do
			opt.Frame.BackgroundColor3 = theme2.Secondary
			opt.Label.TextColor3 = theme2.TitleColor
			if opt.Check then
				opt.Check.ImageColor3 = theme2.Accent
			end
		end
	end)

	local dropdownObject = {
		Frame = row,
		Set = function(_, newValue)
			if isMulti then
				selectedSet = {}
				if typeof(newValue) == "table" then
					for _, v in ipairs(newValue) do
						selectedSet[v] = true
					end
				end
				for _, opt in ipairs(optionRows) do
					if opt.Check then
						opt.Check.ImageTransparency = selectedSet[opt.Name] and 0 or 1
					end
				end
			else
				selectedSingle = newValue
			end
			updateDisplay()
		end,
		Get = function()
			if isMulti then
				local list = {}
				for _, optionName in ipairs(options) do
					if selectedSet[optionName] then
						table.insert(list, optionName)
					end
				end
				return list
			end
			return selectedSingle
		end,
		SetOptions = function(_, newOptions)
			options = newOptions or {}
			if isMulti then
				local kept = {}
				for _, v in ipairs(options) do
					if selectedSet[v] then
						kept[v] = true
					end
				end
				selectedSet = kept
			else
				local stillValid = false
				for _, v in ipairs(options) do
					if v == selectedSingle then
						stillValid = true
						break
					end
				end
				if not stillValid then
					selectedSingle = nil
				end
			end
			rebuildOptions()
			updateDisplay()
		end,
	}

	if config.Flag then
		self.Window.Flags[config.Flag] = dropdownObject
	end

	return dropdownObject
end

function Section:AddDropdown(config)
	return self:_BuildDropdown(config, false)
end

function Section:AddMultiDropdown(config)
	return self:_BuildDropdown(config, true)
end

function Section:AddKeybind(name, config)
	config = config or {}
	self._lastPairRow = nil
	local theme = self.Window.Theme
	local title = config.Title or name or "Keybind"
	local mode = config.Mode or "Toggle"

	local boundValue, boundType = ResolveKeybind(config.Default)
	local toggledState = false
	local listening = false

	local row = CreateInstance("Frame", {
		Name = "Keybind",
		Parent = self.Container,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = theme.Transparency,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 8),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.5,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	local hasDescription = config.Description and config.Description ~= ""

	local titleLabel = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -90, 0, 16),
		Font = Enum.Font.Gotham,
		Text = title,
		TextColor3 = theme.TitleColor,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local descLabel
	if hasDescription then
		descLabel = CreateInstance("TextLabel", {
			Name = "Description",
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 20),
			Size = UDim2.new(1, -90, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.Gotham,
			Text = config.Description,
			TextColor3 = theme.DescColor,
			TextSize = 10,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	local keyButton = CreateInstance("TextButton", {
		Name = "KeyButton",
		Parent = row,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 80, 0, 24),
		BackgroundColor3 = theme.Secondary,
		BackgroundTransparency = 0.25,
		Text = KeybindDisplayName(boundValue, boundType),
		Font = Enum.Font.GothamBold,
		TextColor3 = theme.Accent,
		TextSize = 11,
		AutoButtonColor = false,
	})

	CreateInstance("UICorner", {
		Parent = keyButton,
		CornerRadius = UDim.new(0, 5),
	})

	local keyButtonStroke = CreateInstance("UIStroke", {
		Parent = keyButton,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.5,
	})

	local function setToggled(newState, fireCallback)
		toggledState = newState

		if fireCallback and config.Callback then
			local ok, err = pcall(config.Callback, toggledState)
			if not ok then
				warn("Devlyx Keybind Callback Error: " .. tostring(err))
			end
		end
	end

	local inputBeganConn, inputEndedConn

	local function matchesBound(input)
		if not boundValue then
			return false
		end
		if boundType == "KeyCode" then
			return input.KeyCode == boundValue
		elseif boundType == "MouseButton" then
			return input.UserInputType == boundValue
		end
		return false
	end

	inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if listening or gameProcessed then
			return
		end

		if UserInputService:GetFocusedTextBox() then
			return
		end

		if matchesBound(input) then
			if mode == "Always" then
				setToggled(true, true)
			elseif mode == "Toggle" then
				setToggled(not toggledState, true)
			elseif mode == "Hold" then
				setToggled(true, true)
			end
		end
	end)

	inputEndedConn = UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if listening then
			return
		end

		if mode == "Hold" and matchesBound(input) then
			setToggled(false, true)
		end
	end)

	keyButton.MouseButton1Click:Connect(function()
		if listening then
			return
		end

		listening = true
		keyButton.Text = "..."

		local listenConn
		listenConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if input.KeyCode == Enum.KeyCode.Escape then
				listening = false
				keyButton.Text = KeybindDisplayName(boundValue, boundType)
				listenConn:Disconnect()
				return
			end

			local newValue, newType

			if input.UserInputType == Enum.UserInputType.Keyboard then
				newValue, newType = input.KeyCode, "KeyCode"
			elseif input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3 then
				newValue, newType = input.UserInputType, "MouseButton"
			end

			if newValue then
				boundValue = newValue
				boundType = newType
				keyButton.Text = KeybindDisplayName(boundValue, boundType)
				listening = false
				listenConn:Disconnect()

				if config.ChangedCallback then
					local ok, err = pcall(config.ChangedCallback, boundValue)
					if not ok then
						warn("Devlyx Keybind ChangedCallback Error: " .. tostring(err))
					end
				end
			end
		end)
	end)

	keyButton.MouseEnter:Connect(function()
		PlayTween(self.Window, keyButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = self.Window.Theme.Accent,
		})
	end)

	keyButton.MouseLeave:Connect(function()
		PlayTween(self.Window, keyButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = self.Window.Theme.Secondary,
		})
	end)

	if config.Tooltip then
		AttachTooltip(self.Window, row, config.Tooltip)
	end

	table.insert(self.Window.Controls, function(theme2)
		row.BackgroundColor3 = theme2.Background
		row.BackgroundTransparency = theme2.Transparency
		rowStroke.Color = theme2.Accent
		keyButtonStroke.Color = theme2.Accent
		titleLabel.TextColor3 = theme2.TitleColor
		if descLabel then
			descLabel.TextColor3 = theme2.DescColor
		end
		keyButton.BackgroundColor3 = theme2.Secondary
		keyButton.TextColor3 = theme2.Accent
	end)

	local keybindObject = {
		Frame = row,
		Set = function(_, newKeyName)
			local v, t = ResolveKeybind(newKeyName)
			if v then
				boundValue = v
				boundType = t
				keyButton.Text = KeybindDisplayName(boundValue, boundType)
			end
		end,
		Get = function()
			return boundValue
		end,
		GetString = function()
			return KeybindDisplayName(boundValue, boundType)
		end,
		GetState = function()
			return toggledState
		end,
	}

	if config.Flag then
		self.Window.Flags[config.Flag] = keybindObject
	end

	return keybindObject
end

function Section:AddInput(name, config)
	config = config or {}
	self._lastPairRow = nil
	local theme = self.Window.Theme
	local title = config.Title or name or "Input"

	local row = CreateInstance("Frame", {
		Name = "Input",
		Parent = self.Container,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = theme.Transparency,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 8),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.5,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	local hasDescription = config.Description and config.Description ~= ""
	local iconId = ResolveIcon(config.Icon or "type")
	local textOffset = 32

	local iconChip = CreateInstance("Frame", {
		Name = "IconChip",
		Parent = row,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, 22, 0, 22),
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
	})

	CreateInstance("UICorner", {
		Parent = iconChip,
		CornerRadius = UDim.new(0, 6),
	})

	local iconImage = CreateInstance("ImageLabel", {
		Name = "Icon",
		Parent = iconChip,
		BackgroundTransparency = 1,
		Image = iconId,
		ImageColor3 = theme.Accent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 13, 0, 13),
	})

	local titleLabel = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, textOffset, 0, 4),
		Size = UDim2.new(1, -textOffset, 0, 16),
		Font = Enum.Font.Gotham,
		Text = title,
		TextColor3 = theme.TitleColor,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local descLabel
	local boxYOffset = 30

	if hasDescription then
		descLabel = CreateInstance("TextLabel", {
			Name = "Description",
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, textOffset, 0, 22),
			Size = UDim2.new(1, -textOffset, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.Gotham,
			Text = config.Description,
			TextColor3 = theme.DescColor,
			TextSize = 10,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		boxYOffset = 46
	end

	local isMultiline = config.Multiline == true
	local boxHeight = isMultiline and (config.Lines and config.Lines * 18 + 12 or 70) or 27

	local inputBox = CreateInstance("Frame", {
		Name = "InputBox",
		Parent = row,
		Position = UDim2.new(0, 0, 0, boxYOffset),
		Size = UDim2.new(1, 0, 0, boxHeight),
		BackgroundColor3 = theme.Secondary,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
	})

	CreateInstance("UICorner", {
		Parent = inputBox,
		CornerRadius = UDim.new(0, 5),
	})

	local inputBoxStroke = CreateInstance("UIStroke", {
		Parent = inputBox,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.5,
	})

	local textBox = CreateInstance("TextBox", {
		Name = "TextBox",
		Parent = inputBox,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, isMultiline and 6 or 0),
		Size = UDim2.new(1, -16, 1, isMultiline and -12 or 0),
		Font = Enum.Font.Gotham,
		Text = config.Default or "",
		PlaceholderText = config.Placeholder or "",
		TextColor3 = theme.TitleColor,
		PlaceholderColor3 = theme.DescColor,
		TextSize = 12,
		TextWrapped = true,
		MultiLine = isMultiline,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = isMultiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		ClearTextOnFocus = false,
	})

	local currentValue = config.Default or ""

	local function sanitizeNumeric(text)
		local cleaned = text:gsub("[^%d%.%-]", "")
		return cleaned
	end

	local function fireCallback(value)
		if config.Callback then
			local ok, err = pcall(config.Callback, value)
			if not ok then
				warn("Devlyx Input Callback Error: " .. tostring(err))
			end
		end
	end

	textBox:GetPropertyChangedSignal("Text"):Connect(function()
		if config.Numeric then
			local sanitized = sanitizeNumeric(textBox.Text)
			if sanitized ~= textBox.Text then
				textBox.Text = sanitized
				return
			end
		end

		currentValue = textBox.Text

		if not config.Finished then
			fireCallback(currentValue)
		end
	end)

	textBox.Focused:Connect(function()
		inputBoxStroke.Transparency = 0.2
	end)

	textBox.FocusLost:Connect(function(enterPressed)
		currentValue = textBox.Text
		inputBoxStroke.Transparency = 0.6

		if config.Finished and enterPressed then
			fireCallback(currentValue)
		end
	end)

	if config.Tooltip then
		AttachTooltip(self.Window, row, config.Tooltip)
	end

	table.insert(self.Window.Controls, function(theme2)
		row.BackgroundColor3 = theme2.Background
		row.BackgroundTransparency = theme2.Transparency
		rowStroke.Color = theme2.Accent
		inputBoxStroke.Color = theme2.Accent
		titleLabel.TextColor3 = theme2.TitleColor
		if descLabel then
			descLabel.TextColor3 = theme2.DescColor
		end
		inputBox.BackgroundColor3 = theme2.Secondary
		iconChip.BackgroundColor3 = theme2.Accent
		iconImage.ImageColor3 = theme2.Accent
		textBox.TextColor3 = theme2.TitleColor
		textBox.PlaceholderColor3 = theme2.DescColor
	end)

	local inputObject = {
		Frame = row,
		Set = function(_, newValue)
			textBox.Text = tostring(newValue)
			currentValue = textBox.Text
		end,
		Get = function()
			return currentValue
		end,
	}

	if config.Flag then
		self.Window.Flags[config.Flag] = inputObject
	end

	return inputObject
end

function Section:AddDropdownGroup(config)
	config = config or {}
	self._lastPairRow = nil
	local theme = self.Window.Theme

	local row = CreateInstance("Frame", {
		Name = "DropdownGroup",
		Parent = self.Container,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = theme.Transparency,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 8),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.5,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	local hasDescription = config.Description and config.Description ~= ""
	local headerHeight = hasDescription and 31 or 15
	local iconId = ResolveIcon(config.Icon or "chevron-down")
	local textOffset = 32

	local header = CreateInstance("TextButton", {
		Name = "Header",
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, headerHeight),
		Text = "",
		AutoButtonColor = false,
	})

	local iconChip = CreateInstance("Frame", {
		Name = "IconChip",
		Parent = header,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 22, 0, 22),
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
	})

	CreateInstance("UICorner", {
		Parent = iconChip,
		CornerRadius = UDim.new(0, 6),
	})

	local iconImage = CreateInstance("ImageLabel", {
		Name = "Icon",
		Parent = iconChip,
		BackgroundTransparency = 1,
		Image = iconId,
		ImageColor3 = theme.Accent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 13, 0, 13),
	})

	local titleLabel = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, textOffset, 0, 0),
		Size = UDim2.new(1, -40 - textOffset, 0, 16),
		Font = Enum.Font.Gotham,
		Text = config.Name or config.Title or "Group",
		TextColor3 = theme.TitleColor,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local descLabel
	if hasDescription then
		descLabel = CreateInstance("TextLabel", {
			Name = "Description",
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, textOffset, 0, 20),
			Size = UDim2.new(1, -40 - textOffset, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.Gotham,
			Text = config.Description,
			TextColor3 = theme.DescColor,
			TextSize = 10,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	local chevron = CreateInstance("ImageLabel", {
		Name = "Chevron",
		Parent = row,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 1),
		Size = UDim2.new(0, 14, 0, 14),
		Image = ResolveIcon("chevron-down"),
		ImageColor3 = theme.DescColor,
	})

	local body = CreateInstance("CanvasGroup", {
		Name = "Body",
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, headerHeight + 8),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		GroupTransparency = 1,
		Visible = false,
	})

	CreateInstance("UIListLayout", {
		Parent = body,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local isOpen = false
	local function setOpen(open, instant)
		if isOpen == open then
			return
		end

		isOpen = open

		local animated = (not instant) and self.Window.Animation ~= false

		if animated then
			PlayTween(self.Window, chevron, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Rotation = open and 180 or 0,
			})
		else
			chevron.Rotation = open and 180 or 0
		end

		if open then
			body.Visible = true

			if animated then
				body.GroupTransparency = 1
				PlayTween(self.Window, body, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 })
			else
				body.GroupTransparency = 0
			end
		else
			if animated then
				PlayTween(self.Window, body, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 1 })
				task.delay(0.15, function()
					if not isOpen then
						body.Visible = false
					end
				end)
			else
				body.GroupTransparency = 1
				body.Visible = false
			end
		end
	end

	local dropdownHoverTween = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	header.MouseEnter:Connect(function()
		PlayTween(self.Window, row, dropdownHoverTween, {
			BackgroundColor3 = self.Window.Theme.Secondary,
			BackgroundTransparency = 0.25,
		})
		PlayTween(self.Window, rowStroke, dropdownHoverTween, { Transparency = 0.15 })
	end)

	header.MouseLeave:Connect(function()
		if not isOpen then
			PlayTween(self.Window, row, dropdownHoverTween, {
				BackgroundColor3 = self.Window.Theme.Background,
				BackgroundTransparency = self.Window.Theme.Transparency,
			})
			PlayTween(self.Window, rowStroke, dropdownHoverTween, { Transparency = 0.5 })
		end
	end)

	header.MouseButton1Click:Connect(function()
		setOpen(not isOpen)
	end)

	if config.Tooltip then
		AttachTooltip(self.Window, header, config.Tooltip)
	end

	table.insert(self.Window.Controls, function(theme2)
		row.BackgroundColor3 = theme2.Background
		row.BackgroundTransparency = theme2.Transparency
		rowStroke.Color = theme2.Accent
		titleLabel.TextColor3 = theme2.TitleColor
		chevron.ImageColor3 = theme2.DescColor
		iconChip.BackgroundColor3 = theme2.Accent
		if iconImage then
			iconImage.ImageColor3 = theme2.Accent
		end
		if descLabel then
			descLabel.TextColor3 = theme2.DescColor
		end
	end)

	if config.Default == true or config.Open == true then
		setOpen(true, true)
	end

	local groupObject = setmetatable({
		Name = config.Name or config.Title or "Group",
		Frame = row,
		TitleLabel = titleLabel,
		Container = body,
		Tab = self.Tab,
		Window = self.Window,
	}, Section)

	groupObject.SetOpen = function(_, open)
		setOpen(open and true or false)
	end

	groupObject.Toggle = function(_)
		setOpen(not isOpen)
	end

	groupObject.IsOpen = function(_)
		return isOpen
	end

	return groupObject
end

function Section:AddBoxInfo(config)
	config = config or {}
	self._lastPairRow = nil

	local theme = self.Window.Theme
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer

	local outer = CreateInstance("Frame", {
		Name = "BoxInfo",
		Parent = self.Container,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UIListLayout", {
		Parent = outer,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local titleDivider
	local hasTitle = config.Title and config.Title ~= ""
	if hasTitle then
		titleDivider = BuildTitleDivider(outer, theme, config.Title, 1)
	end

	local card = CreateInstance("Frame", {
		Name = "Card",
		Parent = outer,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = theme.Transparency,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
	})

	CreateInstance("UICorner", {
		Parent = card,
		CornerRadius = UDim.new(0, 8),
	})

	local cardStroke = CreateInstance("UIStroke", {
		Parent = card,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.5,
	})

	CreateInstance("UIPadding", {
		Parent = card,
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	CreateInstance("UIListLayout", {
		Parent = card,
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local showAvatar = config.ShowAvatar ~= false
	local showDisplayName = config.ShowDisplayName ~= false
	local showUsername = config.ShowUsername ~= false
	local showJoinDate = config.ShowJoinDate ~= false
	local showCountry = config.ShowCountry ~= false

	local hasCustomImage = config.Image ~= nil and config.Image ~= ""
	local avatarSize = hasCustomImage and 72 or 56

	local avatarBox, avatarImage
	if showAvatar then
		avatarBox = CreateInstance("Frame", {
			Name = "Avatar",
			Parent = card,
			BackgroundColor3 = theme.Secondary,
			BackgroundTransparency = hasCustomImage and 1 or 0,
			Size = UDim2.new(0, avatarSize, 0, avatarSize),
			ClipsDescendants = true,
			LayoutOrder = 1,
		})

		CreateInstance("UICorner", {
			Parent = avatarBox,
			CornerRadius = UDim.new(0, 8),
		})

		local imageSource
		if hasCustomImage then
			imageSource = ResolveIcon(config.Image)
		else
			local userId = (player and player.UserId) or 0
			imageSource = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=150&h=150"
		end

		avatarImage = CreateInstance("ImageLabel", {
			Name = "Thumbnail",
			Parent = avatarBox,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Image = imageSource,
			ScaleType = hasCustomImage and Enum.ScaleType.Fit or Enum.ScaleType.Stretch,
			LayoutOrder = 1,
		})
	end

	local infoColumn = CreateInstance("Frame", {
		Name = "Info",
		Parent = card,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, showAvatar and -(avatarSize + 10) or 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
	})

	CreateInstance("UIListLayout", {
		Parent = infoColumn,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local row1
	local displayNameLabel, usernameLabel, joinDateLabel
	if showDisplayName or showUsername or showJoinDate then
		row1 = CreateInstance("Frame", {
			Name = "Row1",
			Parent = infoColumn,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			LayoutOrder = 1,
		})

		CreateInstance("UIListLayout", {
			Parent = row1,
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		if showDisplayName then
			displayNameLabel = CreateInstance("TextLabel", {
				Name = "DisplayName",
				Parent = row1,
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = (player and player.DisplayName) or "Player",
				TextColor3 = theme.TitleColor,
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = 1,
			})
		end

		if showUsername then
			usernameLabel = CreateInstance("TextLabel", {
				Name = "Username",
				Parent = row1,
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 1, 0),
				Font = Enum.Font.Gotham,
				Text = "@" .. ((player and player.Name) or "unknown"),
				TextColor3 = theme.DescColor,
				TextSize = 11,
				LayoutOrder = 2,
			})
		end

		if showJoinDate then
			joinDateLabel = CreateInstance("TextLabel", {
				Name = "JoinDate",
				Parent = row1,
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 1, 0),
				Font = Enum.Font.Gotham,
				Text = "Joined " .. FormatJoinDate(player),
				TextColor3 = theme.DescColor,
				TextSize = 11,
				LayoutOrder = 3,
			})
		end
	end

	local countryIcon, countryLabel
	if showCountry then
		local countryText = config.Country
		if not countryText or countryText == "" then
			countryText = ResolveCountryFromLocale(player)
		end

		local row2 = CreateInstance("Frame", {
			Name = "Row2",
			Parent = infoColumn,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			LayoutOrder = 2,
		})

		CreateInstance("UIListLayout", {
			Parent = row2,
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		countryIcon = CreateInstance("ImageLabel", {
			Name = "Icon",
			Parent = row2,
			BackgroundTransparency = 1,
			Image = ResolveIcon("map-pin"),
			ImageColor3 = theme.Accent,
			Size = UDim2.new(0, 12, 0, 12),
			LayoutOrder = 1,
		})

		countryLabel = CreateInstance("TextLabel", {
			Name = "Country",
			Parent = row2,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Font = Enum.Font.Gotham,
			Text = countryText,
			TextColor3 = theme.DescColor,
			TextSize = 11,
			LayoutOrder = 2,
		})
	end

	table.insert(self.Window.Controls, function(theme2)
		card.BackgroundColor3 = theme2.Background
		card.BackgroundTransparency = theme2.Transparency
		cardStroke.Color = theme2.Accent

		if avatarBox and not hasCustomImage then
			avatarBox.BackgroundColor3 = theme2.Secondary
		end

		if displayNameLabel then
			displayNameLabel.TextColor3 = theme2.TitleColor
		end

		if usernameLabel then
			usernameLabel.TextColor3 = theme2.DescColor
		end

		if joinDateLabel then
			joinDateLabel.TextColor3 = theme2.DescColor
		end

		if countryLabel then
			countryLabel.TextColor3 = theme2.DescColor
		end

		if countryIcon then
			countryIcon.ImageColor3 = theme2.Accent
		end

		if titleDivider then
			titleDivider.Label.TextColor3 = theme2.DescColor
			titleDivider.LeftLine.BackgroundColor3 = theme2.Accent
			titleDivider.RightLine.BackgroundColor3 = theme2.Accent
		end
	end)

	local boxInfoObject = {
		Frame = outer,
		Card = card,
		Refresh = function()
			local currentPlayer = Players.LocalPlayer
			if displayNameLabel then
				displayNameLabel.Text = (currentPlayer and currentPlayer.DisplayName) or "Player"
			end
			if usernameLabel then
				usernameLabel.Text = "@" .. ((currentPlayer and currentPlayer.Name) or "unknown")
			end
			if joinDateLabel then
				joinDateLabel.Text = "Joined " .. FormatJoinDate(currentPlayer)
			end
			if countryLabel and (not config.Country or config.Country == "") then
				countryLabel.Text = ResolveCountryFromLocale(currentPlayer)
			end
			if avatarImage and not hasCustomImage then
				local userId = (currentPlayer and currentPlayer.UserId) or 0
				avatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=150&h=150"
			end
		end,
	}

	return boxInfoObject
end

return Section
