local E = {}

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
	{ name = "Lamp Tender", goal = 0 },
	{ name = "Prospector", goal = 3 },
	{ name = "Crystal Seeker", goal = 7 },
	{ name = "Grotto Warden", goal = 12 },
	{ name = "Prism Keeper", goal = 17 },
}
function E.rank(power, speed, capacity)
	local points = power + speed + capacity - 3
	for i = #E.ranks, 2, -1 do
		if points >= E.ranks[i].goal then
			return i, E.ranks[i]
		end
	end
	return 1, E.ranks[1]
end
return E
