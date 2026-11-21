local Players = game:GetService("Players")
local Details = {}
function Details.place(grid, support, feature)
	local lava = feature == "Lava"
	local item = Instance.new("Part")
	item.Name = if lava then "Lava seam" elseif feature == "Egg" then "Drake egg" else "Survey cache"
	item.Anchored, item.CanCollide, item.CanQuery, item.CanTouch = true, false, false, lava
	item.Size = if lava
		then Vector3.new(support.Size.X - 0.06, 0.20, support.Size.Z - 0.06)
		else Vector3.new(2.35, 1.5, 1.65)
	if feature == "Egg" then
		item.Shape, item.Size = Enum.PartType.Ball, Vector3.new(1.65, 2.2, 1.65)
	end
	item.Material = if lava or feature == "Egg" then Enum.Material.Neon else Enum.Material.WoodPlanks
	item.Color = if lava
		then Color3.fromRGB(255, 88, 24)
		elseif feature == "Egg" then Color3.fromRGB(173, 116, 255)
		else Color3.fromRGB(175, 113, 60)
	item.Position = support.Position + Vector3.yAxis * (support.Size.Y + item.Size.Y) / 2
	local lamp = Instance.new("PointLight")
	lamp.Color, lamp.Brightness, lamp.Range, lamp.Parent =
		item.Color, if lava then 0.85 else 0.48, if lava then 11 else 8, item
	if lava then
		item.Touched:Connect(function(body)
			local player = Players:GetPlayerFromCharacter(body.Parent)
			if player and grid.onFeature then
				grid.onFeature(player, feature, item)
			end
		end)
	else
		if feature == "Cache" then
			for _, x in { -0.76, 0.76 } do
				local band = Instance.new("Part")
				band.Name, band.Anchored, band.CanCollide, band.CanTouch, band.CanQuery =
					"Brass strap", true, false, false, false
				band.Size, band.Position = Vector3.new(0.19, 1.54, 1.69), item.Position + Vector3.xAxis * x
				band.Color, band.Material, band.Parent = Color3.fromRGB(255, 201, 88), Enum.Material.Metal, item
			end
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText, prompt.ActionText, prompt.MaxActivationDistance, prompt.HoldDuration =
			item.Name, if feature == "Egg" then "Hatch" else "Open", 9, 0.25
		prompt.Triggered:Connect(function(player)
			if item.Parent and grid.onFeature and grid.onFeature(player, feature, item) then
				item:Destroy()
			end
		end)
		prompt.Parent = item
	end
	item.Parent = support
end
return Details
