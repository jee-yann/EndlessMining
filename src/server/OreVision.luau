local Ores = require(game:GetService("ReplicatedStorage").Shared.Ores)
local Locator = require(script.Parent.OreLocator)

-- This RemoteFunction lives in the owner's PlayerGui. The server chooses the scan center.
return function(gui, owner, world)
	local scan = Instance.new("RemoteFunction")
	scan.Name = "Scan"
	local lastCell, lastGeneration, lastRemoved, hits
	local nextRequest, revision = 0, 0
	local locator = Locator.new()
	scan.OnServerInvoke = function(player, knownRevision, mask)
		if player ~= owner or os.clock() < nextRequest then
			return nil
		end
		nextRequest = os.clock() + 0.25
		if typeof(mask) ~= "number" or mask % 1 ~= 0 or mask < 0 or mask > Ores.visionMask then
			return nil
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not world.ready or not root or not humanoid or humanoid.Health <= 0 then
			return false
		end
		local cell = world.grid:cellAt(root.Position)
		if lastGeneration ~= world.generation then
			locator = Locator.new()
		end
		if lastCell ~= cell or lastGeneration ~= world.generation or lastRemoved ~= world.removed then
			hits = world.grid:scanOres(cell)
			lastCell, lastGeneration, lastRemoved = cell, world.generation, world.removed
			revision += 1
		end
		local targets = locator:locate(world.grid, cell, mask)
		return revision, world.grid:center(cell), if knownRevision ~= revision then hits else nil, targets
	end
	scan.Parent = gui
end
