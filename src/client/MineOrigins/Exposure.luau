-- Graphic exposures are rendered from native triangles in a camera-facing
-- viewport. The drawing scales with the screen and needs no uploaded texture.
local P = require(script.Parent.Props)
local Beats = require(script.Parent.Beats)
local ease, rgb, V = P.ease, Color3.fromHex, Vector3.new
local Exposure = {}
Exposure.__index = Exposure
local black, paper, lilac = "101127", "FFF0C8", "BF99FF"

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

-- Two different contact drawings. The first traps the light against the
-- underside of the meteor. In the second the same light tears out sideways.
local cutSpacing = 512
local function facet(model, outline, tint, z)
	local a = V(outline[1][1], outline[1][2], z)
	for i = 2, #outline - 1 do
		local b, c = outline[i], outline[i + 1]
		P.face(model, a, V(b[1], b[2], z), V(c[1], c[2], z), rgb(tint))
	end
end

local function drawContact(model)
	local ice, red = "93E8FC", "E94454"
	stroke(model, { { -25, 14, 0 }, { -8.5, 5.6, 0.32 }, { -2.6, 2.2, 0.57 }, { 0.23, 0, 0.27 } }, ice, 0.05)
	facet(
		model,
		{ { -8.5, 8.8 }, { -3.77, 6.39 }, { -0.25, 2.0 }, { 0.27, 0.07 }, { -2.43, 0.96 }, { -6.18, 4.56 } },
		"372E54",
		0.1
	)
	facet(model, { { -4.7, 5.91 }, { -0.46, 2.08 }, { 0.27, 0.07 }, { -2.08, 1.58 } }, "E9B8E6", 0.13)
	stroke(model, { { -14, 11, 0 }, { -6.2, 6.4, 0.19 }, { -2.65, 3.52, 0.30 }, { 0, 0, 0.12 } }, paper, 0.17)
	stroke(
		model,
		{
			{ -14, 0.12, 0 },
			{ -5.3, 0.33, 0.06 },
			{ -1.8, 0.18, 0.16 },
			{ 0, 0.05, 0.21 },
			{ 3.6, -0.25, 0.16 },
			{
				13,
				-0.39,
				0,
			},
		},
		ice,
		0.20
	)
	stroke(
		model,
		{ { -2.9, 0.64, 0 }, { -1.3, 0.46, 0.14 }, { 0.12, 0.00, 0.18 }, { 1.89, 0.35, 0.15 }, { 5.7, 0.50, 0 } },
		paper,
		0.22
	)
	stroke(model, { { 0, 0.1, 0.16 }, { 0.38, -0.66, 0.13 }, { 0.13, -1.14, 0.06 }, { 0.69, -1.91, 0 } }, red, 0.24)
end

local function drawRelease(model)
	local red, amber, ice = "F74645", "FFB52D", "77D7ED"
	-- The broad near lip, thin far lip and the lifted wedge of basalt leave
	-- a dark triangular pocket beneath the hottest part of the blast.
	stroke(
		model,
		{
			{ -27, -1.6, 0 },
			{ -12, -0.54, 0.22 },
			{ -3.1, -0.11, 0.51 },
			{ 1.9, 0.21, 0.66 },
			{ 8.6, 1.5, 0.4 },
			{
				23,
				4.4,
				0,
			},
		},
		red,
		0.04
	)
	stroke(
		model,
		{
			{ -29, 1.7, 0 },
			{ -9, 0.50, 0.16 },
			{ -2.3, 0.15, 0.33 },
			{ 2.6, 0.27, 0.47 },
			{ 12, 1.55, 0.22 },
			{
				28,
				4.2,
				0,
			},
		},
		paper,
		0.07
	)
	stroke(
		model,
		{
			{ -10, 0.1, 0 },
			{ -3.6, 0.59, 0.39 },
			{ 0, 0.51, 0.85 },
			{ 3.7, 1.98, 1.23 },
			{ 6.1, 4.25, 1.12 },
			{
				6.32,
				6.15,
				0.46,
			},
			{
				5.32,
				7.2,
				0,
			},
		},
		amber,
		0.12
	)
	stroke(
		model,
		{
			{ -3.6, 0.22, 0 },
			{ 0, 0.73, 0.46 },
			{ 3.57, 2.29, 0.77 },
			{ 5.46, 4.42, 0.68 },
			{ 5.6, 5.8, 0.16 },
			{
				5.19,
				6.32,
				0,
			},
		},
		paper,
		0.14
	)
	stroke(
		model,
		{ { 0.28, 0.18, 0.10 }, { 2.73, 0.91, 0.38 }, { 5.27, 2.38, 0.65 }, { 8.03, 5.54, 0.65 }, { 8.82, 8.28, 0 } },
		red,
		0.10
	)
	stroke(model, { { 1.03, 0.44, 0.06 }, { 4.05, 1.25, 0.18 }, { 7.40, 3.28, 0.29 }, { 10.2, 6.10, 0 } }, ice, 0.15)
	facet(model, { { 0.4, -0.04 }, { 2.36, 0.41 }, { 5.65, 1.82 }, { 2.83, 0.08 }, { 1.48, -0.36 } }, black, 0.22)
	stroke(model, { { -21, -3.45, 0 }, { -9.2, -2.68, 0.37 }, { -3.4, -0.85, 0.43 }, { -0.2, 0, 0 } }, amber, 0.14)
	stroke(
		model,
		{ { -0.27, 0.09, 0.11 }, { 0.19, -0.95, 0.22 }, { -0.24, -1.88, 0.13 }, { 0.17, -3.16, 0 } },
		lilac,
		0.28
	)
	-- Splinters carry the force downwind. Leave the opposite upper quarter empty.
	stroke(
		model,
		{
			{ -8.6, -1.54, 0 },
			{ -4.8, -1.14, 0.18 },
			{ -1.71, -0.10, 0.22 },
			{ 0.47, 1.06, 0.48 },
			{ 0.68, 2.38, 0.32 },
			{ 0.15, 3.14, 0.09 },
			{ -0.53, 2.86, 0 },
		},
		red,
		0.16
	)
	stroke(
		model,
		{ { -2.26, -0.15, 0 }, { -0.29, 0.56, 0.2 }, { 0.48, 1.64, 0.24 }, { 0.31, 2.49, 0.10 }, { -0.14, 2.85, 0 } },
		paper,
		0.19
	)
	stroke(
		model,
		{ { 1.09, 0.21, 0 }, { 3.1, 0.83, 0.25 }, { 5.83, 1.73, 0.41 }, { 8.21, 2.51, 0.30 }, { 10.67, 2.58, 0.13 }, {
			11.6,
			2.15,
			0,
		} },
		amber,
		0.18
	)
	facet(model, { { -3.12, 0.63 }, { -2.01, 1.13 }, { -1.46, 0.95 }, { -2.61, 0.54 } }, black, 0.29)
	facet(model, { { 2.44, 1.47 }, { 4.78, 3.23 }, { 4.49, 2.28 }, { 3.44, 1.58 } }, black, 0.29)
	facet(model, { { 6.04, 4.64 }, { 6.54, 4.87 }, { 7.4, 6.02 }, { 6.72, 5.83 } }, black, 0.29)
	local chips = {
		{ -5, 1.44, 0.32 },
		{ 1.36, 3.12, 0.48 },
		{ 2.08, 5.14, 0.22 },
		{ 4.4, 6.68, 0.31 },
		{ 8.73, 2.80, 0.6 },
		{ 10.4, 4.98, 0.32 },
		{ -6.3, -1.06, 0.16 },
		{ 11.9, 7.62, 0.63 },
	}
	for i, chip in chips do
		local x, y, s = chip[1], chip[2], chip[3]
		facet(
			model,
			{
				{ x - s, y },
				{ x - 0.22 * s, y + 1.22 * s },
				{ x + 1.95 * s, y + 2.16 * s },
				{ x + 0.45 * s, y + 0.27 * s },
			},
			if i % 3 == 0 then ice else paper,
			0.25
		)
	end
end

local function paint(model, draw)
	draw(model)
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
		table.insert(lines, {
			part = line,
			unit = Vector2.new(math.cos(angle), math.sin(angle)),
			phase = rng:NextNumber(),
			thickness = rng:NextNumber(0.001, 0.0032),
		})
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
	paint(P.model(plate, "Compression"), drawContact)
	local release = P.model(plate, "Sheared crust")
	paint(release, drawRelease)
	release:PivotTo(CFrame.new(cutSpacing, 0, 0))
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
			-- Each streak is exposed on twos while the shell crosses the lens at full speed.
			local progress = (2.25 * math.floor(t * 15) / 15 + line.phase) % 1
			local distance = toEdge * (0.60 + 0.47 * progress)
			local p = center + dir * distance
			line.part.Position = UDim2.fromOffset(p.X, p.Y)
			line.part.Size = UDim2.fromOffset(toEdge * (0.22 + 0.15 * progress), math.max(1, size.Y * line.thickness))
			line.part.Rotation = math.deg(math.atan2(dir.Y, dir.X))
			line.part.BackgroundTransparency = 1 - 0.66 * shear * math.sin(progress * math.pi)
		end
	end
	local silhouette = if motion and t >= 6.19 and t < 6.50 then (if t < 6.40 then 0.43 else 1) else 0
	local release = if motion then ease(t, 6.59, 6.69) * (1 - ease(t, 6.76, 6.99)) else 0
	local quiet = ease(t, 8.65, 9.12) * (1 - ease(t, 11.45, 12.56))
	local sky = ease(t, 13.05, 14.45) * (1 - ease(t, 27.9, 30.05))
	local gradeOn = t < 30.6
	grade.Enabled = gradeOn
	if gradeOn then
		grade.Contrast = 0.045 + 0.37 * silhouette + 0.16 * release + 0.055 * quiet + 0.035 * sky
		grade.Brightness = -0.11 * silhouette + 0.085 * release
		local cinders = ease(t, 6.64, 6.77) * (1 - ease(t, 7.82, 8.50))
		grade.Saturation = 0.035 - 0.76 * silhouette - 0.14 * quiet + 0.14 * cinders + 0.09 * sky
		local cold = (1 - ease(t, 6.50, 6.67)) + 0.72 * ease(t, 7.44, 7.95) * (1 - ease(t, 11.56, 13.04))
		grade.TintColor = Color3.new(1, 1, 1)
			:Lerp(rgb("ADC8EB"), 0.36 * cold)
			:Lerp(rgb("D8CAFF"), 0.28 * quiet)
			:Lerp(rgb("FFE4BC"), 0.38 * release)
	end
	local plate = self.plate
	plate.Visible = motion and offset >= 0 and offset < 0.126
	if plate.Visible then
		local viewport = film.camera.ViewportSize
		local hit = film.camera:WorldToViewportPoint(film.impactPoint)
		local aspect = viewport.X / math.max(1, viewport.Y)
		local h = 8.6 * math.max(1, 1.1 / math.max(0.36, aspect))
		local distance = h / math.tan(math.rad(21))
		local u = math.clamp(hit.X / math.max(1, viewport.X), 0.04, 0.96)
		local v = math.clamp(hit.Y / math.max(1, viewport.Y), 0.08, 0.92)
		local releasing = offset >= 0.050
		local sheet = if releasing then cutSpacing else 0
		self.lens.CFrame = CFrame.new(sheet + (1 - 2 * u) * h * aspect, (2 * v - 1) * h, distance)
		plate.BackgroundColor3 = rgb(if releasing then "34213A" else "101127")
		plate.BackgroundTransparency, plate.ImageTransparency = 0.025, 0
	end
end

function Exposure:Destroy()
	self.grade:Destroy()
	self.plate:Destroy()
	self.slip:Destroy()
end

return Exposure
