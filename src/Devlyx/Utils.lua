local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function CreateInstance(className, properties)
	local inst = Instance.new(className)
	pcall(function()
		inst.AutoLocalize = false
	end)
	for prop, value in pairs(properties) do
		inst[prop] = value
	end
	return inst
end

local function MakeDraggable(dragHandle, target)
	local dragging = false
	local dragStart
	local startPos

	local inputBeganConn = dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				local delta = input.Position - dragStart
				target.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end
	end)

	target.Destroying:Connect(function()
		dragging = false
		inputBeganConn:Disconnect()
		inputChangedConn:Disconnect()
	end)
end

local function AttachTooltip(window, target, text)
	if not text or text == "" then
		return
	end

	local tooltipLabel
	local moveConnection

	local function updatePosition(pos)
		if tooltipLabel then
			tooltipLabel.Position = UDim2.new(0, pos.X + 16, 0, pos.Y + 16)
		end
	end

	local function cleanup()
		if moveConnection then
			moveConnection:Disconnect()
			moveConnection = nil
		end
		if tooltipLabel then
			tooltipLabel:Destroy()
			tooltipLabel = nil
		end
	end

	target.MouseEnter:Connect(function()
		window.TooltipGui = window.TooltipGui or CreateInstance("ScreenGui", {
			Name = "DevlyxTooltip",
			Parent = PlayerGui,
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 3000,
			IgnoreGuiInset = true,
		})

		tooltipLabel = CreateInstance("TextLabel", {
			Name = "Tooltip",
			Parent = window.TooltipGui,
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundColor3 = window.Theme.Background,
			BackgroundTransparency = 0.05,
			Text = text,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = window.Theme.TitleColor,
			TextWrapped = true,
			ZIndex = 100,
		})

		CreateInstance("UICorner", {
			Parent = tooltipLabel,
			CornerRadius = UDim.new(0, 6),
		})

		CreateInstance("UIStroke", {
			Parent = tooltipLabel,
			Color = window.Theme.Accent,
			Thickness = 1,
			Transparency = 0.3,
		})

		CreateInstance("UIPadding", {
			Parent = tooltipLabel,
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		})

		local ok, mouseLoc = pcall(function()
			return UserInputService:GetMouseLocation()
		end)
		if ok and mouseLoc then
			updatePosition(mouseLoc)
		end

		moveConnection = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				updatePosition(input.Position)
			end
		end)
	end)

	target.MouseLeave:Connect(cleanup)

	window.TooltipCleanups = window.TooltipCleanups or {}
	table.insert(window.TooltipCleanups, cleanup)
end


local function PlayTween(window, instance, tweenInfo, props)
	if window and window.Animation == false then
		for prop, value in pairs(props) do
			instance[prop] = value
		end
		return nil
	end
	local tween = TweenService:Create(instance, tweenInfo, props)
	tween:Play()
	return tween
end

local function AttachImageTooltip(window, target, title, description)
	local hasTitle = title and title ~= ""
	local hasDescription = description and description ~= ""
	if not hasTitle and not hasDescription then
		return
	end

	local card
	local cardStroke
	local titleLabel
	local descLabel

	local function cleanup()
		if card then
			card:Destroy()
			card = nil
			cardStroke = nil
			titleLabel = nil
			descLabel = nil
		end
	end

	target.MouseEnter:Connect(function()
		window.TooltipGui = window.TooltipGui or CreateInstance("ScreenGui", {
			Name = "DevlyxTooltip",
			Parent = PlayerGui,
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 3000,
			IgnoreGuiInset = true,
		})

		card = CreateInstance("Frame", {
			Name = "ImageTooltip",
			Parent = window.TooltipGui,
			AnchorPoint = Vector2.new(0.5, 1),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundColor3 = window.Theme.Background,
			BackgroundTransparency = 1,
			ZIndex = 100,
		})

		CreateInstance("UICorner", {
			Parent = card,
			CornerRadius = UDim.new(0, 8),
		})

		cardStroke = CreateInstance("UIStroke", {
			Parent = card,
			Color = window.Theme.Accent,
			Thickness = 1,
			Transparency = 1,
		})

		CreateInstance("UIPadding", {
			Parent = card,
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		})

		CreateInstance("UIListLayout", {
			Parent = card,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		})

		if hasTitle then
			titleLabel = CreateInstance("TextLabel", {
				Name = "Title",
				Parent = card,
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				Text = title,
				TextSize = 13,
				TextColor3 = window.Theme.TitleColor,
				TextTransparency = 1,
				LayoutOrder = 1,
			})
		end

		if hasDescription then
			descLabel = CreateInstance("TextLabel", {
				Name = "Description",
				Parent = card,
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				Text = description,
				TextSize = 11,
				TextColor3 = window.Theme.DescColor,
				TextTransparency = 1,
				LayoutOrder = 2,
			})
		end

		local targetPos = target.AbsolutePosition
		local targetSize = target.AbsoluteSize
		local anchorX = targetPos.X + targetSize.X / 2
		local anchorY = targetPos.Y - 10

		local restPosition = UDim2.new(0, anchorX, 0, anchorY)
		local startPosition = UDim2.new(0, anchorX, 0, anchorY + 6)

		card.Position = startPosition

		PlayTween(window, card, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.05,
			Position = restPosition,
		})
		PlayTween(window, cardStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 0.3,
		})
		if titleLabel then
			PlayTween(window, titleLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 0,
			})
		end
		if descLabel then
			PlayTween(window, descLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 0,
			})
		end
	end)

	target.MouseLeave:Connect(cleanup)

	window.TooltipCleanups = window.TooltipCleanups or {}
	table.insert(window.TooltipCleanups, cleanup)
end

local function FadeTransparency(entries, duration, easingDirection, window)
	for _, entry in ipairs(entries) do
		if window and window.Animation == false then
			entry.instance[entry.prop] = entry.target
		else
			local tween = TweenService:Create(
				entry.instance,
				TweenInfo.new(duration, Enum.EasingStyle.Quad, easingDirection),
				{ [entry.prop] = entry.target }
			)
			tween:Play()
		end
	end
end

local function MakeResizable(handle, target, minSize, maxSize, direction)
	direction = direction or { X = 1, Y = 1 }
	local dirX = direction.X or 0
	local dirY = direction.Y or 0

	local resizing = false
	local dragStart
	local startSize
	local startPos
	local activeInputConnection

	local function applyDelta(delta)
		local newWidth = startSize.X.Offset
		local newHeight = startSize.Y.Offset
		local posX = startPos.X.Offset
		local posY = startPos.Y.Offset

		if dirX == 1 then
			newWidth = math.clamp(startSize.X.Offset + delta.X, minSize.X, maxSize.X)
		elseif dirX == -1 then
			local rawWidth = startSize.X.Offset - delta.X
			newWidth = math.clamp(rawWidth, minSize.X, maxSize.X)
			posX = startPos.X.Offset + (startSize.X.Offset - newWidth)
		end

		if dirY == 1 then
			newHeight = math.clamp(startSize.Y.Offset + delta.Y, minSize.Y, maxSize.Y)
		elseif dirY == -1 then
			local rawHeight = startSize.Y.Offset - delta.Y
			newHeight = math.clamp(rawHeight, minSize.Y, maxSize.Y)
			posY = startPos.Y.Offset + (startSize.Y.Offset - newHeight)
		end

		target.Size = UDim2.new(0, newWidth, 0, newHeight)

		if dirX == -1 or dirY == -1 then
			target.Position = UDim2.new(startPos.X.Scale, posX, startPos.Y.Scale, posY)
		end
	end

	local function stopResizing()
		resizing = false
		if activeInputConnection then
			activeInputConnection:Disconnect()
			activeInputConnection = nil
		end
	end

	local inputBeganConn = handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			dragStart = input.Position
			startSize = target.Size
			startPos = target.Position

			if activeInputConnection then
				activeInputConnection:Disconnect()
			end

			activeInputConnection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
					stopResizing()
				end
			end)
		end
	end)

	local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			applyDelta(delta)
		end
	end)

	local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			stopResizing()
		end
	end)

	target.Destroying:Connect(function()
		stopResizing()
		inputBeganConn:Disconnect()
		inputChangedConn:Disconnect()
		inputEndedConn:Disconnect()
	end)
end


return {
	CreateInstance = CreateInstance,
	MakeDraggable = MakeDraggable,
	AttachTooltip = AttachTooltip,
	AttachImageTooltip = AttachImageTooltip,
	FadeTransparency = FadeTransparency,
	PlayTween = PlayTween,
	MakeResizable = MakeResizable,
}
