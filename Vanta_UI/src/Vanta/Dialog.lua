local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Utils = require(script.Parent.Utils)
local CreateInstance = Utils.CreateInstance
local FadeTransparency = Utils.FadeTransparency

local M = {}

function M:Dialog(config)
	config = config or {}

	self.DialogGui = self.DialogGui or CreateInstance("ScreenGui", {
		Name = "VantaDialog",
		Parent = PlayerGui,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 2000,
	})

	local fadeEntries = {}

	local backdrop = CreateInstance("Frame", {
		Name = "Backdrop",
		Parent = self.DialogGui,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = true,
	})
	table.insert(fadeEntries, { instance = backdrop, prop = "BackgroundTransparency", target = 0.5 })

	local card = CreateInstance("Frame", {
		Name = "DialogCard",
		Parent = backdrop,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 380, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = self.Theme.Background,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})
	table.insert(fadeEntries, { instance = card, prop = "BackgroundTransparency", target = self.Theme.Transparency })

	CreateInstance("UICorner", {
		Parent = card,
		CornerRadius = UDim.new(0, 12),
	})

	local cardStroke = CreateInstance("UIStroke", {
		Parent = card,
		Color = self.Theme.Accent,
		Thickness = 1,
		Transparency = 1,
	})
	table.insert(fadeEntries, { instance = cardStroke, prop = "Transparency", target = 0.3 })

	CreateInstance("UIPadding", {
		Parent = card,
		PaddingTop = UDim.new(0, 20),
		PaddingBottom = UDim.new(0, 20),
		PaddingLeft = UDim.new(0, 20),
		PaddingRight = UDim.new(0, 20),
	})

	local layout = CreateInstance("UIListLayout", {
		Parent = card,
		Padding = UDim.new(0, 14),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local titleLabel = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = card,
		BackgroundTransparency = 1,
		TextTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = config.Title or "Dialog",
		TextColor3 = self.Theme.TitleColor,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		LayoutOrder = 1,
	})
	table.insert(fadeEntries, { instance = titleLabel, prop = "TextTransparency", target = 0 })

	if config.Content and config.Content ~= "" then
		local contentLabel = CreateInstance("TextLabel", {
			Name = "Content",
			Parent = card,
			BackgroundTransparency = 1,
			TextTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.Gotham,
			Text = config.Content,
			TextColor3 = self.Theme.DescColor,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LayoutOrder = 2,
		})
		table.insert(fadeEntries, { instance = contentLabel, prop = "TextTransparency", target = 0 })
	end

	local buttons = config.Buttons or {}
	local buttonCount = math.max(#buttons, 1)

	local buttonsRow = CreateInstance("Frame", {
		Name = "Buttons",
		Parent = card,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = 3,
	})

	CreateInstance("UIListLayout", {
		Parent = buttonsRow,
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local dismissed = false
	local function close()
		if dismissed then
			return
		end
		dismissed = true

		local exitEntries = {}
		for _, entry in ipairs(fadeEntries) do
			table.insert(exitEntries, { instance = entry.instance, prop = entry.prop, target = 1 })
		end

		FadeTransparency(exitEntries, 0.18, Enum.EasingDirection.In, self)

		task.delay(0.18, function()
			backdrop:Destroy()
		end)
	end

	for index, buttonConfig in ipairs(buttons) do
		local buttonFrame = CreateInstance("TextButton", {
			Name = "Button" .. index,
			Parent = buttonsRow,
			Size = UDim2.new(1 / buttonCount, -8, 1, 0),
			BackgroundColor3 = self.Theme.Background,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = index,
		})
		table.insert(fadeEntries, {
			instance = buttonFrame,
			prop = "BackgroundTransparency",
			target = 0,
		})

		CreateInstance("UICorner", {
			Parent = buttonFrame,
			CornerRadius = UDim.new(0, 6),
		})

		local btnStroke = CreateInstance("UIStroke", {
			Parent = buttonFrame,
			Color = self.Theme.Accent,
			Thickness = 1,
			Transparency = 1,
		})
		table.insert(fadeEntries, { instance = btnStroke, prop = "Transparency", target = 0.7 })

		local btnLabel = CreateInstance("TextLabel", {
			Parent = buttonFrame,
			BackgroundTransparency = 1,
			TextTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Font = Enum.Font.Gotham,
			Text = buttonConfig.Title or ("Button " .. index),
			TextColor3 = self.Theme.TitleColor,
			TextSize = 13,
		})
		table.insert(fadeEntries, { instance = btnLabel, prop = "TextTransparency", target = 0 })

		buttonFrame.MouseEnter:Connect(function()
			buttonFrame.BackgroundColor3 = self.Theme.Secondary
		end)

		buttonFrame.MouseLeave:Connect(function()
			buttonFrame.BackgroundColor3 = self.Theme.Background
		end)

		buttonFrame.MouseButton1Down:Connect(function()
			buttonFrame.BackgroundColor3 = self.Theme.Accent
		end)

		buttonFrame.MouseButton1Up:Connect(function()
			buttonFrame.BackgroundColor3 = self.Theme.Secondary
		end)

		buttonFrame.MouseButton1Click:Connect(function()
			if buttonConfig.Callback then
				local ok, err = pcall(buttonConfig.Callback)
				if not ok then
					warn("Vanta Dialog Callback Error: " .. tostring(err))
				end
			end
			close()
		end)
	end

	FadeTransparency(fadeEntries, 0.2, Enum.EasingDirection.Out, self)

	return {
		Frame = card,
		Close = close,
	}
end


return M
