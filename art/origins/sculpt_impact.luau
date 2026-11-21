-- Run with Lune from the project root to bake the native Roblox models.
-- Dimensions are in studs. All model pivots are the local origin.
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local I, V, CF, rgb = roblox.Instance, roblox.Vector3.new, roblox.CFrame, roblox.Color3.fromHex
local smooth, hot, slate = roblox.Enum.Material.SmoothPlastic, roblox.Enum.Material.Neon, roblox.Enum.Material.Slate
local tau = math.pi * 2
local library = I.new("Folder")
library.Name = "ImpactSculptures"

local function model(name)
	local m = I.new("Model")
	m.Name, m.Parent = name, library
	-- A physical pivot also survives import by .rbxm readers that omit WorldPivotData.
	local pivot = I.new("Part")
	pivot.Name, pivot.Size, pivot.CFrame = "Pivot", V(0.05, 0.05, 0.05), CF.identity
	pivot.Transparency, pivot.CastShadow = 1, false
	pivot.Anchored, pivot.CanCollide, pivot.CanQuery, pivot.CanTouch = true, false, false, false
	pivot.Parent, m.PrimaryPart = m, pivot
	return m
end

local function face(m, a, b, c, tone, material, name)
	local ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude > ac.Magnitude and ab.Magnitude > bc.Magnitude then
		a, c = c, a
	elseif ac.Magnitude > bc.Magnitude then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	if ac:Cross(ab).Magnitude < 0.00005 then
		return
	end
	local normal, along = ac:Cross(ab).Unit, bc.Unit
	local up = along:Cross(normal)
	for i, vertex in { b, c } do
		local sign = if i == 1 then 1 else -1
		local depth = math.abs((vertex - a):Dot(along))
		if depth > 0.001 then
			local p = I.new("WedgePart")
			p.Name, p.Material, p.Color = name or "Facet", material or smooth, rgb(tone)
			p.Size = V(0.023, math.abs(ab:Dot(up)), depth)
			p.CFrame = CF.fromMatrix((a + vertex) / 2, normal * sign, up, along * sign)
			p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
			p.CastShadow = (material ~= hot)
			p.Parent = m
		end
	end
end

-- A weathered meteorite, flattened at the leading edge, with seven twisting flutes.
-- Each cell dishes toward its center like a thumbprint. Copper fusion crust rims the
-- deeper cavities; the bare break on the +Z face shows the same purple core as the mine.
local meteor = model("Fluted iron")
local widths = { 0.43, 0.93, 1.05, 0.87, 0.32 }
local heights = { -2.36, -1.65, -0.1, 1.42, 2.46 }
local rings = {}
for row, radius in widths do
	local ring = {}
	for i = 1, 8 do
		local a = tau * (i - 1) / 8 + 0.12 * row
		local uneven = 1 + 0.12 * math.sin(i * 2.5 + 0.3 * row) + 0.055 * math.cos(i + row)
		ring[i] = V(
			3.48 * radius * uneven * math.cos(a) + 0.24 * (row - 3),
			heights[row] + 0.23 * math.sin(i * 2.2 + 0.79 * row),
			2.82 * radius * uneven * math.sin(a) + 0.19 * math.sin(row)
		)
	end
	rings[row] = ring
end
local iron = { "493A47", "59434F", "744D50", "443645", "6A4E57", "895D59" }
for j = 1, #rings - 1 do
	for i, a in rings[j] do
		local k = i % 8 + 1
		local b, c, d = rings[j][k], rings[j + 1][k], rings[j + 1][i]
		local center = (a + b + c + d) / 4
		local pit = center * 0.86 + V(0.13, -0.04, 0.06)
		local r = if (i + 2 * j) % 5 == 1 then 0.13 else 0
		local p, q, s, t = a:Lerp(center, r), b:Lerp(center, r), c:Lerp(center, r), d:Lerp(center, r)
		local color = iron[(i * 3 + j) % #iron + 1]
		face(meteor, p, q, pit, color, slate)
		face(meteor, q, s, pit, iron[(i + j + 1) % #iron + 1], slate)
		face(meteor, s, t, pit, iron[(i + 3 * j) % #iron + 1], slate)
		face(meteor, t, p, pit, color, slate)
		if r > 0 then
			local vein = if i % 2 == 0 then "F5AD75" else "C28897"
			for _, bank in { { a, b, p, q }, { b, c, q, s }, { c, d, s, t }, { d, a, t, p } } do
				local u, v, ui, vi = table.unpack(bank)
				face(meteor, u, v, vi, vein, smooth, "Fusion crust")
				face(meteor, u, vi, ui, vein, smooth, "Fusion crust")
			end
		end
	end
end
for i, b in rings[1] do
	local k = i % 8 + 1
	face(meteor, b, rings[1][k], V(-0.55, -2.53, 0.1), "705258", slate)
	face(meteor, rings[5][k], rings[5][i], V(0.72, 2.64, 0.1), "745762", slate)
end

-- A hot fracture has two bright broken banks inset into a low sheet of melt.
local scar = model("Contact fault")
local last
for _, p in
	{
		V(-4.5, 0, -1.9),
		V(-3.3, 0.15, -0.53),
		V(-1.9, 0.17, -0.73),
		V(-0.91, 0.31, 0.16),
		V(0.35, 0.36, -0.05),
		V(1.45, 0.23, 0.69),
		V(3.08, 0.12, 0.96),
		V(4.2, 0, 2),
	}
do
	local width = math.max(0.05, 1 - math.abs(p.X) / 4.6)
	local a, b, c = p + V(0, 0.05, width * 0.43), p + V(0, 0.02, -width * 0.47), p + V(0, 0.17, width * 0.06)
	if last then
		face(scar, a, last[1], c, "FFF5CC", hot)
		face(scar, c, last[1], last[3], "FFF1B2", hot)
		face(scar, c, last[3], b, "FFBB74", hot)
		face(scar, b, last[3], last[2], "FF9A58", hot)
	end
	last = { a, b, c }
end

-- Thin, wind-torn sheets of incandescent soil. Coordinates run along the fold
-- from left to right. A second lip doubles back and exposes the hot broken edge.
for variant, name in { "Low curtain", "Tall curtain", "Split curtain" } do
	local curtain = model(name)
	local rim = ({
		{
			V(-2.2, 0.7, 2.7),
			V(-1.8, 2.6, 3.5),
			V(-0.95, 2.36, 3.9),
			V(-0.62, 3.55, 4.1),
			V(0.17, 3.08, 4.05),
			V(0.7, 3.25, 3.87),
			V(1.29, 1.65, 3.6),
			V(2.1, 1.94, 3.1),
		},
		{
			V(-1.72, 1.48, 1.8),
			V(-1.43, 3.69, 2.0),
			V(-0.89, 3.08, 2.4),
			V(-0.48, 5.18, 2.82),
			V(0.25, 5.58, 2.67),
			V(0.74, 4.32, 2.19),
			V(1.28, 2.56, 2.1),
		},
		{
			V(-2.1, 0.97, 2.1),
			V(-1.48, 4, 2.75),
			V(-0.72, 4.19, 2.98),
			V(-0.28, 2.05, 2.65),
			V(0.06, 2.39, 2.64),
			V(0.56, 3.36, 3.29),
			V(1.13, 3.19, 3.18),
			V(1.68, 1.38, 2.52),
		},
	})[variant]
	local previous
	for i, v in rim do
		local foot = V(v.X * 0.28, 0, 0.1 * math.cos(i))
		local waist = foot:Lerp(v, 0.62) + V(0.12 * math.sin(i * 1.5), 0.2, -0.35)
		local fold = v + V(0.09, 0.11, 0.25)
		if previous then
			local f, w, r, l = table.unpack(previous)
			face(curtain, f, foot, waist, "B96851", smooth, "Scoria")
			face(curtain, f, waist, w, if i % 2 == 0 then "8D4D4D" else "C67B5A", smooth, "Scoria")
			face(curtain, w, waist, v, if i % 3 == 0 then "EC9D60" else "D88662", smooth, "Scoria")
			face(curtain, w, v, r, "AC685B", smooth, "Scoria")
			face(
				curtain,
				r,
				v,
				fold,
				if i % 3 == 0 then "E6A16D" else "FFD08C",
				if i % 3 == 0 then smooth else hot,
				"Molten lip"
			)
			face(curtain, r, fold, l, "F6A468", smooth, "Molten lip")
		end
		previous = { foot, waist, v, fold }
	end
end

-- Spalled stones split along a slant. Two differently colored bevels read as
-- a torn chunk with a warm underside even when it is only a few pixels wide.
for variant, name in { "Spall", "Slag blade" } do
	local rock = model(name)
	local form = if variant == 1
		then { V(-0.92, -0.14, -0.51), V(0.08, -0.1, -0.72), V(1.13, 0.13, -0.33), V(0.85, 0.2, 0.49), V(
			-0.21,
			0.11,
			0.75
		), V(
			-1.02,
			-0.16,
			0.29
		) }
		else { V(-1.22, -0.19, -0.3), V(-0.3, 0.03, -0.58), V(1.34, 0.25, -0.16), V(0.96, 0.17, 0.22), V(
			-0.48,
			0.04,
			0.47
		), V(
			-1.18,
			-0.13,
			0.31
		) }
	for i, v in form do
		local k = i % #form + 1
		local w = form[k]
		local lo = v * 0.78 - V(0.12, 0.28, 0)
		local ll = w * 0.78 - V(0.12, 0.28, 0)
		face(rock, v, w, V(0.17, 0.55, -0.08), if i % 2 == 0 then "685660" else "504551", slate)
		face(rock, v, lo, w, "99705D", slate)
		face(rock, lo, ll, w, if i % 3 == 0 then "E59B65" else "C08061", smooth)
		face(rock, lo, V(-0.13, -0.45, 0.02), ll, "79565B", slate)
	end
end
fs.writeFile("src/client/MineOrigins/ImpactSculptures.rbxm", roblox.serializeModel({ library }))
