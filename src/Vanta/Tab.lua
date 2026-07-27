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
	local boxEnabled = true

	if type(config) == "string" then
		text = config
	elseif type(config) == "table" then
		text = config.Name or config.Text or text
		iconName = config.Icon
		if config.Box == false then
			boxEnabled = false
		end
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
		BackgroundColor3 = self.Window.Theme.Secondary,
		BackgroundTransparency = boxEnabled and self.Window.Theme.Transparency or 1,
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
		Color = self.Window.Theme.Accent,
		Thickness = 1,
		Transparency = boxEnabled and 0.6 or 1,
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

	table.insert(self.Window.Controls, function(theme2)
		elementsFrame.BackgroundColor3 = theme2.Secondary
		elementsFrame.BackgroundTransparency = boxEnabled and theme2.Transparency or 1
		elementsStroke.Color = theme2.Accent
		elementsStroke.Transparency = boxEnabled and 0.6 or 1
	end)

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
		Box = boxEnabled,
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
			CellSize = UDim2.new(0.5, -4, 0, 104),
			CellPadding = UDim2.new(0, 8, 0, 8),
			FillDirectionMaxCells = 2,
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		boxSystem.Grid = grid
	end

	local tile = CreateInstance("TextButton", {
		Name = "BoxTile",
		Parent = boxSystem.Grid,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = #boxSystem.Grid:GetChildren(),
	})

	CreateInstance("UICorner", {
		Parent = tile,
		CornerRadius = UDim.new(0, 10),
	})

	local tileStroke = CreateInstance("UIStroke", {
		Parent = tile,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.6,
	})

	CreateInstance("UIPadding", {
		Parent = tile,
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	CreateInstance("UIListLayout", {
		Parent = tile,
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	CreateInstance("ImageLabel", {
		Name = "Image",
		Parent = tile,
		BackgroundTransparency = 1,
		Image = resolvedImage,
		Size = UDim2.new(0, 36, 0, 36),
		ScaleType = Enum.ScaleType.Fit,
		LayoutOrder = 1,
	})

	local tileTitle = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = tile,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = theme.TitleColor,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
	})

	tile.MouseEnter:Connect(function()
		tile.BackgroundColor3 = self.Window.Theme.Secondary
	end)
	tile.MouseLeave:Connect(function()
		tile.BackgroundColor3 = self.Window.Theme.Background
	end)
	tile.MouseButton1Down:Connect(function()
		tile.BackgroundColor3 = self.Window.Theme.Accent
	end)
	tile.MouseButton1Up:Connect(function()
		tile.BackgroundColor3 = self.Window.Theme.Secondary
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
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = theme.SectionColor,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
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
		tile.BackgroundColor3 = theme2.Background
		tileStroke.Color = theme2.Accent
		tileTitle.TextColor3 = theme2.TitleColor
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
