local shared = game:GetService("ReplicatedStorage").Shared
local Config = require(shared.GameConfig)
local Audio = require(script.Parent.HarborAudio)
local Tween = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Effects = {}
Effects.__index = Effects
local rng = Random.new()
function Effects.new()
	local self = setmetatable({ activeChips = 0, lastBurst = 0, markers = {} }, Effects)
	local preview = Instance.new("Folder")
	preview.Name, preview.Parent = "MiningSelection", workspace
	self.preview = preview
	local impact = Instance.new("Sound")
	impact.Name, impact.SoundId, impact.Volume, impact.Parent =
		"Rock impact", "rbxasset://sounds/action_jump_land.mp3", 0.19, SoundService
	self.impact = impact
	local sparkOrigin = Instance.new("Attachment")
	sparkOrigin.Name, sparkOrigin.Parent = "Quarry discovery", workspace.Terrain
	local glints = Instance.new("ParticleEmitter")
	glints.Texture, glints.Rate, glints.LightEmission = "rbxasset://textures/particles/sparkles_main.dds", 0, 1
	glints.Lifetime, glints.Speed = NumberRange.new(0.28, 0.48), NumberRange.new(2, 8)
	glints.SpreadAngle, glints.Size = Vector2.new(120, 120), NumberSequence.new(0.75, 0)
	glints.Parent = sparkOrigin
	self.glints, self.sparkOrigin = glints, sparkOrigin
	return self
end
function Effects:chime(pitch)
	Audio.reward(pitch)
end
local function newMarker()
	local model = Instance.new("Model")
	model.Name = "Selected block"
	local width = 0.085
	local half = Config.Cell * 0.5
	-- Real edges share the same depth buffer as the mined rock, including the
	-- selected cell itself. The rock hides the back edges and any buried edges.
	for _, axis in { Vector3.xAxis, Vector3.yAxis, Vector3.zAxis } do
		local across = Vector3.new(axis.Z, axis.X, axis.Y)
		local up = axis:Cross(across)
		for _, a in { -half, half } do
			for _, b in { -half, half } do
				local edge = Instance.new("Part")
				edge.Name, edge.Anchored, edge.CastShadow = "Edge", true, false
				edge.CanCollide, edge.CanTouch, edge.CanQuery = false, false, false
				edge.Material, edge.Color = Enum.Material.Neon, Color3.fromRGB(68, 220, 186)
				edge.Size = axis * Config.Cell + (Vector3.one - axis) * width
				edge.Position, edge.Parent = across * a + up * b, model
			end
		end
	end
	model.WorldPivot = CFrame.identity
	return model
end

function Effects:aim(cells)
	local count = if cells then #cells else 0
	for i = count + 1, self.visibleCount or 0 do
		self.markers[i].Parent = nil
	end
	self.visibleCount = count
	if cells then
		for i, center in cells do
			local marker = self.markers[i]
			if not marker then
				marker = newMarker()
				self.markers[i] = marker
			end
			if marker:GetPivot().Position ~= center then
				marker:PivotTo(CFrame.new(center))
			end
			if not marker.Parent then
				marker.Parent = self.preview
			end
		end
	end
end
function Effects:burst(point, spread, ore, quiet)
	local now = os.clock()
	if now - self.lastBurst < 0.085 then
		return
	end
	self.lastBurst = now
	local camera = workspace.CurrentCamera
	local outward = if camera and (camera.CFrame.Position - point).Magnitude > 0.1
		then (camera.CFrame.Position - point).Unit
		else Vector3.yAxis
	local rare = ore.hardness >= 4
	if rare then
		self.sparkOrigin.WorldPosition = point + outward * 3
		self.glints.Color = ColorSequence.new(ore.color, Color3.new(1, 1, 1))
		self.glints:Emit(9)
	end
	if not quiet then
		self.impact.PlaybackSpeed = rng:NextNumber(1.25, 1.55)
		SoundService:PlayLocalSound(self.impact)
		if rare then
			self:chime(1.7)
		end
	end
	for i = 1, math.min(if rare then 10 else 6, 28 - self.activeChips) do
		local chip = Instance.new("Part")
		chip.Name, chip.Anchored, chip.CanCollide, chip.CanTouch, chip.CanQuery, chip.CastShadow =
			"Ore chip", true, false, false, false, false
		local size = rng:NextNumber(0.55, 1.05) * (if rare then 1.25 else 1)
		chip.Size, chip.Color, chip.Material =
			Vector3.new(size * 1.65, size * 0.72, size),
			ore.color,
			if rare and i % 2 == 0 then Enum.Material.Neon else Enum.Material.Plastic
		chip.TopSurface, chip.BottomSurface = Enum.SurfaceType.Studs, Enum.SurfaceType.Smooth
		local drift = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.3, 1), rng:NextNumber(-1, 1))
		local start = point + outward * 2.5 + drift * math.min(spread * 0.5, 4)
		chip.CFrame = CFrame.new(start) * CFrame.Angles(i, 0, i * 0.7)
		chip.Parent = workspace
		self.activeChips += 1
		chip.Destroying:Once(function()
			self.activeChips -= 1
		end)
		local finish = CFrame.new(start + drift * 3 + outward * 3 + Vector3.yAxis) * CFrame.Angles(i * 0.4, i, i * 0.7)
		Tween:Create(
			chip,
			TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = finish, Size = Vector3.one * 0.09, Transparency = 1 }
		):Play()
		Debris:AddItem(chip, 0.36)
	end
end
return Effects
