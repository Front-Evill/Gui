local Utils = require(script.Parent.Utils)
local CreateInstance = Utils.CreateInstance
local PlayTween = Utils.PlayTween

local IconsModule = require(script.Parent.Icons)
local ResolveIcon = IconsModule.ResolveIcon

local Section = require(script.Parent.Section)

local Tab = {}
Tab.__index = Tab


function Tab:Select()
	self.Window:SelectTab(self.Name)
end


function Tab:AddSection(config)
	local text = "Section"
	local iconName = nil

	if type(config) == "string" then
		text = config
	elseif type(config) == "table" then
		text = config.Name or config.Text or text
		iconName = config.Icon
	end

	local elementsRoot = self.ElementsRoot or self.Page

	local sectionFrame = CreateInstance("Frame", {
		Name = "Section",
		Parent = elementsRoot,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #elementsRoot:GetChildren(),
	})

	CreateInstance("UIListLayout", {
		Parent = sectionFrame,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local headerFrame = CreateInstance("Frame", {
		Name = "Header",
		Parent = sectionFrame,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = 1,
	})

	CreateInstance("UIListLayout", {
		Parent = headerFrame,
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	if iconName and iconName ~= "" then
		CreateInstance("ImageLabel", {
			Name = "Icon",
			Parent = headerFrame,
			BackgroundTransparency = 1,
			Image = ResolveIcon(iconName),
			ImageColor3 = self.Window.Theme.SectionColor,
			Size = UDim2.new(0, 20, 0, 20),
			LayoutOrder = 1,
		})
	end

	local titleLabel = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = headerFrame,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = self.Window.Theme.SectionColor,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
	})

	local elementsFrame = CreateInstance("Frame", {
		Name = "Elements",
		Parent = sectionFrame,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
	})

	CreateInstance("UIPadding", {
		Parent = elementsFrame,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	CreateInstance("UIListLayout", {
		Parent = elementsFrame,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	table.insert(self.Window.SectionLabels, titleLabel)

	local sectionIcon = headerFrame:FindFirstChild("Icon")
	if sectionIcon then
		table.insert(self.Window.SectionLabels, sectionIcon)
	end

	local sectionObject = setmetatable({
		Name = text,
		Frame = sectionFrame,
		TitleLabel = titleLabel,
		Container = elementsFrame,
		Tab = self,
		Window = self.Window,
	}, Section)

	return sectionObject
end


local function EnsureBoxSystem(self)
	if self.BoxSystem then
		return self.BoxSystem
	end

	local existingChildren = {}
	for _, child in ipairs(self.Page:GetChildren()) do
		if child:IsA("GuiObject") then
			table.insert(existingChildren, child)
		end
	end

	local stageFrame = CreateInstance("Frame", {
		Name = "BoxStage",
		Parent = self.Page,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #self.Page:GetChildren(),
	})

	local normalCanvas = CreateInstance("CanvasGroup", {
		Name = "NormalContent",
		Parent = stageFrame,
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		GroupTransparency = 0,
		Visible = true,
	})

	CreateInstance("UIListLayout", {
		Parent = normalCanvas,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	for _, child in ipairs(existingChildren) do
		local order = child.LayoutOrder
		child.Parent = normalCanvas
		child.LayoutOrder = order
	end

	local expandedCanvas = CreateInstance("CanvasGroup", {
		Name = "ExpandedContent",
		Parent = stageFrame,
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		GroupTransparency = 1,
		Visible = false,
	})

	self.ElementsRoot = normalCanvas

	local boxSystem = {
		Stage = stageFrame,
		NormalCanvas = normalCanvas,
		ExpandedCanvas = expandedCanvas,
		Grid = nil,
		ActiveBox = nil,
	}

	self.BoxSystem = boxSystem
	return boxSystem
end


local function OpenBox(self, boxData)
	local boxSystem = self.BoxSystem
	if boxSystem.ActiveBox == boxData then
		return
	end

	if boxSystem.ActiveBox then
		boxSystem.ActiveBox.ExpandedFrame.Visible = false
	end

	boxSystem.ActiveBox = boxData
	boxData.ExpandedFrame.Visible = true
	boxSystem.ExpandedCanvas.Visible = true
	boxSystem.NormalCanvas.Visible = true

	local animated = self.Window.Animation ~= false

	PlayTween(self.Window, boxSystem.NormalCanvas, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 1 })
	PlayTween(self.Window, boxSystem.ExpandedCanvas, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 })

	local function hideNormal()
		if boxSystem.ActiveBox == boxData then
			boxSystem.NormalCanvas.Visible = false
		end
	end

	if animated then
		task.delay(0.35, hideNormal)
	else
		hideNormal()
	end
end


local function CloseBox(self)
	local boxSystem = self.BoxSystem
	local boxData = boxSystem.ActiveBox
	if not boxData then
		return
	end

	boxSystem.ActiveBox = nil
	boxSystem.NormalCanvas.Visible = true

	local animated = self.Window.Animation ~= false

	PlayTween(self.Window, boxSystem.NormalCanvas, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 })
	PlayTween(self.Window, boxSystem.ExpandedCanvas, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 1 })

	local function hideExpanded()
		if boxSystem.ActiveBox == nil then
			boxSystem.ExpandedCanvas.Visible = false
			boxData.ExpandedFrame.Visible = false
		end
	end

	if animated then
		task.delay(0.3, hideExpanded)
	else
		hideExpanded()
	end
end


local function EnsureSubTabSystem(self)
	if self.SubTabSystem then
		return self.SubTabSystem
	end

	local elementsRoot = self.ElementsRoot or self.Page
	local theme = self.Window.Theme

	local stageFrame = CreateInstance("Frame", {
		Name = "SubTabStage",
		Parent = elementsRoot,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #elementsRoot:GetChildren(),
	})

	CreateInstance("UIListLayout", {
		Parent = stageFrame,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local barFrame = CreateInstance("ScrollingFrame", {
		Name = "SubTabBar",
		Parent = stageFrame,
		BackgroundColor3 = theme.Secondary,
		BackgroundTransparency = theme.Transparency,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 36),
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = theme.Accent,
		ScrollBarImageTransparency = 0.4,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		LayoutOrder = 1,
	})

	CreateInstance("UICorner", {
		Parent = barFrame,
		CornerRadius = UDim.new(0, 8),
	})

	CreateInstance("UIPadding", {
		Parent = barFrame,
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
	})

	CreateInstance("UIListLayout", {
		Parent = barFrame,
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local pagesFrame = CreateInstance("Frame", {
		Name = "SubTabPages",
		Parent = stageFrame,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
	})

	local subTabSystem = {
		Stage = stageFrame,
		Bar = barFrame,
		PagesFrame = pagesFrame,
		Items = {},
		ActiveItem = nil,
	}

	table.insert(self.Window.Controls, function(theme2)
		barFrame.BackgroundColor3 = theme2.Secondary
		barFrame.BackgroundTransparency = theme2.Transparency
		barFrame.ScrollBarImageColor3 = theme2.Accent
	end)

	self.SubTabSystem = subTabSystem
	return subTabSystem
end


local function ScrollButtonIntoView(system, button)
	local bar = system.Bar
	local viewWidth = bar.AbsoluteSize.X
	if viewWidth <= 0 then
		return
	end

	local canvasX = bar.CanvasPosition.X
	local buttonStart = (button.AbsolutePosition.X - bar.AbsolutePosition.X) + canvasX
	local buttonEnd = buttonStart + button.AbsoluteSize.X

	local targetX = canvasX
	if buttonStart < canvasX then
		targetX = buttonStart
	elseif buttonEnd > canvasX + viewWidth then
		targetX = buttonEnd - viewWidth
	end

	targetX = math.max(targetX, 0)

	if math.abs(targetX - canvasX) > 0.5 then
		bar.CanvasPosition = Vector2.new(targetX, bar.CanvasPosition.Y)
	end
end


local function ActivateSubTab(self, itemData, instant)
	local system = self.SubTabSystem
	if system.ActiveItem == itemData then
		return
	end

	local previous = system.ActiveItem
	system.ActiveItem = itemData

	if previous then
		previous.Active = false
		previous.RefreshButton()
	end

	itemData.Active = true
	itemData.RefreshButton()
	task.defer(ScrollButtonIntoView, system, itemData.Button)

	local animated = (not instant) and self.Window.Animation ~= false

	itemData.Canvas.Visible = true

	if animated then
		itemData.Canvas.GroupTransparency = 1
		PlayTween(self.Window, itemData.Canvas, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 })
	else
		itemData.Canvas.GroupTransparency = 0
	end

	if previous then
		if animated then
			PlayTween(self.Window, previous.Canvas, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 1 })
			task.delay(0.18, function()
				if system.ActiveItem ~= previous then
					previous.Canvas.Visible = false
				end
			end)
		else
			previous.Canvas.GroupTransparency = 1
			previous.Canvas.Visible = false
		end
	end
end


function Tab:AddSubTab(config)
	config = config or {}

	local text = "Sub Tab"
	local iconName = nil

	if type(config) == "string" then
		text = config
	elseif type(config) == "table" then
		text = config.Name or config.Title or text
		iconName = config.Icon
	end

	local theme = self.Window.Theme
	local system = EnsureSubTabSystem(self)

	local button = CreateInstance("TextButton", {
		Name = "SubTabButton",
		Parent = system.Bar,
		BackgroundColor3 = theme.Secondary,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = #system.Bar:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = button,
		CornerRadius = UDim.new(0, 6),
	})

	local content = CreateInstance("Frame", {
		Name = "Content",
		Parent = button,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
	})

	CreateInstance("UIPadding", {
		Parent = content,
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	CreateInstance("UIListLayout", {
		Parent = content,
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local iconImage
	if iconName and iconName ~= "" then
		iconImage = CreateInstance("ImageLabel", {
			Name = "Icon",
			Parent = content,
			BackgroundTransparency = 1,
			Image = ResolveIcon(iconName),
			ImageColor3 = theme.DescColor,
			Size = UDim2.new(0, 16, 0, 16),
			LayoutOrder = 1,
		})
	end

	local label = CreateInstance("TextLabel", {
		Name = "Label",
		Parent = content,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = theme.DescColor,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
	})

	local underline = CreateInstance("Frame", {
		Name = "Underline",
		Parent = button,
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 10, 1, -3),
		Size = UDim2.new(1, -20, 0, 2),
		ZIndex = 2,
	})

	CreateInstance("UICorner", {
		Parent = underline,
		CornerRadius = UDim.new(1, 0),
	})

	local canvas = CreateInstance("CanvasGroup", {
		Name = "SubTabPage",
		Parent = system.PagesFrame,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		GroupTransparency = 1,
		Visible = false,
		LayoutOrder = #system.PagesFrame:GetChildren(),
	})

	CreateInstance("UIListLayout", {
		Parent = canvas,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local itemData = {
		Button = button,
		Label = label,
		Icon = iconImage,
		Underline = underline,
		Canvas = canvas,
		Active = false,
		Hover = false,
	}

	local function ApplyButtonStyle(animate)
		local theme2 = self.Window.Theme
		local labelColor, iconColor, underlineTransparency

		if itemData.Active then
			labelColor = theme2.Accent
			iconColor = theme2.Accent
			underlineTransparency = 0
		elseif itemData.Hover then
			labelColor = Color3.fromRGB(255, 255, 255)
			iconColor = Color3.fromRGB(255, 255, 255)
			underlineTransparency = 1
		else
			labelColor = theme2.DescColor
			iconColor = theme2.DescColor
			underlineTransparency = 1
		end

		underline.BackgroundColor3 = theme2.Accent

		if animate then
			PlayTween(self.Window, label, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextColor3 = labelColor })
			PlayTween(self.Window, underline, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = underlineTransparency })
			if iconImage then
				PlayTween(self.Window, iconImage, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageColor3 = iconColor })
			end
		else
			label.TextColor3 = labelColor
			underline.BackgroundTransparency = underlineTransparency
			if iconImage then
				iconImage.ImageColor3 = iconColor
			end
		end
	end

	itemData.RefreshButton = function()
		ApplyButtonStyle(true)
	end

	ApplyButtonStyle(false)

	button.MouseEnter:Connect(function()
		itemData.Hover = true
		if not itemData.Active then
			ApplyButtonStyle(true)
		end
	end)

	button.MouseLeave:Connect(function()
		itemData.Hover = false
		if not itemData.Active then
			ApplyButtonStyle(true)
		end
	end)

	button.MouseButton1Click:Connect(function()
		ActivateSubTab(self, itemData)
	end)

	table.insert(system.Items, itemData)
	table.insert(self.Window.Controls, function()
		ApplyButtonStyle(false)
	end)

	if #system.Items == 1 then
		ActivateSubTab(self, itemData, true)
	end

	local sectionObject = setmetatable({
		Name = text,
		Frame = canvas,
		TitleLabel = label,
		Container = canvas,
		SubTab = true,
		Tab = self,
		Window = self.Window,
	}, Section)

	return sectionObject
end


function Tab:AddSectionsBox(config)
	config = config or {}
	local text = config.Name or config.Title or "Box"
	local imageId = config.Image or config.Icon or config.Id or config.IdIcon
	local resolvedImage = ResolveIcon((imageId ~= nil and imageId ~= "") and imageId or "image")

	local theme = self.Window.Theme
	local boxSystem = EnsureBoxSystem(self)

	if not boxSystem.Grid then
		local grid = CreateInstance("Frame", {
			Name = "BoxesGrid",
			Parent = boxSystem.NormalCanvas,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = #boxSystem.NormalCanvas:GetChildren(),
		})

		CreateInstance("UIGridLayout", {
			Parent = grid,
			CellSize = UDim2.new(0.5, -12, 0, 120),
			CellPadding = UDim2.new(0, 20, 0, 20),
			FillDirectionMaxCells = 2,
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		boxSystem.Grid = grid
	end

	local tile = CreateInstance("TextButton", {
		Name = "BoxTile",
		Parent = boxSystem.Grid,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ClipsDescendants = true,
		LayoutOrder = #boxSystem.Grid:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = tile,
		CornerRadius = UDim.new(0, 10),
	})

	local tileStroke = CreateInstance("UIStroke", {
		Parent = tile,
		Color = theme.Accent,
		Thickness = 0.8,
		Transparency = math.min(1, theme.Transparency + 0.34),
	})

	CreateInstance("UIPadding", {
		Parent = tile,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
	})

	CreateInstance("UIListLayout", {
		Parent = tile,
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local imageBox = CreateInstance("Frame", {
		Name = "ImageBox",
		Parent = tile,
		BackgroundColor3 = theme.Secondary,
		BackgroundTransparency = 0.3,
		Size = UDim2.new(0, 48, 0, 48),
		LayoutOrder = 1,
	})

	CreateInstance("UICorner", {
		Parent = imageBox,
		CornerRadius = UDim.new(0, 10),
	})

	local iconImage = CreateInstance("ImageLabel", {
		Name = "Image",
		Parent = imageBox,
		BackgroundTransparency = 1,
		Image = resolvedImage,
		ImageColor3 = theme.Accent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 26, 0, 26),
		ScaleType = Enum.ScaleType.Fit,
	})

	local tileTitle = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = tile,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
	})

	local tileDescription
	local descriptionText = config.Description or config.SubTitle
	if descriptionText and descriptionText ~= "" then
		tileDescription = CreateInstance("TextLabel", {
			Name = "Description",
			Parent = tile,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Font = Enum.Font.Gotham,
			Text = descriptionText,
			TextColor3 = Color3.fromRGB(163, 163, 163),
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 3,
		})
	end

	tile.MouseEnter:Connect(function()
		tile.BackgroundTransparency = 0.9
		tile.BackgroundColor3 = self.Window.Theme.Secondary
	end)
	tile.MouseLeave:Connect(function()
		tile.BackgroundTransparency = 1
	end)
	tile.MouseButton1Down:Connect(function()
		tile.BackgroundTransparency = 0.8
	end)
	tile.MouseButton1Up:Connect(function()
		tile.BackgroundTransparency = 0.9
	end)

	local expandedFrame = CreateInstance("Frame", {
		Name = "BoxExpanded",
		Parent = boxSystem.ExpandedCanvas,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		LayoutOrder = tile.LayoutOrder,
	})

	CreateInstance("UIListLayout", {
		Parent = expandedFrame,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local headerRow = CreateInstance("Frame", {
		Name = "Header",
		Parent = expandedFrame,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		LayoutOrder = 1,
	})

	local leftGroup = CreateInstance("Frame", {
		Name = "Left",
		Parent = headerRow,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -32, 1, 0),
	})

	CreateInstance("UIListLayout", {
		Parent = leftGroup,
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local headerImage = CreateInstance("ImageLabel", {
		Name = "Icon",
		Parent = leftGroup,
		BackgroundTransparency = 1,
		Image = resolvedImage,
		Size = UDim2.new(0, 20, 0, 20),
		LayoutOrder = 1,
	})

	local headerTitle = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = leftGroup,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -26, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = theme.SectionColor,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 2,
	})

	local backButton = CreateInstance("ImageButton", {
		Name = "Back",
		Parent = headerRow,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 24, 0, 24),
		BackgroundColor3 = theme.Secondary,
		BackgroundTransparency = 1,
		Image = ResolveIcon("arrow-left"),
		ImageColor3 = theme.DescColor,
		AutoButtonColor = false,
	})

	CreateInstance("UICorner", {
		Parent = backButton,
		CornerRadius = UDim.new(0, 6),
	})

	local backHover = false
	local function RefreshBackButton()
		backButton.ImageColor3 = backHover and self.Window.Theme.Accent or self.Window.Theme.DescColor
	end
	RefreshBackButton()

	backButton.MouseEnter:Connect(function()
		backHover = true
		RefreshBackButton()
		PlayTween(self.Window, backButton, TweenInfo.new(0.12), { BackgroundTransparency = 0.85 })
	end)
	backButton.MouseLeave:Connect(function()
		backHover = false
		RefreshBackButton()
		PlayTween(self.Window, backButton, TweenInfo.new(0.12), { BackgroundTransparency = 1 })
	end)

	local elementsFrame = CreateInstance("Frame", {
		Name = "Elements",
		Parent = expandedFrame,
		BackgroundColor3 = theme.Secondary,
		BackgroundTransparency = theme.Transparency,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		LayoutOrder = 2,
	})

	CreateInstance("UICorner", {
		Parent = elementsFrame,
		CornerRadius = UDim.new(0, 10),
	})

	local elementsStroke = CreateInstance("UIStroke", {
		Parent = elementsFrame,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.6,
	})

	CreateInstance("UIPadding", {
		Parent = elementsFrame,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	CreateInstance("UIListLayout", {
		Parent = elementsFrame,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local boxData = {
		Tile = tile,
		ExpandedFrame = expandedFrame,
	}

	tile.MouseButton1Click:Connect(function()
		OpenBox(self, boxData)
	end)

	backButton.MouseButton1Click:Connect(function()
		CloseBox(self)
	end)

	table.insert(self.Window.Controls, function(theme2)
		imageBox.BackgroundColor3 = theme2.Secondary
		iconImage.ImageColor3 = theme2.Accent
		tileStroke.Color = theme2.Accent
		tileStroke.Transparency = math.min(1, theme2.Transparency + 0.34)
		headerTitle.TextColor3 = theme2.SectionColor
		backButton.BackgroundColor3 = theme2.Secondary
		RefreshBackButton()
		elementsFrame.BackgroundColor3 = theme2.Secondary
		elementsFrame.BackgroundTransparency = theme2.Transparency
		elementsStroke.Color = theme2.Accent
	end)

	table.insert(self.Window.SectionLabels, headerTitle)
	table.insert(self.Window.SectionLabels, headerImage)

	local sectionObject = setmetatable({
		Name = text,
		Frame = expandedFrame,
		TitleLabel = headerTitle,
		Container = elementsFrame,
		Box = true,
		Tab = self,
		Window = self.Window,
	}, Section)

	return sectionObject
end


return Tab
