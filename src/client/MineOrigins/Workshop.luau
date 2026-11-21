local P, Actor = require(script.Parent.Props), require(script.Parent.Actor)
local Workshop = {}
Workshop.__index = Workshop
local V, CF, A, rgb, ease = Vector3.new, CFrame.new, CFrame.Angles, Color3.fromHex, P.ease
function Workshop.new(shelf)
	local m = P.model(shelf, "Core shed")
	local self = setmetatable({ root = m }, Workshop)
	P.box(m, "Floorboards", V(0, -0.17, 0), V(18, 0.32, 16), "85664E", nil, Enum.Material.WoodPlanks)
	P.box(m, "Plank wall", V(0, 3.8, -4.7), V(18, 7.6, 0.35), "716955", nil, Enum.Material.WoodPlanks)
	P.box(m, "Side wall", V(-7.5, 3.8, 0), V(0.32, 7.6, 11), "786F59", nil, Enum.Material.WoodPlanks)
	for i = -3, 3 do
		P.box(m, "Upright", V(i * 2.4, 3.7, -4.42), V(0.20, 7.4, 0.27), "504F44")
	end
	for i = 1, 3 do
		P.box(m, "Ocean window", V(1.4 + i * 0.91, 3.75, -4.18), V(0.86, 2.1, 0.13), "9FC6C6", nil, Enum.Material.Neon)
	end
	P.box(m, "Window sill", V(3.24, 2.63, -4.0), V(3.18, 0.15, 0.37), "D1AD7E")
	for i = 1, 3 do
		local x = -3.9 + i * 0.52
		P.rod(m, "Survey tool", V(x, 2.85, -4.04), V(x + 0.11, 4, -4.03), 0.085, rgb("B7B1A1"))
	end
	P.box(m, "Worktop", V(-0.05, 1.47, 1.13), V(5.1, 0.27, 1.72), "B99063", nil, Enum.Material.Wood)
	for _, x in { -2.1, 2.1 } do
		for _, z in { 0.46, 1.8 } do
			P.box(m, "Trestle", V(x, 0.69, z), V(0.23, 1.38, 0.23), "705440")
		end
	end
	P.box(m, "Drill bed", V(-1.04, 1.70, 1.2), V(1.45, 0.19, 1.25), "445C62")
	P.box(m, "Drill column", V(-1.66, 2.82, 0.85), V(0.24, 2.5, 0.28), "46686C")
	P.box(m, "Cast iron press", V(-1.26, 4.03, 1.05), V(1.3, 0.57, 0.8), "4F8587")
	self.rotor = P.model(m, "Drill spindle")
	P.cylinder(self.rotor, "Chuck", V(0, 0, 0), 0.27, 0.48, "676C74", Enum.Material.Metal)
	P.cylinder(self.rotor, "Core barrel", V(0, -0.46, 0), 0.16, 0.55, "BDB8A6", Enum.Material.Metal)
	for i = 1, 9 do
		local a = i * math.pi / 2
		P.rod(
			self.rotor,
			"Flute",
			V(math.cos(a) * 0.16, -0.27 - i * 0.05, math.sin(a) * 0.16),
			V(math.cos(a + 1.5) * 0.16, -0.32 - i * 0.05, math.sin(a + 1.5) * 0.16),
			0.044,
			rgb("75645C")
		)
	end
	self.wheel = P.model(m, "Feed wheel")
	for i = 1, 4 do
		local a = i * math.pi / 2
		P.rod(self.wheel, "Spoke", V(0, 0, 0), V(math.sin(a) * 0.46, math.cos(a) * 0.46, 0), 0.065, rgb("BF9C6E"))
		P.sphere(self.wheel, "Grip", V(math.sin(a) * 0.46, math.cos(a) * 0.46, 0), V(0.14, 0.14, 0.14), "754F3B")
	end
	self.worker = Actor.new(m, "Core driller", "4F7883", "A56E51", "E5B665")
	self.sample = P.model(m, "Split drill core")
	self.half = {}
	for i = 1, 2 do
		local side = if i == 1 then -1 else 1
		local half = P.model(self.sample, "Basalt half")
		P.box(
			half,
			"Core crust",
			V(0, 0, 0),
			V(0.30, 0.72, 0.47),
			if i == 1 then "706275" else "8C7583",
			A(0, 0, side * 0.07),
			Enum.Material.Slate
		)
		P.box(half, "Inclusion", V(-side * 0.145, 0.02, 0.015), V(0.065, 0.54, 0.3), "BD8CDE", nil, Enum.Material.Neon)
		self.half[i] = half
	end
	self.wick = P.crystal(self.sample, Vector3.zero, 0.27)
	self.glow = P.light(self.wick:FindFirstChildWhichIsA("BasePart"), "D6A4FF", 4, 0)
	local benchLight = P.sphere(m, "Work lamp", V(2.2, 4.10, 1.3), V(0.42, 0.56, 0.42), "FFDC91", Enum.Material.Neon)
	P.light(benchLight, "FFD299", 13, 1.6)
	return self
end
function Workshop:draw(t, base)
	local plunge = ease(t, 32.2, 33.45)
	local lift = ease(t, 33.5, 34.65)
	local catch = ease(t, 34.1, 35.1)
	local present = ease(t, 35.05, 37.35)
	local open = ease(t, 36.15, 37.4)
	self.glow.Brightness = open * 1.6
	self.rotor:PivotTo(base * CF(-1.04, 3.42 - 0.57 * plunge + 0.75 * lift, 1.23) * A(0, (t - 32.2) * 15, 0))
	self.wheel:PivotTo(base * CF(-0.78, 3.92, 1.48) * A(0, 0, -plunge * 2.6 + lift * 3.7))
	local left = V(-0.56, 1.5, 0.35):Lerp(V(-0.92, 2.28, 1.23), catch):Lerp(V(-0.21, 2.60, 1.00), present)
	local right = V(0.72, 1.05, 0.37):Lerp(V(0.03, 2.37, 1.05), present)
	left += V(-0.28, 0.06, 0.12) * open
	right += V(0.29, 0.19, 0.08) * open
	self.worker:pose(base, 0.26 * (1 - present), -0.37 + 0.55 * present, 0.22 - 0.34 * present, left, right, 0)
	local sample = base
		* CF(V(-1.04, 1.99, 1.23):Lerp(V(-0.92, 2.38, 1.23), catch):Lerp(V(-0.12, 2.69, 1.08), present))
		* A(0, present * 0.37, -0.10 - 0.48 * present)
	for i, h in self.half do
		local s = if i == 1 then -1 else 1
		h:PivotTo(sample * CF(s * (0.165 + 0.23 * open), 0, 0) * A(0, s * open * 0.4, -s * 0.23 * open))
	end
	self.wick:PivotTo(sample * A(0, t * 0.8, 0.28))
end
return Workshop
