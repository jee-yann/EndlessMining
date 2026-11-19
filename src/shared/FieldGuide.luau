local E = require(script.Parent.Expeditions)
local Guide = {}
-- One point per earned level. Links and positions are shared by the map and server.
Guide.skills = {
	{ id = "Reach", name = "Long Arm", detail = "+5 studs of pick reach", x = 77, y = 73 },
	{ id = "Stride", name = "Quick Feet", detail = "+3 walk speed", x = 225, y = 73 },
	{ id = "Lamp", name = "Lantern Wick", detail = "+8 studs of light", x = 373, y = 73 },
	{ id = "ReachII", name = "Far Reach", detail = "+5 more studs of reach", parent = "Reach", x = 77, y = 151 },
	{ id = "Spring", name = "Spring Step", detail = "Jump 25% higher", parent = "Stride", x = 225, y = 151 },
	{ id = "Lantern", name = "Afterglow", detail = "+8 more studs of light", parent = "Lamp", x = 373, y = 151 },
	{ id = "Tempo", name = "Steady Hands", detail = "Cut blocks 10% faster", parent = "ReachII", x = 77, y = 229 },
	{ id = "Scout", name = "Trail Runner", detail = "+3 more walk speed", parent = "Spring", x = 225, y = 229 },
}
Guide.byId = {}
for _, node in Guide.skills do
	Guide.byId[node.id] = node
end
Guide.petNames = { Pebble = true, Chips = true, Granite = true, Chip = true, Pip = true, Flint = true }
Guide.achievements = {
	{ id = "PocketChange", name = "Pocket Change", ore = "Coal", goal = 1 },
	{ id = "PayDirt", name = "Certified Dirt Person", ore = "Dirt", goal = 1000 },
	{ id = "RockSolid", name = "Rock Solid", ore = "Stone", goal = 500 },
	{ id = "CopperCollector", name = "Copper Collector", ore = "Copper", goal = 50 },
	{ id = "GoldenTouch", name = "Golden Touch", ore = "Gold", goal = 25 },
	{ id = "Ice", name = "Ice in My Pockets", ore = "Diamond", goal = 10 },
	{ id = "Envy", name = "Green With Envy", ore = "Emerald", goal = 5 },
	{
		id = "LuckAndSkill",
		name = "Once Is Luck, Twice Is Skill",
		ore = "Starfall",
		goal = 2,
		detail = "Mine Starfall twice across any number of shifts.",
	},
	{
		id = "Scales",
		name = "Practicing My Scales",
		sequence = { "Dirt", "Stone", "Coal", "Copper", "Iron", "Gold", "Diamond" },
	},
	{ id = "Sandwich", name = "24-Carat Sandwich", sequence = { "Stone", "Gold", "Stone" } },
	{ id = "Pressure", name = "Under Pressure", sequence = { "Coal", "Coal", "Diamond" } },
	{ id = "Penny", name = "A Penny for Your Soot", sequence = { "Copper", "Coal", "Copper" } },
	{ id = "Traffic", name = "Traffic Lights", sequence = { "Copper", "Gold", "Emerald" } },
	{
		id = "Variety",
		name = "Variety Pack",
		distinct = true,
		goal = 5,
		detail = "Mine five different materials in five consecutive cuts.",
	},
}
Guide.cutWindow = 0
Guide.cutAwards = {}
for _, award in Guide.achievements do
	if award.sequence then
		award.goal = #award.sequence
		award.detail = table.concat(award.sequence, " → ")
	end
	if not award.ore then
		Guide.cutAwards[award.id] = true
		Guide.cutWindow = math.max(Guide.cutWindow, award.goal)
	end
end

function Guide.progress(p, award)
	if award.ore then
		return math.min(p.counts[award.ore] or 0, award.goal)
	end
	if p.earned[award.id] then
		return award.goal
	end
	local cuts = p.recentCuts
	local limit = math.min(#cuts, award.goal)
	if award.distinct then
		local seen = {}
		for length = 1, limit do
			local ore = cuts[#cuts - length + 1]
			if seen[ore] then
				return length - 1
			end
			seen[ore] = true
		end
		return limit
	end
	-- A mismatch can also begin a new run, e.g. Stone, Stone, Gold, Stone.
	for length = limit, 1, -1 do
		local matches = true
		for i = 1, length do
			if cuts[#cuts - length + i] ~= award.sequence[i] then
				matches = false
				break
			end
		end
		if matches then
			return length
		end
	end
	return 0
end
function Guide.points(xp, skills)
	local spent = 0
	for _ in skills do
		spent += 1
	end
	return math.max(0, E.level(xp) - 1 - spent)
end
function Guide.selectedTitle(p)
	return p.title or E.rank(E.level(p.xp))
end
return Guide
