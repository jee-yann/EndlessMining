-- The impact and time-lapse share the headland above the future gallery.
-- Coordinates are relative to the playable mine's portal paving.
local shore = require(script.Parent.HistoryAtlas).coast
local V, TAU = Vector3.new, 2 * math.pi
local Land = { crater = V(0, -0.205, -37.25), rings = 10, slices = 44 }
local rim = {}
for i, p in shore do
	rim[i] = { x = p[1] - Land.crater.X, z = p[2] - Land.crater.Z, height = p[3] }
end

local function coastRay(angle)
	local dx, dz = math.cos(angle), math.sin(angle)
	for i, a in rim do
		local b = rim[i % #rim + 1]
		local ex, ez = b.x - a.x, b.z - a.z
		local det = dx * ez - dz * ex
		if math.abs(det) > 0.00001 then
			local run, along = (a.x * ez - a.z * ex) / det, (a.x * dz - a.z * dx) / det
			if run > 0 and along >= -0.00001 and along <= 1.00001 then
				return run, a.height + (b.height - a.height) * along
			end
		end
	end
	error("Strike is outside the surveyed cove")
end
Land.shoreAt = coastRay

local function dome(x, z, cx, cz, width, depth)
	return math.exp(-((x - cx) / width) ^ 2 - ((z - cz) / depth) ^ 2)
end

-- The northern high ground already has its modern dimensions. The temporary
-- higher ground is concentrated on the future landing court and market lots.
local function upland(x, z)
	return 6
		+ 18 * dome(x, z, -62, -19, 46, 44)
		+ 22 * dome(x, z, 70, -30, 49, 40)
		+ 17 * dome(x, z, -52, 65, 48, 48)
		+ 25 * dome(x, z, 67, 66, 52, 58)
		+ 10 * dome(x, z, 11, 114, 50, 32)
		- 6 * dome(x, z, -11, 56, 26, 64)
end

local function sample(r, i)
	local a = i * TAU / Land.slices + 0.017 * math.sin(i * 1.73 + r)
	local dx, dz = math.cos(a), math.sin(a)
	local rimRadius = 1 / math.sqrt((dx / 34) ^ 2 + (dz / 29) ^ 2)
	local coast, crest = coastRay(a)
	local reach, h
	if r <= 4 then
		reach = ({ 0.34, 0.71, 1, 1.21 })[r] * rimRadius * (1 + 0.034 * math.sin(3 * a + 0.51))
		h = ({ -3.2, -1.2, 3.6, 1.63 })[r] + math.sin(a * 3 + 0.4) * (0.17 + r * 0.12)
	else
		local u = ({ 0.19, 0.44, 0.70, 0.87, 0.976, 1 })[r - 4]
		reach = 1.21 * rimRadius + u * (coast - 1.21 * rimRadius)
		local x, z = dx * reach, Land.crater.Z + dz * reach
		local rough = 1.4 * math.sin(x * 0.048 + z * 0.052) + 0.65 * math.cos(x * 0.066 - z * 0.094)
		if r == 10 then
			-- Fall into the same wave-cut shelf retained on the inhabited island.
			reach += 3.3
			h = -3.32 + 0.54 * math.cos(a * 4)
		elseif r == 9 then
			h = crest + 1.4 + 1.9 * math.cos(a * 3.5)
		elseif r == 8 then
			h = upland(x, z) * 0.49 + crest * 0.51 + rough
		else
			h = upland(x, z) + rough
		end
	end
	return Land.crater + V(reach * dx, h, reach * dz)
end
local grid = {}
for r = 1, Land.rings do
	grid[r] = {}
	for i = 1, Land.slices do
		grid[r][i] = sample(r, i)
	end
end
function Land.vertex(r, i)
	return grid[r][(i - 1) % Land.slices + 1]
end
return Land
