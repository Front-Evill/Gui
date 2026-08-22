local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Utils = require(script.Parent.Utils)
local CreateInstance = Utils.CreateInstance
local MakeDraggable = Utils.MakeDraggable
local MakeResizable = Utils.MakeResizable
local AttachTooltip = Utils.AttachTooltip
local FadeTransparency = Utils.FadeTransparency
local PlayTween = Utils.PlayTween

local IconsModule = require(script.Parent.Icons)
local ResolveIcon = IconsModule.ResolveIcon

local Theme = require(script.Parent.Theme)
local ToColor3 = Theme.ToColor3
local ResolveTheme = Theme.ResolveTheme
local GenerateThemeFromAccent = Theme.GenerateThemeFromAccent
local GetRandomPresetName = Theme.GetRandomPresetName

local Acrylic = require(script.Parent.Acrylic)
local EnableAcrylicLighting = Acrylic.EnableAcrylicLighting
local DisableAcrylicLighting = Acrylic.DisableAcrylicLighting
local AttachAcrylicGlass = Acrylic.AttachAcrylicGlass

local Tab = require(script.Parent.Tab)

local ErrorHookConnected = false

return function(Library)
local M = {}

function M:Window(config)
	config = config or {}

	local rawTheme = {}
	local currentThemeName = "Dark"
	for key, value in pairs(Theme.Presets.Dark) do
		rawTheme[key] = value
	end

	if type(config.Theme) == "string" then
		local themeName = config.Theme
		if themeName == "All" or themeName == "Random" then
			themeName = GetRandomPresetName()
		end

		currentThemeName = themeName

		local preset = Theme.Presets[themeName]
		if preset then
			for key, value in pairs(preset) do
				rawTheme[key] = value
			end
		end
	elseif type(config.Theme) == "table" then
		currentThemeName = nil

		if config.Theme.Accent and not config.Theme.Background and not config.Theme.Secondary then
			local generated = GenerateThemeFromAccent(ToColor3(config.Theme.Accent))
			for key, value in pairs(generated) do
				rawTheme[key] = value
			end
		end

		for key, value in pairs(config.Theme) do
			rawTheme[key] = value
		end
	end

	local theme = ResolveTheme(rawTheme)

	local self = setmetatable({}, Library)
	self.Theme = theme
	self.Controls = {}
	self.Animation = config.Animation ~= false

	local tabWidth = config.TabWidth or 160
	local windowSize = config.Size or UDim2.fromOffset(830, 525)
	local minSize = Vector2.new(420, 300)
	local maxSize = Vector2.new(1200, 800)

	local screenGui = CreateInstance("ScreenGui", {
		Name = "DevlyxUI",
		Parent = PlayerGui,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})

	local mainFrame = CreateInstance("Frame", {
		Name = "MainFrame",
		Parent = screenGui,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = windowSize,
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = theme.Transparency,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})

	CreateInstance("UICorner", {
		Parent = mainFrame,
		CornerRadius = UDim.new(0, 10),
	})

	local stroke = CreateInstance("UIStroke", {
		Parent = mainFrame,
		Color = theme.Accent,
		Thickness = 1,
		Transparency = 0.4,
	})

	local windowScale = CreateInstance("UIScale", {
		Parent = mainFrame,
		Scale = 1,
	})

	local backgroundImage, backgroundOverlay
	if config.Background and config.Background.work then
		backgroundImage = CreateInstance("ImageLabel", {
			Name = "BackgroundImage",
			Parent = mainFrame,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = ResolveIcon(config.Background.id),
			ImageTransparency = theme.Transparency,
			ScaleType = Enum.ScaleType.Crop,
			ZIndex = -1,
		})

		backgroundOverlay = CreateInstance("Frame", {
			Name = "BackgroundOverlay",
			Parent = mainFrame,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.Background,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			ZIndex = 0,
		})
	end

	local function UpdateResponsiveScale()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end

		local ok, viewport = pcall(function()
			return camera.ViewportSize
		end)
		if not ok or not viewport or viewport.X <= 0 or viewport.Y <= 0 then
			return
		end

		local maxW = viewport.X * 0.94
		local maxH = viewport.Y * 0.88

		local scaleX = windowSize.X.Offset > 0 and math.min(1, maxW / windowSize.X.Offset) or 1
		local scaleY = windowSize.Y.Offset > 0 and math.min(1, maxH / windowSize.Y.Offset) or 1

		windowScale.Scale = math.min(scaleX, scaleY)
	end

	UpdateResponsiveScale()

	local viewportConnection
	local cameraOk, camera = pcall(function()
		return Workspace.CurrentCamera
	end)
	if cameraOk and camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateResponsiveScale)
	end

	local acrylicCleanup

	if config.Acrylic then
		EnableAcrylicLighting()
		local _, cleanup = AttachAcrylicGlass(mainFrame, screenGui)
		acrylicCleanup = cleanup

		local frostTint = CreateInstance("Frame", {
			Name = "AcrylicTint",
			Parent = mainFrame,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.92,
			BorderSizePixel = 0,
			ZIndex = 0,
		})

		CreateInstance("UIGradient", {
			Parent = frostTint,
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.85),
				NumberSequenceKeypoint.new(0.5, 0.95),
				NumberSequenceKeypoint.new(1, 0.85),
			}),
		})

		CreateInstance("ImageLabel", {
			Name = "AcrylicNoise",
			Parent = mainFrame,
			Image = "rbxassetid://9968344227",
			ImageTransparency = 0.94,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.new(0, 128, 0, 128),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 0,
		})

		mainFrame.Destroying:Connect(function()
			DisableAcrylicLighting()
		end)
	end

	local topBar = CreateInstance("Frame", {
		Name = "TopBar",
		Parent = mainFrame,
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 15,
	})

	local topBarDivider = CreateInstance("Frame", {
		Name = "Divider",
		Parent = topBar,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
	})

	local headerContainer = CreateInstance("Frame", {
		Name = "Header",
		Parent = topBar,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.new(0, 16, 0, 0),
		Size = UDim2.new(1, -32, 1, 0),
	})

	CreateInstance("UIListLayout", {
		Parent = headerContainer,
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local titleLabel = CreateInstance("TextLabel", {
		Name = "Title",
		Parent = headerContainer,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = config.Title or "Devlyx",
		TextColor3 = theme.TitleColor,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})

	local descLabel = CreateInstance("TextLabel", {
		Name = "SubTitle",
		Parent = headerContainer,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Font = Enum.Font.Gotham,
		Text = config.SubTitle or config.Description or "",
		TextColor3 = theme.DescColor,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})

	local controlsRow = CreateInstance("Frame", {
		Name = "WindowControls",
		Parent = topBar,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
	})

	CreateInstance("UIListLayout", {
		Parent = controlsRow,
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local function SyncHeaderWidth()
		local reserved = controlsRow.AbsoluteSize.X + 24
		headerContainer.Size = UDim2.new(1, -(32 + reserved), 1, 0)
	end

	controlsRow:GetPropertyChangedSignal("AbsoluteSize"):Connect(SyncHeaderWidth)
	SyncHeaderWidth()

	local statsButton
	if config.Stats ~= false then
		statsButton = CreateInstance("ImageButton", {
		Name = "StatsButton",
		Parent = controlsRow,
		Size = UDim2.new(0, 18, 0, 18),
		BackgroundColor3 = theme.Secondary,
		BackgroundTransparency = 1,
		Image = ResolveIcon("settings"),
		ImageColor3 = theme.DescColor,
		AutoButtonColor = false,
		LayoutOrder = 1,
	})

	CreateInstance("UICorner", {
		Parent = statsButton,
		CornerRadius = UDim.new(0, 6),
	})

	local statsHover = false
	local function RefreshStatsButton()
		statsButton.ImageColor3 = statsHover and theme.Accent or theme.DescColor
	end
	RefreshStatsButton()

	statsButton.MouseEnter:Connect(function()
		statsHover = true
		RefreshStatsButton()
		PlayTween(self, statsButton, TweenInfo.new(0.12), { BackgroundTransparency = 0.85 })
	end)

	statsButton.MouseLeave:Connect(function()
		statsHover = false
		RefreshStatsButton()
		PlayTween(self, statsButton, TweenInfo.new(0.12), { BackgroundTransparency = 1 })
	end)

	table.insert(self.Controls, function(theme2)
		statsButton.BackgroundColor3 = theme2.Secondary
		RefreshStatsButton()
	end)

	local statsOpen = false
	statsButton.MouseButton1Click:Connect(function()
		if statsOpen then
			return
		end
		statsOpen = true

		local fadeEntries = {}

		local backdrop = CreateInstance("Frame", {
			Name = "StatsBackdrop",
			Parent = mainFrame,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Active = true,
			ZIndex = 50,
		})
		table.insert(fadeEntries, { instance = backdrop, prop = "BackgroundTransparency", target = 0.5 })

		local card = CreateInstance("Frame", {
			Name = "StatsCard",
			Parent = backdrop,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 220, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = theme.Background,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 51,
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
			ZIndex = 51,
		})
		table.insert(fadeEntries, { instance = cardStroke, prop = "Transparency", target = 0.3 })

		CreateInstance("UIPadding", {
			Parent = card,
			PaddingTop = UDim.new(0, 20),
			PaddingBottom = UDim.new(0, 20),
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
		})

		CreateInstance("UIListLayout", {
			Parent = card,
			Padding = UDim.new(0, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		local avatar = CreateInstance("ImageLabel", {
			Name = "Avatar",
			Parent = card,
			Size = UDim2.new(0, 70, 0, 70),
			BackgroundColor3 = theme.Secondary,
			BackgroundTransparency = 1,
			ImageTransparency = 1,
			Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150",
			LayoutOrder = 1,
		})
		table.insert(fadeEntries, { instance = avatar, prop = "BackgroundTransparency", target = 0 })
		table.insert(fadeEntries, { instance = avatar, prop = "ImageTransparency", target = 0 })

		CreateInstance("UICorner", {
			Parent = avatar,
			CornerRadius = UDim.new(1, 0),
		})

		local nameLabel = CreateInstance("TextLabel", {
			Name = "PlayerName",
			Parent = card,
			BackgroundTransparency = 1,
			TextTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			Font = Enum.Font.GothamBold,
			Text = LocalPlayer.DisplayName or LocalPlayer.Name,
			TextColor3 = theme.TitleColor,
			TextSize = 14,
			LayoutOrder = 2,
		})
		table.insert(fadeEntries, { instance = nameLabel, prop = "TextTransparency", target = 0 })

		local statsContainer = CreateInstance("Frame", {
			Name = "Stats",
			Parent = card,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 3,
		})

		CreateInstance("UIListLayout", {
			Parent = statsContainer,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		local fpsLabel = CreateInstance("TextLabel", {
			Name = "FPS",
			Parent = statsContainer,
			BackgroundTransparency = 1,
			TextTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			Font = Enum.Font.Gotham,
			Text = "FPS: --",
			TextColor3 = theme.DescColor,
			TextSize = 12,
			LayoutOrder = 1,
		})
		table.insert(fadeEntries, { instance = fpsLabel, prop = "TextTransparency", target = 0 })

		local playersLabel = CreateInstance("TextLabel", {
			Name = "Players",
			Parent = statsContainer,
			BackgroundTransparency = 1,
			TextTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			Font = Enum.Font.Gotham,
			Text = "Players: " .. tostring(#Players:GetPlayers()),
			TextColor3 = theme.DescColor,
			TextSize = 12,
			LayoutOrder = 2,
		})
		table.insert(fadeEntries, { instance = playersLabel, prop = "TextTransparency", target = 0 })

		local closeButton = CreateInstance("TextButton", {
			Name = "Close",
			Parent = card,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 10, 0, -10),
			Size = UDim2.new(0, 20, 0, 20),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 52,
		})

		local closeIcon = CreateInstance("ImageLabel", {
			Parent = closeButton,
			BackgroundTransparency = 1,
			ImageTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Image = ResolveIcon("x"),
			ImageColor3 = theme.DescColor,
			ZIndex = 52,
		})
		table.insert(fadeEntries, { instance = closeIcon, prop = "ImageTransparency", target = 0 })

		local fpsAccumulator = 0
		local fpsFrames = 0
		local fpsConnection = RunService.Heartbeat:Connect(function(dt)
			fpsAccumulator = fpsAccumulator + dt
			fpsFrames = fpsFrames + 1
			if fpsAccumulator >= 0.5 then
				local fps = math.floor(fpsFrames / fpsAccumulator + 0.5)
				fpsLabel.Text = "FPS: " .. tostring(fps)
				playersLabel.Text = "Players: " .. tostring(#Players:GetPlayers())
				fpsAccumulator = 0
				fpsFrames = 0
			end
		end)

		local function closeStats()
			if fpsConnection then
				fpsConnection:Disconnect()
			end

			local exitEntries = {}
			for _, entry in ipairs(fadeEntries) do
				table.insert(exitEntries, { instance = entry.instance, prop = entry.prop, target = 1 })
			end
			FadeTransparency(exitEntries, 0.15, Enum.EasingDirection.In, self)

			task.delay(0.15, function()
				backdrop:Destroy()
				statsOpen = false
			end)
		end

		closeButton.MouseButton1Click:Connect(closeStats)

		FadeTransparency(fadeEntries, 0.2, Enum.EasingDirection.Out, self)
	end)
	end

	local collapseButton = CreateInstance("ImageButton", {
		Name = "CollapseButton",
		Parent = controlsRow,
		Size = UDim2.new(0, 18, 0, 18),
		BackgroundColor3 = theme.Secondary,
		BackgroundTransparency = 1,
		Image = ResolveIcon("chevron-up"),
		ImageColor3 = theme.DescColor,
		AutoButtonColor = false,
		LayoutOrder = 2,
	})

	CreateInstance("UICorner", {
		Parent = collapseButton,
		CornerRadius = UDim.new(0, 6),
	})

	local collapseHover = false
	local function RefreshCollapseButton()
		collapseButton.ImageColor3 = collapseHover and theme.Accent or theme.DescColor
	end
	RefreshCollapseButton()

	collapseButton.MouseEnter:Connect(function()
		collapseHover = true
		RefreshCollapseButton()
		PlayTween(self, collapseButton, TweenInfo.new(0.12), { BackgroundTransparency = 0.85 })
	end)

	collapseButton.MouseLeave:Connect(function()
		collapseHover = false
		RefreshCollapseButton()
		PlayTween(self, collapseButton, TweenInfo.new(0.12), { BackgroundTransparency = 1 })
	end)

	table.insert(self.Controls, function(theme2)
		collapseButton.BackgroundColor3 = theme2.Secondary
		RefreshCollapseButton()
	end)

	local maximizeButton = CreateInstance("ImageButton", {
		Name = "MaximizeButton",
		Parent = controlsRow,
		Size = UDim2.new(0, 16, 0, 16),
		BackgroundColor3 = theme.Secondary,
		BackgroundTransparency = 1,
		Image = ResolveIcon("maximize"),
		ImageColor3 = theme.DescColor,
		AutoButtonColor = false,
		LayoutOrder = 3,
	})

	CreateInstance("UICorner", {
		Parent = maximizeButton,
		CornerRadius = UDim.new(0, 6),
	})

	local maximizeHover = false
	local function RefreshMaximizeButton()
		maximizeButton.ImageColor3 = maximizeHover and theme.Accent or theme.DescColor
	end
	RefreshMaximizeButton()

	maximizeButton.MouseEnter:Connect(function()
		maximizeHover = true
		RefreshMaximizeButton()
		PlayTween(self, maximizeButton, TweenInfo.new(0.12), { BackgroundTransparency = 0.85 })
	end)

	maximizeButton.MouseLeave:Connect(function()
		maximizeHover = false
		RefreshMaximizeButton()
		PlayTween(self, maximizeButton, TweenInfo.new(0.12), { BackgroundTransparency = 1 })
	end)

	table.insert(self.Controls, function(theme2)
		maximizeButton.BackgroundColor3 = theme2.Secondary
		RefreshMaximizeButton()
	end)

	local windowCloseButton = CreateInstance("ImageButton", {
		Name = "CloseButton",
		Parent = controlsRow,
		Size = UDim2.new(0, 16, 0, 16),
		BackgroundColor3 = Color3.fromRGB(255, 90, 90),
		BackgroundTransparency = 1,
		Image = ResolveIcon("x"),
		ImageColor3 = theme.DescColor,
		AutoButtonColor = false,
		LayoutOrder = 4,
	})

	CreateInstance("UICorner", {
		Parent = windowCloseButton,
		CornerRadius = UDim.new(0, 6),
	})

	local closeHover = false
	local function RefreshCloseButton()
		windowCloseButton.ImageColor3 = closeHover and Color3.fromRGB(255, 90, 90) or theme.DescColor
	end
	RefreshCloseButton()

	windowCloseButton.MouseEnter:Connect(function()
		closeHover = true
		RefreshCloseButton()
		PlayTween(self, windowCloseButton, TweenInfo.new(0.12), { BackgroundTransparency = 0.85 })
	end)

	windowCloseButton.MouseLeave:Connect(function()
		closeHover = false
		RefreshCloseButton()
		PlayTween(self, windowCloseButton, TweenInfo.new(0.12), { BackgroundTransparency = 1 })
	end)

	table.insert(self.Controls, function()
		RefreshCloseButton()
	end)

	local verticalTabs = (windowSize.X.Offset / math.max(windowSize.Y.Offset, 1)) >= 1.3

	local tabsFrame = CreateInstance("ScrollingFrame", {
		Name = "TabsFrame",
		Parent = mainFrame,
		Position = verticalTabs and UDim2.new(0, 0, 0, 50) or UDim2.new(0, 0, 0, 50),
		Size = verticalTabs and UDim2.new(0, tabWidth, 1, -50) or UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollingDirection = verticalTabs and Enum.ScrollingDirection.Y or Enum.ScrollingDirection.X,
		AutomaticCanvasSize = verticalTabs and Enum.AutomaticSize.Y or Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = theme.Accent,
		ScrollBarImageTransparency = 0.4,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		ZIndex = 15,
	})

	table.insert(self.Controls, function(theme2)
		tabsFrame.ScrollBarImageColor3 = theme2.Accent
	end)

	local tabsDivider
	local tabsGrip
	if verticalTabs then
		tabsDivider = CreateInstance("Frame", {
			Name = "TabsDivider",
			Parent = mainFrame,
			Position = UDim2.new(0, tabWidth, 0, 50),
			Size = UDim2.new(0, 1, 1, -50),
			BackgroundColor3 = theme.Accent,
			BackgroundTransparency = 0.75,
			BorderSizePixel = 0,
		})

		tabsGrip = CreateInstance("Frame", {
			Name = "TabsGrip",
			Parent = mainFrame,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0, tabWidth, 0, 50),
			Size = UDim2.new(0, 6, 1, -50),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 16,
			Active = true,
		})
	else
		tabsDivider = CreateInstance("Frame", {
			Name = "TabsDivider",
			Parent = mainFrame,
			Position = UDim2.new(0, 0, 0, 94),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = theme.Accent,
			BackgroundTransparency = 0.75,
			BorderSizePixel = 0,
		})
	end

	CreateInstance("UIListLayout", {
		Parent = tabsFrame,
		FillDirection = verticalTabs and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		HorizontalAlignment = verticalTabs and Enum.HorizontalAlignment.Center or Enum.HorizontalAlignment.Left,
		VerticalAlignment = verticalTabs and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	CreateInstance("UIPadding", {
		Parent = tabsFrame,
		PaddingTop = UDim.new(0, verticalTabs and 10 or 6),
		PaddingBottom = UDim.new(0, verticalTabs and 0 or 6),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	local searchIcon, searchBox, searchRow, searchBoxStroke
	if config.Search then
		searchRow = CreateInstance("Frame", {
			Name = "SearchRow",
			Parent = tabsFrame,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 24),
			LayoutOrder = -1,
		})

		searchIcon = CreateInstance("ImageButton", {
			Name = "SearchIcon",
			Parent = searchRow,
			Size = UDim2.new(0, 24, 0, 24),
			BackgroundColor3 = theme.Secondary,
			BackgroundTransparency = 1,
			Image = ResolveIcon("search"),
			ImageColor3 = theme.DescColor,
			AutoButtonColor = false,
		})

		CreateInstance("UICorner", {
			Parent = searchIcon,
			CornerRadius = UDim.new(0, 6),
		})

		searchBox = CreateInstance("TextBox", {
			Name = "SearchBox",
			Parent = searchRow,
			Position = UDim2.new(0, 28, 0, 0),
			Size = UDim2.new(1, -28, 1, 0),
			BackgroundColor3 = theme.Secondary,
			BackgroundTransparency = 1,
			PlaceholderText = "Search...",
			PlaceholderColor3 = theme.DescColor,
			Text = "",
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = theme.TitleColor,
			ClearTextOnFocus = false,
			Visible = false,
			ZIndex = 2,
		})

		CreateInstance("UICorner", {
			Parent = searchBox,
			CornerRadius = UDim.new(0, 6),
		})

		searchBoxStroke = CreateInstance("UIStroke", {
			Parent = searchBox,
			Color = theme.Accent,
			Thickness = 1,
			Transparency = 0.5,
		})

		CreateInstance("UIPadding", {
			Parent = searchBox,
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		})
	end

	local contentFrame = CreateInstance("Frame", {
		Name = "ContentFrame",
		Parent = mainFrame,
		Position = verticalTabs and UDim2.new(0, tabWidth, 0, 50) or UDim2.new(0, 0, 0, 94),
		Size = verticalTabs and UDim2.new(1, -tabWidth, 1, -50) or UDim2.new(1, 0, 1, -94),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 15,
	})

	if verticalTabs and tabsGrip then
		local dragging = false
		local minTabWidth = 100
		local maxTabWidth = 260

		local function applyTabWidth(width)
			tabWidth = math.clamp(width, minTabWidth, maxTabWidth)
			tabsFrame.Size = UDim2.new(0, tabWidth, 1, -50)
			tabsDivider.Position = UDim2.new(0, tabWidth, 0, 50)
			tabsGrip.Position = UDim2.new(0, tabWidth, 0, 50)
			contentFrame.Position = UDim2.new(0, tabWidth, 0, 50)
			contentFrame.Size = UDim2.new(1, -tabWidth, 1, -50)
		end

		tabsGrip.MouseEnter:Connect(function()
			PlayTween(self, tabsDivider, TweenInfo.new(0.12), { BackgroundTransparency = 0.2 })
		end)

		tabsGrip.MouseLeave:Connect(function()
			if not dragging then
				PlayTween(self, tabsDivider, TweenInfo.new(0.12), { BackgroundTransparency = 0.75 })
			end
		end)

		tabsGrip.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if not dragging then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local mouseX = input.Position.X
				applyTabWidth(mouseX - mainFrame.AbsolutePosition.X)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if dragging then
					dragging = false
					PlayTween(self, tabsDivider, TweenInfo.new(0.12), { BackgroundTransparency = 0.75 })
				end
			end
		end)
	end

	CreateInstance("UIPadding", {
		Parent = contentFrame,
		PaddingTop = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	})

	MakeDraggable(topBar, mainFrame)

	local resizeHandle
	local resizeHandles = {}
	if config.Resize then
		local CORNER_SIZE = 14
		local EDGE_THICKNESS = 6

		local function addResizeHandle(name, anchorPoint, position, size, direction)
			local h = CreateInstance("Frame", {
				Name = name,
				Parent = mainFrame,
				AnchorPoint = anchorPoint,
				Position = position,
				Size = size,
				BackgroundTransparency = 1,
				ZIndex = 10,
			})

			MakeResizable(h, mainFrame, minSize, maxSize, direction)
			table.insert(resizeHandles, h)
			return h
		end

		addResizeHandle("ResizeTopLeft", Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), UDim2.new(0, CORNER_SIZE, 0, CORNER_SIZE), { X = -1, Y = -1 })
		addResizeHandle("ResizeTopRight", Vector2.new(1, 0), UDim2.new(1, 0, 0, 0), UDim2.new(0, CORNER_SIZE, 0, CORNER_SIZE), { X = 1, Y = -1 })
		addResizeHandle("ResizeBottomLeft", Vector2.new(0, 1), UDim2.new(0, 0, 1, 0), UDim2.new(0, CORNER_SIZE, 0, CORNER_SIZE), { X = -1, Y = 1 })
		resizeHandle = addResizeHandle("ResizeBottomRight", Vector2.new(1, 1), UDim2.new(1, 0, 1, 0), UDim2.new(0, CORNER_SIZE, 0, CORNER_SIZE), { X = 1, Y = 1 })

		addResizeHandle("ResizeTop", Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 0), UDim2.new(1, -CORNER_SIZE * 2, 0, EDGE_THICKNESS), { X = 0, Y = -1 })
		addResizeHandle("ResizeBottom", Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, 0), UDim2.new(1, -CORNER_SIZE * 2, 0, EDGE_THICKNESS), { X = 0, Y = 1 })
		addResizeHandle("ResizeLeft", Vector2.new(0, 0.5), UDim2.new(0, 0, 0.5, 0), UDim2.new(0, EDGE_THICKNESS, 1, -CORNER_SIZE * 2), { X = -1, Y = 0 })
		addResizeHandle("ResizeRight", Vector2.new(1, 0.5), UDim2.new(1, 0, 0.5, 0), UDim2.new(0, EDGE_THICKNESS, 1, -CORNER_SIZE * 2), { X = 1, Y = 0 })
	end

	local isMaximized = false
	local storedWindowSize = windowSize

	local function setMaximized(maximized)
		isMaximized = maximized

		local targetSize
		if maximized then
			local camera = Workspace.CurrentCamera
			local vp = (camera and camera.ViewportSize) or Vector2.new(1280, 720)
			local w = math.min(vp.X * 0.92, maxSize.X)
			local h = math.min(vp.Y * 0.88, maxSize.Y)
			targetSize = UDim2.new(0, w, 0, h)
			maximizeButton.Image = ResolveIcon("minimize-2")
		else
			targetSize = storedWindowSize
			maximizeButton.Image = ResolveIcon("maximize")
		end

		PlayTween(self, mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = targetSize,
		})
	end

	maximizeButton.MouseButton1Click:Connect(function()
		setMaximized(not isMaximized)
	end)

	local isCollapsed = false
	local expandedHeight = nil
	local collapsedHeight = 50

	local function setCollapsed(collapsed)
		isCollapsed = collapsed

		local currentSize = mainFrame.Size
		local currentPos = mainFrame.Position

		if collapsed then
			expandedHeight = currentSize.Y.Offset
			local delta = (expandedHeight - collapsedHeight) / 2

			PlayTween(self, mainFrame, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(currentSize.X.Scale, currentSize.X.Offset, currentSize.Y.Scale, collapsedHeight),
				Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset, currentPos.Y.Scale, currentPos.Y.Offset + delta),
			})

			collapseButton.Image = ResolveIcon("chevron-down")

			for _, h in ipairs(resizeHandles) do
				h.Visible = false
			end

			tabsFrame.Visible = false
			contentFrame.Visible = false
			if tabsDivider then
				tabsDivider.Visible = false
			end
			if tabsGrip then
				tabsGrip.Visible = false
			end
		else
			local delta = (expandedHeight - collapsedHeight) / 2

			PlayTween(self, mainFrame, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(currentSize.X.Scale, currentSize.X.Offset, currentSize.Y.Scale, expandedHeight),
				Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset, currentPos.Y.Scale, currentPos.Y.Offset - delta),
			})

			collapseButton.Image = ResolveIcon("chevron-up")

			for _, h in ipairs(resizeHandles) do
				h.Visible = true
			end

			tabsFrame.Visible = true
			contentFrame.Visible = true
			if tabsDivider then
				tabsDivider.Visible = true
			end
			if tabsGrip then
				tabsGrip.Visible = true
			end
		end
	end

	collapseButton.MouseButton1Click:Connect(function()
		setCollapsed(not isCollapsed)
	end)

	local iconButton
	local iconFrameStroke
	local iconCornerStroke
	if config.icno and config.icno.work then
		local hasImage = config.icno.IdIcon and config.icno.IdIcon ~= ""
		local iconSize = config.icno.Size or 44
		local innerImageSize = math.floor(iconSize * 0.9)
		local innerCornerSize = math.floor(iconSize * 0.45)

		local shape = config.icno.Shape
		local cornerRadius = UDim.new(0, 12)
		if shape == "Circle" then
			cornerRadius = UDim.new(1, 0)
		elseif shape == "Square" then
			cornerRadius = UDim.new(0, 6)
		elseif shape == "Triangle" then
			cornerRadius = UDim.new(0, 6)
		end

		local iconGui = CreateInstance("ScreenGui", {
			Name = "DevlyxIcon",
			Parent = PlayerGui,
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 1000,
		})

		iconButton = CreateInstance("TextButton", {
			Name = "IconToggle",
			Parent = iconGui,
			Position = UDim2.new(0, 40, 0, 40),
			Size = UDim2.new(0, iconSize, 0, iconSize),
			BackgroundColor3 = theme.Background,
			BackgroundTransparency = hasImage and 1 or theme.Transparency,
			Text = "",
			AutoButtonColor = false,
		})

		local iconCorner = CreateInstance("UICorner", {
			Parent = iconButton,
			CornerRadius = cornerRadius,
		})

		iconFrameStroke = CreateInstance("UIStroke", {
			Parent = iconButton,
			Color = theme.Accent,
			Thickness = 1,
			Transparency = hasImage and 1 or 0.3,
		})

		local iconImageLabel
		if hasImage then
			iconImageLabel = CreateInstance("ImageLabel", {
				Parent = iconButton,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, innerImageSize, 0, innerImageSize),
				BackgroundTransparency = 1,
				Image = ResolveIcon(config.icno.IdIcon),
			})
			self.IconImage = iconImageLabel
		elseif shape == "Triangle" then
			local triangleGlyph = CreateInstance("ImageLabel", {
				Name = "Corner",
				Parent = iconButton,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, innerImageSize, 0, innerImageSize),
				BackgroundTransparency = 1,
				Image = ResolveIcon("triangle"),
				ImageColor3 = theme.Accent,
			})
			self.IconImage = triangleGlyph
		else
			local corner = CreateInstance("Frame", {
				Name = "Corner",
				Parent = iconButton,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, innerCornerSize, 0, innerCornerSize),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
			})

			CreateInstance("UICorner", {
				Parent = corner,
				CornerRadius = shape == "Square" and UDim.new(0, 4) or UDim.new(1, 0),
			})

			iconCornerStroke = CreateInstance("UIStroke", {
				Parent = corner,
				Color = theme.Accent,
				Thickness = 2,
				Transparency = 0,
			})
		end

		MakeDraggable(iconButton, iconButton)

		iconButton.MouseEnter:Connect(function()
			PlayTween(self, iconButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Size = UDim2.new(0, iconSize + 4, 0, iconSize + 4) })
		end)

		iconButton.MouseLeave:Connect(function()
			PlayTween(self, iconButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Size = UDim2.new(0, iconSize, 0, iconSize) })
		end)

		local iconDragged = false
		iconButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				iconDragged = false
			end
		end)

		iconButton.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				iconDragged = true
			end
		end)

		iconButton.MouseButton1Click:Connect(function()
			if not iconDragged then
				screenGui.Enabled = not screenGui.Enabled
			end
		end)
	end

	local minimizeKeyConnection
	if config.MinimizeKey then
		minimizeKeyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if self.Destroyed then
				return
			end
			if gameProcessed then
				return
			end
			if UserInputService:GetFocusedTextBox() then
				return
			end
			if input.KeyCode == config.MinimizeKey then
				screenGui.Enabled = not screenGui.Enabled
			end
		end)
	end

	self.ScreenGui = screenGui
	self.MainFrame = mainFrame
	self.MinimizeKeyConnection = minimizeKeyConnection
	self.Stroke = stroke
	self.TopBar = topBar
	self.TitleLabel = titleLabel
	self.DescLabel = descLabel
	self.TabsFrame = tabsFrame
	self.ContentFrame = contentFrame
	self.TabsVertical = verticalTabs
	self.TabsDivider = tabsDivider
	self.Tabs = {}
	self.TabOrderCounter = 0
	self.CurrentThemeName = currentThemeName
	self.SectionLabels = {}
	self.ScrollFrames = {}
	self.Flags = {}
	self.Pages = {}
	self.TabButtons = {}
	self.TabObjects = {}
	self.TabHasName = {}
	self.AllTabsIconOnly = true
	self.ActiveTabName = nil
	self.ResizeHandle = resizeHandle
	self.ResizeHandles = resizeHandles
	self.SearchRow = searchRow
	self.SearchIcon = searchIcon
	self.SearchBox = searchBox
	self.IconButton = iconButton
	self.IconFrameStroke = iconFrameStroke
	self.IconCornerStroke = iconCornerStroke
	self.BackgroundImage = backgroundImage
	self.BackgroundOverlay = backgroundOverlay
	self.AcrylicCleanup = acrylicCleanup
	self.WindowScale = windowScale
	self.StatsButton = statsButton
	self.ViewportConnection = viewportConnection
	self.CollapseButton = collapseButton
	self.MaximizeButton = maximizeButton
	self.CloseButton = windowCloseButton

	local closeConfirmOpen = false
	windowCloseButton.MouseButton1Click:Connect(function()
		if closeConfirmOpen or self.Destroyed then
			return
		end
		closeConfirmOpen = true

		self:Dialog({
			Title = "Close interface?",
			Content = "Are you sure you want to close this window?",
			Buttons = {
				{
					Title = "Close",
					Callback = function()
						if not self.Destroyed then
							self:Destroy()
						end
					end,
				},
				{
					Title = "Cancel",
					Callback = function()
						closeConfirmOpen = false
					end,
				},
			},
		})
	end)

	if searchIcon and searchBox then
		local searchOpen = false
		local searchHover = false

		local function RefreshSearchIcon()
			searchIcon.ImageColor3 = (searchHover or searchOpen) and self.Theme.Accent or self.Theme.DescColor
			PlayTween(self, searchIcon, TweenInfo.new(0.12), {
				BackgroundTransparency = (searchHover or searchOpen) and 0.85 or 1,
			})
		end

		local function setSearchOpen(open)
			searchOpen = open
			RefreshSearchIcon()

			if open then
				searchBox.Visible = true
				FadeTransparency({
					{ instance = searchBox, prop = "BackgroundTransparency", target = self.Theme.Transparency },
				}, 0.18, Enum.EasingDirection.Out, self)
				task.defer(function()
					searchBox:CaptureFocus()
				end)
			else
				FadeTransparency({
					{ instance = searchBox, prop = "BackgroundTransparency", target = 1 },
				}, 0.15, Enum.EasingDirection.In, self)

				task.delay(0.15, function()
					if not searchOpen then
						searchBox.Visible = false
					end
				end)

				searchBox.Text = ""
				for _, button in pairs(self.TabButtons) do
					button.Visible = true
				end
			end
		end

		searchIcon.MouseButton1Click:Connect(function()
			setSearchOpen(not searchOpen)
		end)

		searchIcon.MouseEnter:Connect(function()
			searchHover = true
			RefreshSearchIcon()
		end)

		searchIcon.MouseLeave:Connect(function()
			searchHover = false
			RefreshSearchIcon()
		end)

		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local query = searchBox.Text:lower()
			for tabName, button in pairs(self.TabButtons) do
				if query == "" then
					button.Visible = true
				else
					button.Visible = tabName:lower():find(query, 1, true) ~= nil
				end
			end
		end)

		searchBox.Focused:Connect(function()
			PlayTween(self, searchBoxStroke, TweenInfo.new(0.12), { Transparency = 0.1 })
		end)

		searchBox.FocusLost:Connect(function()
			PlayTween(self, searchBoxStroke, TweenInfo.new(0.12), { Transparency = 0.5 })
		end)

		table.insert(self.Controls, function(theme2)
			searchIcon.BackgroundColor3 = theme2.Secondary
			RefreshSearchIcon()
			searchBox.PlaceholderColor3 = theme2.DescColor
			searchBox.TextColor3 = theme2.TitleColor
			if searchBoxStroke then
				searchBoxStroke.Color = theme2.Accent
			end
			if searchOpen then
				searchBox.BackgroundColor3 = theme2.Secondary
			end
		end)
	end

	if not ErrorHookConnected then
		ErrorHookConnected = true

		local ok, ScriptContext = pcall(function()
			return game:GetService("ScriptContext")
		end)

		if ok and ScriptContext then
			ScriptContext.Error:Connect(function(message, trace, errScript)
				local scriptName = errScript and errScript.Name or "Unknown"

				self:Notify({
					Title = "Script Error",
					Content = tostring(message),
					SubContent = "Script: " .. tostring(scriptName),
					Duration = 7,
				})
			end)
		end
	end

	return self
end

function M:SetTheme(newTheme)
	local rawTheme = newTheme

	if type(newTheme) == "string" then
		local themeName = newTheme
		if themeName == "All" or themeName == "Random" then
			themeName = GetRandomPresetName()
		end
		self.CurrentThemeName = themeName
		rawTheme = Theme.Presets[themeName] or {}
	elseif type(newTheme) == "table" and newTheme.Accent and not newTheme.Background and not newTheme.Secondary then
		self.CurrentThemeName = nil
		local generated = GenerateThemeFromAccent(ToColor3(newTheme.Accent))
		for key, value in pairs(newTheme) do
			generated[key] = value
		end
		rawTheme = generated
	else
		self.CurrentThemeName = nil
	end

	local resolved = ResolveTheme(rawTheme)
	for key, value in pairs(resolved) do
		self.Theme[key] = value
	end

	self.Stroke.Color = self.Theme.Accent
	self.MainFrame.BackgroundColor3 = self.Theme.Background
	self.MainFrame.BackgroundTransparency = self.Theme.Transparency

	if self.BackgroundImage then
		self.BackgroundImage.ImageTransparency = self.Theme.Transparency
	end

	if self.BackgroundOverlay then
		self.BackgroundOverlay.BackgroundColor3 = self.Theme.Background
	end

	local topDivider = self.TopBar:FindFirstChild("Divider")
	if topDivider then
		topDivider.BackgroundColor3 = self.Theme.Accent
	end

	if self.TabsDivider then
		self.TabsDivider.BackgroundColor3 = self.Theme.Accent
	end

	self.TitleLabel.TextColor3 = self.Theme.TitleColor
	self.DescLabel.TextColor3 = self.Theme.DescColor

	for _, section in ipairs(self.SectionLabels) do
		if section and section.Parent then
			if section:IsA("ImageLabel") then
				section.ImageColor3 = self.Theme.SectionColor
			else
				section.TextColor3 = self.Theme.SectionColor
			end
		end
	end

	if self.IconButton then
		if self.IconButton.BackgroundTransparency ~= 1 then
			self.IconButton.BackgroundColor3 = self.Theme.Background
		end
		if self.IconFrameStroke then
			self.IconFrameStroke.Color = self.Theme.Accent
		end
		if self.IconCornerStroke then
			self.IconCornerStroke.Color = self.Theme.Accent
		end
	end

	for _, refresh in ipairs(self.Controls) do
		pcall(refresh, self.Theme)
	end

	for _, scrollFrame in ipairs(self.ScrollFrames) do
		if scrollFrame and scrollFrame.Parent then
			scrollFrame.ScrollBarImageColor3 = self.Theme.Accent
		end
	end

	if self.ActiveTabName then
		self:SelectTab(self.ActiveTabName)
	end
end

function M:SetTitle(text)
	self.TitleLabel.Text = text
end

function M:SetSubTitle(text)
	self.DescLabel.Text = text
end

function M:SetIcon(id)
	if not id or id == "" then
		return false
	end

	if self.IconImage then
		self.IconImage.Image = ResolveIcon(id)
		return true
	end

	return false
end

function M:SetAnimation(enabled)
	self.Animation = enabled ~= false
end

function M:SelectTab(name)
	if not self.Pages[name] then
		return
	end

	if self.ActiveTabName == name then
		return
	end

	local animated = (not self.AllTabsIconOnly) and self.Animation ~= false
	local previousName = self.ActiveTabName
	local previousPage = previousName and self.Pages[previousName]
	local newPage = self.Pages[name]

	self.ActiveTabName = name

	newPage.Visible = true
	local newCanvas = newPage:FindFirstChild("PageCanvas")

	if newCanvas then
		if animated then
			newCanvas.GroupTransparency = 1
			PlayTween(self, newCanvas, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 })
		else
			newCanvas.GroupTransparency = 0
		end
	end

	if previousPage and previousPage ~= newPage then
		local prevCanvas = previousPage:FindFirstChild("PageCanvas")
		if animated and prevCanvas then
			PlayTween(self, prevCanvas, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 1 })
			task.delay(0.15, function()
				if self.Pages[self.ActiveTabName] ~= previousPage then
					previousPage.Visible = false
				end
			end)
		else
			previousPage.Visible = false
			if prevCanvas then
				prevCanvas.GroupTransparency = 0
			end
		end
	end

	for tabName, button in pairs(self.TabButtons) do
		local active = tabName == name
		local content = button:FindFirstChild("Content")
		local indicator = button:FindFirstChild("Indicator")
		local icon = content and content:FindFirstChildOfClass("ImageLabel")
		local label = content and content:FindFirstChildOfClass("TextLabel")

		button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		button.BackgroundTransparency = active and 0.9 or 1

		if indicator then
			indicator.BackgroundColor3 = self.Theme.Accent
			local targetTransparency = active and 0 or 1
			local targetSize = active and UDim2.new(0, 3, 1, -12) or UDim2.new(0, 3, 0, 0)
			if animated then
				PlayTween(self, indicator, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					BackgroundTransparency = targetTransparency,
					Size = targetSize,
				})
			else
				indicator.BackgroundTransparency = targetTransparency
				indicator.Size = targetSize
			end
		end

		if icon then
			local targetIconColor = active and self.Theme.Accent or self.Theme.DescColor
			if animated then
				PlayTween(self, icon, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageColor3 = targetIconColor })
			else
				icon.ImageColor3 = targetIconColor
			end
		end

		if label then
			local targetLabelColor = active and self.Theme.TitleColor or self.Theme.DescColor
			if animated then
				PlayTween(self, label, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextColor3 = targetLabelColor })
			else
				label.TextColor3 = targetLabelColor
			end
		end
	end
end


function M:AddTab(tabConfig)
	tabConfig = tabConfig or {}

	if tabConfig[1] ~= nil then
		local created = {}
		for _, entry in ipairs(tabConfig) do
			local single = entry

			if typeof(entry) == "table" and not entry.Name and not entry.Title and not entry.Icon then
				single = { Name = entry[1], Icon = entry[2] }
			end

			local tabObject = self:AddTab(single)
			table.insert(created, tabObject)
			created[tabObject.Name] = tabObject
		end

		return created
	end

	local isBulkKeyed = false
	for key, value in pairs(tabConfig) do
		if typeof(value) == "table" and key ~= "Name" and key ~= "Title" and key ~= "Icon" then
			isBulkKeyed = true
			break
		end
	end

	if isBulkKeyed then
		local created = {}
		for key, entry in pairs(tabConfig) do
			local single = entry
			if typeof(entry) == "table" and not entry.Name and not entry.Title then
				single = { Name = key, Icon = entry.Icon }
			end

			local tabObject = self:AddTab(single)
			table.insert(created, tabObject)
			created[key] = tabObject
		end

		return created
	end

	local displayName = tabConfig.Name or tabConfig.Title
	local hasName = displayName ~= nil and displayName ~= ""
	local name = hasName and displayName or ("Tab " .. tostring(#self.Tabs + 1))
	local iconId = ResolveIcon(tabConfig.Icon)

	self.TabOrderCounter = self.TabOrderCounter + 1
	local tabOrder = self.TabOrderCounter

	local button = CreateInstance("TextButton", {
		Name = name,
		Parent = self.TabsFrame,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ClipsDescendants = true,
		AutomaticSize = self.TabsVertical and Enum.AutomaticSize.None or Enum.AutomaticSize.X,
		Size = self.TabsVertical and UDim2.new(1, 0, 0, 34) or UDim2.new(0, 0, 1, 0),
		LayoutOrder = tabOrder,
	})

	CreateInstance("UICorner", {
		Parent = button,
		CornerRadius = UDim.new(0, 8),
	})

	local indicator = CreateInstance("Frame", {
		Name = "Indicator",
		Parent = button,
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = self.Theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 3, 0, 0),
		ZIndex = 2,
	})

	CreateInstance("UICorner", {
		Parent = indicator,
		CornerRadius = UDim.new(1, 0),
	})

	local content = CreateInstance("Frame", {
		Name = "Content",
		Parent = button,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	})

	CreateInstance("UIPadding", {
		Parent = content,
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	CreateInstance("UIListLayout", {
		Parent = content,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = hasName and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	CreateInstance("ImageLabel", {
		Name = "Icon",
		Parent = content,
		BackgroundTransparency = 1,
		Image = iconId,
		ImageColor3 = self.Theme.DescColor,
		Size = UDim2.new(0, 18, 0, 18),
		LayoutOrder = 1,
	})

	if hasName then
		CreateInstance("TextLabel", {
			Name = "Label",
			Parent = content,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Font = Enum.Font.Gotham,
			Text = name,
			TextColor3 = self.Theme.DescColor,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 2,
		})
	end

	local page = CreateInstance("ScrollingFrame", {
		Name = name .. "Page",
		Parent = self.ContentFrame,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = self.Theme.Accent,
		ScrollBarImageTransparency = 0.3,
		BorderSizePixel = 0,
		Visible = false,
	})

	local pageCanvas = CreateInstance("CanvasGroup", {
		Name = "PageCanvas",
		Parent = page,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		GroupTransparency = 0,
	})

	CreateInstance("UIListLayout", {
		Parent = pageCanvas,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	CreateInstance("UIPadding", {
		Parent = pageCanvas,
		PaddingRight = UDim.new(0, 8),
	})

	table.insert(self.ScrollFrames, page)

	table.insert(self.Tabs, name)
	self.Pages[name] = page
	self.TabButtons[name] = button
	self.TabHasName[name] = hasName

	local allIconOnly = true
	for _, tabHasName in pairs(self.TabHasName) do
		if tabHasName then
			allIconOnly = false
			break
		end
	end
	self.AllTabsIconOnly = allIconOnly

	button.MouseEnter:Connect(function()
		if self.ActiveTabName ~= name then
			if self.AllTabsIconOnly then
				button.BackgroundTransparency = 0.95
			else
				PlayTween(self, button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = 0.95,
				})
			end
		end
	end)

	button.MouseLeave:Connect(function()
		if self.ActiveTabName ~= name then
			if self.AllTabsIconOnly then
				button.BackgroundTransparency = 1
			else
				PlayTween(self, button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = 1,
				})
			end
		end
	end)

	button.MouseButton1Click:Connect(function()
		self:SelectTab(name)
	end)

	if #self.Tabs == 1 then
		self:SelectTab(name)
	end

	local tabObject = setmetatable({
		Name = name,
		Page = page,
		ElementsRoot = pageCanvas,
		Button = button,
		Window = self,
	}, Tab)

	self.TabObjects[name] = tabObject

	return tabObject
end

function M:AddTapHover(config)
	config = config or {}
	local text = config.Name or config.Title or config.Text or ""

	self.TabOrderCounter = self.TabOrderCounter + 1
	local order = self.TabOrderCounter

	local holder = CreateInstance("Frame", {
		Name = "TapHover",
		Parent = self.TabsFrame,
		BackgroundTransparency = 1,
		Size = self.TabsVertical and UDim2.new(1, 0, 0, 22) or UDim2.new(0, 90, 1, 0),
		LayoutOrder = order,
	})

	local line = CreateInstance("Frame", {
		Name = "Line",
		Parent = holder,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = self.TabsVertical and UDim2.new(1, 0, 0, 1) or UDim2.new(1, -6, 0, 1),
		BackgroundColor3 = self.Theme.Accent,
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
	})

	local label
	if text ~= "" then
		label = CreateInstance("TextLabel", {
			Name = "Label",
			Parent = holder,
			BackgroundColor3 = self.Theme.Background,
			BackgroundTransparency = self.Theme.Transparency,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.new(0, 0, 0, 0),
			Font = Enum.Font.Gotham,
			Text = text,
			TextColor3 = self.Theme.DescColor,
			TextSize = 10,
			ZIndex = 2,
		})

		CreateInstance("UIPadding", {
			Parent = label,
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
		})
	end

	table.insert(self.Controls, function(theme2)
		line.BackgroundColor3 = theme2.Accent
		if label then
			label.BackgroundColor3 = theme2.Background
			label.BackgroundTransparency = theme2.Transparency
			label.TextColor3 = theme2.DescColor
		end
	end)

	return {
		Frame = holder,
		SetText = function(_, newText)
			if label then
				label.Text = newText or ""
			end
		end,
	}
end


function M:SafeFind(root, ...)
	local current = root
	local pathParts = {...}

	if not current then
		self:Notify({
			Title = "Path Error",
			Content = "The root you provided is nil",
			Duration = 6,
		})
		return nil
	end

	for _, part in ipairs(pathParts) do
		local ok, child = pcall(function()
			return current:WaitForChild(part, 3)
		end)

		if not ok or not child then
			self:Notify({
				Title = "Path Error",
				Content = 'Could not find "' .. tostring(part) .. '" inside ' .. tostring(current.Name),
				Duration = 6,
				})
			return nil
		end

		current = child
	end

	return current
end


function M:SafePlayer(nameOrUserId)
	local Players = game:GetService("Players")
	local player = nil

	if type(nameOrUserId) == "number" then
		local ok, result = pcall(function()
			return Players:GetPlayerByUserId(nameOrUserId)
		end)
		player = ok and result or nil
	else
		local ok, result = pcall(function()
			return Players:FindFirstChild(tostring(nameOrUserId))
		end)
		player = ok and result or nil
	end

	if not player then
		self:Notify({
			Title = "Player Error",
			Content = "No player found with name/id: " .. tostring(nameOrUserId),
			Duration = 6,
		})
		return nil
	end

	return player
end


function M:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true

	if self.ViewportConnection then
		self.ViewportConnection:Disconnect()
		self.ViewportConnection = nil
	end
	if self.MinimizeKeyConnection then
		self.MinimizeKeyConnection:Disconnect()
		self.MinimizeKeyConnection = nil
	end
	if self.AcrylicCleanup then
		self.AcrylicCleanup()
		self.AcrylicCleanup = nil
	end
	if self.IconButton and self.IconButton.Parent then
		self.IconButton.Parent:Destroy()
	end
	if self.NotifyGui then
		self.NotifyGui:Destroy()
		self.NotifyGui = nil
		self.NotifyContainers = nil
	end
	if self.DialogGui then
		self.DialogGui:Destroy()
		self.DialogGui = nil
	end
	if self.TooltipCleanups then
		for _, cleanup in ipairs(self.TooltipCleanups) do
			pcall(cleanup)
		end
		self.TooltipCleanups = nil
	end
	if self.TooltipGui then
		self.TooltipGui:Destroy()
		self.TooltipGui = nil
	end
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end
end


return M
end
