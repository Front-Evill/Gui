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
	part.CanTouch = false
	part.CastShadow = false
	part.Locked = true
	part.Material = Enum.Material.Glass
	part.Reflectance = 0.05
	part.Color = Color3.new(1, 1, 1)
	part.Transparency = 0.92
	part.Size = Vector3.new(1, 1, 0)

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Brick
	mesh.Offset = Vector3.new(0, 0, -0.0001)
	mesh.Parent = part

	return part, mesh
end

local function AttachAcrylicGlass(frame, screenGui)
	local part, mesh = CreateGlassPart()

	local distance = 0.05
	local inset = 3
	local connections = {}
	local running = true

	local lastCamCFrame = nil
	local lastCamFOV = nil
	local lastAbsPos = nil
	local lastAbsSize = nil

	local function project(cam, point2D)
		local ok, ray = pcall(function()
			return cam:ScreenPointToRay(point2D.X, point2D.Y)
		end)
		if not ok then
			return Vector3.new()
		end
		return ray.Origin + ray.Direction * distance
	end

	local function recompute(cam, absPos, absSize)
		local topLeft = absPos + Vector2.new(inset, inset)
		local topRight = topLeft + Vector2.new(math.max(absSize.X - inset * 2, 1), 0)
		local bottomRight = topLeft + Vector2.new(math.max(absSize.X - inset * 2, 1), math.max(absSize.Y - inset * 2, 1))

		local p1 = project(cam, topLeft)
		local p2 = project(cam, topRight)
		local p3 = project(cam, bottomRight)

		local width = (p2 - p1).Magnitude
		local height = (p2 - p3).Magnitude

		part.CFrame = CFrame.fromMatrix((p1 + p3) / 2, cam.CFrame.XVector, cam.CFrame.YVector, cam.CFrame.ZVector)
		mesh.Scale = Vector3.new(width, height, 0)
	end

	local function ensureParented()
		local cam = Workspace.CurrentCamera
		if cam and part.Parent ~= cam then
			pcall(function()
				part.Parent = cam
			end)
		end
		return cam
	end

	local function update()
		if not running or not screenGui.Enabled then
			return
		end

		local cam = ensureParented()
		if not cam then
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
			pcall(function()
				part.Transparency = 1
			end)
		end
	end

	connections[#connections + 1] = RunService.RenderStepped:Connect(update)

	-- Some games swap or recreate Workspace.CurrentCamera (respawns, cutscenes,
	-- custom camera scripts). Re-parent the glass part whenever that happens
	-- instead of silently losing the effect.
	connections[#connections + 1] = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		lastCamCFrame = nil
		ensureParented()
		update()
	end)

	connections[#connections + 1] = screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
		pcall(function()
			part.Transparency = screenGui.Enabled and 0.92 or 1
		end)
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
		pcall(function()
			part:Destroy()
		end)
	end

	frame.Destroying:Connect(cleanup)
	ensureParented()
	update()

	return part, cleanup
end

return {
	EnableAcrylicLighting = EnableAcrylicLighting,
	DisableAcrylicLighting = DisableAcrylicLighting,
	AttachAcrylicGlass = AttachAcrylicGlass,
}
