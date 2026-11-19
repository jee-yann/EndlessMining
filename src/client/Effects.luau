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
-- A hand-drawn, 24-pixel fault. Digits mark the impact that exposes each chip.
-- Contiguous pixels share a rectangle. The studs show through the blank cells.
local fault = {
	"...4....................",
	"...44...................",
	"....44..................",
	".....4..................",
	".....333................",
	".......33...............",
	"........3............4..",
	"........22..........44..",
	".......222..........4...",
	".......22.........333...",
	"........1111......3.....",
	"..........111.....2.....",
	"........111111..222.....",
	".......222..11111.......",
	".......2......11........",
	"....2222......22........",
	"....33........2222......",
	"...33...........22......",
	"4444.............3......",
	".................333....",
	"..................33....",
	"..................44....",
	"...................44...",
	"....................4...",
}
local function facePrint(part, face, group, turn)
	local size = #fault
	local gui = Instance.new("SurfaceGui")
	gui.Name, gui.Face, gui.Adornee = face.Name, face, part
	gui.SizingMode, gui.CanvasSize = Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(size, size)
	gui.AlwaysOnTop, gui.LightInfluence, gui.ZOffset = false, 1, 0
	gui.Parent = group
	local strokes = {}
	local ink = part.Color:Lerp(Color3.fromRGB(17, 16, 23), 0.83)
	for row, pixels in fault do
		local col = 1
		while col <= size do
			local mark = pixels:sub(col, col)
			local stop = col + 1
			while stop <= size and pixels:sub(stop, stop) == mark do
				stop += 1
			end
			if mark ~= "." then
				local x, y, w, h = col - 1, row - 1, stop - col, 1
				for _ = 1, turn do
					x, y, w, h = size - y - h, x, h, w
				end
				local chip = Instance.new("Frame")
				chip.Name, chip.BorderSizePixel, chip.BackgroundColor3 = "Fault", 0, ink
				chip.Position, chip.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
				chip.BackgroundTransparency, chip.Visible, chip.Parent = 0.08, false, gui
				table.insert(strokes, { bar = chip, stage = tonumber(mark) })
			end
			col = stop
		end
	end
	return strokes
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
	local stage = math.min(4, 1 + math.floor(progress * 4))
	local mask = part:GetAttribute("OpenFaces") or 0
	if self.crackStep == stage and self.crackMask == mask then
		return
	end
	self.crackStep, self.crackMask = stage, mask
	local cell = (part.Position / Config.Cell):Floor()
	for _, face in Enum.NormalId:GetEnumItems() do
		if not bit32.btest(mask, bit32.lshift(1, face.Value)) then
			continue
		end
		if not self.inkFaces[face] then
			self.inkFaces[face] = facePrint(part, face, self.fracture, (cell.X + cell.Y + cell.Z + face.Value) % 4)
		end
		for _, stroke in self.inkFaces[face] do
			stroke.bar.Visible = stroke.stage <= stage
		end
	end
end
-- One label per ore in a cut, anchored at a cell that actually yielded that ore.
function Effects:labels(finds, loot, normal, distant)
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
			Enum.Font.FredokaOne,
			"+" .. loot[name] .. " " .. (if distant
					and ore.secret
					and not game.Players.LocalPlayer:GetAttribute("Found" .. name)
				then "???"
				else name),
			ore.color:Lerp(Color3.new(1, 1, 1), 0.38)
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
