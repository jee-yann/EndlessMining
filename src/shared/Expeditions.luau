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
