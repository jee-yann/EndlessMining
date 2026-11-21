local P, Actor = require(script.Parent.Props), require(script.Parent.Actor)
local Shore = {}
Shore.__index = Shore
local V, CF, A, rgb, ease = Vector3.new, CFrame.new, CFrame.Angles, Color3.fromHex, P.ease
local tau = math.pi * 2
local function ground(x, z)
	return 1.35 - 0.11 * z + 0.37 * math.sin(x * 0.16 + z * 0.08)
end

local function island(root, rng)
	local ring, inner, top = {}, {}, {}
	for i = 1, 30 do
		local a = (i - 1) * tau / 30
		local x, z = math.cos(a) * 30 * rng:NextNumber(0.93, 1.07), math.sin(a) * 19 * rng:NextNumber(0.92, 1.1)
		ring[i], inner[i] = V(x, ground(x, z), z), V(x * 0.47, ground(x * 0.47, z * 0.47), z * 0.47)
	end
	local bands = { "433D53", "815E66", "B0836A", "6C5960" }
	for i, v in ring do
		local j = i % #ring + 1
		local w = ring[j]
		local surface = P.model(root, "Shore turf")
		local color = rgb(if i % 3 == 0 then "8C746D" else "796868")
		P.face(surface, V(0, ground(0, 0), 0), inner[i], inner[j], color)
		P.face(surface, inner[i], v, w, color)
		P.face(surface, inner[i], w, inner[j], color)
		for _, p in surface:GetChildren() do
			local grass = rgb(if i % 4 == 0 then "849557" else "73874F")
			local beach = ease(p.Position.Z, 6, 13)
			table.insert(top, { p = p, from = color, to = grass:Lerp(rgb("CCB086"), beach) })
		end
		for b = 1, 4 do
			local hi, lo = (b - 1) * 2.25, b * 2.25
			local function level(q, h)
				return V(q.X * (1 - h * 0.009), q.Y - h, q.Z * (1 - h * 0.009))
			end
			local c = rgb(bands[b]):Lerp(rgb("BD9378"), (i % 5) * 0.024)
			P.face(root, level(v, hi), level(w, hi), level(w, lo), c)
			P.face(root, level(v, hi), level(w, lo), level(v, lo), c)
		end
	end
	return top
end
local function hut(parent, tint)
	local m = P.model(parent, "Harbor cottage")
	P.box(m, "Limewashed walls", V(0, 1.27, 0), V(4.2, 2.54, 3.5), "E9D9A7")
	for _, s in { -1, 1 } do
		P.box(m, "Roof pitch", V(s * 1.14, 3.15, 0), V(2.65, 0.26, 4.05), tint, A(0, 0, -s * 0.47))
		P.box(m, "Shutter", V(s * 1.22, 1.52, 1.78), V(0.67, 0.79, 0.10), "456A74")
		P.box(m, "Window light", V(s * 1.22, 1.55, 1.85), V(0.40, 0.57, 0.06), "F1B865")
	end
	P.box(m, "Door", V(0, 0.88, 1.80), V(0.77, 1.76, 0.11), "784C3B")
	P.box(m, "Chimney", V(1.41, 3.49, -0.74), V(0.53, 1.20, 0.62), "AD7259")
	return m
end
local function pine(parent)
	local m = P.model(parent, "Shore pine")
	P.box(m, "Trunk", V(0, 1.35, 0), V(0.46, 2.7, 0.46), "795842")
	for i = 1, 3 do
		local width = 2.4 - (i - 1) * 0.55
		local a = P.sphere(
			m,
			"Needles",
			V(0, 1.35 + i * 0.77, 0),
			V(width, 1.8, width * 0.92),
			({ "385D51", "48715A", "638662" })[i]
		)
		a.Material = Enum.Material.Grass
	end
	return m
end
local function boat(parent)
	local m = P.model(parent, "Returning cutter")
	P.box(m, "Keel", V(0, 0, 0), V(1.32, 0.46, 5.05), "704637")
	for _, s in { -1, 1 } do
		P.box(m, "Gunwale", V(s * 0.85, 0.34, 0), V(0.24, 0.70, 4.8), "A75E45", A(0, 0, -s * 0.23))
		P.box(m, "Sheer stripe", V(s * 0.96, 0.63, 0), V(0.12, 0.15, 4.82), "F0C184")
	end
	for _, z in { -1.7, 0, 1.7 } do
		P.box(m, "Thwart", V(0, 0.5, z), V(1.7, 0.14, 0.35), "BC8C58")
	end
	P.box(m, "Mast", V(0, 2.7, -0.25), V(0.12, 5.3, 0.12), "674E40")
	P.rod(m, "Forestay", V(0, 5.18, -0.24), V(0, 0.39, 2.38), 0.045, rgb("8B755F"))
	P.rod(m, "Backstay", V(0, 5.18, -0.24), V(0, 0.39, -2.38), 0.045, rgb("8B755F"))
	local lamp = P.sphere(m, "Bow lantern", V(0, 0.91, 2.05), V(0.31, 0.42, 0.31), "FFC879", Enum.Material.Neon)
	P.light(lamp, "FFBA80", 4, 0.8)
	P.face(m, V(0, 5.25, -0.24), V(0, 1.03, -0.24), V(2.55, 1.22, 0.24), rgb("F2D5A2"))
	P.face(m, V(0, 4.8, -0.28), V(0, 2.5, -0.29), V(-1.2, 1.21, -1.2), rgb("C27752"))
	return m
end
function Shore.new(shelf)
	local root = P.model(shelf, "Beacon Point through time")
	local rng = Random.new(412)
	local self = setmetatable(
		{ root = root, top = island(root, rng), waves = {}, growth = {}, rings = {}, rubble = {}, lensColors = {} },
		Shore
	)
	self.water = P.box(root, "Open sea", V(0, -6, 0), V(900, 1, 900), "336F81")
	self.water.Material = Enum.Material.SmoothPlastic
	for i = 1, 48 do
		local x, z = rng:NextNumber(-64, 64), rng:NextNumber(-46, 54)
		local p = P.sphere(
			root,
			"Whitecap",
			V(x, -5, z),
			V(rng:NextNumber(2.5, 8), 0.10, 0.37),
			if i % 4 == 0 then "D3E7D9" else "86BCC0"
		)
		table.insert(self.waves, { p = p, x = x, z = z, phase = rng:NextNumber(0, tau) })
	end
	for layer = 1, 2 do
		local previous, foot
		for i = -16, 16 do
			local x = i * 8
			local z = -47 - layer * 23 + 5.1 * math.sin(i * 0.8 + layer)
			local h = 4
				+ layer * 1.8
				+ 4.5 * math.sin(i * 0.53 + layer)
				+ 2.6 * math.cos(i * 0.98)
				+ rng:NextNumber(-1.8, 1.8)
			local peak = V(x, h, z)
			local base = V(x + 2, -8, z + 4.5)
			if previous then
				local c = rgb(if layer == 1 then "677F83" else "88A5A9")
				P.face(root, previous, foot, base, c)
				P.face(root, previous, base, peak, c:Lerp(rgb("B5B9A8"), 0.12))
			end
			previous, foot = peak, base
		end
	end
	-- Two distinctive teeth hold the headland in register across all its ages.
	for i, v in { V(-12, 0, -7), V(-8.8, 0, -8.8) } do
		P.box(
			root,
			"Split basalt tooth",
			V(v.X, ground(v.X, v.Z) + 2.1, v.Z),
			V(2.4, if i == 1 then 7.9 else 6.1, 3),
			"675D67",
			A(0.08, i * 0.25, if i == 1 then -0.20 else 0.18),
			Enum.Material.Slate
		)
	end
	for i = 1, 28 do
		local x, z = rng:NextNumber(-23, 22), rng:NextNumber(-13, 13)
		P.sphere(
			root,
			"Beach stone",
			V(x, ground(x, z) + 0.12, z),
			V(rng:NextNumber(0.6, 1.6), rng:NextNumber(0.35, 0.8), rng:NextNumber(0.65, 1.8)),
			"948273",
			Enum.Material.Slate
		)
	end
	local function plant(model, x, z, time, angle, scale)
		table.insert(
			self.growth,
			{ m = model, cf = CF(x, ground(x, z), z) * A(0, angle, 0), time = time, scale = scale or 1 }
		)
	end
	for i = 1, 18 do
		local x, z = rng:NextNumber(-22, 23), rng:NextNumber(-13, -5)
		plant(pine(root), x, z, 14.0 + i * 0.102, rng:NextNumber(0, tau), rng:NextNumber(0.78, 1.25))
	end
	for i, v in { V(-15, 0, 2), V(-8, 0, -3), V(0, 0, -8), V(16, 0, -7), V(19, 0, 1) } do
		plant(hut(root, ({ "9E514B", "397881", "A85C46" })[i % 3 + 1]), v.X, v.Z, 21.0 + i * 0.39, i * 0.33, 0.86)
	end
	self.towerAt = V(7, ground(7, -2), -2)
	self.tower = P.model(root, "Beacon tower")
	for i = 1, 6 do
		P.cylinder(
			self.tower,
			"Stone course",
			V(0, (i - 0.5) * 1.14, 0),
			2.22 - i * 0.13,
			1.14,
			if i == 4 or i == 5 then "AC5549" else "F1DEB8"
		)
	end
	P.cylinder(self.tower, "Lantern balcony", V(0, 6.95, 0), 2.2, 0.24, "454F58")
	for i = 1, 8 do
		local a = i * tau / 8
		P.box(self.tower, "Gallery rail", V(math.cos(a) * 2.0, 7.48, math.sin(a) * 2.0), V(0.1, 0.93, 0.1), "514D48")
		P.rod(
			self.tower,
			"Handrail",
			V(math.cos(a) * 2, 7.85, math.sin(a) * 2),
			V(math.cos(a + tau / 8) * 2, 7.85, math.sin(a + tau / 8) * 2),
			0.1,
			rgb("574E46")
		)
	end
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			P.box(self.tower, "Lantern mullion", V(x, 8.13, z), V(0.13, 2.30, 0.13), "45545C")
		end
	end
	P.cylinder(self.tower, "Copper cap", V(0, 9.46, 0), 1.8, 0.36, "4A7978")
	P.sphere(self.tower, "Weathered dome", V(0, 9.62, 0), V(3.1, 1.25, 3.1), "639491")
	self.lens = P.crystal(root, Vector3.zero, 0.68)
	self.beam = P.model(root, "Rotating lantern")
	local source = P.box(self.beam, "Lens", V(0, 0, 0), V(0.40, 0.65, 0.32), "FFDF9C", nil, Enum.Material.Neon)
	self.lamp = P.light(source, "FFD39A", 20, 2)
	local start = Instance.new("Attachment", source)
	local finish = Instance.new("Attachment", source)
	finish.Position = V(0, 0, 33)
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1, beam.Width0, beam.Width1 = start, finish, 0.25, 5.9
	beam.FaceCamera, beam.LightEmission, beam.Color = true, 0.7, ColorSequence.new(rgb("FFE4AB"), rgb("F2CCBC"))
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.42),
		NumberSequenceKeypoint.new(0.7, 0.73),
		NumberSequenceKeypoint.new(1, 1),
	})
	beam.Parent = source
	self.ray = beam
	self.boat = boat(root)
	self.fisher = Actor.new(root, "Beachcomber", "D19642", "B57F5C", "547C77")
	self.keeper = Actor.new(root, "Beacon keeper", "40747C", "B57F5C", "9F5F49")
	self.carpenter = Actor.new(root, "Harbor carpenter", "A56D4C", "B78460", "536E72")
	self.timber = P.box(root, "Carried spar", Vector3.zero, V(0.22, 0.25, 4.2), "C59B6B", nil, Enum.Material.Wood)
	self.chip = P.crystal(root, Vector3.zero, 0.32)
	self.ember = P.crystal(root, Vector3.zero, 1.0)
	self.scar = P.crystal(root, Vector3.zero, 1.25)
	self.lens.Name, self.chip.Name, self.ember.Name, self.scar.Name =
		"Beacon wick", "Beach chip", "Falling ember", "Buried heart"
	P.light(self.chip:FindFirstChildWhichIsA("BasePart"), "D9A7FF", 3.5, 0.9)
	local torch = self.ember:FindFirstChildWhichIsA("BasePart")
	self.fire = P.light(torch, "FFB986", 26, 3)
	self.tail = P.sphere(root, "Meteor wake", Vector3.zero, V(0.6, 0.6, 8), "FFDAB1", Enum.Material.Neon)
	local trailA, trailB = Instance.new("Attachment", torch), Instance.new("Attachment", torch)
	trailA.Position, trailB.Position = V(-0.37, 0, 0), V(0.37, 0, 0)
	local flame = Instance.new("Trail")
	flame.Attachment0, flame.Attachment1, flame.Lifetime = trailA, trailB, 0.62
	flame.FaceCamera, flame.LightEmission = true, 1
	flame.Color = ColorSequence.new(rgb("FFF2B6"), rgb("D575A1"))
	flame.Transparency = NumberSequence.new(0.08, 1)
	flame.Parent = torch
	self.flash = P.sphere(root, "Impact flash", Vector3.zero, Vector3.one, "FFE0A2", Enum.Material.Neon)
	local bed = P.box(root, "Crater floor", V(0, ground(0, 0), 0), Vector3.one, "806E68")
	bed.Transparency = 1
	local dust = Instance.new("ParticleEmitter")
	dust.Name, dust.Texture, dust.Rate = "Basalt plume", "rbxasset://textures/particles/smoke_main.dds", 0
	dust.Lifetime, dust.Speed, dust.SpreadAngle =
		NumberRange.new(0.95, 1.85), NumberRange.new(5, 12), Vector2.new(75, 75)
	dust.Acceleration, dust.Drag = V(1, 2, 0), 1.6
	dust.Color = ColorSequence.new(rgb("D0A084"), rgb("8E777A"))
	dust.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.30),
		NumberSequenceKeypoint.new(0.35, 0.47),
		NumberSequenceKeypoint.new(1, 1),
	})
	dust.Size = NumberSequence.new(1.2, 5.6)
	dust.Parent, self.dust = bed, dust
	self.strata = {}
	for i, tint in { "614E60", "B27C67", "C7A280", "92A06B" } do
		local p = P.sphere(
			root,
			"Settling sediment",
			V(0, ground(0, 0) + i * 0.21, 0),
			Vector3.one,
			tint,
			Enum.Material.Slate
		)
		table.insert(self.strata, p)
	end
	self.courses = {}
	for _, part in self.tower:GetChildren() do
		table.insert(self.courses, { part = part, pose = part.CFrame, start = 21.25 + part.Position.Y * 0.25 })
	end
	for i = 1, 24 do
		local angle = i * tau / 24
		table.insert(
			self.rings,
			P.box(root, "Shock front", Vector3.zero, V(1, 0.16, 0.25), "FFE4A2", nil, Enum.Material.Neon)
		)
		local speed = rng:NextNumber(4, 14)
		local s = rng:NextNumber(0.22, 0.82)
		table.insert(self.rubble, {
			p = P.box(
				root,
				"Thrown basalt",
				Vector3.zero,
				V(s, s * 1.4, s * 0.83),
				if i % 4 == 0 then "D59764" else "785B63"
			),
			v = V(math.cos(angle) * speed, rng:NextNumber(6, 16), math.sin(angle) * speed),
		})
	end
	return self
end

function Shore:draw(t, base, shelf, motion)
	local function show(m, yes)
		local dest = if yes then self.root else shelf
		if m.Parent ~= dest then
			m.Parent = dest
		end
	end
	local tide = -4.1 + 8.0 * ease(t, 10.45, 13.4) - 4.6 * ease(t, 13.7, 17.4)
	self.water.Position = base:PointToWorldSpace(V(0, tide - 0.5, 0))
	for _, w in self.waves do
		w.p.Position = base:PointToWorldSpace(
			V(
				w.x + math.sin(t * 0.38 + w.phase) * 0.9,
				tide + 0.045 + 0.05 * math.sin(t + w.phase),
				w.z + math.sin(t * 0.52 + w.phase) * 1.8
			)
		)
	end
	local grown = ease(t, 13.0, 17.35)
	if self.grass ~= grown then
		for _, v in self.top do
			v.p.Color = v.from:Lerp(v.to, grown)
		end
		self.grass = grown
	end
	for _, v in self.growth do
		local u = ease(t, v.time, v.time + 1.35)
		if u ~= v.last then
			show(v.m, u > 0)
			if u > 0 then
				v.m:ScaleTo(math.max(0.015, u) * v.scale)
				v.m:PivotTo(base * v.cf)
			end
			v.last = u
		end
	end
	local impact = V(0, ground(0, 0), 0)
	show(self.ember, t < 8.4)
	show(self.tail, t < 8.4)
	if t < 8.4 then
		local drop = math.clamp((t - 5.15) / 3.25, 0, 1) ^ 1.45
		local path = V(-32, 34, -10)
		local at = impact + path * (1 - drop)
		self.ember:PivotTo(base * CF(at) * A(t * 2, t * 3, -0.6))
		self.tail.CFrame = base * CFrame.lookAt(at + path.Unit * 4, at)
		self.tail.Transparency = 0.20 + 0.12 * math.sin(t * 18)
	end
	local age = t - 8.4
	if age >= 0 and age < 0.45 and not self.emitted then
		self.dust:Emit(if motion then 45 else 18)
		self.emitted = true
	end
	for i, p in self.strata do
		local u = ease(t, 10.5 + i * 0.64, 12.6 + i * 0.64)
		show(p, u > 0)
		if u > 0 and self.settled ~= true then
			p.Size = V((11 - i) * u + 0.05, 0.48, (8.4 - i * 0.6) * u + 0.05)
		end
	end
	self.settled = t >= 16
	show(self.scar, age >= 0 and t < 15)
	if age >= 0 and t < 15 then
		self.scar:PivotTo(base * CF(impact + V(0, 0.49 - 2.1 * ease(t, 10.8, 14.5), 0)) * A(0, 0.3, 0.41))
	end
	local burst = age >= 0 and age < 2.5
	show(self.flash, age >= 0 and age < 0.65)
	if age >= 0 and age < 0.65 then
		self.flash.Position = base:PointToWorldSpace(impact)
		self.flash.Size = Vector3.one * (0.45 + (if motion then 6.5 else 3) * ease(t, 8.4, 8.85))
		self.flash.Transparency = 0.22 + 0.78 * ease(t, 8.4, 9.05)
	end
	for i, p in self.rings do
		show(p, burst)
		if burst then
			local a = i * tau / #self.rings
			local r = 1 + age * 11
			local x, z = math.sin(a) * r, math.cos(a) * r
			p.Size = V(r * 0.275, 0.16, 0.3 + age * 0.16)
			p.CFrame = base * CF(x, ground(x, z) + 0.19, z) * A(0, a, 0)
			p.Transparency = ease(t, 8.8, 10.3)
		end
	end
	for i, chip in self.rubble do
		show(chip.p, burst)
		if burst then
			local pos = impact + chip.v * age - V(0, 8.5 * age ^ 2, 0)
			chip.p.CFrame = base * CF(pos) * A(age * 4, i + age * 3, age * 2)
			chip.p.Transparency = if pos.Y < ground(pos.X, pos.Z) then 1 else ease(t, 10, 10.85)
		end
	end
	local build = ease(t, 21.25, 24.5)
	show(self.tower, build > 0)
	if build > 0 and self.built ~= build then
		for _, course in self.courses do
			local p = course.part
			local u = ease(t, course.start, course.start + 0.48)
			p.Transparency = 1 - u
			p.CFrame = base * CF(self.towerAt) * CF(0, 2.0 * (1 - u), 0) * A(0, 0.8 * (1 - u), 0) * course.pose
		end
		self.built = build
	end
	local beacon = base * CF(self.towerAt + V(0, 8.12, 0))
	show(self.lens, t >= 23.35)
	show(self.beam, t >= 23.35)
	if t >= 23.35 then
		local lit = t < 28.85 and (t < 28.05 or math.sin(t * 33) > -0.15)
		self.lens:PivotTo(beacon * A(0, math.min(t, 28.85) * 0.8, 0))
		if self.lit ~= lit then
			for _, p in self.lens:GetChildren() do
				self.lensColors[p] = self.lensColors[p] or p.Color
				p.Color = if lit then self.lensColors[p] else rgb("65556F")
				if p.Name == "Bright fracture" then
					p.Material = if lit then Enum.Material.Neon else Enum.Material.Slate
				end
			end
			self.lit = lit
		end
		self.beam:PivotTo(beacon * A(0, math.min(t, 28.85) * 1.16, 0))
		self.lamp.Enabled, self.ray.Enabled = lit, lit
		self.beam.Lens.Transparency = if lit then 0.2 else 1
	end
	show(self.boat, t >= 16.3)
	if t >= 16.3 then
		local sailing = ease(t, 22, 31.9)
		self.boat:PivotTo(
			base
				* CF(-7 + 22 * sailing, tide + 0.12 * math.sin(t * 1.8), 17 + 6 * sailing)
				* A(0.035 * math.sin(t * 1.7), -0.8 + sailing * 0.62, 0.055 * math.sin(t * 1.35))
		)
	end
	show(self.fisher.model, t >= 16.7 and t < 22.2)
	local building = t >= 21.9 and t < 27.1
	show(self.carpenter.model, building)
	show(self.timber, building)
	if building then
		local u = ease(t, 21.9, 26.9)
		local stride = math.sin(t * 6.8)
		local x, z = -11 + 12 * u, 5 - 2 * u
		local actor = base * CF(x, ground(x, z), z) * A(0, 1.68, 0)
		self.carpenter:pose(
			actor,
			0.055 * math.abs(stride),
			-0.12,
			0.04,
			V(-0.67, 1.06, 0.35 + 0.24 * stride),
			V(0.67, 2.20, 0.34),
			stride
		)
		self.timber.CFrame = actor * CF(0.70, 2.32 + 0.045 * stride, 0.25) * A(0.12, 0, -0.18)
	end
	show(self.chip, t >= 16.7 and t < 22.2)
	if t >= 16.7 and t < 22.2 then
		local grab = ease(t, 17.4, 19.0)
		local lift = ease(t, 19, 20.65)
		local actor = base * CF(-3, ground(-3, 13), 13) * A(0, -0.31, 0)
		local right = V(0.80, 1.34, 0.20):Lerp(V(0.54, 0.23, 0.74), grab):Lerp(V(0.36, 2.68, 0.8), lift)
		self.fisher:pose(
			actor,
			0.9 * grab * (1 - lift),
			-0.18 + 0.3 * lift,
			0.34 * grab - 0.64 * lift,
			V(-0.75, 1.15 + 0.55 * lift, 0.55),
			right,
			0
		)
		local chip = if t < 19 then V(0.54, 0.23, 0.74) else right
		self.chip:PivotTo(actor * CF(chip + V(0, 0.14, 0.08)) * A(0, t * 0.8, 0.38 - lift * 0.64))
	end
	show(self.keeper.model, t >= 27.1)
	if t >= 27.1 then
		local reach = ease(t, 27.3, 29)
		local turn = ease(t, 29.0, 30.65)
		self.keeper:pose(
			base * CF(self.towerAt + V(-0.95, 7.05, 1.55)) * A(0, 2.63 - 2.15 * turn, 0),
			0.32 * reach * (1 - turn),
			-0.42 + 0.65 * turn,
			0.12 + 0.12 * reach - 0.33 * turn,
			V(-0.57, 1.16, 0.44),
			V(0.64, 1.40, 0.14):Lerp(V(0.18, 1.16, 1.52), reach):Lerp(V(0.67, 1.38, 0.32), turn),
			0
		)
	end
end
return Shore
