local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.GameConfig)
local Ores = require(Shared.Ores)
local Geology = {}
Geology.__index = Geology
local air = Enum.Material.Air

function Geology.new(seed)
	return setmetatable({ seed = seed, veins = {} }, Geology)
end

-- One seeded, tilted vein per 32-stud region. A few deeper regions grow a
-- wider gem lode with a hollow pocket through its centre.
function Geology:vein(a, b, c)
	local key = (a + 16) * 4096 + (b + 32) * 64 + c + 16
	if self.veins[key] then
		return self.veins[key]
	end
	local rng = Random.new((self.seed + a * 73856093 + b * 19349663 + c * 83492791) % 2147483647)
	local x, y, z =
		a * 32 + rng:NextNumber(10, 22), b * 32 + rng:NextNumber(10, 22), c * 32 + rng:NextNumber(10, 22)
	local depth = math.max(0, -y)
	local lode = depth >= 104 and rng:NextNumber() < 0.075
	local total, ore = 0, Ores.byName.Coal
	for i = 2, #Ores.list do
		local candidate = Ores.list[i]
		if depth >= candidate.min and (not lode or candidate.hardness >= 4) then
			local weight = candidate.weight / (1 + ((depth - candidate.preferred) / 58) ^ 2)
			total += weight
			if rng:NextNumber() * total < weight then
				ore = candidate
			end
		end
	end
	local v = {
		x = x,
		y = y,
		z = z,
		ore = ore,
		lode = lode,
		tilt = rng:NextNumber(-0.45, 0.45),
		rx = if lode then 13 else rng:NextNumber(7, 11),
		ry = if lode then 12 else rng:NextNumber(4, 7),
		rz = if lode then 14 else rng:NextNumber(6, 10),
	}
	self.veins[key] = v
	return v
end

function Geology:sample(x, y, z)
	local top = Config.ridgeHeight(self.seed, x, z)
	if y > top then
		return air, 0
	end
	-- Scallop the face beyond the tram entrance and expose a darker rock band.
	local shoulder = math.clamp((math.abs(x) - 15) / 16, 0, 1)
	local face = -shoulder * (4 + math.sin(x / 9) * 2 + math.max(0, y) * 0.14)
	if y >= 0 and z > face then
		return air, 0
	end
	if y >= 0 and z > -23 and (x / 13) ^ 2 + (y / 15) ^ 2 < 1 then
		return air, 0
	end
	if y > top - 3 then
		return Enum.Material.Grass, math.clamp((top + 2 - y) / 4, 0.3, 1)
	end
	if shoulder > 0.4 and z > face - 8 and math.abs(y - 12 - math.sin(x / 14) * 3) < 2 then
		return Enum.Material.Rock, 1
	end

	-- A visible, accessible coal seam and copper pocket at the first face.
	if ((x + 1) / 8) ^ 2 + ((y - 6) / 4.5) ^ 2 + ((z + 25) / 7) ^ 2 < 1 then
		return Ores.byName.Coal.material, 1
	end
	if ((x - 9) / 5) ^ 2 + ((y - 5) / 5) ^ 2 + ((z + 28) / 6) ^ 2 < 1 then
		return Ores.byName.Copper.material, 1
	end

	local v = self:vein(math.floor(x / 32), math.floor(y / 32), math.floor(z / 32))
	local dx, dz = x - v.x, z - v.z
	local d = (dx / v.rx) ^ 2 + ((y - v.y - dx * v.tilt) / v.ry) ^ 2 + (dz / v.rz) ^ 2
	if d < 1 and math.max(0, -y) >= v.ore.min then
		if v.lode and d < 0.20 then
			return air, 0
		end
		return v.ore.material, 1
	end
	return Config.layer(-y).material, 1
end
return Geology
