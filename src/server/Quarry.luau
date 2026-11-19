local Quarry = {}

function Quarry.bind(map, world)
	-- The surface is authored in Workspace so it can be explored in edit mode.
	map:PivotTo(CFrame.new(world.origin))
	local preview = map:FindFirstChild("EditFace")
	if preview then
		preview:Destroy()
	end
	local market = map["Shore market"]
	return {
		spawn = map["Sand path and bridge"].Landing,
		stations = {
			Sell = market.Sell["Service mat"].Service,
			Shop = market.Upgrades["Service mat"].Service,
		},
	}
end

return Quarry
