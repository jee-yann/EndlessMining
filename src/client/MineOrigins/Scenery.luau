-- Practical foreground models for the painted prologue.
local Scenery = {}
local V, rgb = Vector3.new, Color3.fromHex
local function model(parent, name)
	local m = Instance.new("Model")
	m.Name, m.WorldPivot, m.Parent = name, CFrame.identity, parent
	return m
end
local function part(parent, name, size, cf, color, class)
	local p = Instance.new(class or "Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.TopSurface, p.BottomSurface, p.Parent = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth, parent
	return p
end
local function orb(parent, name, at, size, color)
	local p = part(parent, name, size, CFrame.new(at), color)
	p.Shape = Enum.PartType.Ball
	return p
end
local function rod(parent, name, a, b, width, color)
	return part(parent, name, V(width, width, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), color)
end
-- Split a triangular face along the altitude to its longest side.
local function face(parent, a, b, c, color)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local normal, along = ac:Cross(ab).Unit, bc.Unit
	local up = along:Cross(normal)
	local height = math.abs(ab:Dot(up))
	for i, vertex in { b, c } do
		local sign = if i == 1 then 1 else -1
		local depth = math.abs((vertex - a):Dot(along))
		if depth > 0.01 and height > 0.01 then
			part(
				parent,
				"Facet",
				V(0.025, height, depth),
				CFrame.fromMatrix((a + vertex) / 2, normal * sign, up, along * sign),
				color,
				"WedgePart"
			)
		end
	end
end

-- The pale gold edge and lavender fracture recur in orbit, in the lamp and
-- in the drill sample. These are asymmetric splinters, with a broken base.
local function crystal(parent, at, size)
	local m = model(parent, "Star heart")
	local top, foot = V(0.23, 1.4, -0.06) * size, V(-0.17, -0.86, 0.04) * size
	local waist = {
		V(-0.51, -0.19, 0),
		V(-0.13, 0.02, 0.41),
		V(0.42, -0.18, 0.17),
		V(0.36, -0.22, -0.26),
		V(-0.18, -0.31, -0.33),
	}
	local hues = { "FFE9B6", "F2D4FF", "BC8FE4", "6E588F", "AD8DC7" }
	for i, v in waist do
		local w = waist[i % #waist + 1] * size
		local color = rgb(hues[i])
		face(m, top, v * size, w, color)
		face(m, foot, w, v * size, color:Lerp(rgb("5F487E"), 0.44))
	end
	-- Splitting planes through the crystal catch a different color as it turns.
	local fracture = {
		V(-0.38, -0.16, 0.19),
		V(-0.13, 0.02, 0.43),
		V(0.032, 0.34, 0.302),
		V(0.14, 0.47, 0.232),
		V(0.17, 0.92, 0.104),
	}
	for i = 2, #fracture do
		rod(
			m,
			"Bright fracture",
			fracture[i - 1] * size,
			fracture[i] * size,
			math.max(0.025, 0.027 * size),
			rgb("FFF2CD")
		)
	end
	m:PivotTo(CFrame.new(at))
	return m
end

local function stars(parent, rng, count, width, bottom, top, z)
	for i = 1, count do
		local at = V(rng:NextNumber(-width, width), rng:NextNumber(bottom, top), z - rng:NextNumber(0, 12))
		local r = rng:NextNumber(0.10, 0.41)
		local tint = rgb("9FAACF"):Lerp(rgb("FFE5BF"), rng:NextNumber())
		orb(parent, "Starlight", at, Vector3.one * r, tint)
		if i % 12 == 0 then
			part(parent, "Diffraction", V(r * 0.3, r * 3, 0.05), CFrame.new(at), tint)
			part(parent, "Diffraction", V(r * 2, r * 0.28, 0.05), CFrame.new(at), tint)
		end
	end
end
function Scenery.space(parent)
	local sky = model(parent, "The dying star")
	local rng = Random.new(311)
	stars(sky, rng, 170, 108, -55, 57, -63)
	-- Ejecta form an inclined, broken belt behind the tumbling hero fragment.
	for i = 1, 28 do
		local x = rng:NextNumber(-34, 34)
		local at = V(x, x * 0.25 + rng:NextNumber(-2.6, 2.6), -5 - rng:NextNumber(0, 18))
		local size = rng:NextNumber(0.06, 0.33)
		part(
			sky,
			"Cinder",
			V(size * 1.6, size, size * 0.65),
			CFrame.new(at) * CFrame.Angles(x, i, 0.3),
			rgb("79637C"):Lerp(rgb("F6C18E"), rng:NextNumber()),
			"WedgePart"
		)
	end
	return sky, crystal(sky, Vector3.zero, 2.6)
end

function Scenery.landfall(parent)
	local coast = model(parent, "Impact coast")
	local rng = Random.new(3496)
	local stage = { root = coast }
	stage.trail = model(coast, "Falling ember")
	crystal(stage.trail, Vector3.zero, 1.1)
	for i, width in { 0.81, 0.47, 0.20 } do
		face(
			stage.trail,
			V(-width, 0, 0.03 * i),
			V(width, 0, 0.03 * i),
			V(-i * 1.9, i * 3.5, 0.03 * i),
			rgb(({ "D794B5", "F1BAA5", "FFDFAB" })[i])
		)
	end
	stage.impact = model(coast, "Ejecta")
	stage.stones = {}
	for i = 1, 23 do
		local a = i * 2.4
		local velocity =
			V(math.sin(a) * rng:NextNumber(3, 8), rng:NextNumber(6, 18), math.cos(a) * rng:NextNumber(3, 8))
		local size = rng:NextNumber(0.25, 0.95)
		local stone = part(
			stage.impact,
			"Hot basalt",
			V(size, size * 1.5, size * 0.72),
			CFrame.identity,
			if i % 3 == 0 then rgb("FFCD9A") else rgb("8D6377"),
			"WedgePart"
		)
		table.insert(stage.stones, { part = stone, velocity = velocity })
	end
	stage.scar = crystal(coast, V(0, 0.4, 0), 1.65)
	return stage
end

return Scenery
