local P = require(script.Parent.Props)
local Space = {}
Space.__index = Space
local V, CF, A, rgb = Vector3.new, CFrame.new, CFrame.Angles, Color3.fromHex
function Space.new(shelf)
	local root = P.model(shelf, "Stellar nursery")
	local self = setmetatable({ root = root, shards = {}, dust = {} }, Space)
	P.box(root, "Night", V(0, 0, -115), V(480, 300, 1), "090B19", nil, Enum.Material.Neon)
	local rng = Random.new(3181)
	for i = 1, 138 do
		local x, y, z = rng:NextNumber(-115, 115), rng:NextNumber(-59, 59), rng:NextNumber(-96, -38)
		local r = rng:NextNumber(0.06, 0.27)
		local point = P.sphere(
			root,
			"Distant star",
			V(x, y, z),
			Vector3.one * r,
			if i % 4 == 0 then "FFE0A9" else "C0CDE8",
			Enum.Material.Neon
		)
		if i % 16 == 0 then
			P.box(root, "Star flare", point.Position, V(0.044, r * 3, 0.04), "FFDEBC", nil, Enum.Material.Neon)
		end
	end
	P.sphere(root, "Young planet", V(34, -40, -57), V(75, 75, 75), "473B56", Enum.Material.Slate)
	P.sphere(root, "Planet limb", V(34.8, -40.7, -59.8), V(76, 76, 76), "E6A68D", Enum.Material.Neon)
	local orbit = CF(34, -40, -57) * A(0.16, 0, -0.29)
	local prior
	for i = 0, 72 do
		local theta = i * math.pi / 36
		local p = orbit:PointToWorldSpace(V(math.cos(theta) * 54, 0, math.sin(theta) * 51))
		if prior then
			local band = P.rod(root, "Orbital dust", prior, p, 0.28, rgb("B49AA8"))
			band.Material, band.Transparency = Enum.Material.Neon, 0.38
		end
		prior = p
	end
	local sun = P.sphere(root, "Red giant", V(-23, 7, -54), Vector3.one * 15, "F8B17F", Enum.Material.Neon)
	P.light(sun, "FFC091", 35, 2)
	self.heart = P.crystal(root, Vector3.zero, 1.7)
	local key = P.sphere(root, "Stellar fill", V(-3, 3, 5), Vector3.one, "FFC995")
	key.Transparency = 1
	P.light(key, "FFD7B1", 24, 3)
	local rim = P.sphere(root, "Violet rim", V(2, 1, -2), Vector3.one, "C597F2")
	rim.Transparency = 1
	P.light(rim, "BB92E2", 14, 2.2)
	for i = 1, 15 do
		local a = i * 2.4
		local dir = V(math.sin(a), rng:NextNumber(-0.86, 0.86), math.cos(a)).Unit
		local rock = P.model(root, "Fracturing shell")
		local tip = V(-0.15, rng:NextNumber(0.65, 1.28), -0.15)
		local left, right, back = V(-0.62, -0.6, 0.22), V(0.54, -0.4, 0.37), V(0.18, -0.2, -0.51)
		P.face(rock, tip, left, right, rgb("927382"))
		P.face(rock, tip, right, back, rgb("694E67"))
		P.face(rock, tip, back, left, rgb("AD8179"))
		P.face(rock, back, right, left, rgb("DAA083"))
		table.insert(self.shards, { p = rock, dir = dir, spin = rng:NextNumber(0.38, 1.2) })
	end
	for i = 1, 26 do
		local dir = V(rng:NextNumber(-1, 1), rng:NextNumber(-0.65, 0.65), rng:NextNumber(-1, 1)).Unit
		table.insert(self.dust, {
			p = P.sphere(
				root,
				"Ember",
				Vector3.zero,
				Vector3.one * rng:NextNumber(0.06, 0.18),
				"FFD79F",
				Enum.Material.Neon
			),
			dir = dir,
			dist = rng:NextNumber(3, 17),
		})
	end
	return self
end
function Space:draw(t, base)
	local split = P.ease(t, 1.1, 3.7)
	local spin = A(0.08, t * 0.36, -0.17)
	self.heart:PivotTo(base * CF(0, 0.23 * math.sin(t), 0) * spin * A(0, 0.5, t * 0.16))
	for i, s in self.shards do
		s.p:PivotTo(
			base
				* spin
				* CF(s.dir * (1.35 + split * (2.8 + i % 4)))
				* A(t * s.spin, i + t * 0.45, i * 0.5 + split * 1.5)
		)
	end
	for _, s in self.dust do
		s.p.Position = base:PointToWorldSpace(s.dir * (2 + split * s.dist))
		s.p.Transparency = 1 - split * 0.92
	end
end
return Space
