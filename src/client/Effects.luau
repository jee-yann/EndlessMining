local shared = game:GetService("ReplicatedStorage").Shared
local Config = require(shared.GameConfig)
local Ores = require(shared.Ores)
local Audio = require(script.Parent.HarborAudio)
local Tween = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Effects = {}
Effects.__index = Effects
local rng = Random.new()
function Effects.new()
	local self = setmetatable({ activeChips = 0, lastBurst = 0, markers = {} }, Effects)
	local preview = Instance.new("Folder")
	preview.Name, preview.Parent = "MiningSelection", workspace
	self.preview = preview
	local sparkOrigin = Instance.new("Attachment")
	sparkOrigin.Name, sparkOrigin.Parent = "Ore discovery", workspace.Terrain
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
-- Surface ink has no thickness. Four fissures advance together and meet the
-- adjoining faces at their edge midpoints. The rock owns the ink's lifetime.
local branches = {
	{ Vector2.new(64, 64), Vector2.new(59, 48), Vector2.new(72, 29), Vector2.new(64, 0) },
	{ Vector2.new(64, 64), Vector2.new(82, 69), Vector2.new(103, 56), Vector2.new(128, 64) },
	{ Vector2.new(64, 64), Vector2.new(70, 80), Vector2.new(57, 101), Vector2.new(64, 128) },
	{ Vector2.new(64, 64), Vector2.new(45, 57), Vector2.new(28, 69), Vector2.new(0, 64) },
}
local function segment(gui, a, b, start, finish, width)
	local bar = Instance.new("Frame")
	bar.Name = "Fissure"
	bar.BackgroundColor3, bar.BackgroundTransparency, bar.BorderSizePixel = Color3.fromRGB(42, 32, 36), 0.12, 0
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	local delta = b - a
	bar.Rotation = math.deg(math.atan2(delta.Y, delta.X))
	bar.Visible = false
	bar.Parent = gui
	return { bar = bar, a = a, delta = delta, length = delta.Magnitude, start = start, finish = finish, width = width }
end
function Effects:clearDamage()
	if self.fracture then
		self.fracture:Destroy()
	end
	self.fracture, self.cracked, self.inkFaces, self.crackStep = nil, nil, nil, nil
end
function Effects:damage(part, progress)
	if not part or not part.Parent or progress <= 0 then
		self:clearDamage()
		return
	end
	if self.cracked ~= part then
		self:clearDamage()
		local group = Instance.new("Folder")
		group.Name, group.Parent = "Fractures", part
		self.fracture, self.cracked, self.inkFaces = group, part, {}
	end
	local step = math.min(32, math.ceil(progress * 32))
	local mask = part:GetAttribute("OpenFaces") or 0
	if self.crackStep == step and self.crackMask == mask then
		return
	end
	self.crackStep, self.crackMask = step, mask
	for _, face in Enum.NormalId:GetEnumItems() do
		if not bit32.btest(mask, bit32.lshift(1, face.Value)) then
			continue
		end
		local lines = self.inkFaces[face]
		if not lines then
			local gui = Instance.new("SurfaceGui")
			gui.Name, gui.Face, gui.Adornee = face.Name, face, part
			gui.SizingMode, gui.CanvasSize = Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(128, 128)
			gui.AlwaysOnTop, gui.LightInfluence, gui.ZOffset = false, 1, 0
			gui.Parent = self.fracture
			lines = {}
			for _, path in branches do
				for j = 1, 3 do
					table.insert(lines, segment(gui, path[j], path[j + 1], (j - 1) / 3, j / 3, 2.8 - 0.45 * j))
				end
				local d = path[3] - path[2]
				table.insert(lines, segment(gui, path[2], path[2] + Vector2.new(-d.Y, d.X) * 0.74, 0.39, 0.83, 1.35))
			end
			self.inkFaces[face] = lines
		end
		for _, line in lines do
			local t = math.clamp((step / 32 - line.start) / (line.finish - line.start), 0, 1)
			local mid = line.a + line.delta * (0.5 * t)
			line.bar.Visible = t > 0
			line.bar.Position = UDim2.fromOffset(mid.X, mid.Y)
			line.bar.Size = UDim2.fromOffset(line.length * t + 0.45, line.width)
		end
	end
end
-- One label per ore in a cut, anchored at a cell that actually yielded that ore.
function Effects:labels(finds, loot, normal)
	for name, center in finds do
		local ore = Ores.byName[name]
		local anchor = Instance.new("Attachment")
		anchor.Name, anchor.Parent = "Ore find", workspace.Terrain
		anchor.WorldPosition = center + normal * (Config.Cell * 0.5)
		local gui = Instance.new("BillboardGui")
		gui.Name, gui.Size, gui.MaxDistance, gui.LightInfluence = "Ore popup", UDim2.fromScale(6.8, 1.35), 64, 0
		gui.StudsOffsetWorldSpace = Vector3.new(0, 0.3, 0)
		gui.Parent = anchor
		local label = Instance.new("TextLabel")
		label.Size, label.BackgroundTransparency, label.TextScaled = UDim2.fromScale(1, 1), 1, true
		label.Font, label.Text, label.TextColor3 =
			Enum.Font.FredokaOne, "+" .. loot[name] .. " " .. name, ore.color:Lerp(Color3.new(1, 1, 1), 0.38)
		local outline = Instance.new("UIStroke")
		outline.Color, outline.Thickness, outline.Parent = Color3.fromRGB(38, 49, 76), 2, label
		label.Parent = gui
		Tween:Create(
			gui,
			TweenInfo.new(1.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ StudsOffsetWorldSpace = Vector3.new(0, 1.9, 0) }
		):Play()
		local fade = TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.58)
		Tween:Create(label, fade, { TextTransparency = 1 }):Play()
		Tween:Create(outline, fade, { Transparency = 1 }):Play()
		Debris:AddItem(anchor, 1.08)
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
