local Run = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local View = {}
function View.start(player, origin)
	local daylight = Lighting.Ambient
	local cave = Color3.fromRGB(31, 30, 43)
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name, grade.Parent = "Underground light", Lighting
	local curtain = Instance.new("ScreenGui")
	curtain.Name, curtain.ScreenInsets, curtain.ResetOnSpawn, curtain.DisplayOrder =
		"Inside rock", Enum.ScreenInsets.None, false, -1
	local dark = Instance.new("Frame")
	dark.Size, dark.BackgroundColor3, dark.BorderSizePixel = UDim2.fromScale(1, 1), Color3.fromRGB(32, 26, 30), 0
	dark.Parent = curtain
	curtain.Enabled, curtain.Parent = false, player:WaitForChild("PlayerGui")
	local overlap = OverlapParams.new()
	overlap.FilterType, overlap.MaxParts = Enum.RaycastFilterType.Include, 1
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Include
	local grid, shade = nil, 0
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
		if not root or not camera or pos.Z > 40 or math.abs(pos.X) > 120 then
			curtain.Enabled = false
			return
		end
		if not grid or not grid.Parent then
			local island = workspace:FindFirstChild("CitrineCove")
			grid = island and island:FindFirstChild("MineBlocks")
			if not grid then
				curtain.Enabled = false
				return
			end
			ray.FilterDescendantsInstances = { grid }
			overlap.FilterDescendantsInstances = { grid }
		end
		-- Keep the near clipping plane on the player's side of a solid wall.
		local eye = root.Position + Vector3.yAxis * math.min(1.3, root.Size.Y * 0.6)
		local view = camera.CFrame
		local delta = view.Position - eye
		local hit = if delta.Magnitude > 0.04 then workspace:Spherecast(eye, 0.32, delta, ray) else nil
		if hit then
			camera.CFrame = view.Rotation + (eye + delta.Unit * math.max(0, hit.Distance - 0.12))
		end
		local near = camera.CFrame * CFrame.new(0, 0, -0.25)
		curtain.Enabled = #workspace:GetPartBoundsInBox(near, Vector3.new(0.46, 0.38, 0.38), overlap) > 0
			or #workspace:GetPartBoundsInBox(CFrame.new(eye), Vector3.one * 0.18, overlap) > 0
	end)
end
return View
