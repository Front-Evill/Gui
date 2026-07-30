local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Utils = require(script.Parent.Utils)
local CreateInstance = Utils.CreateInstance
local FadeTransparency = Utils.FadeTransparency
local PlayTween = Utils.PlayTween

local IconsModule = require(script.Parent.Icons)
local ResolveIcon = IconsModule.ResolveIcon

local M = {}

function M:GetNotifyContainer(position)
	self.NotifyGui = self.NotifyGui or CreateInstance("ScreenGui", {
		Name = "VantaNotifications",
		Parent = PlayerGui,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 1500,
	})

	self.NotifyContainers = self.NotifyContainers or {}

	if self.NotifyContainers[position] then
		return self.NotifyContainers[position]
	end

	local container = CreateInstance("Frame", {
		Name = "NotifyContainer_" .. position,
		Parent = self.NotifyGui,
		BackgroundTransparency = 1,
		AnchorPoint = position == "down" and Vector2.new(1, 1) or Vector2.new(1, 0),
		Position = position == "down" and UDim2.new(1, -20, 1, -20) or UDim2.new(1, -20, 0, 20),
		Size = UDim2.new(0, 310, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})

	CreateInstance("UIListLayout", {
		Parent = container,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = position == "down" and Enum.VerticalAlignment.Bottom or Enum.VerticalAlignment.Top,
	})

	self.NotifyContainers[position] = container
	return container
end

function M:Notify(config)
	config = config or {}
	local theme = self.Theme

	local iconCfg = config.icone

	if iconCfg == true then
		iconCfg = { Work = true, IdIcon = "", Type = "up" }
	elseif iconCfg == false or iconCfg == nil then
		iconCfg = { Work = false }
	end
	local position = iconCfg.Type == "down" and "down" or "up"
	local container = self:GetNotifyContainer(position)

	self.NotifyOrder = (self.NotifyOrder or 0) + 1

	local fadeEntries = {}

	local card = CreateInstance("Frame", {
		Name = "Notification",
		Parent = container,
		BackgroundColor3 = theme.Secondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self.NotifyOrder,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	table.insert(fadeEntries, { instance = card, prop = "BackgroundTransparency", target = theme.Transparency })

	CreateInstance("UICorner", {
		Parent = card,
		CornerRadius = UDim.new(0, 12),
	})

	local cardStroke = CreateInstance("UIStroke", {
		Parent = card,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 1,
	})
	table.insert(fadeEntries, { instance = cardStroke, prop = "Transparency", target = 0.4 })

	local accentBar = CreateInstance("Frame", {
		Name = "AccentBar",
		Parent = card,
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 6, 0, 8),
		Size = UDim2.new(0, 3, 1, -16),
	})
	table.insert(fadeEntries, { instance = accentBar, prop = "BackgroundTransparency", target = 0 })

	CreateInstance("UICorner", {
		Parent = accentBar,
		CornerRadius = UDim.new(1, 0),
	})

	local hasIcon = iconCfg.Work == true
	local contentLeftPadding = hasIcon and 56 or 20

	local contentWrapper = CreateInstance("Frame", {
		Name = "Content",
		Parent = card,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})

	CreateInstance("UIPadding", {
		Parent = contentWrapper,
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, contentLeftPadding),
		PaddingRight = UDim.new(0, 32),
	})

	if hasIcon then
		local iconId = (iconCfg.IdIcon and iconCfg.IdIcon ~= "") and ResolveIcon(iconCfg.IdIcon) or ResolveIcon("alert-triangle")

		local iconBadge = CreateInstance("Frame", {
			Name = "IconBadge",
			Parent = contentWrapper,
			BackgroundColor3 = theme.Accent,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, -40, 0, 0),
			Size = UDim2.new(0, 30, 0, 30),
			BorderSizePixel = 0,
		})
		table.insert(fadeEntries, { instance = iconBadge, prop = "BackgroundTransparency", target = 0.85 })

		CreateInstance("UICorner", {
			Parent = iconBadge,
			CornerRadius = UDim.new(0, 10),
		})

		local iconLabel = CreateInstance("ImageLabel", {
			Name = "Icon",
			Parent = iconBadge,
			BackgroundTransparency = 1,
			ImageTransparency = 1,
			Image = iconId,
			ImageColor3 = theme.Accent,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 16, 0, 16),
		})
		table.insert(fadeEntries, { instance = iconLabel, prop = "ImageTransparency", target = 0 })
	end

	CreateInstance("UIListLayout", {
		Parent = contentWrapper,
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local titleLabel = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = contentWrapper,
		BackgroundTransparency = 1,
		TextTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.GothamBold,
		Text = config.Title or "Notification",
		TextColor3 = theme.TitleColor,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		LayoutOrder = 1,
	})
	table.insert(fadeEntries, { instance = titleLabel, prop = "TextTransparency", target = 0 })

	if config.Content and config.Content ~= "" then
		local contentLabel = CreateInstance("TextLabel", {
			Name = "Description",
			Parent = contentWrapper,
			BackgroundTransparency = 1,
			TextTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.Gotham,
			Text = config.Content,
			TextColor3 = theme.DescColor,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LayoutOrder = 2,
		})
		table.insert(fadeEntries, { instance = contentLabel, prop = "TextTransparency", target = 0 })
	end

	if config.SubContent and config.SubContent ~= "" then
		local subContentLabel = CreateInstance("TextLabel", {
			Name = "SubDescription",
			Parent = contentWrapper,
			BackgroundTransparency = 1,
			TextTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.Gotham,
			Text = config.SubContent,
			TextColor3 = theme.DescColor,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LayoutOrder = 3,
		})
		table.insert(fadeEntries, { instance = subContentLabel, prop = "TextTransparency", target = 0.35 })
	end

	local closeButton = CreateInstance("ImageButton", {
		Name = "Close",
		Parent = card,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.new(0, 20, 0, 20),
		Image = ResolveIcon("x"),
		ImageTransparency = 1,
		ImageColor3 = theme.DescColor,
		AutoButtonColor = false,
	})
	table.insert(fadeEntries, { instance = closeButton, prop = "ImageTransparency", target = 0 })

	CreateInstance("UICorner", {
		Parent = closeButton,
		CornerRadius = UDim.new(0, 6),
	})

	closeButton.MouseEnter:Connect(function()
		closeButton.ImageColor3 = theme.Accent
		PlayTween(self, closeButton, TweenInfo.new(0.12), { BackgroundTransparency = 0.85 })
	end)
	closeButton.MouseLeave:Connect(function()
		closeButton.ImageColor3 = theme.DescColor
		PlayTween(self, closeButton, TweenInfo.new(0.12), { BackgroundTransparency = 1 })
	end)

	local progressBar
	if config.Duration and config.Duration > 0 and self.Animation ~= false then
		progressBar = CreateInstance("Frame", {
			Name = "Progress",
			Parent = card,
			BackgroundColor3 = theme.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 3),
			ZIndex = 5,
		})
		table.insert(fadeEntries, { instance = progressBar, prop = "BackgroundTransparency", target = 0.25 })
	end

	local dismissed = false
	local function dismiss()
		if dismissed then
			return
		end
		dismissed = true

		local exitEntries = {}
		for _, entry in ipairs(fadeEntries) do
			table.insert(exitEntries, { instance = entry.instance, prop = entry.prop, target = 1 })
		end

		FadeTransparency(exitEntries, 0.2, Enum.EasingDirection.In, self)

		task.delay(0.2, function()
			card:Destroy()
		end)
	end

	closeButton.MouseButton1Click:Connect(dismiss)

	FadeTransparency(fadeEntries, 0.25, Enum.EasingDirection.Out, self)

	if progressBar then
		task.delay(0.1, function()
			if dismissed then
				return
			end
			PlayTween(self, progressBar, TweenInfo.new(config.Duration, Enum.EasingStyle.Linear), {
				Size = UDim2.new(0, 0, 0, 3),
			})
		end)
	end

	if config.SoundID and config.SoundID ~= "" then
		local soundId = tostring(config.SoundID)
		if not soundId:match("^rbxassetid://") then
			soundId = "rbxassetid://" .. soundId
		end

		local sound = CreateInstance("Sound", {
			Name = "NotifySound",
			Parent = card,
			SoundId = soundId,
			Volume = config.SoundVolume or 1,
			PlaybackSpeed = config.SoundSpeed or 1,
			Looped = config.SoundLooped or false,
		})

		sound.Ended:Connect(function()
			if not config.SoundLooped then
				sound:Destroy()
			end
		end)

		pcall(function()
			sound:Play()
		end)
	end

	if config.Duration then
		task.delay(config.Duration, dismiss)
	end

	return {
		Frame = card,
		Dismiss = dismiss,
	}
end


return M
