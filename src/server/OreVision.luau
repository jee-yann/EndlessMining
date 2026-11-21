-- This RemoteFunction lives in the owner's PlayerGui. The server chooses the scan center.
return function(gui, owner, world)
	local scan = Instance.new("RemoteFunction")
	scan.Name = "Scan"
	local lastCell, lastGeneration, lastRemoved, hits
	local nextRequest, revision = 0, 0
	scan.OnServerInvoke = function(player, knownRevision)
		if player ~= owner or os.clock() < nextRequest then
			return nil
		end
		nextRequest = os.clock() + 0.25
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not world.ready or not root or not humanoid or humanoid.Health <= 0 then
			return false
		end
		local cell = world.grid:cellAt(root.Position)
		if lastCell ~= cell or lastGeneration ~= world.generation or lastRemoved ~= world.removed then
			hits = world.grid:scanOres(cell)
			lastCell, lastGeneration, lastRemoved = cell, world.generation, world.removed
			revision += 1
		end
		if knownRevision == revision then return nil end
		return revision, world.grid:center(cell), hits
	end
	scan.Parent = gui
end
