local rgb = Color3.fromRGB
local E = {}

-- Floor centres are on the same four-stud grid as the mine.
E.stops = {
	{
		key = "Harbor",
		name = "Citrine Harbor",
		goal = 0,
		color = rgb(62, 211, 255),
		detail = "Shops, jobs & starter mine",
	},
	{
		key = "Foundry",
		name = "Ember Foundry",
		goal = 36,
		floor = Vector3.new(-16, -128, -36),
		color = rgb(255, 152, 59),
		ore = "Iron",
		detail = "128 studs down  ·  Iron & copper",
	},
	{
		key = "Prism",
		name = "Prism Arcade",
		goal = 150,
		floor = Vector3.new(-16, -448, -36),
		color = rgb(186, 116, 255),
		ore = "Diamond",
		detail = "448 studs down  ·  Diamonds & gold",
	},
	{
		key = "Deep",
		name = "Emerald Vault",
		goal = 420,
		floor = Vector3.new(-16, -1024, -36),
		color = rgb(61, 231, 158),
		ore = "Emerald",
		detail = "1,024 studs down  ·  Emeralds & diamonds",
	},
}
E.byKey, E.byBand = {}, {}
for _, stop in E.stops do
	E.byKey[stop.key] = stop
	if stop.floor then
		for band = math.floor(stop.floor.Y / 32), math.floor((stop.floor.Y + 20) / 32) do
			E.byBand[band] = stop
		end
	end
end

E.jobs = {
	{ title = "First strike", goal = 8, reward = 25 },
	{ title = "Break the bank", goal = 36, reward = 80 },
	{ title = "Foundry shift", goal = 80, reward = 160 },
	{ title = "Prism express", goal = 150, reward = 350 },
	{ title = "Deep pockets", goal = 260, reward = 650 },
	{ title = "Vault breaker", goal = 420, reward = 1200 },
	{ title = "Cove legend", goal = 750, reward = 2400 },
}
E.ranks = {
	{ name = "Rookie", goal = 0 },
	{ name = "Digger", goal = 36 },
	{ name = "Prospector", goal = 150 },
	{ name = "Deep diver", goal = 420 },
	{ name = "Cove legend", goal = 750 },
}
function E.rank(mined)
	for i = #E.ranks, 2, -1 do
		if mined >= E.ranks[i].goal then
			return i, E.ranks[i], E.ranks[i + 1]
		end
	end
	return 1, E.ranks[1], E.ranks[2]
end
return E
