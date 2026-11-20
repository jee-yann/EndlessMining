local E = require(script.Parent.Expeditions)
local Ores = require(script.Parent.Ores)
local Guide = {}
-- One point per earned level. Links and positions are shared by the map and server.
Guide.skills = {
	{ id = "Reach", name = "Long Arm", detail = "+5 studs of pick reach", x = -154, y = -36 },
	{ id = "Stride", name = "Quick Feet", detail = "+3 walk speed", x = 38, y = 108 },
	{ id = "Lamp", name = "Lantern Wick", detail = "+8 studs of light", x = 150, y = -46 },
	{ id = "ReachII", name = "Far Reach", detail = "+5 more studs of reach", parent = "Reach", x = -278, y = -148 },
	{ id = "Spring", name = "Spring Step", detail = "Jump 25% higher", parent = "Stride", x = -85, y = 177 },
	{ id = "Lantern", name = "Afterglow", detail = "+8 more studs of light", parent = "Lamp", x = 286, y = -155 },
	{ id = "Tempo", name = "Steady Hands", detail = "Cut blocks 10% faster", parent = "ReachII", x = -424, y = -78 },
	{ id = "Scout", name = "Trail Runner", detail = "+3 more walk speed", parent = "Spring", x = 41, y = 254 },
}
Guide.byId = {}
for _, node in Guide.skills do
	Guide.byId[node.id] = node
end
Guide.petNames = { Pebble = true, Chips = true, Granite = true, Chip = true, Pip = true, Flint = true }
Guide.achievements = {
	{ id = "PocketChange", name = "Pocket Change", ore = "Coal", goal = 1 },
	{ id = "CleanSale", name = "All Pay, No Gravel", goal = 1, detail = "Sell a haul made entirely of ore." },
	{ id = "PickUpgrade", name = "Pick Me Up", goal = 1, detail = "Upgrade your pickaxe’s Power at the workshop." },
	{
		id = "Scales",
		name = "Practicing My Scales",
		sequence = { "Dirt", "Stone", "Coal", "Copper", "Iron", "Gold", "Diamond" },
	},
	{
		id = "Ascent",
		name = "Taking the Scenic Route",
		goal = 1,
		detail = "Reach the surface on foot from 101+ blocks deep in one life.",
	},
	{
		id = "LuckAndSkill",
		name = "Once Is Luck, Twice Is Skill",
		ore = "Starfall",
		goal = 2,
		detail = "Mine Starfall twice across any number of shifts.",
	},
	{ id = "PetName", name = "Pet Rock, Proper Noun", goal = 1, detail = "Give your rock companion a new name." },
	{
		id = "Branch",
		name = "Branch Manager",
		goal = 3,
		detail = "Learn all three skills along one skill-tree branch.",
	},
	{ id = "Shifts", name = "Timecard Complete", goal = #E.jobs, detail = "Collect the reward for every shift job." },
	{ id = "PayDirt", name = "Certified Dirt Person", ore = "Dirt", goal = 1000 },
	{ id = "RockSolid", name = "Rock Solid", ore = "Stone", goal = 500 },
	{ id = "CopperCollector", name = "Copper Collector", ore = "Copper", goal = 50 },
	{ id = "GoldenTouch", name = "Midas Touch", ore = "Gold", goal = 25 },
	{ id = "Ice", name = "Ice in My Pockets", ore = "Diamond", goal = 10 },
	{ id = "Envy", name = "Green With Envy", ore = "Emerald", goal = 5 },
}
Guide.awardsById = {}
-- Keep previously awarded, retired badges readable in existing saves.
Guide.storedAwards = { Sandwich = true, Pressure = true, Penny = true, Traffic = true, Variety = true }
for _, award in Guide.achievements do
	Guide.awardsById[award.id] = award
	if award.sequence then
		award.goal = #award.sequence
	end
	if not award.ore then
		Guide.storedAwards[award.id] = true
	end
end
Guide.cutWindow = #Guide.awardsById.Scales.sequence

function Guide.awardText(award, player)
	local detail = award.detail
		or (
			if award.sequence
				then table.concat(award.sequence, " → ")
				else string.format("Mine %d %s.", award.goal, award.ore)
		)
	local function mask(word)
		if Ores.byName[word] and not player:GetAttribute("Found" .. word) then
			return "???"
		end
		return word
	end
	local title = string.gsub(award.name, "%a+", mask)
	local requirement = string.gsub(detail, "%a+", mask)
	return title, requirement
end

function Guide.progress(p, award)
	if award.ore then
		return math.min(p.counts[award.ore] or 0, award.goal)
	end
	if p.earned[award.id] then
		return award.goal
	end
	if award.id == "PickUpgrade" then
		return math.min(1, p.levels.Power - 1)
	elseif award.id == "Shifts" then
		return p.jobs
	elseif award.id == "Branch" then
		if p.skills.Tempo or p.skills.Scout then
			return 3
		elseif p.skills.ReachII or p.skills.Spring then
			return 2
		elseif p.skills.Reach or p.skills.Stride then
			return 1
		end
	end
	if not award.sequence then
		return 0
	end
	local cuts = p.recentCuts
	for length = math.min(#cuts, award.goal), 1, -1 do
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
