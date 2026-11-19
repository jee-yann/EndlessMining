local MineSite = {}

function MineSite.bind(map, world)
	-- The surface is authored in Workspace so it can be explored in edit mode.
	map:PivotTo(CFrame.new(world.origin))
	local preview = map:FindFirstChild("EditFace")
	if preview then
		preview:Destroy()
	end
	local market = map["Shore market"]
	local harbor = map["Harbor Plaza"]
	local stations = {
		Sell = market.Sell["Service mat"].Service,
		Shop = market.Upgrades["Service mat"].Service,
	}
	for _, name in { "Jobs", "Store", "Book" } do
		stations[name] = harbor[name].Counter.Service
	end
	return {
		spawn = map["Sand path and bridge"].Landing,
		stations = stations,
		court = harbor["Miners Court"],
	}
end

return MineSite
