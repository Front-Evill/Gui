local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Utils = require(script.Parent.Utils)
local CreateInstance = Utils.CreateInstance

local ActiveAcrylicCount = 0

local function EnableAcrylicLighting()
	ActiveAcrylicCount = ActiveAcrylicCount + 1

	local existing = Lighting:FindFirstChild("VantaAcrylicDOF")
	if existing then
		return
	end

	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "VantaAcrylicDOF"
	dof.FarIntensity = 1
	dof.NearIntensity = 1
	dof.InFocusRadius = 0.05
	dof.FocusDistance = 0.05
	dof.Parent = Lighting
end

local function DisableAcrylicLighting()
	ActiveAcrylicCount = math.max(0, ActiveAcrylicCount - 1)

	if ActiveAcrylicCount == 0 then
		local existing = Lighting:FindFirstChild("VantaAcrylicDOF")
		if existing then
			existing:Destroy()
		end
	end
end

local function CreateGlassPart()
	local part = Instance.new("Part")
	part.Name = "VantaGlass"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CastShadow = false
	part.Locked = true
	part.Material = Enum.Material.SmoothPlastic
	part.Reflectance = 0
	part.Color = Color3.new(0, 0, 0)
	part.Transparency = 0.98
	part.Size = Vector3.new(1, 1, 0)

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Brick
	mesh.Offset = Vector3.new(0, 0, -0.0001)
	mesh.Parent = part

	return part, mesh
end

local function AttachAcrylicGlass(frame, screenGui)
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end

	local part, mesh = CreateGlassPart()
	part.Parent = camera

	local distance = 0.05
	local inset = 3
	local connections = {}
	local running = true

	local lastCamCFrame = nil
	local lastCamFOV = nil
	local lastAbsPos = nil
	local lastAbsSize = nil

	local function project(point2D)
		local cam = Workspace.CurrentCamera
		if not cam then
			return Vector3.new()
		end
		local ray = cam:ScreenPointToRay(point2D.X, point2D.Y)
		return ray.Origin + ray.Direction * distance
	end

	local function recompute(cam, absPos, absSize)
		local topLeft = absPos + Vector2.new(inset, inset)
		local topRight = topLeft + Vector2.new(math.max(absSize.X - inset * 2, 1), 0)
		local bottomRight = topLeft + Vector2.new(math.max(absSize.X - inset * 2, 1), math.max(absSize.Y - inset * 2, 1))

		local p1 = project(topLeft)
		local p2 = project(topRight)
		local p3 = project(bottomRight)

		local width = (p2 - p1).Magnitude
		local height = (p2 - p3).Magnitude

		part.CFrame = CFrame.fromMatrix((p1 + p3) / 2, cam.CFrame.XVector, cam.CFrame.YVector, cam.CFrame.ZVector)
		mesh.Scale = Vector3.new(width, height, 0)
	end

	local function update()
		if not running or not screenGui.Enabled then
			return
		end

		local cam = Workspace.CurrentCamera
		if not cam or not part.Parent then
			return
		end

		local absPos = frame.AbsolutePosition
		local absSize = frame.AbsoluteSize

		if lastCamCFrame == cam.CFrame
			and lastCamFOV == cam.FieldOfView
			and lastAbsPos == absPos
			and lastAbsSize == absSize
		then
			return
		end

		local ok = pcall(recompute, cam, absPos, absSize)

		if ok then
			lastCamCFrame = cam.CFrame
			lastCamFOV = cam.FieldOfView
			lastAbsPos = absPos
			lastAbsSize = absSize
		else
			part.Transparency = 1
		end
	end

	connections[#connections + 1] = RunService.RenderStepped:Connect(update)

	connections[#connections + 1] = screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
		part.Transparency = screenGui.Enabled and 0.98 or 1
		if screenGui.Enabled then
			lastCamCFrame = nil
			update()
		end
	end)

	local function cleanup()
		running = false
		for _, connection in ipairs(connections) do
			pcall(function()
				connection:Disconnect()
			end)
		end
		if part then
			part:Destroy()
		end
	end

	frame.Destroying:Connect(cleanup)
	update()

	return part, cleanup
end

return {
	EnableAcrylicLighting = EnableAcrylicLighting,
	DisableAcrylicLighting = DisableAcrylicLighting,
	AttachAcrylicGlass = AttachAcrylicGlass,
}
