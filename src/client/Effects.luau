local Tween = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Effects = {}
Effects.__index = Effects
local rng = Random.new()
function Effects.new(aimGui)
	local self = setmetatable({ activeChips = 0, lastBurst = 0 }, Effects)
	local ring = Instance.new("Frame")
	ring.Name, ring.AnchorPoint, ring.BorderSizePixel = "BrushRadius", Vector2.new(0.5, 0.5), 0
	ring.BackgroundColor3, ring.BackgroundTransparency = Color3.fromRGB(89, 232, 224), 0.965
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(1, 0), ring
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness, stroke.Transparency, stroke.Parent =
		ring.BackgroundColor3, 2, 0.18, ring
	ring.Visible, ring.Parent = false, aimGui
	self.ring = ring
	local impact = Instance.new("Sound")
	impact.Name, impact.SoundId, impact.Volume, impact.Parent =
		"Rock impact", "rbxasset://sounds/action_jump_land.mp3", 0.19, SoundService
	local coin = Instance.new("Sound")
	coin.Name, coin.SoundId, coin.Volume, coin.Parent =
		"Quarry reward", "rbxasset://sounds/volume_slider.ogg", 0.21, SoundService
	self.impact, self.coin = impact, coin
	local sparkOrigin = Instance.new("Attachment")
	sparkOrigin.Name, sparkOrigin.Parent = "Quarry discovery", workspace.Terrain
	local glints = Instance.new("ParticleEmitter")
	glints.Texture, glints.Rate, glints.LightEmission =
		"rbxasset://textures/particles/sparkles_main.dds", 0, 1
	glints.Lifetime, glints.Speed = NumberRange.new(0.28, 0.48), NumberRange.new(2, 8)
	glints.SpreadAngle, glints.Size = Vector2.new(120, 120), NumberSequence.new(0.75, 0)
	glints.Parent = sparkOrigin
	self.glints, self.sparkOrigin = glints, sparkOrigin
	return self
end
function Effects:chime(pitch)
	self.coin.PlaybackSpeed = pitch
	SoundService:PlayLocalSound(self.coin)
end
function Effects:aim(point, radius)
	local camera = workspace.CurrentCamera
	self.ring.Visible = point ~= nil and camera ~= nil
	if not self.ring.Visible then
		return
	end
	local screen = camera:WorldToViewportPoint(point)
	if screen.Z <= 0.1 then
		self.ring.Visible = false
		return
	end
	local edge = camera:WorldToViewportPoint(point + camera.CFrame.RightVector * radius)
	local diameter = 2 * math.abs(edge.X - screen.X)
	self.ring.Position = UDim2.fromOffset(screen.X, screen.Y)
	self.ring.Size = UDim2.fromOffset(diameter, diameter)
end
function Effects:burst(point, radius, ore, quiet)
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
		local start = point + outward * 2.5 + drift * math.min(radius * 0.5, 4)
		chip.CFrame = CFrame.new(start) * CFrame.Angles(i, 0, i * 0.7)
		chip.Parent = workspace
		self.activeChips += 1
		chip.Destroying:Once(function()
			self.activeChips -= 1
		end)
		local finish = CFrame.new(start + drift * 3 + outward * 3 + Vector3.yAxis)
			* CFrame.Angles(i * 0.4, i, i * 0.7)
		Tween:Create(
			chip,
			TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = finish, Size = Vector3.one * 0.09, Transparency = 1 }
		):Play()
		Debris:AddItem(chip, 0.36)
	end
end
return Effects
