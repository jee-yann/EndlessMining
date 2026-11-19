local Shared = game:GetService("ReplicatedStorage").Shared
local Ores = require(Shared.Ores)
local Upgrades = require(Shared.Upgrades)
local Expeditions = require(Shared.Expeditions)
local Preferences = require(Shared.Preferences)
local Profile = {}

function Profile.new()
	return {
		version = 1,
		gold = 0,
		levels = { Speed = 1, Power = 1, Capacity = 1 },
		bag = {},
		mined = 0,
		xp = 0,
		bestDepth = 0,
		jobs = 0,
		discoveries = {},
		preferences = table.clone(Preferences.defaults),
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
	if p.levels.Radius ~= nil and (not integer(p.levels.Radius, 8) or p.levels.Radius < 1) then
		return false
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
	if p.xp ~= nil and not integer(p.xp, 9e15) then
		return false
	end
	if p.jobs ~= nil and not integer(p.jobs, #Expeditions.jobs) then
		return false
	end
	if p.discoveries ~= nil then
		if type(p.discoveries) ~= "table" then
			return false
		end
		for name, seen in p.discoveries do
			if not Ores.byName[name] or seen ~= true then
				return false
			end
		end
	end
	if p.preferences ~= nil then
		if type(p.preferences) ~= "table" then
			return false
		end
		for key, value in p.preferences do
			if not Preferences.valid(key, value) then
				return false
			end
		end
	end
	return Profile.used(p) <= Profile.stat(p, "Capacity")
end

function Profile.upgradeSave(p)
	-- Repay retired area upgrades once, using their original workshop prices.
	for level = 1, (p.levels.Radius or 1) - 1 do
		p.gold += math.floor(24 * 2.5 ^ (level - 1) + 0.5)
	end
	p.levels.Radius = nil
	p.xp = p.xp or p.mined * 2
	p.preferences = p.preferences or {}
	for key, value in Preferences.defaults do
		if p.preferences[key] == nil then
			p.preferences[key] = value
		end
	end
	p.jobs = p.jobs or 0
	p.discoveries = p.discoveries or {}
	for name, amount in p.bag do
		if amount > 0 then
			p.discoveries[name] = true
		end
	end
	return p
end

function Profile.claimJob(p, number)
	local i = p.jobs + 1
	local job = Expeditions.jobs[i]
	if number ~= i or not job or p.mined < job.goal then
		return nil
	end
	p.jobs = i
	p.gold += job.reward
	return job
end

function Profile.value(bag)
	local amount = 0
	for name, n in bag do
		amount += Ores.byName[name].value * n
	end
	return amount
end

function Profile.sell(p, multiplier)
	local amount = Profile.value(p.bag) * (multiplier or 1)
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
