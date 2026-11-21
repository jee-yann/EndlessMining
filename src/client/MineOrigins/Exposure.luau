-- Graphic exposures are rendered from native triangles in a camera-facing
-- viewport. The drawing scales with the screen and needs no uploaded texture.
local P = require(script.Parent.Props)
local Beats = require(script.Parent.Beats)
local ease, rgb, V = P.ease, Color3.fromHex, Vector3.new
local Exposure = {}
Exposure.__index = Exposure
local black, ink, paper, edge, lilac = "070A12", "262238", "FFF2CE", "F8B271", "CEB3FF"

local function vertex(x, y, z)
	return V(x, y, z)
end

-- A brushstroke is a closed, tapered strip with a curved spine. The width
-- belongs to each knot so a hard edge can suddenly break into a hairline.
local function stroke(model, knots, tint, z)
	local left, right
	for i, knot in knots do
		local before, after = knots[math.max(i - 1, 1)], knots[math.min(i + 1, #knots)]
		local tangent = Vector2.new(after[1] - before[1], after[2] - before[2]).Unit
		local normal = Vector2.new(-tangent.Y, tangent.X) * knot[3]
		local a = vertex(knot[1] + normal.X, knot[2] + normal.Y, z)
		local b = vertex(knot[1] - normal.X, knot[2] - normal.Y, z)
		if left then
			if (left - right).Magnitude > 0.015 then
				P.face(model, left, right, a, rgb(tint))
			end
			if (a - b).Magnitude > 0.015 then
				P.face(model, right, b, a, rgb(tint))
			end
		end
		left, right = a, b
	end
end

local function drawPlate(model)
	-- Push the leading edge into the ground. Only the windward side lifts.
	stroke(
		model,
		{ { -32, 7.1, 0 }, { -18, 4.5, 0.19 }, { -6, 1.9, 0.51 }, { 0, 0, 0.24 }, { 4.4, -1, 0 } },
		lilac,
		0.08
	)
	stroke(model, { { -30, 7.0, 0 }, { -14, 3.85, 0.14 }, { -2.8, 0.82, 0.39 }, { 1.0, -0.22, 0 } }, paper, 0.16)
	stroke(
		model,
		{
			{ -29, -3.1, 0 },
			{ -14, -1.7, 0.10 },
			{ -3.3, -0.45, 0.31 },
			{ 3.7, -0.12, 0.52 },
			{ 17, -1.15, 0.57 },
			{
				33,
				-2.5,
				0,
			},
		},
		paper,
		0.12
	)
	stroke(
		model,
		{ { -1.8, -0.2, 0 }, { 0.6, 0.8, 0.49 }, { 4.1, 2.23, 0.9 }, { 8.4, 5.6, 1.2 }, { 11.5, 10.0, 0 } },
		paper,
		0.18
	)
	stroke(
		model,
		{ { -0.15, 0, 0 }, { 2.2, 0.7, 0.11 }, { 6.9, 2.0, 0.62 }, { 12.5, 4.8, 0.75 }, { 21, 9.8, 0 } },
		edge,
		0.18
	)
	stroke(
		model,
		{ { 0.2, 0.0, 0 }, { 4.9, 0.18, 0.25 }, { 9.8, 0.88, 0.51 }, { 16, 2.0, 0.42 }, { 22.4, 4.3, 0 } },
		paper,
		0.18
	)
	stroke(model, { { 1.0, 0.13, 0 }, { 4.8, 1.55, 0.26 }, { 7.1, 2.9, 0.48 }, { 10.5, 6.1, 0 } }, black, 0.29)
	stroke(model, { { -12, -5.7, 0 }, { -5.9, -2.5, 0.15 }, { -2.6, -1.3, 0.42 }, { -0.1, -0.08, 0 } }, edge, 0.21)
	stroke(model, { { -1.3, -0.15, 0 }, { -0.13, -0.05, 0.27 }, { 0.08, -1.5, 0.17 }, { -0.7, -3.45, 0 } }, lilac, 0.31)
	-- The lifted side of the crater in crosslight. A broken rim, a curling
	-- vapour cap, and black chips interrupt the directional brush lines.
	stroke(
		model,
		{
			{ -7.8, 0.2, 0 },
			{ -6.1, 0.34, 0.10 },
			{ -4.1, 0.49, 0.08 },
			{ -2.8, 0.74, 0.16 },
			{ -1.35, 0.49, 0.12 },
			{
				-0.22,
				0.08,
				0,
			},
		},
		paper,
		0.24
	)
	stroke(model, {
		{ 0.17, 0.05, 0 },
		{ 1.02, 1.03, 0.16 },
		{ 2.03, 1.41, 0.46 },
		{ 3.06, 2.61, 0.70 },
		{ 3.24, 3.86, 0.46 },
		{ 2.70, 4.47, 0.22 },
		{ 2.12, 4.26, 0 },
	}, edge, 0.24)
	stroke(
		model,
		{
			{ 0.36, 0.12, 0 },
			{ 1.40, 1.17, 0.08 },
			{ 2.87, 1.78, 0.14 },
			{ 3.66, 2.90, 0.36 },
			{ 3.55, 4.02, 0.29 },
			{
				2.93,
				4.45,
				0,
			},
		},
		paper,
		0.27
	)
	stroke(
		model,
		{
			{ 1.14, 0.01, 0 },
			{ 2.44, 0.72, 0.11 },
			{ 3.68, 1.02, 0.35 },
			{ 4.54, 1.28, 0.37 },
			{ 5.01, 1.92, 0.14 },
			{
				4.70,
				2.25,
				0,
			},
		},
		lilac,
		0.25
	)
	stroke(
		model,
		{ { -0.13, 0.02, 0 }, { 0.7, 1.04, 0.05 }, { 1.40, 1.67, 0.14 }, { 1.6, 2.4, 0.08 }, { 1.34, 2.78, 0 } },
		paper,
		0.25
	)
	-- Air and stone are swept sideways in the same direction as the fire.
	local rng = Random.new(6517)
	for i = 1, 31 do
		local angle = math.rad(rng:NextNumber(6, 148))
		local r = rng:NextNumber(3, 12)
		local dx, dy = math.cos(angle), math.sin(angle)
		local x, y = dx * r, dy * r * 0.72
		local w = rng:NextNumber(0.045, 0.23)
		local length = rng:NextNumber(0.65, 2.8)
		P.face(
			model,
			V(x - dy * w, y + dx * w, 0.40),
			V(x + dy * w, y - dx * w, 0.40),
			V(x + dx * length + 0.32, y + dy * length, 0.40),
			rgb(if i % 4 == 0 then edge elseif i % 3 == 0 then ink else paper)
		)
	end
	for i = 1, 14 do
		local x, y = rng:NextNumber(0.6, 7.3), rng:NextNumber(0.35, 4.2)
		local r = rng:NextNumber(0.08, 0.34)
		P.face(
			model,
			V(x - r, y + r * 0.3, 0.46),
			V(x - r * 0.58, y + r * 1.14, 0.46),
			V(x + r, y - r * 0.72, 0.46),
			rgb(black)
		)
	end
	for _, part in model:GetChildren() do
		part.Material, part.CastShadow = Enum.Material.SmoothPlastic, false
	end
end

local function flightLines(screen)
	local layer = Instance.new("Frame")
	layer.Name, layer.Size, layer.BackgroundTransparency = "Slipstream", UDim2.fromScale(1, 1), 1
	layer.Visible, layer.ZIndex, layer.Parent = false, 2, screen
	local rng, lines = Random.new(240), {}
	for i = 1, 16 do
		local angle = (i + rng:NextNumber(-0.40, 0.40)) * math.pi / 8
		local line = Instance.new("Frame")
		line.Name, line.AnchorPoint, line.BorderSizePixel = "Air shear", Vector2.new(0.5, 0.5), 0
		line.BackgroundColor3 = rgb(if i % 3 == 0 then lilac else paper)
		local tip = Instance.new("UIGradient")
		tip.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.54, 0.10),
			NumberSequenceKeypoint.new(1, 1),
		})
		tip.Parent, line.Parent = line, layer
		table.insert(
			lines,
			{
				part = line,
				unit = Vector2.new(math.cos(angle), math.sin(angle)),
				phase = rng:NextNumber(),
				thickness = rng:NextNumber(0.001, 0.0032),
			}
		)
	end
	return layer, lines
end

function Exposure.new(screen, camera)
	local plate = Instance.new("ViewportFrame")
	plate.Name, plate.Size = "Contact drawing", UDim2.fromScale(1, 1)
	plate.BorderSizePixel, plate.BackgroundColor3 = 0, rgb(black)
	plate.Ambient, plate.LightColor = Color3.new(1, 1, 1), Color3.new()
	plate.Visible, plate.ZIndex, plate.Parent = false, 2, screen
	local lens = Instance.new("Camera")
	lens.FieldOfView, lens.Parent = 42, plate
	plate.CurrentCamera = lens
	local model = P.model(plate, "Pressure engraving")
	drawPlate(model)
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name, grade.Parent = "Starfall exposure", camera
	local slip, lines = flightLines(screen)
	return setmetatable({ plate = plate, lens = lens, grade = grade, slip = slip, lines = lines }, Exposure)
end

function Exposure:draw(t, film)
	local motion, grade = film.motion, self.grade
	local offset = t - Beats.impact
	local passing = ease(t, 0.57, 0.79) * (1 - ease(t, 0.98, 1.09))
	local chase = ease(t, 2.46, 2.72) * (1 - ease(t, 3.51, 3.97))
	local shear = if motion then math.max(passing, 0.76 * chase) else 0
	self.slip.Visible = shear > 0.01
	if self.slip.Visible then
		local size = film.camera.ViewportSize
		local at = if passing > 0 then film.strike.meteor:GetPivot().Position else film.impactPoint
		local point = film.camera:WorldToViewportPoint(at)
		local center = Vector2.new(
			math.clamp(point.X, size.X * 0.20, size.X * 0.80),
			math.clamp(point.Y, size.Y * 0.25, size.Y * 0.75)
		)
		for _, line in self.lines do
			local dir = line.unit
			local dx = (if dir.X > 0 then size.X - center.X else -center.X) / dir.X
			local dy = (if dir.Y > 0 then size.Y - center.Y else -center.Y) / dir.Y
			local toEdge = math.min(dx, dy)
			local progress = (2.25 * t + line.phase) % 1
			local distance = toEdge * (0.60 + 0.47 * progress)
			local p = center + dir * distance
			line.part.Position = UDim2.fromOffset(p.X, p.Y)
			line.part.Size = UDim2.fromOffset(toEdge * (0.22 + 0.15 * progress), math.max(1, size.Y * line.thickness))
			line.part.Rotation = math.deg(math.atan2(dir.Y, dir.X))
			line.part.BackgroundTransparency = 1 - 0.66 * shear * math.sin(progress * math.pi)
		end
	end
	local silhouette = if motion then ease(t, 6.16, 6.48) * (1 - ease(t, 6.50, 6.78)) else 0
	local release = if motion then ease(t, 6.57, 6.67) * (1 - ease(t, 6.67, 7.12)) else 0
	local quiet = ease(t, 8.65, 9.12) * (1 - ease(t, 11.45, 12.56))
	local sky = ease(t, 13.05, 14.45) * (1 - ease(t, 27.9, 30.05))
	local gradeOn = t < 30.6
	grade.Enabled = gradeOn
	if gradeOn then
		grade.Contrast = 0.045 + 0.37 * silhouette + 0.16 * release + 0.055 * quiet + 0.035 * sky
		grade.Brightness = -0.11 * silhouette + 0.085 * release
		grade.Saturation = 0.035 - 0.85 * silhouette - 0.21 * quiet + 0.09 * sky
		grade.TintColor = Color3.new(1, 1, 1):Lerp(rgb("D8CAFF"), 0.28 * quiet):Lerp(rgb("FFE4BC"), 0.40 * release)
	end
	local plate = self.plate
	plate.Visible = motion and offset >= 0 and offset < 0.126
	if plate.Visible then
		local viewport = film.camera.ViewportSize
		local hit = film.camera:WorldToViewportPoint(film.impactPoint)
		local aspect = viewport.X / math.max(1, viewport.Y)
		local h = 7.1 * math.max(1, 1.1 / math.max(0.36, aspect))
		local distance = h / math.tan(math.rad(21))
		local u = math.clamp(hit.X / math.max(1, viewport.X), 0.04, 0.96)
		local v = math.clamp(hit.Y / math.max(1, viewport.Y), 0.08, 0.92)
		self.lens.CFrame = CFrame.new((1 - 2 * u) * h * aspect, (2 * v - 1) * h, distance)
		local fade = ease(offset, 0.077, 0.126)
		plate.BackgroundTransparency, plate.ImageTransparency = 0.045 + 0.955 * fade, fade
	end
end

function Exposure:Destroy()
	self.grade:Destroy()
	self.plate:Destroy()
	self.slip:Destroy()
end

return Exposure
