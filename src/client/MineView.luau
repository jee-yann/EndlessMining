local Run = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local View = {}
function View.start(player, origin)
	local daylight = Lighting.Ambient
	local cave = Color3.fromRGB(31, 30, 43)
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name, grade.Parent = "Underground light", Lighting
	local overlap = OverlapParams.new()
	overlap.FilterType, overlap.MaxParts = Enum.RaycastFilterType.Include, 1
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Include
	local grid, shade = nil, 0
	local previousEye, previousChar
	local function clearance(eye, radius)
		local block = workspace:GetPartBoundsInBox(CFrame.new(eye), Vector3.one * (2 * radius), overlap)[1]
		if not block then
			return eye
		end
		if
			previousEye
			and (eye - previousEye).Magnitude < 5
			and #workspace:GetPartBoundsInBox(CFrame.new(previousEye), Vector3.one * (2 * radius), overlap) == 0
		then
			return previousEye
		end
		local best, distance = nil, math.huge
		for _, face in Enum.NormalId:GetEnumItems() do
			if bit32.btest(block:GetAttribute("OpenFaces") or 0, bit32.lshift(1, face.Value)) then
				local n = Vector3.FromNormalId(face)
				local half = block.Size / 2
				local at = (eye - block.Position):Max(-half + Vector3.one * radius):Min(half - Vector3.one * radius)
				local candidate = block.Position
					+ at * (Vector3.one - n:Abs())
					+ n * (half + Vector3.one * (radius + 0.03))
				local d = (candidate - eye).Magnitude
				if
					d < distance
					and #workspace:GetPartBoundsInBox(CFrame.new(candidate), Vector3.one * (2 * radius), overlap)
						== 0
				then
					best, distance = candidate, d
				end
			end
		end
		return best or previousEye or eye
	end
	Run:BindToRenderStep("Mine enclosure", Enum.RenderPriority.Camera.Value + 2, function(dt)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local camera = workspace.CurrentCamera
		local pos = if root then root.Position - origin else Vector3.zero
		local inside = root ~= nil and Config.inMine(pos)
		local target = if inside then math.clamp(math.max((-pos.Z - 3) / 20, -pos.Y / 12), 0, 1) else 0
		if shade ~= target then
			shade += (target - shade) * (1 - math.exp(-dt * 5))
			if math.abs(shade - target) < 0.002 then
				shade = target
			end
			Lighting.Ambient = daylight:Lerp(cave, shade)
			grade.Brightness = -0.075 * shade
			grade.TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(229, 230, 245), shade)
		end
		if char ~= previousChar then
			previousEye, previousChar = nil, char
		end
		if not root or not camera or not inside then
			previousEye = nil
			return
		end
		if not grid or not grid.Parent then
			local island = workspace:FindFirstChild("CitrineCove")
			grid = island and island:FindFirstChild("MineBlocks")
			if not grid then
				return
			end
			ray.FilterDescendantsInstances = { grid }
			overlap.FilterDescendantsInstances = { grid }
		end
		-- Keep the near clipping plane on the player's side of a solid wall.
		local head = char:FindFirstChild("Head")
		if not head then
			return
		end
		local near = math.abs(camera.NearPlaneZ)
		local radius = math.clamp(
			near
				* (
					1
					+ math.tan(math.rad(camera.FieldOfView / 2))
						* camera.ViewportSize.X
						/ math.max(1, camera.ViewportSize.Y)
				),
			0.4,
			1.1
		)
		local eye = clearance(head.Position, radius)
		previousEye = eye
		local view = camera.CFrame
		local delta = view.Position - eye
		local hit = if delta.Magnitude > 0.015 then workspace:Spherecast(eye, radius, delta, ray) else nil
		local point = if hit
			then eye + delta.Unit * math.max(0, hit.Distance - 0.06)
			else clearance(view.Position, radius)
		if (point - view.Position).Magnitude > 0.005 then
			camera.CFrame = view.Rotation + point
		end
	end)
end
return View
