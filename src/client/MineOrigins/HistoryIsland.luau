-- Closed rock parcels let a bank be cut down in successive exposures. Each
-- parcel uses the same vertices as its neighbours until a cut exposes its side.
local P = require(script.Parent.Props)
local Island = {}
local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local rgb = Color3.fromHex
local TAU, slices = 2 * math.pi, 38
local crater = V(0, -0.205, -37.25)
local function mound(x, z, cx, cz, rx, rz)
	return math.exp(-((x - cx) / rx) ^ 2 - ((z - cz) / rz) ^ 2)
end

local function tide(shelf, register, spent)
	local sea = P.model(shelf, "Open strait and submerged banks")
	local bands = {}
	local function add(part, ancient, modern)
		part.CastShadow = false
		local key = ancient .. modern
		if not bands[key] then
			bands[key] = { old = rgb(ancient), new = rgb(modern), parts = {} }
		end
		table.insert(bands[key].parts, part)
	end
	-- At sea level the sight line reaches well beyond the entire camera move.
	for x = -2, 2 do
		for z = -2, 2 do
			local p = P.box(sea, "Open sea", V(x * 1984, -4.91, z * 1984), V(1984, 0.35, 1984), "31586F")
			add(p, "547B92", "407C99")
		end
	end
	local contours = {}
	local rings = {
		{ 0, "31586F", "3FBCD0" },
		{ 164, "31586F", "3FBCD0" },
		{ 217, "386079", "40ADB9" },
		{ 285, "426A82", "409EAE" },
		{ 390, "4A7188", "408FA4" },
		{ 575, "50778E", "40869E" },
	}
	for k, ring in rings do
		local vertices = {}
		for i = 1, slices do
			local az = i * TAU / slices
			local r = ring[1] * (1 + 0.052 * math.sin(3 * az) + 0.04 * math.sin(5 * az + 0.5))
			vertices[i] = V(r * math.cos(az), -4.65 - 0.016 * k, 20 + r * 1.03 * math.sin(az))
		end
		if k > 1 then
			local patch = P.model(sea, "Shallow soundings")
			for i = 1, slices do
				local j = i % slices + 1
				if k == 2 then
					P.face(patch, V(0, -4.67, 20), vertices[i], vertices[j], rgb(ring[2]))
				else
					P.face(patch, contours[i], vertices[i], vertices[j], rgb(ring[2]))
					P.face(patch, contours[i], vertices[j], contours[j], rgb(ring[2]))
				end
				spent(3)
			end
			for _, p in patch:GetChildren() do
				add(p, ring[2], ring[3])
			end
		end
		contours = vertices
	end
	register(sea, 0, nil, true)
	return bands
end

local function coastAt(a)
	local x, z = math.cos(a), math.sin(a)
	-- Ray from the crater inside a displaced ellipse, with coves incised
	-- into the west-facing headland and a long southern spit.
	local dz = crater.Z - 19
	local aa = x * x / 146 ^ 2 + z * z / 143 ^ 2
	local b = 2 * z * dz / 143 ^ 2
	local c = dz * dz / 143 ^ 2 - 1
	local distance = (-b + math.sqrt(b * b - 4 * aa * c)) / (2 * aa)
	local function spur(direction, width)
		return math.exp(-((math.atan2(math.sin(a - direction), math.cos(a - direction))) / width) ^ 2)
	end
	return distance
		* (
			1
			+ 0.085 * math.sin(3 * a - 0.73)
			+ 0.04 * math.cos(5 * a + 0.4)
			+ 0.026 * math.sin(9 * a)
			+ 0.30 * spur(2.66, 0.21)
			- 0.31 * spur(2.23, 0.22)
			+ 0.20 * spur(1.79, 0.20)
			- 0.20 * spur(1.44, 0.17)
			+ 0.21 * spur(0.64, 0.23)
			- 0.31 * spur(0.24, 0.18)
			- 0.16 * spur(-1.72, 0.27)
		)
end

local function vertex(ring, i)
	local a = i * TAU / slices + 0.022 * math.sin(i * 1.64 + ring * 1.29)
	-- The inner lip is the same coal-stained ellipse as the preceding impact.
	local radius = 1 / math.sqrt((math.cos(a) / 34) ^ 2 + (math.sin(a) / 29) ^ 2)
	local coast = coastAt(a)
	local multipliers = { 0.36, 0.73, 1, 1.25 }
	local reach
	if ring <= 4 then
		reach = multipliers[ring] * radius * (1 + 0.039 * math.sin(3 * a + 0.5) + 0.028 * math.sin(5 * a))
	else
		local land = { 0.14, 0.31, 0.48, 0.65, 0.81, 0.965, 1.065 }
		reach = 1.25 * radius + (coast - 1.25 * radius) * land[ring - 4]
	end
	local x = crater.X + math.cos(a) * reach
	local z = crater.Z + math.sin(a) * reach
	local rough = math.sin(x * 0.05 + z * 0.037) * 2.5 + math.cos(z * 0.077 - x * 0.058) * 1.4
	local h
	if ring <= 4 then
		h = ({ -3.45, -0.83, 3.73, 1.43 })[ring] + (0.18 + ring * 0.12) * math.sin(a * 3 + 0.4)
	else
		local capes = (0.5 + 0.5 * math.cos(5 * a - 0.8)) ^ 4
		local hills = 5
			+ 35 * mound(x, z, -77, -25, 48, 52)
			+ 42 * mound(x, z, 57, -39, 46, 52)
			+ 37 * mound(x, z, -6, -85, 55, 30)
			+ 26 * mound(x, z, -33, 70, 34, 48)
			+ 38 * mound(x, z, 74, 73, 29, 45)
			+ 37 * mound(x, z, -97, 58, 27, 34)
			+ 27 * mound(x, z, 13, 121, 32, 25)
			- 13 * mound(x, z, -6, 73, 25, 68)
		h = if ring == 11
			then -10.3
			elseif ring == 10 then -0.8 + 9.6 * capes + 1.95 * math.sin(a * 4 + 0.25)
			elseif ring == 9 then hills * 0.58 + rough + 8 * capes
			else hills + rough
	end
	return V(x, h + crater.Y, z)
end

-- A tapered vertical surface needs exactly a rectangular foot and one wedge.
local function wall(model, a, b, bottom, tint)
	local h, l = if a.Y > b.Y then a else b, if a.Y > b.Y then b else a
	local delta = V(h.X - l.X, 0, h.Z - l.Z)
	local n = delta.Magnitude
	if n < 0.05 then
		return
	end
	local mid = (h + l) * 0.5
	local function frame(y)
		local at = V(mid.X, y, mid.Z)
		return CFrame.lookAt(at, at - delta)
	end
	if l.Y > bottom + 0.015 then
		P.part(model, "Rock section", V(0.11, l.Y - bottom, n), frame((l.Y + bottom) * 0.5), tint)
	end
	if h.Y > l.Y + 0.015 then
		P.part(model, "Raked face", V(0.11, h.Y - l.Y, n), frame((h.Y + l.Y) * 0.5), tint, "WedgePart")
	end
end

local function gradeAt(ring, p)
	if ring <= 3 then
		return 4.07 + ring * 0.16 + 0.14 * math.sin(p.X * 0.11)
	end
	if p.Z < -28 or (p.Z < 4 and math.abs(p.X) > 46) then
		return 4.32 + 0.86 * math.clamp(-p.Z / 107, 0, 1) + 0.18 * math.sin(p.X * 0.095)
	end
	local sweep = math.clamp(0.46 + p.X / 300 - p.Z / 410, 0, 1)
	if p.Z < 25 and math.abs(p.X) < 63 then
		return 9.18 + sweep * 0.99
	end
	if ring >= 10 then
		return 6.54 + 1.62 * sweep + 0.38 * math.sin(p.X * 0.06)
	end
	return 7.76 + sweep * 2.22 + 0.28 * math.sin(p.X * 0.067 + p.Z * 0.023)
end

local function paint(model, verts, hue)
	P.face(model, verts[1], verts[2], verts[3], hue)
	if #verts == 4 then
		P.face(model, verts[1], verts[3], verts[4], hue)
	end
end

-- Basalt is exposed in oblique beds. Their vertices follow the very same
-- two triangles as the ground, including its diagonal, so a stratum never
-- floats across a hollow or vanishes beneath a steeper section.
local function bedding(model, vs, across, width, tone)
	local a, b, c, d = table.unpack(vs)
	local lift = V(0, 0.11, 0)
	local function line(q)
		return { a:Lerp(b, q) + lift, a:Lerp(c, q) + lift, d:Lerp(c, q) + lift }
	end
	local low, top = line(across), line(across + width)
	for j = 1, 2 do
		P.face(model, low[j], low[j + 1], top[j], tone)
		P.face(model, low[j + 1], top[j + 1], top[j], tone)
	end
end

-- Four connected sections share their rim vertices. Removing the light upper
-- bed leaves a naturally broken rock stack rooted below the tideline.
local function seaStacks(shelf, register, spent)
	local heads = {
		{ 2.82, 18, 10, 19 },
		{ 2.59, 11, 5, 8 },
		{ 2.04, 15, 7, 14 },
		{ 1.78, 18, 12, 22 },
		{ 1.68, 31, 6, 9 },
		{ 1.04, 15, 7, 12 },
		{ 0.62, 11, 11, 18 },
		{ 0.41, 24, 5, 8 },
		{ -0.28, 13, 6, 13 },
		{ -2.69, 16, 9, 18 },
	}
	for k, head in heads do
		local az, distance, r, h = table.unpack(head)
		local dir = V(math.cos(az), 0, math.sin(az))
		local point = crater + dir * (coastAt(az) + distance)
		local seed = Random.new(k * 237)
		local spin = seed:NextNumber(-2, 2)
		local rim = {}
		for j = 1, 7 do
			local angle = j * TAU / 7 + spin
			local reach = r * (0.81 + 0.18 * math.sin(j * 3.5 + spin))
			rim[j] = V(math.cos(angle) * reach, 0, math.sin(angle) * reach * 0.67)
		end
		local last = {}
		local cuts =
			{ { 0, 1.12, "625B60" }, { 0.38, 1.00, "736869" }, { 0.47, 0.86, "B19B83" }, { 1, 0.66, "837471" } }
		for m, bed in cuts do
			local ring = {}
			for j, v in rim do
				local u = bed[1]
				ring[j] = V(point.X, -7.6, point.Z)
					+ v * bed[2]
					+ V(u * r * 0.17, h * u + u * (v.X * 0.19 + math.sin(j * 4 + k) * 0.66), u * r * 0.12)
			end
			if m > 1 then
				local rock = P.model(shelf, "Tide-cut sea stack")
				local center = Vector3.zero
				for _, v in ring do
					center += v
				end
				center /= #ring
				for j, v in ring do
					local n = j % #ring + 1
					local tint = rgb(bed[3]):Lerp(rgb("A18B79"), 0.075 * ((j + k) % 3))
					P.face(rock, v, ring[n], last[j], tint)
					P.face(rock, ring[n], last[n], last[j], tint)
					P.face(rock, v, ring[n], center, rgb("8C7F71"))
				end
				for _, p in rock:GetChildren() do
					p.Material = Enum.Material.Slate
				end
				register(rock, 0, 6.05 + (k % 4) * 0.23 + (4 - m) * 0.37, true)
				spent(38)
			end
			last = ring
		end
	end
end

local function woodland(shelf, register, spent, patch, index)
	local p = patch.center
	if patch.clear < 6.0 or patch.ring < 5 or patch.ring > 9 then
		return
	end
	local planted = 3.38 + 1.50 * math.clamp((p.Z + 65) / 190, 0, 1) + 0.22 * (index % 3)
	local group = P.model(shelf, "A stand on the uncut hillside")
	local a, b, c = patch.verts[1], patch.verts[2], patch.verts[3]
	local seed = Random.new(4017 + index)
	for j = 1, if index % 4 == 1 then 3 else 2 do
		local u, w = seed:NextNumber(0.08, 0.64), seed:NextNumber(0.08, 0.34)
		local root = a + (b - a) * u + (c - a) * w
		local h = seed:NextNumber(7.0, 16.2)
		P.box(
			group,
			"Pine trunk",
			root + V(0, h * 0.25, 0),
			V(h * 0.11, h * 0.55, h * 0.11),
			"725740",
			nil,
			Enum.Material.Wood
		)
		if (index + j) % 3 ~= 0 then
			for k = 1, 4 do
				local a = k * 2.4 + seed:NextNumber(-0.4, 0.4)
				local crown = P.sphere(
					group,
					"Wind-cut canopy",
					root + V(math.cos(a) * h * 0.19, h * (0.53 + k * 0.073), math.sin(a) * h * 0.19),
					V(h * 0.66, h * 0.43, h * 0.53),
					if k % 2 == 0 then "668050" else "537A51"
				)
				crown.CFrame *= A(0.16 * math.sin(a), a, 0.17 * math.cos(a))
			end
			spent(5)
			continue
		end
		-- Intersecting quadrilateral boughs keep the miniature's silhouette.
		local tint = rgb(if j == 1 then "3E6755" elseif j == 2 then "557D58" else "416F50")
		for tier = 1, 2 do
			local base = root + V(0, h * (if tier == 1 then 0.32 else 0.60), 0)
			local tip = root + V(0, h * (if tier == 1 then 0.81 else 1.06), 0)
			local width = h * (if tier == 1 then 0.34 else 0.23)
			local phase = seed:NextNumber(0, 0.7)
			for side = 1, 4 do
				local aa = phase + side * math.pi / 2
				local bb = aa + math.pi / 2
				P.face(
					group,
					base + V(math.cos(aa) * width, 0, math.sin(aa) * width),
					base + V(math.cos(bb) * width, 0, math.sin(bb) * width),
					tip,
					tint
				)
			end
		end
		spent(17)
	end
	register(group, planted, patch.clear - 0.33, true)
end

local function buildCliffs(shelf, register, spent)
	local grid = {}
	for r = 1, 11 do
		grid[r] = {}
		for i = 1, slices do
			grid[r][i] = vertex(r, i)
		end
	end
	local patches = {}
	for r = 1, 11 do
		patches[r] = {}
		for i = 1, slices do
			local j = i % slices + 1
			local vs = if r == 1
				then { crater + V(0, -4.17, 0), grid[1][i], grid[1][j] }
				else { grid[r - 1][i], grid[r][i], grid[r][j], grid[r - 1][j] }
			local center = Vector3.zero
			for _, v in vs do
				center += v
			end
			center /= #vs
			patches[r][i] = { verts = vs, ring = r, center = center, clear = gradeAt(r, center) }
		end
	end
	local coatings, plantings, cuts = {}, {}, {}
	for r, strip in patches do
		for i, part in strip do
			local vs, at = part.verts, part.center
			local paintAge = 1.80 + 0.23 * r + 0.59 * (math.sin(i * 0.57) * 0.5 + 0.5)
			local brown = if r == 1
				then "4A4652"
				elseif r == 2 then "665966"
				elseif r == 3 then "5C535E"
				elseif r == 4 then "826F6B"
				elseif r >= 10 then "958976"
				elseif at.Y > 30 then "786D72"
				else "9B837B"
			local green = if r <= 2
				then "8D8273"
				elseif r <= 4 then "94936F"
				elseif r == 10 then "B39D7C"
				elseif r == 11 then "938375"
				elseif at.Y > 30 then "788166"
				else "7C965E"
			local delta = ((r * 3 + i * 7) % 8) / 55
			local early = rgb(brown):Lerp(rgb("C4A397"), delta)
			local heath = rgb(green):Lerp(rgb("B9A985"), delta)
			local rock = P.model(shelf, if r <= 4 then "Sealed impact basin" else "Ancient folded headland")
			paint(rock, vs, early)
			local top = rock:GetChildren()
			for _, facet in top do
				facet.Material = Enum.Material.Slate
			end
			table.insert(
				coatings,
				{ parts = top, start = paintAge, old = early, new = heath, meadow = r > 4 and r < 10 }
			)
			-- Shattered layers run into the basin on its western face and out
			-- through two worn shoulders. Their spacing follows the local slope.
			if (r == 2 or r == 3) and (i % 13 < 8) then
				bedding(rock, vs, 0.26 + 0.076 * math.sin(i * 0.65), 0.10, rgb(if r == 2 then "847477" else "937E77"))
			elseif (r == 5 or r == 6 or r == 9) and (i % 17 < 4 or i > 29 and i < 35) then
				bedding(rock, vs, 0.27 + 0.13 * math.sin(i * 0.53), 0.07, rgb("8B7771"))
			end
			if r <= 4 and (i * 5 + r * 7) % 11 < 3 then
				local seed = Random.new(i * 771 + r)
				for j = 1, 4 do
					local origin = vs[1]
						+ (vs[2] - vs[1]) * seed:NextNumber(0.06, 0.48)
						+ (vs[3] - vs[1]) * seed:NextNumber(0.07, 0.46)
					local k = seed:NextNumber(0.33, 1.38) * (if r == 1 then 0.62 else 1)
					local stone = P.sphere(
						rock,
						"Settled ejecta",
						origin + V(0, 0.11 * k, 0),
						V(2.8 * k, 1.38 * k, 2.14 * k),
						if j == 1 then "5A555D" else "73676A",
						Enum.Material.Slate
					)
					stone.CFrame *= A(0.09 * j, seed:NextNumber(-3, 3), 0.26)
				end
			end
			local stage = part.clear
			local cut =
				{ stage = stage, verts = vs, bench = stage > 7 and r > 4 and r < 10, edges = {}, first = stage, tone = delta }
			for edge = 1, #vs do
				local nextEdge = edge % #vs + 1
				local neighbour
				if r == 1 then
					neighbour = if edge == 1
						then strip[(i - 2) % slices + 1]
						elseif edge == 2 then patches[2][i]
						else strip[i % slices + 1]
				elseif edge == 1 then
					neighbour = strip[(i - 2) % slices + 1]
				elseif edge == 2 then
					neighbour = if r < 11 then patches[r + 1][i] else nil
				elseif edge == 3 then
					neighbour = strip[i % slices + 1]
				else
					neighbour = patches[r - 1][i]
				end
				if neighbour and neighbour.clear < stage or not neighbour and r < 11 then
					table.insert(cut.edges, { edge, nextEdge })
					cut.first = math.min(cut.first, if neighbour then neighbour.clear else 0)
				end
			end
			register(rock, 0, stage, true)
			table.insert(cuts, cut)
			if (i + r) % 3 ~= 0 or r == 6 then
				table.insert(plantings, { part, i + r * 47 })
			end
			spent(#rock:GetChildren())
		end
	end
	local coastalPoint, seabed = grid[10][12], grid[11][12]
	-- Take the landing from the natural waterline on the sheltered side of
	-- the southern spit, close to the front of the miniature.
	local dock = coastalPoint:Lerp(seabed, math.clamp((coastalPoint.Y + 3.4) / (coastalPoint.Y - seabed.Y), 0, 1))
	return coatings, dock, plantings, patches, cuts
end

-- An interior rock face cannot be seen until the neighbouring parcel has
-- been quarried. Build those faces ahead of the settlement exposures; keep
-- them out of the ancient renderer, where the adjacent parcels share a lid.
local function benches(land, shelf, register, spent)
	for _, cut in land.cuts do
		local vs = cut.verts
		if #cut.edges > 0 then
			local section = P.model(shelf, "Exposed rim of the earthwork")
			for _, e in cut.edges do
				wall(section, vs[e[1]], vs[e[2]], -8.3, rgb("796A65"))
			end
			register(section, cut.first, cut.stage, true)
			spent(#section:GetChildren())
		end
		if cut.bench then
			local bench = P.model(shelf, "First pass of the quarry bench")
			local lower = {}
			for _, v in vs do
				table.insert(lower, V(v.X, math.max(0.33, v.Y * 0.42), v.Z))
			end
			paint(bench, lower, rgb("B29978"):Lerp(rgb("916F59"), cut.tone))
			for edge, v in lower do
				wall(bench, v, lower[edge % #lower + 1], -5.5, rgb("96785B"))
			end
			register(bench, cut.stage, cut.stage + 0.43, true)
			spent(#bench:GetChildren())
		end
	end
	land.cuts = nil
end

local function bedAt(land, x, z)
	for _, strip in land.patches do
		for _, p in strip do
			local a = p.verts[1]
			for j = 2, #p.verts - 1 do
				local b, c = p.verts[j], p.verts[j + 1]
				local u, v = b - a, c - a
				local det = u.X * v.Z - u.Z * v.X
				if math.abs(det) < 0.001 then
					continue
				end
				local s = ((x - a.X) * v.Z - (z - a.Z) * v.X) / det
				local t = (u.X * (z - a.Z) - u.Z * (x - a.X)) / det
				if s >= -0.0001 and t >= -0.0001 and s + t <= 1.0001 then
					return a.Y + s * u.Y + t * v.Y, p.clear
				end
			end
		end
	end
	return -5, 6
end

local function surveyTrail(land, shelf, register, spent)
	local x, z = land.dock.X, land.dock.Z
	local switches = {
		V(x, 0, z),
		V(x * 0.77, 0, z * 0.85),
		V(x * 0.48, 0, z * 0.79),
		V(x * 0.53, 0, z * 0.49),
		V(x * 0.32, 0, z * 0.60),
		V(x * 0.16, 0, z * 0.32),
		V(-8, 0, 14),
	}
	local teams = {}
	for k = 2, #switches do
		local first, last = switches[k - 1], switches[k]
		local steps = math.max(1, math.ceil((first - last).Magnitude / 5.6))
		for j = 1, steps do
			table.insert(teams, { first:Lerp(last, (j - 1) / steps), first:Lerp(last, j / steps) })
		end
	end
	for i, ends in teams do
		local a, b = table.unpack(ends)
		local right = (b - a).Unit:Cross(Vector3.yAxis) * (1.14 + 0.23 * math.sin(i * 0.72))
		local strip = P.model(shelf, "Survey cut across the hillside")
		local corners = {}
		local clear = 10.5
		for _, point in { a + right, b + right, b - right, a - right } do
			local y, age = bedAt(land, point.X, point.Z)
			clear = math.min(clear, age)
			table.insert(corners, V(point.X, y + 0.19, point.Z))
		end
		paint(strip, corners, rgb(if i % 4 == 0 then "C49F73" else "B59A74"))
		if i % 4 == 1 then
			local at = corners[3]
			P.box(strip, "Survey stake", at + V(0, 1.18, 0), V(0.22, 2.48, 0.22), "BE915C")
			P.face(strip, at + V(0, 2.44, 0), at + V(0, 1.7, 0), at + V(1.29, 2.02, 0.18), rgb("FFC46C"))
		end
		local start = 6.42 + 1.27 * (i / #teams)
		if clear > start then
			register(strip, start, clear, true)
		else
			strip:Destroy()
		end
		spent(5)
	end
	local pad = switches[3]
	local elevation, clear = bedAt(land, pad.X, pad.Z)
	local deckY = elevation + 0.62
	local sill = P.model(shelf, "A level platform for the survey")
	for _, side in { -1, 1 } do
		for _, endZ in { -1, 1 } do
			local foot = pad + V(side * 3.6, 0, endZ * 3.7)
			local floor = bedAt(land, foot.X, foot.Z)
			deckY = math.max(deckY, floor + 0.48)
		end
	end
	for _, side in { -1, 1 } do
		for _, endZ in { -1, 1 } do
			local foot = pad + V(side * 3.6, 0, endZ * 3.7)
			local floor = bedAt(land, foot.X, foot.Z)
			P.box(
				sill,
				"Camp pile",
				foot + V(0, (floor + deckY) * 0.5, 0),
				V(0.56, deckY - floor + 0.23, 0.56),
				"937250"
			)
		end
	end
	P.box(sill, "Camp decking", pad + V(0, deckY, 0), V(8.6, 0.58, 9), "B29571", nil, Enum.Material.Wood)
	register(sill, 6.91, clear - 0.14, true)
	local hut = P.model(shelf, "Canvas over the prospectors' camp")
	local front, back = pad + V(0, deckY + 6.9, -4.5), pad + V(0, deckY + 6.9, 4.5)
	for _, side in { -1, 1 } do
		local lowA, lowB = front + V(4.2 * side, -6.45, 0), back + V(4.2 * side, -6.45, 0)
		P.face(hut, front, back, lowA, rgb("E8A365"))
		P.face(hut, back, lowB, lowA, rgb("D68C56"))
	end
	P.box(hut, "Signal mast", pad + V(3.75, deckY + 6.4, -3.68), V(0.25, 12.5, 0.25), "B68A5D")
	P.face(
		hut,
		pad + V(3.75, deckY + 12.57, -3.7),
		pad + V(3.75, deckY + 9.9, -3.7),
		pad + V(9.2, deckY + 11.2, -2.2),
		rgb("F5994D")
	)
	register(hut, 7.18, clear - 0.25, true)
end

local function waterInCrater(shelf, register, spent)
	for i, spec in { { 1.45, 3.1, 6.5, -3.98 }, { 3.1, 4.02, 13.1, -3.25 }, { 4.02, 4.39, 20.7, -1.74 } } do
		local model = P.model(shelf, "Rainwater sealed above the fault")
		local center = crater + V(0, spec[4], 0)
		for j = 1, 18 do
			local function edge(k)
				local a = k * TAU / 18
				local radius = spec[3] * (1 + 0.091 * math.sin(a * 3))
				return center + V(math.cos(a) * radius, 0, math.sin(a) * radius * 0.85)
			end
			P.face(model, center, edge(j), edge(j + 1), rgb(if i == 1 then "778F90" else "719A99"))
			spent(2)
		end
		register(model, spec[1], spec[2], true)
	end
end

function Island.build(shelf, register, spent)
	local bands = tide(shelf, register, spent)
	seaStacks(shelf, register, spent)
	local coatings, dock, plantings, patches, cuts = buildCliffs(shelf, register, spent)
	waterInCrater(shelf, register, spent)
	return { bands = bands, coatings = coatings, dock = dock, plantings = plantings, patches = patches, cuts = cuts }
end

function Island.plant(land, shelf, register, spent)
	benches(land, shelf, register, spent)
	for _, patch in land.plantings do
		woodland(shelf, register, spent, patch[1], patch[2])
	end
	surveyTrail(land, shelf, register, spent)
	land.plantings = nil
	land.patches = nil
end

function Island.expose(land, t)
	local clear = math.clamp((t - 2.1) / 3.5, 0, 1)
	if clear ~= land.clear then
		land.clear = clear
		for _, b in land.bands do
			local hue = b.old:Lerp(b.new, clear)
			for _, p in b.parts do
				p.Color = hue
			end
		end
	end
	if t <= 6 or land.last == nil or land.last < 6 then
		for _, b in land.coatings do
			local step = math.clamp(math.floor((t - b.start) * 3.6), 0, 3)
			if step ~= b.step then
				b.step = step
				local color = b.old:Lerp(b.new, step / 3)
				for _, p in b.parts do
					p.Color = color
					p.Material = if step == 3 and b.meadow then Enum.Material.Grass else Enum.Material.Slate
				end
			end
		end
	end
	land.last = t
end

return Island
