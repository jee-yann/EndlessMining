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
	{ name = "Pocket Change", ore = "Coal", goal = 1 },
	{ name = "Certified Dirt Person", ore = "Dirt", goal = 1000 },
	{ name = "Rock Solid", ore = "Stone", goal = 500 },
	{ name = "Copper Collector", ore = "Copper", goal = 50 },
	{ name = "Golden Touch", ore = "Gold", goal = 25 },
	{ name = "Ice in My Pockets", ore = "Diamond", goal = 10 },
	{ name = "Green With Envy", ore = "Emerald", goal = 5 },
	{ name = "Second Opinion", ore = "Starfall", goal = 2, secret = true },
}
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
