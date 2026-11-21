-- Natural rock above the later terrain cuts. The talus uses the dimensions
-- of the native mesa caps, and the coastal beds follow each live escarpment.
-- Strike reads these same triangles for its establishing camera.
local Atlas = require(script.Parent.HistoryAtlas)
local V = Vector3.new
local Mantle = { points = {}, faces = {} }

local function point(at, stripTime)
	local index = #Mantle.points + 1
	Mantle.points[index] = { at, stripTime }
	return index
end
local function facet(a, b, c, tone)
	table.insert(Mantle.faces, { a, b, c, tone })
end
local function ramp(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end
local function height(x, z)
	local h = -9
	for _, cap in Atlas.bluffs do
		local cx, y, cz, w, d = table.unpack(cap)
		local dx, dz = (x - cx) / (w * 0.59 + 8.2), (z - cz) / (d * 0.61 + 7.8)
		-- A resistant shoulder remains near the old crown. Eroded gravel
		-- falls away steeply beyond it; adjacent shoulders become one saddle.
		local r = math.sqrt(dx * dx + dz * dz)
		local q = math.max(0, r - 0.48)
		local shoulder = (y + 16) * math.exp(-0.80 * q * q) - 8
		h = math.max(h, shoulder)
	end
	if h < -4 then
		return -6.88
	end
	local rough = 2.7 * math.sin(x * 0.056 + z * 0.091)
		+ 2.3 * math.cos(x * 0.121 - z * 0.069)
		+ 1.1 * math.sin(z * 0.25)
	local radius = math.sqrt((x / 35) ^ 2 + ((z + 37.25) / 31) ^ 2)
	local rim = ramp((radius - 1.08) / 0.54)
	return -6.88 + (h + rough + 6.88) * rim
end

local grid = {}
for j = 0, 16 do
	grid[j] = {}
	for i = 0, 30 do
		local x = -183 + i * 12.2 + 3.0 * math.sin(j * 1.26 + i * 2.58)
		local z = -155 + j * 11.35 + 2.3 * math.sin(i * 0.97 - j * 1.83)
		local y = height(x, z)
		local quarry = 5.10 + 2.6 * math.clamp(0.46 + x / 360 + z / 580, 0, 1)
		grid[j][i] = point(V(x, y, z), quarry)
	end
end
for j = 1, 16 do
	for i = 1, 30 do
		local a, b, c, d = grid[j - 1][i - 1], grid[j - 1][i], grid[j][i], grid[j][i - 1]
		local function add(v, w, s)
			local p, q, r = Mantle.points[v][1], Mantle.points[w][1], Mantle.points[s][1]
			if math.max(p.Y, q.Y, r.Y) < -0.8 then
				return
			end
			local slope = math.abs((q - p):Cross(r - p).Unit.Y)
			local band = if slope > 0.86 then 3 elseif slope > 0.59 then 2 else 1
			facet(v, w, s, band)
		end
		if (i + j) % 2 == 0 then
			add(a, b, c)
			add(a, c, d)
		else
			add(a, b, d)
			add(b, c, d)
		end
	end
end

local bands = {
	{ -11.1, 1.10, 1.6 },
	{ 0.65, 1.06, 1.65 },
	{ 4.1, 0.82, 0.11 },
	{ 6.8, 0.70, -0.33 },
	{ 7.6, 0.60, -0.86 },
	{ 10.2, 0.48, -1.60 },
	{ 15.8, 0.0, -3.96 },
}
local bank = {}
for i, p in Atlas.coast do
	local x, z, top = table.unpack(p)
	local normal = V(x, 0, z - 27.75).Unit
	local stray = 1.6 * math.cos(i * 0.83) + 1.1 * math.sin(i * 1.91)
	local quarry = 7.3 + 2.06 * math.clamp(0.45 + x / 318 - z / 390, 0, 1)
	bank[i] = {}
	for k, s in bands do
		local dist = s[1] + stray * (0.65 + 0.18 * k)
		local y = top * s[2] + s[3] + math.sin(i * 1.53 + k * 0.34) * (0.6 + top * 0.035) * s[2]
		bank[i][k] = point(V(x, y, z) + normal * dist, quarry)
	end
end
for i, row in bank do
	local nextRow = bank[i % #bank + 1]
	for k = 2, #row do
		local tone = ({ 4, 5, 6, 5, 7, 6 })[k - 1]
		facet(row[k - 1], nextRow[k - 1], nextRow[k], tone)
		facet(row[k - 1], nextRow[k], row[k], tone)
	end
end
return Mantle
