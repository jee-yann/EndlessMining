-- The center of the settled basin opens like two sides of one sheared rock
-- bed. Both shelves share every boundary vertex with the surrounding crater.
local P = require(script.Parent.Props)
local V, CF, A, rgb, ease = Vector3.new, CFrame.new, CFrame.Angles, Color3.fromHex, P.ease
local Fault = {}
Fault.__index = Fault
local function vertex(at)
	return { at = at, point = at }
end
local function add(self, a, b, c, color)
	-- Endpoint fans meet at a single point.
	if (b.at - a.at):Cross(c.at - a.at).Magnitude < 0.001 then
		return
	end
	local ink = rgb(color)
	local pieces = {}
	for i = 1, 2 do
		pieces[i] = P.part(self.root, "Broken bedrock", Vector3.one, CFrame.identity, ink, "WedgePart")
	end
	table.insert(self.faces, { a, b, c, pieces })
end
local function fit(face, base)
	local a, b, c = face[1].point, face[2].point, face[3].point
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > math.max(ac.Magnitude, bc.Magnitude) then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local normal, along = ac:Cross(ab).Unit, bc.Unit
	local up = along:Cross(normal)
	for i, v in { b, c } do
		local sign = if i == 1 then 1 else -1
		local p = face[4][i]
		p.Size = V(0.025, math.max(0.025, math.abs(ab:Dot(up))), math.max(0.025, math.abs((v - a):Dot(along))))
		p.CFrame = base * CFrame.fromMatrix((a + v) * 0.5, normal * sign, up, along * sign)
	end
end
local function grounded(bed, x, z)
	return V(x, bed:heightAt(x, z), z)
end
function Fault.new(parent, bed)
	local self = setmetatable(
		{ root = P.model(parent, "Sealed impact fault"), faces = {}, banks = {}, lightPaths = {}, chips = {} },
		Fault
	)
	local previous
	for i = 0, 16 do
		local outerA = bed.edge[i + 1]
		local outerB = bed.edge[(32 - i) % 32 + 1]
		local taper = math.sin(i * math.pi / 16)
		local x = (outerA.X + outerB.X) * 0.5
		local z = (x * 0.26 + 0.87 * math.sin(i * 2.27) + 0.41 * math.cos(i * 1.29)) * taper
		local center = if i == 0 or i == 16 then outerA else grounded(bed, x, z)
		local row = { center = center, sides = {}, floor = center - V(0, 0.76 + 0.25 * taper, 0) }
		for n, edge in { outerA, outerB } do
			local side = if n == 1 then 1 else -1
			local lip = vertex(center)
			local wall = vertex(center - V(0, 1.56 + 0.64 * taper, 0))
			local mid = center:Lerp(edge, 0.49)
			local seam = {
				inner = lip,
				low = wall,
				mid = vertex(grounded(bed, mid.X, mid.Z)),
				outer = vertex(edge),
				side = side,
				dist = math.abs(x - 1.6),
				span = taper * (1.06 + 0.18 * math.cos(i * 2.3)),
				last = -1,
			}
			row.sides[n] = seam
			table.insert(self.banks, seam)
			if previous then
				local last = previous.sides[n]
				local middle = if n == 1 then "685B5E" else "66595E"
				add(self, last.inner, seam.inner, seam.mid, middle)
				add(self, last.inner, seam.mid, last.mid, middle)
				add(self, last.mid, seam.mid, seam.outer, "736367")
				add(self, last.mid, seam.outer, last.outer, "736367")
				add(self, last.inner, seam.inner, seam.low, "3F3549")
				add(self, last.inner, seam.low, last.low, "4A3A4C")
			end
		end
		if previous then
			local a, b = previous.floor, row.floor
			local under = rgb("292335")
			P.face(self.root, a - V(0, 0.16, 2), b - V(0, 0.16, 2), b + V(0, -0.16, 2), under)
			P.face(self.root, a - V(0, 0.16, 2), b + V(0, -0.16, 2), a + V(0, -0.16, 2), under)
			local vein = P.rod(self.root, "Light below the lip", a, b, 0.16 + 0.12 * taper, rgb("BD7EFF"))
			local hair =
				P.rod(self.root, "Hot center of fault", a + V(0, 0.08, 0), b + V(0, 0.08, 0), 0.078, rgb("FFE1F3"))
			vein.Material, hair.Material = Enum.Material.Neon, Enum.Material.Neon
			vein.CastShadow, hair.CastShadow = false, false
			table.insert(
				self.lightPaths,
				{ violet = vein, hair = hair, dist = math.abs((a.X + b.X) * 0.5 - 1.6), taper = taper }
			)
		end
		previous = row
	end
	local lamp = P.box(self.root, "Light rising through the fault", V(0.8, -3.12, 0.32), Vector3.one * 0.1, "FFFFFF")
	lamp.Transparency, lamp.CastShadow = 1, false
	self.lamp = P.light(lamp, "D6A6F5", 19, 0)
	local rng = Random.new(48009)
	for i = 1, 24 do
		local x = rng:NextNumber(-12.4, 12.1)
		local side = if i % 2 == 0 then 1 else -1
		local z = 0.25 * x + side * rng:NextNumber(2.3, 6.5)
		local s = rng:NextNumber(0.15, 0.55)
		local at = grounded(bed, x, z) + V(0, s * 0.13, 0)
		local p = P.part(self.root, "Scoria fragment", V(s * 1.5, s * 0.63, s), CF(at), rgb("635359"), "WedgePart")
		table.insert(
			self.chips,
			{ part = p, at = at, side = side, off = rng:NextNumber(0, 0.38), rot = rng:NextNumber(-1.4, 1.4) }
		)
	end
	return self
end

function Fault:draw(t, base)
	local reflection = 0
	for _, p in self.lightPaths do
		local ext = 0.035 * p.dist
		local ignite = ease(t, 8.65 + ext, 9.09 + ext)
		local ember = 0.52 * (1 - ease(t, 9.30, 10.04))
		local pull = ease(t, 10.07 - ext, 10.30 - ext) * (1 - ease(t, 10.43 - ext, 10.80 - ext))
		local glow = ignite * math.clamp(ember + pull, 0, 1) * p.taper ^ 0.6
		p.violet.Transparency, p.hair.Transparency = 1 - glow, 1 - glow * 0.85
		reflection = math.max(reflection, glow)
	end
	self.lamp.Brightness = reflection * 1.78
	local dirty = false
	for _, b in self.banks do
		local open = ease(t, 8.60 + 0.034 * b.dist, 9.05 + 0.029 * b.dist)
			* (1 - ease(t, 10.54 + 0.014 * b.dist, 11.28 + 0.010 * b.dist))
		if b.last ~= open then
			b.last = open
			local move = V(0.12 * b.side, 0.40 + 0.08 * b.side, b.side * 1.08) * b.span * open
			b.inner.point = b.inner.at + move
			b.low.point = b.low.at + V(move.X * 0.38, move.Y * 0.38, move.Z * 0.48)
			b.mid.point = b.mid.at + move * 0.14
			dirty = true
		end
	end
	if dirty then
		for _, f in self.faces do
			fit(f, base)
		end
	end
	for _, c in self.chips do
		local settle = ease(t, 10.26 + c.off, 11.09 + c.off)
		c.part.CFrame = base
			* CF(c.at + V(0.21 * settle, 0.22 * math.sin(math.pi * settle) - 0.12 * settle, -c.side * 0.73 * settle))
			* A(0.15 + c.rot * 0.24, c.rot + settle * 0.9, -0.08)
	end
end
return Fault
