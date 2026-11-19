local Descent = require(script.Parent.Descent)
local Quarry = {}

function Quarry.bind(map, world)
	-- The surface is authored in Workspace so it can be explored in edit mode.
	map:PivotTo(CFrame.new(world.origin))
	local preview = map:FindFirstChild("EditFace")
	if preview then
		preview:Destroy()
	end
	Descent.build(map, world.origin)
	local market = map["Shore market"]
	local harbor = map["Harbor Plaza"]
	local stations = {
		Sell = market.Sell["Service mat"].Service,
		Shop = market.Upgrades["Service mat"].Service,
	}
	for _, name in { "Jobs", "Store", "Book", "Lift" } do
		stations[name] = harbor[name].Counter.Service
	end
	for _, deck in map["Lift Landings"]:GetChildren() do
		stations["Lift" .. deck.Name] = deck.Console.Service
	end
	return {
		spawn = map["Sand path and bridge"].Landing,
		stations = stations,
		court = harbor["Miners Court"],
	}
end

return Quarry
