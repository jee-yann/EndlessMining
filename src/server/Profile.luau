local Shared = game:GetService("ReplicatedStorage").Shared
local Ores = require(Shared.Ores)
local Upgrades = require(Shared.Upgrades)
local Profile = {}

function Profile.new()
	return {
		version = 1,
		gold = 0,
		levels = { Radius = 1, Speed = 1, Power = 1, Capacity = 1 },
		bag = {},
		mined = 0,
		bestDepth = 0,
	}
end

local function integer(n, max)
	return type(n) == "number" and n >= 0 and n <= max and n % 1 == 0
end

function Profile.used(p)
	local n = 0
	for _, count in p.bag do
		n += count
	end
	return n
end

function Profile.stat(p, key)
	return Upgrades.items[key].values[p.levels[key]]
end

-- Refuse incompatible records instead of silently replacing them with defaults.
function Profile.valid(p)
	if type(p) ~= "table" or p.version ~= 1 or type(p.levels) ~= "table" or type(p.bag) ~= "table" then
		return false
	end
	for _, n in { "gold", "mined", "bestDepth" } do
		if not integer(p[n], 9e15) then
			return false
		end
	end
	for _, k in Upgrades.order do
		if not integer(p.levels[k], #Upgrades.items[k].values) or p.levels[k] < 1 then
			return false
		end
	end
	for name, n in p.bag do
		if not Ores.byName[name] or not integer(n, 9e15) then
			return false
		end
	end
	return Profile.used(p) <= Profile.stat(p, "Capacity")
end

function Profile.value(bag)
	local amount = 0
	for name, n in bag do
		amount += Ores.byName[name].value * n
	end
	return amount
end

function Profile.sell(p)
	local amount = Profile.value(p.bag)
	p.gold += amount
	p.bag = {}
	return amount
end

function Profile.buy(p, key)
	local item = Upgrades.items[key]
	if not item then
		return false, "Unknown upgrade"
	end
	local price = Upgrades.price(key, p.levels[key])
	if not price then
		return false, "Already at maximum level"
	end
	if p.gold < price then
		return false, "Need " .. (price - p.gold) .. " more gold"
	end
	p.gold -= price
	p.levels[key] += 1
	return true, (item.label or key) .. " upgraded!"
end
return Profile
