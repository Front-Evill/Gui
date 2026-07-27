local UserInputService = game:GetService("UserInputService")

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

local Section = {}
Section.__index = Section

function Section:AddButton(config)
	config = config or {}
	local theme = self.Window.Theme

	local row = CreateInstance("TextButton", {
		Name = "Button",
		Parent = self.Container,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 6),
	})

	local stroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.7,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	local hasDescription = config.Description and config.Description ~= ""

	local title = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Font = Enum.Font.Gotham,
		Text = config.Name or "Button",
		TextColor3 = theme.TitleColor,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local descLabel
	if hasDescription then
		title.Size = UDim2.new(1, 0, 0, 16)
		descLabel = CreateInstance("TextLabel", {
			Name = "Description",
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 18),
			Size = UDim2.new(1, 0, 0, 14),
			Font = Enum.Font.Gotham,
			Text = config.Description,
			TextColor3 = theme.DescColor,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	row.MouseEnter:Connect(function()
		row.BackgroundColor3 = self.Window.Theme.Secondary
	end)

	row.MouseLeave:Connect(function()
		row.BackgroundColor3 = self.Window.Theme.Background
	end)

	row.MouseButton1Down:Connect(function()
		row.BackgroundColor3 = self.Window.Theme.Accent
	end)

	row.MouseButton1Up:Connect(function()
		row.BackgroundColor3 = self.Window.Theme.Secondary
	end)

	row.MouseButton1Click:Connect(function()
		local function runCallback()
			if config.Callback then
				local ok, err = pcall(config.Callback)
				if not ok then
					warn("Vanta Button Callback Error: " .. tostring(err))
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
		stroke.Color = theme2.Accent
		title.TextColor3 = theme2.TitleColor
		if descLabel then
			descLabel.TextColor3 = theme2.DescColor
		end
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

	local row = CreateInstance("Frame", {
		Name = "Toggle",
		Parent = self.Container,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 6),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.7,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	local hasDescription = config.Description and config.Description ~= ""

	local textContainer = CreateInstance("Frame", {
		Name = "TextContainer",
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -56, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})

	local title = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = textContainer,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Font = Enum.Font.Gotham,
		Text = config.Name or "Toggle",
		TextColor3 = theme.TitleColor,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local descLabel
	if hasDescription then
		descLabel = CreateInstance("TextLabel", {
			Name = "Description",
			Parent = textContainer,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 18),
			Size = UDim2.new(1, 0, 0, 14),
			Font = Enum.Font.Gotham,
			Text = config.Description,
			TextColor3 = theme.DescColor,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	local switchBg = CreateInstance("Frame", {
		Name = "Switch",
		Parent = row,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 40, 0, 22),
		BackgroundColor3 = value and theme.Accent or theme.Background,
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
		Position = value and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.new(0, 18, 0, 18),
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

		local targetPos = value and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
		local targetColor = value and currentTheme.Accent or currentTheme.Background

		PlayTween(self.Window, knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = targetPos,
		})

		PlayTween(self.Window, switchBg, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = targetColor,
		})

		if fireCallback and config.Callback then
			local ok, err = pcall(config.Callback, value)
			if not ok then
				warn("Vanta Toggle Callback Error: " .. tostring(err))
			end
		end
	end

	clickArea.MouseButton1Click:Connect(function()
		setValue(not value, true)
	end)

	row.MouseEnter:Connect(function()
		row.BackgroundColor3 = self.Window.Theme.Secondary
	end)

	row.MouseLeave:Connect(function()
		row.BackgroundColor3 = self.Window.Theme.Background
	end)

	if config.Tooltip then
		AttachTooltip(self.Window, row, config.Tooltip)
	end

	table.insert(self.Window.Controls, function(theme2)
		row.BackgroundColor3 = theme2.Background
		rowStroke.Color = theme2.Accent
		title.TextColor3 = theme2.TitleColor
		if descLabel then
			descLabel.TextColor3 = theme2.DescColor
		end
		switchBg.BackgroundColor3 = value and theme2.Accent or theme2.Background
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
	local theme = self.Window.Theme

	local row = CreateInstance("Frame", {
		Name = "Paragraph",
		Parent = self.Container,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 6),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.7,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
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
			TextSize = 13,
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
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	})

	if config.Tooltip then
		AttachTooltip(self.Window, row, config.Tooltip)
	end

	table.insert(self.Window.Controls, function(theme2)
		row.BackgroundColor3 = theme2.Background
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

function Section:AddColorPicker(config)
	config = config or {}
	local theme = self.Window.Theme

	local row = CreateInstance("Frame", {
		Name = "ColorPicker",
		Parent = self.Container,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 6),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.7,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	local hasDescription = config.Description and config.Description ~= ""

	local titleLabel = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Font = Enum.Font.Gotham,
		Text = config.Name or "Theme Color",
		TextColor3 = theme.TitleColor,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local descLabel
	if hasDescription then
		descLabel = CreateInstance("TextLabel", {
			Name = "Description",
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 18),
			Size = UDim2.new(1, 0, 0, 14),
			Font = Enum.Font.Gotham,
			Text = config.Description,
			TextColor3 = theme.DescColor,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	local swatchesContainer = CreateInstance("Frame", {
		Name = "Swatches",
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, hasDescription and 36 or 20),
		Size = UDim2.new(1, 0, 0, 26),
	})

	CreateInstance("UIListLayout", {
		Parent = swatchesContainer,
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local presetOrder = { "Dark", "Purple", "Rose", "Blue", "Green", "Orange", "Cyan", "Gold" }
	local swatchList = {}

	local function refreshSelection()
		for _, swatch in ipairs(swatchList) do
			local isActive = swatch.PresetName == self.Window.CurrentThemeName
			swatch.Ring.Transparency = isActive and 0 or 1
		end
	end

	for _, presetName in ipairs(presetOrder) do
		local preset = Presets[presetName]
		if preset then
			local swatchButton = CreateInstance("TextButton", {
				Name = presetName,
				Parent = swatchesContainer,
				Size = UDim2.new(0, 26, 0, 26),
				BackgroundColor3 = preset.Accent,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = #swatchesContainer:GetChildren(),
			})

			CreateInstance("UICorner", {
				Parent = swatchButton,
				CornerRadius = UDim.new(1, 0),
			})

			local ring = CreateInstance("UIStroke", {
				Parent = swatchButton,
				Color = Color3.fromRGB(255, 255, 255),
				Thickness = 2,
				Transparency = 1,
			})

			swatchButton.MouseButton1Click:Connect(function()
				self.Window:SetTheme(presetName)
				refreshSelection()

				if config.Callback then
					local ok, err = pcall(config.Callback, presetName)
					if not ok then
						warn("Vanta ColorPicker Callback Error: " .. tostring(err))
					end
				end
			end)

			table.insert(swatchList, { PresetName = presetName, Button = swatchButton, Ring = ring })
		end
	end

	refreshSelection()

	if config.Default and Presets[config.Default] then
		self.Window:SetTheme(config.Default)
		refreshSelection()
	end

	if config.Tooltip then
		AttachTooltip(self.Window, row, config.Tooltip)
	end

	table.insert(self.Window.Controls, function(theme2)
		row.BackgroundColor3 = theme2.Background
		rowStroke.Color = theme2.Accent
		titleLabel.TextColor3 = theme2.TitleColor
		if descLabel then
			descLabel.TextColor3 = theme2.DescColor
		end
		refreshSelection()
	end)

	local colorPickerObject = {
		Frame = row,
		Set = function(_, presetName)
			if Presets[presetName] then
				self.Window:SetTheme(presetName)
				refreshSelection()
			end
		end,
		Get = function()
			return self.Window.CurrentThemeName
		end,
	}

	if config.Flag then
		self.Window.Flags[config.Flag] = colorPickerObject
	end

	return colorPickerObject
end


function Section:AddProgressBar(config)
	config = config or {}
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
		BackgroundTransparency = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 6),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.7,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	local titleLabel = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -50, 0, 16),
		Font = Enum.Font.Gotham,
		Text = title,
		TextColor3 = theme.TitleColor,
		TextSize = 13,
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
		TextSize = 12,
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
		BackgroundTransparency = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 6),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.7,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
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
		TextSize = 13,
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
		TextSize = 13,
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
			Position = UDim2.new(0, 0, 0, 18),
			Size = UDim2.new(1, 0, 0, 14),
			Font = Enum.Font.Gotham,
			Text = config.Description,
			TextColor3 = theme.DescColor,
			TextSize = 11,
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

	local function updateVisual()
		local ratio = (value - min) / math.max(max - min, 0.0001)
		fill.Size = UDim2.new(ratio, 0, 1, 0)
		knob.Position = UDim2.new(ratio, 0, 0.5, 0)
		valueLabel.Text = tostring(value)
	end
	updateVisual()

	local dragging = false

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
					warn("Vanta Slider Callback Error: " .. tostring(err))
				end
			end
		end
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromInputX(input.Position.X, true)

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromInputX(input.Position.X, true)
		end
	end)

	if config.Tooltip then
		AttachTooltip(self.Window, row, config.Tooltip)
	end

	table.insert(self.Window.Controls, function(theme2)
		row.BackgroundColor3 = theme2.Background
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
		BackgroundTransparency = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 6),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.7,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	local hasDescription = config.Description and config.Description ~= ""
	local headerHeight = hasDescription and 34 or 16

	local header = CreateInstance("TextButton", {
		Name = "Header",
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, headerHeight),
		Text = "",
		AutoButtonColor = false,
	})

	local titleLabel = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -100, 0, 16),
		Font = Enum.Font.Gotham,
		Text = config.Name or "Dropdown",
		TextColor3 = theme.TitleColor,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local descLabel
	if hasDescription then
		descLabel = CreateInstance("TextLabel", {
			Name = "Description",
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 18),
			Size = UDim2.new(1, -100, 0, 14),
			Font = Enum.Font.Gotham,
			Text = config.Description,
			TextColor3 = theme.DescColor,
			TextSize = 11,
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
		TextSize = 12,
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

	header.MouseButton1Click:Connect(function()
		setOpen(not isOpen)
	end)

	for _, optionName in ipairs(options) do
		local optionRow = CreateInstance("TextButton", {
			Name = "Option",
			Parent = optionsContainer,
			BackgroundColor3 = theme.Secondary,
			BackgroundTransparency = 0,
			Size = UDim2.new(1, 0, 0, 28),
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
			TextSize = 12,
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
						warn("Vanta Dropdown Callback Error: " .. tostring(err))
					end
				end
			else
				selectedSingle = optionName
				updateDisplay()
				setOpen(false)

				if config.Callback then
					local ok, err = pcall(config.Callback, selectedSingle)
					if not ok then
						warn("Vanta Dropdown Callback Error: " .. tostring(err))
					end
				end
			end
		end)

		table.insert(optionRows, { Frame = optionRow, Label = optionLabel, Check = checkIcon, Name = optionName })
	end

	updateDisplay()

	if config.Tooltip then
		AttachTooltip(self.Window, row, config.Tooltip)
	end

	table.insert(self.Window.Controls, function(theme2)
		row.BackgroundColor3 = theme2.Background
		rowStroke.Color = theme2.Accent
		titleLabel.TextColor3 = theme2.TitleColor
		valueLabel.TextColor3 = theme2.Accent
		chevron.ImageColor3 = theme2.DescColor
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
		BackgroundTransparency = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 6),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.7,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
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
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local descLabel
	if hasDescription then
		descLabel = CreateInstance("TextLabel", {
			Name = "Description",
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 18),
			Size = UDim2.new(1, -90, 0, 14),
			Font = Enum.Font.Gotham,
			Text = config.Description,
			TextColor3 = theme.DescColor,
			TextSize = 11,
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
		BackgroundTransparency = 0,
		Text = KeybindDisplayName(boundValue, boundType),
		Font = Enum.Font.GothamBold,
		TextColor3 = theme.Accent,
		TextSize = 12,
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
				warn("Vanta Keybind Callback Error: " .. tostring(err))
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
						warn("Vanta Keybind ChangedCallback Error: " .. tostring(err))
					end
				end
			end
		end)
	end)

	keyButton.MouseEnter:Connect(function()
		keyButton.BackgroundColor3 = self.Window.Theme.Accent
	end)

	keyButton.MouseLeave:Connect(function()
		keyButton.BackgroundColor3 = self.Window.Theme.Secondary
	end)

	if config.Tooltip then
		AttachTooltip(self.Window, row, config.Tooltip)
	end

	table.insert(self.Window.Controls, function(theme2)
		row.BackgroundColor3 = theme2.Background
		rowStroke.Color = theme2.Accent
		titleLabel.TextColor3 = theme2.TitleColor
		if descLabel then
			descLabel.TextColor3 = theme2.DescColor
		end
		keyButton.BackgroundColor3 = theme2.Secondary
		keyButton.TextColor3 = theme2.Accent
		keyButtonStroke.Color = theme2.Accent
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
	local theme = self.Window.Theme
	local title = config.Title or name or "Input"

	local row = CreateInstance("Frame", {
		Name = "Input",
		Parent = self.Container,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #self.Container:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = row,
		CornerRadius = UDim.new(0, 6),
	})

	local rowStroke = CreateInstance("UIStroke", {
		Parent = row,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.7,
	})

	CreateInstance("UIPadding", {
		Parent = row,
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	local hasDescription = config.Description and config.Description ~= ""

	local titleLabel = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Font = Enum.Font.Gotham,
		Text = title,
		TextColor3 = theme.TitleColor,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local descLabel
	local boxYOffset = 22

	if hasDescription then
		descLabel = CreateInstance("TextLabel", {
			Name = "Description",
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 18),
			Size = UDim2.new(1, 0, 0, 14),
			Font = Enum.Font.Gotham,
			Text = config.Description,
			TextColor3 = theme.DescColor,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		boxYOffset = 38
	end

	local inputBox = CreateInstance("Frame", {
		Name = "InputBox",
		Parent = row,
		Position = UDim2.new(0, 0, 0, boxYOffset),
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = theme.Secondary,
		BackgroundTransparency = 0,
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
		Transparency = 0.6,
	})

	local textBox = CreateInstance("TextBox", {
		Name = "TextBox",
		Parent = inputBox,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(1, -16, 1, 0),
		Font = Enum.Font.Gotham,
		Text = config.Default or "",
		PlaceholderText = config.Placeholder or "",
		TextColor3 = theme.TitleColor,
		PlaceholderColor3 = theme.DescColor,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
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
				warn("Vanta Input Callback Error: " .. tostring(err))
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
		rowStroke.Color = theme2.Accent
		titleLabel.TextColor3 = theme2.TitleColor
		if descLabel then
			descLabel.TextColor3 = theme2.DescColor
		end
		inputBox.BackgroundColor3 = theme2.Secondary
		inputBoxStroke.Color = theme2.Accent
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


return Section
