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
			Name = "VantaTooltip",
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

local function MakeResizable(handle, target, minSize, maxSize)
	local resizing = false
	local dragStart
	local startSize

	local inputBeganConn = handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			dragStart = input.Position
			startSize = target.Size

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
				end
			end)
		end
	end)

	local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if resizing then
				local delta = input.Position - dragStart
				local newWidth = math.clamp(startSize.X.Offset + delta.X, minSize.X, maxSize.X)
				local newHeight = math.clamp(startSize.Y.Offset + delta.Y, minSize.Y, maxSize.Y)
				target.Size = UDim2.new(0, newWidth, 0, newHeight)
			end
		end
	end)

	target.Destroying:Connect(function()
		resizing = false
		inputBeganConn:Disconnect()
		inputChangedConn:Disconnect()
	end)
end


return {
	CreateInstance = CreateInstance,
	MakeDraggable = MakeDraggable,
	AttachTooltip = AttachTooltip,
	FadeTransparency = FadeTransparency,
	PlayTween = PlayTween,
	MakeResizable = MakeResizable,
}
