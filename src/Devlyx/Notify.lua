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
		Name = "DevlyxNotifications",
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

	local position = "down"
	local container = self:GetNotifyContainer(position)

	self.NotifyOrder = (self.NotifyOrder or 0) + 1

	local fadeEntries = {}

	local slot = CreateInstance("Frame", {
		Name = "NotificationSlot",
		Parent = container,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self.NotifyOrder,
	})

	local card = CreateInstance("Frame", {
		Name = "Notification",
		Parent = slot,
		BackgroundColor3 = theme.Secondary,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 42, 0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
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

	local contentLeftPadding = 20

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
		TextColor3 = Color3.fromRGB(255, 255, 255),
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
			TextColor3 = Color3.fromRGB(163, 163, 163),
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
			TextColor3 = Color3.fromRGB(163, 163, 163),
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LayoutOrder = 3,
		})
		table.insert(fadeEntries, { instance = subContentLabel, prop = "TextTransparency", target = 0.35 })
	end

	local isConfirm = config.Accept ~= nil or config.Reject ~= nil

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

		PlayTween(self, card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0, 42, 0, 0),
		})

		task.delay(0.2, function()
			slot:Destroy()
		end)
	end

	local acceptButton, rejectButton
	if isConfirm then
		local actionsRow = CreateInstance("Frame", {
			Name = "Actions",
			Parent = contentWrapper,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 30),
			LayoutOrder = 4,
		})

		CreateInstance("UIPadding", {
			Parent = actionsRow,
			PaddingTop = UDim.new(0, 8),
		})

		CreateInstance("UIListLayout", {
			Parent = actionsRow,
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		rejectButton = CreateInstance("TextButton", {
			Name = "Reject",
			Parent = actionsRow,
			BackgroundColor3 = theme.Background,
			BackgroundTransparency = 1,
			Size = UDim2.new(0.5, -4, 1, -8),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = 1,
		})

		CreateInstance("UICorner", {
			Parent = rejectButton,
			CornerRadius = UDim.new(0, 8),
		})

		local rejectStroke = CreateInstance("UIStroke", {
			Parent = rejectButton,
			Color = theme.DescColor,
			Thickness = 1,
			Transparency = 1,
		})
		table.insert(fadeEntries, { instance = rejectStroke, prop = "Transparency", target = 0.4 })

		local rejectLabel = CreateInstance("TextLabel", {
			Parent = rejectButton,
			BackgroundTransparency = 1,
			TextTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Font = Enum.Font.GothamBold,
			Text = config.RejectText or "Reject",
			TextColor3 = theme.DescColor,
			TextSize = 12,
		})
		table.insert(fadeEntries, { instance = rejectLabel, prop = "TextTransparency", target = 0 })

		acceptButton = CreateInstance("TextButton", {
			Name = "Accept",
			Parent = actionsRow,
			BackgroundColor3 = theme.Accent,
			BackgroundTransparency = 1,
			Size = UDim2.new(0.5, -4, 1, -8),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = 2,
		})
		table.insert(fadeEntries, { instance = acceptButton, prop = "BackgroundTransparency", target = 0.1 })

		CreateInstance("UICorner", {
			Parent = acceptButton,
			CornerRadius = UDim.new(0, 8),
		})

		local acceptLabel = CreateInstance("TextLabel", {
			Parent = acceptButton,
			BackgroundTransparency = 1,
			TextTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Font = Enum.Font.GothamBold,
			Text = config.AcceptText or "Accept",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
		})
		table.insert(fadeEntries, { instance = acceptLabel, prop = "TextTransparency", target = 0 })

		local function decide(accepted)
			if dismissed then
				return
			end

			local callback = accepted and config.Accept or config.Reject
			if callback then
				local ok, err = pcall(callback)
				if not ok then
					warn("Devlyx Notify " .. (accepted and "Accept" or "Reject") .. " Callback Error: " .. tostring(err))
				end
			end

			dismiss()
		end

		acceptButton.MouseButton1Click:Connect(function()
			decide(true)
		end)
		rejectButton.MouseButton1Click:Connect(function()
			decide(false)
		end)

		acceptButton.MouseEnter:Connect(function()
			PlayTween(self, acceptButton, TweenInfo.new(0.12), { BackgroundTransparency = 0 })
		end)
		acceptButton.MouseLeave:Connect(function()
			PlayTween(self, acceptButton, TweenInfo.new(0.12), { BackgroundTransparency = 0.1 })
		end)

		rejectButton.MouseEnter:Connect(function()
			rejectStroke.Color = theme.Accent
			PlayTween(self, rejectButton, TweenInfo.new(0.12), { BackgroundTransparency = 0.85 })
		end)
		rejectButton.MouseLeave:Connect(function()
			rejectStroke.Color = theme.DescColor
			PlayTween(self, rejectButton, TweenInfo.new(0.12), { BackgroundTransparency = 1 })
		end)
	end

	local closeButton
	if not isConfirm then
		closeButton = CreateInstance("ImageButton", {
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

		closeButton.MouseButton1Click:Connect(dismiss)
	end

	PlayTween(self, card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
	})

	FadeTransparency(fadeEntries, 0.25, Enum.EasingDirection.Out, self)

	local soundIdRaw = config.idsound or config.SoundID
	if soundIdRaw and soundIdRaw ~= "" then
		local soundId = tostring(soundIdRaw)
		if not soundId:match("^rbxassetid://") then
			soundId = "rbxassetid://" .. soundId
		end

		local isLooped = config.Loopsound
		if isLooped == nil then
			isLooped = config.SoundLooped or false
		end

		local sound = CreateInstance("Sound", {
			Name = "NotifySound",
			Parent = card,
			SoundId = soundId,
			Volume = config.Volumesound or config.SoundVolume or 1,
			PlaybackSpeed = config.Speedsound or config.SoundSpeed or 1,
			Looped = isLooped,
		})

		sound.Ended:Connect(function()
			if not isLooped then
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
