local Shared = game:GetService("ReplicatedStorage").Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local Geology = {}
Geology.__index = Geology
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
local function hash(seed, x, y, z)
	local n = bit32.bxor(seed, x * 73856093, y * 19349663, z * 83492791)
	n = bit32.bxor(n, bit32.rshift(n, 16))
	n = bit32.band(n * 1664525, 0xffffffff)
	n = bit32.bxor(n, bit32.rshift(n, 15))
	n = bit32.band(n * 1597333, 0xffffffff)
	return bit32.bxor(n, bit32.rshift(n, 16))
end
function Geology.new(seed)
	return setmetatable({ seed = seed }, Geology)
end
local function chamber(x, y, z, rx, ry, rz)
	return (x / rx) ^ 2 + (y / ry) ^ 2 + (z / rz) ^ 2 < 1
end
function Geology:isCave(p)
	local row = -1 - p.Y
	if row < Config.DirtLayers + 1 then
		return false
	end
	-- Solid bands at Power transitions keep a natural shaft from skipping the gate.
	local y = Config.FloorY - (row + 0.5) * Config.Cell
	if Config.strength(y + Config.Cell) ~= Config.strength(y - Config.Cell) then
		return false
	end
	-- A small pocket just past the lower workface gives early miners a cave to discover.
	if chamber(p.X - 2, row - 6, p.Z + 44, 4.2, 2.6, 4.0) then
		return true
	end
	if row < 12 and math.abs(p.X) <= 15 and p.Z >= -51 and p.Z <= -14 then
		return false
	end
	local tx, ty, tz = math.floor(p.X / 20), math.floor(row / 14), math.floor(p.Z / 20)
	local h = hash(self.seed, tx, ty, tz)
	if h % 5 == 0 then
		return false
	end
	local x = p.X % 20 - 8 - bit32.extract(h, 4, 2)
	local dy = row % 14 - 6 - bit32.extract(h, 6, 1)
	local z = p.Z % 20 - 8 - bit32.extract(h, 8, 2)
	-- Two joined lobes fit inside their tile, bounding the work of opening a pocket.
	return chamber(x, dy, z, 4.8, 2.6, 3.6) or chamber(x - 3, dy + 0.8, z + 1.4, 3.4, 2.1, 3.1)
end
function Geology:material(p)
	if p.Y >= 0 then
		return Enum.Material.Cobblestone
	end
	if -p.Y <= Config.DirtLayers then
		return Ores.byName.Dirt.material
	end
	if self:isCave(p) then
		return Enum.Material.Air
	end
	local layer = Config.layer((-p.Y - 0.5) * Config.Cell)
	local roll = hash(self.seed, p.X, p.Y, p.Z) % 100
	for _, entry in thresholds[layer] do
		if roll < entry.limit then
			return entry.material
		end
	end
	return layer.material
end
-- Coordinates are relative to the entrance in studs, as in a Studio map probe.
function Geology:sample(x, y, z)
	return self:material((Vector3.new(x, y - Config.FloorY, z) / Config.Cell):Floor())
end
return Geology
