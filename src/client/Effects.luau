local shared = game:GetService("ReplicatedStorage").Shared
local Config = require(shared.GameConfig)
local Swing = require(script.Parent.PickSwing)
local Audio = require(script.Parent.HarborAudio)
local Tween = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Effects = {}
Effects.__index = Effects
local rng = Random.new()
function Effects.new()
	local self = setmetatable({ activeChips = 0, lastBurst = 0, markers = {} }, Effects)
	local preview = Instance.new("ScreenGui")
	preview.Name, preview.ResetOnSpawn = "MiningSelection", false
	preview.ScreenInsets, preview.DisplayOrder = Enum.ScreenInsets.None, -1
	preview.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
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
function Effects:swing(miner)
	local character = miner and miner.Character
	local rig = Swing.new(character)
	if not rig then
		return
	end
	task.spawn(function()
		local start = os.clock()
		while character.Parent and os.clock() - start < 0.17 do
			rig:pose(math.min((os.clock() - start) / 0.17, 1))
			game:GetService("RunService").Heartbeat:Wait()
		end
		rig:reset()
	end)
end
-- Project the eight real cell corners so even buried edges are visible.
local corners, edges = {}, {}
local half = Config.Cell * 0.5 - 0.04
for index = 0, 7 do
	local x, y, z = bit32.band(index, 1), bit32.band(index, 2), bit32.band(index, 4)
	corners[index + 1] =
		Vector3.new(if x == 0 then -half else half, if y == 0 then -half else half, if z == 0 then -half else half)
	for _, bit in { 1, 2, 4 } do
		if bit32.band(index, bit) == 0 then
			table.insert(edges, { index + 1, index + bit + 1 })
		end
	end
end

local function newMarker(parent)
	local group = Instance.new("Folder")
	group.Name, group.Parent = "Selected block", parent
	local lines = {}
	for i = 1, #edges do
		local line = Instance.new("Frame")
		line.Name, line.AnchorPoint = "Edge", Vector2.new(0.5, 0.5)
		line.BackgroundColor3 = Color3.fromRGB(127, 255, 227)
		line.BorderSizePixel = 1
		line.BorderColor3 = Color3.fromRGB(21, 78, 93)
		line.Parent = group
		lines[i] = line
	end
	return { group = group, lines = lines, points = {} }
end

function Effects:aim(cells)
	local count = if cells then #cells else 0
	for i = count + 1, #self.markers do
		self.markers[i].group.Parent = nil
	end
	if count == 0 then
		return
	end
	local camera = workspace.CurrentCamera
	local thickness = math.clamp(math.round(camera.ViewportSize.Y / 360), 2, 4)
	for i, center in cells do
		local marker = self.markers[i] or newMarker(self.preview)
		self.markers[i] = marker
		marker.group.Parent = self.preview
		for k, corner in corners do
			marker.points[k] = camera:WorldToViewportPoint(center + corner)
		end
		for k, pair in edges do
			local a, b = marker.points[pair[1]], marker.points[pair[2]]
			local line = marker.lines[k]
			line.Visible = a.Z > 0.1 and b.Z > 0.1
			if line.Visible then
				local delta = Vector2.new(b.X - a.X, b.Y - a.Y)
				line.Position = UDim2.fromOffset((a.X + b.X) * 0.5, (a.Y + b.Y) * 0.5)
				line.Size = UDim2.fromOffset(delta.Magnitude, thickness)
				line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
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
