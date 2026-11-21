local P = require(script.Parent.Props)
local V, CF, A, ease = Vector3.new, CFrame.new, CFrame.Angles, P.ease
local rgb = Color3.fromHex
local Burial = {}
Burial.__index = Burial

-- Depth, then vertical speed (studs/sec). Hermite interpolation keeps velocity
-- continuous as the core crosses each formation and finally loses momentum.
local knots = {
	{ 6.50, -1.5, 14 },
	{ 7.58, 13, 22 },
	{ 8.39, 36, 37 },
	{ 9.10, 67, 54 },
	{ 10.10, 133, 84 },
	{ 10.56, 174, 84 },
	{ 10.81, 185.5, 0 },
}
local function depth(t)
	for i = 2, #knots do
		local a, b = knots[i - 1], knots[i]
		if t <= b[1] then
			local span = b[1] - a[1]
			local u = math.clamp((t - a[1]) / span, 0, 1)
			return a[2] * (1 - 3 * u * u + 2 * u ^ 3)
				+ b[2] * (3 * u * u - 2 * u ^ 3)
				+ a[3] * span * u * (1 - u) ^ 2
				+ b[3] * span * u * u * (u - 1)
		end
	end
	return knots[#knots][2]
end
local function faultX(d)
	return 0.72 + 0.125 * d + 2.1 * math.sin(d / 26) + 0.72 * math.sin(d / 9)
end
function Burial.point(t)
	local d = depth(t)
	return V(faultX(d), -d, 0.42 + 0.43 * math.sin(d / 29))
end

-- A continuous geological section. Each boundary is shared by the beds on
-- either side. Their narrowing center strips break and reclose in sequence.
local beds = {
	{ 0, "8B7670" },
	{ 3.3, "6E5559" },
	{ 7, "91695A" },
	{ 11, "AB795D" },
	{ 14, "784E4D" },
	{ 18, "A9765C" },
	{ 22, "BA9270" },
	{ 27, "8B7867" },
	{ 31, "B9A17C" },
	{ 36, "D2B999" },
	{ 38.1, "8C827D" },
	{ 43, "AA967C" },
	{ 47, "B9997A" },
	{ 53, "946C64" },
	{ 58, "AF7666" },
	{ 61, "7D5B5D" },
	{ 67, "AA7265" },
	{ 74, "8A5D60" },
	{ 79, "B17F72" },
	{ 82, "77565D" },
	{ 90, "815F68" },
	{ 95, "706273" },
	{ 103, "71677C" },
	{ 109, "5C586A" },
	{ 119, "68667D" },
	{ 124, "827A87" },
	{ 128, "535A69" },
	{ 137, "616375" },
	{ 148, "4E596B" },
	{ 153, "708091" },
	{ 156, "475364" },
	{ 168, "586478" },
	{ 174, "445064" },
	{ 181, "55586F" },
	{ 187, "505669" },
	{ 194, "3C475A" },
	{ 203, "586278" },
	{ 215, "464F66" },
	{ 239, "424859" },
	{ 278, "424859" },
}
local function layerY(d, offset)
	local weight = math.min(math.abs(offset) / 10, 1)
	local fold = 2.8 * math.sin(offset / 25 + d * 0.014) + 1.7 * math.sin(offset / 13.8 - d * 0.022)
	local slope = offset * (0.055 + 0.062 * math.sin(d * 0.014))
	return -d + weight * (fold + slope) - 2.8 * math.exp(-(offset / 18) ^ 2) * math.exp(-d / 4.1)
end
local function faceZ(d, offset)
	return 2.1 + 0.78 * math.sin(d * 0.072 + offset * 0.09) + 0.44 * math.cos(offset * 0.15 - d * 0.10)
end
local function vertex(d, offset)
	return V(faultX(d) + offset, layerY(d, offset), faceZ(d, offset))
end
local function quad(parent, a, b, c, d, ink)
	P.face(parent, a, b, c, ink)
	P.face(parent, a, c, d, ink)
end
local function mouth(d)
	return (1.66 + 0.78 * math.sin(d * 0.19) ^ 2 + 0.47 * math.cos(d * 0.081) + 2.20 * math.exp(-((d - 184) / 4) ^ 2))
end
local function strikeTime(d)
	local low, high = 6.5, 10.81
	for _ = 1, 14 do
		local middle = (low + high) * 0.5
		if depth(middle) < d then
			low = middle
		else
			high = middle
		end
	end
	return high
end

local function layers(self)
	local surface = P.model(self.root, "Folded sediment and basalt")
	self.shutters = {}
	for row = 1, #beds - 1 do
		local d, nextD = beds[row][1], beds[row + 1][1]
		local ink = rgb(beds[row][2])
		local bed = P.model(surface, "Bedding plane")
		local finish = if d < 22
			then Enum.Material.Ground
			elseif d < 54 then Enum.Material.Limestone
			elseif d < 95 then Enum.Material.Sandstone
			elseif d < 153 then Enum.Material.Slate
			else Enum.Material.Basalt
		for _, sign in { -1, 1 } do
			local inner, lowerInner = sign * mouth(d), sign * mouth(nextD)
			local top = { inner, sign * 11, sign * 24, sign * 43, sign * 76, sign * 121, sign * 210 }
			local bottom = table.clone(top)
			bottom[1] = lowerInner
			for col = 1, #top - 1 do
				local a, b, c, e =
					vertex(d, top[col]),
					vertex(d, top[col + 1]),
					vertex(nextD, bottom[col + 1]),
					vertex(nextD, bottom[col])
				local color = ink:Lerp(rgb("7B6E71"), 0.03 + 0.055 * math.sin(col * 2.1 + row * 1.41) ^ 2)
				quad(bed, a, b, c, e, color)
			end
			local upper, lower = vertex(d, inner), vertex(nextD, lowerInner)
			quad(surface, upper, lower, lower - V(0, 0, 8.3), upper - V(0, 0, 8.3), ink:Lerp(rgb("282739"), 0.52))
			local uMid = vertex(d, 0) + V(0, 0, 0.12)
			local lMid = vertex(nextD, 0) + V(0, 0, 0.12)
			local shutter = P.model(self.root, "Fault shutter")
			quad(shutter, uMid, upper, lower, lMid, ink:Lerp(rgb("716271"), 0.04))
			quad(shutter, uMid, lMid, lMid - V(0, 0, 2.8), uMid - V(0, 0, 2.8), ink:Lerp(rgb("313043"), 0.47))
			for _, face in shutter:GetChildren() do
				face.Material = finish
			end
			local center = (uMid + upper + lower + lMid) * 0.25
			shutter.WorldPivot = CF(center)
			local at = (nextD + d) * 0.5
			table.insert(self.shutters, {
				model = shutter,
				d = at,
				at = strikeTime(at),
				side = sign,
				center = center,
				span = math.abs(inner) * 1.44,
				reachable = d < 189,
			})
		end
		for _, face in bed:GetChildren() do
			face.Material = finish
		end
		coroutine.yield()
		-- Back wall seen only through the moving fracture.
		local backA, backB = vertex(d, -mouth(d)), vertex(d, mouth(d))
		local lowA, lowB = vertex(nextD, -mouth(nextD)), vertex(nextD, mouth(nextD))
		local feed = V(0, 0, 8.35)
		quad(surface, backA - feed, backB - feed, lowB - feed, lowA - feed, ink:Lerp(rgb("29253C"), 0.84))
	end
	-- The knife cut intersects the ancient shoreline. Its dark, irregular cap
	-- anchors the surface at the top of the first below-ground shot.
	for i = -7, 6 do
		local a, b = vertex(0, i * 26), vertex(0, (i + 1) * 26)
		quad(surface, a, b, b + V(0, 3.7, -16), a + V(0, 3.7, -16), rgb("80706B"))
	end
end

local function ornaments(self)
	local material = P.model(self.root, "Mineral lenses and shell beds")
	local rng = Random.new(993)
	for i = 1, 64 do
		local d = rng:NextNumber(8, 189)
		local off = (if i % 2 == 0 then 1 else -1) * rng:NextNumber(8.4, 65)
		local c = vertex(d, off) + V(0, 0, 0.11)
		local width = rng:NextNumber(0.7, 3.1)
		local color = if d < 51 then "B5A18D" elseif d < 91 then "AF8178" else "7C7B89"
		local l =
			P.sphere(material, "Pressure lens", c, V(width * 2, 0.17 + width * 0.25, 0.55), color, Enum.Material.Slate)
		l.CFrame *= A(0, 0, 0.16 * math.sin(d * 0.041 + off * 0.035))
	end
	-- Halves of fossil shells reveal which of the passing beds once held water.
	for i, entry in { { 33, -17, 1.1 }, { 43, 20, 0.78 }, { 51, -10, 0.66 }, { 27, 30, 0.55 } } do
		local d, off, s = table.unpack(entry)
		local center = vertex(d, off) + V(0, 0, 0.43)
		local previous
		for j = 0, 14 do
			local phi = j * 0.55
			local r = (0.11 + j * 0.099) * s
			local point = center + V(math.cos(phi) * r, math.sin(phi) * r * 0.85, 0)
			if previous then
				local rib = P.rod(material, "Fossil whorl", previous, point, 0.10 * s, rgb("D5BD9E"))
				rib.CastShadow = false
			end
			previous = point
		end
	end
	self.veins = {}
	for i, d in { 15, 31, 38, 54, 71, 89, 104, 122, 139, 158, 179, 185 } do
		local direction = if i % 3 == 1 then -1 else 1
		local previous = vertex(d, direction * mouth(d)) + V(0, 0, 0.08)
		for j = 1, 4 do
			local off = direction * (mouth(d) + j * (1.6 + 0.4 * (i % 3)))
			local p = vertex(d + 0.58 * math.sin(i + 0.9 * j), off) + V(0, 0, 0.16)
			local stroke = P.rod(
				material,
				"Transmission along bedding",
				previous,
				p,
				if j == 1 then 0.13 else 0.074,
				rgb("D9ADFE")
			)
			stroke.Material, stroke.CastShadow, stroke.Transparency = Enum.Material.Neon, false, 1
			table.insert(self.veins, { part = stroke, at = strikeTime(d) + 0.035 * j })
			previous = p
		end
	end
end

function Burial.new(parent)
	local self = setmetatable({ root = P.model(parent, "Section through the island") }, Burial)
	self.loader = coroutine.create(function()
		layers(self)
		ornaments(self)
		local fill =
			P.box(self.root, "Cold skylight on the basal section", V(-3, -151, 23), Vector3.one * 0.12, "AFC9E2")
		fill.Transparency, fill.CastShadow = 1, false
		P.light(fill, "BDCCDF", 79, 1.45)
	end)
	return self
end

function Burial:prepare(rows)
	while self.loader and rows > 0 do
		local ok, message = coroutine.resume(self.loader)
		if not ok then
			error(message, 2)
		end
		if coroutine.status(self.loader) == "dead" then
			self.loader = nil
		end
		rows -= 1
	end
end

function Burial:draw(t, base)
	for _, leaf in self.shutters do
		if leaf.reachable then
			local s = t - leaf.at
			local closeAt = if leaf.d >= 179 then 0.66 else 0.43
			local opening = ease(s, -0.16, 0.02) * (1 - ease(s, closeAt, closeAt + 0.43))
			if opening ~= leaf.last then
				leaf.last = opening
				local x = leaf.side * leaf.span * opening
				local y = -0.38 * opening + 0.24 * math.sin(math.pi * opening)
				local hinge = CF(leaf.center + V(x, y, -opening * 0.65))
				leaf.model:PivotTo(base * hinge * A(0, leaf.side * 0.29 * opening, leaf.side * 0.08 * opening))
			end
		end
	end
	for _, seam in self.veins do
		local age = t - seam.at
		local strength = ease(age, -0.07, 0.06) * (1 - ease(age, 0.12, 0.54))
		seam.part.Transparency = 1 - strength * 0.89
	end
end

return Burial
