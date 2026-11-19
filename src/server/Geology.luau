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
-- Finite winding passages turn through their own rock tile. Their closed ends
-- keep opening one cave from instantiating a whole underground network.
local function passage(along, across, row, length, middle, phase)
	if along < 0 or along > length then
		return false
	end
	local t = along / length
	local bend = 3.2 * math.sin(t * 7 + phase) + 1.6 * math.sin(t * 12 + phase)
	local floor = middle + 1.2 * math.sin(t * 5 + phase)
	local width = 1.7 + 1.05 * math.sin(t * 8 + phase) ^ 2
	local taper = math.min(1, (along + 0.6) / 2, (length - along + 0.6) / 2)
	return ((across - bend) / width) ^ 2 + ((row - floor) / 1.85) ^ 2 < taper
end
function Geology:isCave(p)
	local row = -1 - p.Y
	if row < 3 then
		return false
	end
	local y = Config.FloorY - (row + 0.5) * Config.Cell
	if Config.strength(y + Config.Cell) ~= Config.strength(y - Config.Cell) then
		return false
	end
	if row < 12 and math.abs(p.X) < 12 and p.Z >= -41 and p.Z <= 2 then
		return passage(-p.Z - 7, p.X, row, 30, 4.8, 0)
	end
	local tx, tz, ty = math.floor(p.X / 40), math.floor(p.Z / 40), math.floor(row / 16)
	local h = hash(self.seed, tx, ty, tz)
	if h % 5 == 0 then
		return false
	end
	local x, z = p.X % 40, p.Z % 40
	if bit32.btest(h, 8) then
		x, z = z, x
	end
	return passage(z - 3, x - 18, row % 16, 32, 7 + bit32.extract(h, 4, 2), bit32.extract(h, 8, 5) * 0.2)
end
function Geology:material(p)
	if p.Y >= 0 then
		return Enum.Material.Cobblestone
	end
	if -p.Y <= Config.DirtLayers then
		-- The island foundation encloses the shallow dirt. Below it, headings
		-- can run under any part of the island without opening its surface.
		return if Config.inHall((p + Vector3.one * 0.5) * Config.Cell)
			then Ores.byName.Dirt.material
			else Enum.Material.Cobblestone
	end
	if self:isCave(p) then
		return Enum.Material.Air
	end
	local layer = Config.layer((-p.Y - 0.5) * Config.Cell)
	local roll = (hash(self.seed, p.X, p.Y, p.Z) % 100000) / 1000
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
