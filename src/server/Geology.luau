local Shared = game:GetService("ReplicatedStorage").Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local Geology = {}
Geology.__index = Geology
local earth, air = Enum.Material.Cobblestone, Enum.Material.Air
local thresholds = {}
for _, layer in Config.Layers do
	local list, total = {}, 0
	for _, ore in Ores.list do
		local chance = layer.oreChances[ore.name]
		if chance then
			total += chance
			table.insert(list, { limit = total, material = ore.material })
		end
	end
	thresholds[layer] = list
end

function Geology.new(seed)
	return setmetatable({ seed = seed }, Geology)
end

-- Two rounds of integer mixing avalanche each cell's coordinates independently.
-- The ore key is generated on the server and never replicated to players.
local function roll(seed, x, y, z)
	local n = bit32.bxor(seed, x * 73856093, y * 19349663, z * 83492791)
	n = bit32.bxor(n, bit32.rshift(n, 16))
	-- Products stay below 2^53, preserving all low bits in Luau numbers.
	n = bit32.band(n * 1664525, 0xffffffff)
	n = bit32.bxor(n, bit32.rshift(n, 15))
	n = bit32.band(n * 1597333, 0xffffffff)
	return bit32.bxor(n, bit32.rshift(n, 16)) % 100
end

function Geology:sample(x, y, z)
	local cell = Config.Cell
	-- Only the narrow portal crosses authored surface scenery. Below the island
	-- foundation the full field opens out, with one sealed cell on every edge.
	if y >= -24 then
		local top = Config.ridgeHeight(Config.LandscapeSeed, x, z)
		if y > top or (math.abs(x) < 12 and z > -8 and y > 12) then
			return air, 0
		end
		if y >= 0 and z > -24 and math.abs(x) < 8 and y < 12 then
			return air, 0
		end
		local gallery = math.abs(x) < 8 and z >= -48 and y < 12 and (y < 8 or z > -24)
		if y <= -8 and math.abs(x) < 40 and z >= -104 and z < -4 then
			gallery = true
		end
		if not gallery or y + cell > top or (z > -4 and y < 0) then
			if (math.abs(x) > 44 or z < -108) and y + cell > top and y >= -12 then
				return Enum.Material.Grass, 1
			end
			return earth, 1
		end
	end
	if
		x < Config.Min.X + cell
		or x >= Config.Max.X - cell
		or z < Config.Min.Z + cell
		or (z >= Config.Max.Z - cell and y < 0)
		or y < Config.Min.Y + cell
	then
		return earth, 1
	end
	local layer = Config.layer(-y)
	local value = roll(self.seed, math.floor(x / cell), math.floor(y / cell), math.floor(z / cell))
	for _, entry in thresholds[layer] do
		if value < entry.limit then
			return entry.material, 1
		end
	end
	if y >= -Config.DirtMaxDepth and value >= 72 then
		return Ores.byName.Dirt.material, 1
	end
	return layer.material, 1
end
return Geology
