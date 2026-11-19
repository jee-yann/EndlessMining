local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.GameConfig)
local Ores = require(Shared.Ores)

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

function Quarry.palette()
	if workspace.Terrain:CountCells() ~= 0 then
		return
	end
	for _, ore in Ores.list do
		workspace.Terrain:SetMaterialColor(ore.material, ore.color)
	end
	for _, layer in Config.Layers do
		workspace.Terrain:SetMaterialColor(layer.material, layer.color)
	end
	workspace.Terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(118, 201, 84))
end
return Quarry
