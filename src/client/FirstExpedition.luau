local Shared = game:GetService("ReplicatedStorage").Shared
local Config, Upgrades, Ores = require(Shared.GameConfig), require(Shared.Upgrades), require(Shared.Ores)
local W = require(script.Parent.Widgets)
local Guide = {}
Guide.__index = Guide

function Guide.new(player, net)
	local anchor = Instance.new("Attachment")
	anchor.Name = "First expedition waypoint"
	anchor.Parent = workspace.Terrain
	local pin = Instance.new("BillboardGui")
	pin.Name = "Destination"
	pin.Size = UDim2.fromOffset(132, 48)
	pin.LightInfluence = 0
	pin.Enabled = false
	pin.Parent = anchor
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.FredokaOne
	text.TextSize = 18
	text.TextStrokeTransparency = 0
	text.TextStrokeColor3 = W.ink
	text.Parent = pin
	local nearby = OverlapParams.new()
	nearby.FilterType = Enum.RaycastFilterType.Include
	return setmetatable({
		player = player,
		net = net,
		pin = pin,
		anchor = anchor,
		label = text,
		nearby = nearby,
		sight = RaycastParams.new(),
		nextSearch = 0,
	}, Guide)
end

function Guide:hide()
	self.pin.Enabled = false
	self.nextUpdate = nil
end

function Guide:mark(position, text, tint, surface)
	if not position then
		return
	end
	self.anchor.WorldPosition = position
	self.label.Text, self.label.TextColor3 = text .. "\n▼", tint
	self.pin.AlwaysOnTop = surface
	self.pin.Enabled = true
end

-- Only mark an ore the miner can reach and see from their own head.
function Guide:visibleOre(head)
	if os.clock() < self.nextSearch then
		return self.ore and self.ore.Parent and self.ore, self.face
	end
	self.nextSearch = os.clock() + 0.45
	self.ore, self.face = nil, nil
	local island = workspace:FindFirstChild("CitrineCove")
	local grid = island and island:FindFirstChild("MineBlocks")
	if not grid then
		return
	end
	self.nearby.FilterDescendantsInstances = { grid }
	self.sight.FilterDescendantsInstances = { self.player.Character }
	local power = Upgrades.items.Power.values[self.player:GetAttribute("Power") or 1]
	local reach = self.player.Character:GetAttribute("PickReach") or Config.Reach
	local candidates = {}
	for _, block in workspace:GetPartBoundsInRadius(head.Position, reach, self.nearby) do
		local ore = Ores.byName[block.Name]
		if block.Parent == grid and ore and not ore.host and ore.hardness <= power then
			table.insert(candidates, block)
		end
	end
	table.sort(candidates, function(a, b)
		return (a.Position - head.Position).Magnitude < (b.Position - head.Position).Magnitude
	end)
	for i = 1, math.min(#candidates, 8) do
		local block = candidates[i]
		local hit = workspace:Raycast(head.Position, block.Position - head.Position, self.sight)
		if hit and hit.Instance == block and hit.Distance <= reach then
			self.ore, self.face = block, hit.Position + hit.Normal * 0.4
			break
		end
	end
	return self.ore, self.face
end

function Guide:station(name, label, color, inMine, mobile)
	local pos = self.net:GetAttribute(name .. "Position")
	if pos and not inMine then
		self:mark(pos + Vector3.yAxis * 3.6, label, color, true)
	end
	if inMine then
		return "Use ↑ Surface, then follow the " .. label .. " marker"
	end
	return if mobile then "Tap the prompt on the " .. label .. " pad" else "Tap E on the " .. label .. " pad"
end

function Guide:bearing(head)
	if not self.pin.Enabled or not self.pin.AlwaysOnTop then
		return nil
	end
	local camera = workspace.CurrentCamera
	local _, onScreen = camera:WorldToViewportPoint(self.anchor.WorldPosition)
	if onScreen then
		return nil
	end
	local delta = self.anchor.WorldPosition - head.Position
	local right = camera.CFrame.RightVector:Dot(delta)
	local forward = camera.CFrame.LookVector:Dot(delta)
	if forward < -math.abs(right) then
		return "Turn around"
	end
	return if right < 0 then "Look left" else "Look right"
end

function Guide:objective(head, inMine, depth, mobile, full, step)
	local p = self.player
	if full then
		return "Backpack full", self:station("Sell", "Sell", W.gold, inMine, mobile)
	end
	local gold = p:GetAttribute("Gold") or 0
	local haul = (p:GetAttribute("BagValue") or 0) * (if p:GetAttribute("DoubleGold") then 2 else 1)
	local price = Upgrades.price("Speed", 1)
	local gathering = step == "Upgrade" and gold < price
	if step == "Sell" or gathering then
		local canFundUpgrade = gold + haul >= price
		local hasUpgrade = (p:GetAttribute("Speed") or 1) > 1
			or (p:GetAttribute("Power") or 1) > 1
			or (p:GetAttribute("Capacity") or 1) > 1
		if haul > 0 and (canFundUpgrade or hasUpgrade or not inMine) then
			return "Sell your haul", self:station("Sell", "Sell", W.gold, inMine, mobile)
		end
		gathering = true
	elseif step == "Upgrade" then
		return "Try Speed · " .. price .. " G", self:station("Shop", "Upgrades", W.aqua, inMine, mobile)
	end
	local action = if mobile then "Aim and hold Mine" else "Hold the left mouse button"
	if not inMine then
		local entrance = self.net:GetAttribute("Entrance")
		if entrance then
			self:mark(entrance + Vector3.yAxis * 4, "Mine", W.gold, true)
		end
		if step == "Return" then
			return "Try your new gear", "Follow the mine marker and break a block"
		end
		if gathering then
			return "Mine a haul for Speed", (gold + haul) .. " / " .. price .. " G toward your upgrade"
		end
		return if step == "Ore" then "Find your first ore" else "Take the first shift",
			"Follow the gold marker to the mine  ·  Skip guide in Settings"
	end
	if step == "Dig" then
		local floor = self.net:GetAttribute("DigFloor")
		if floor and (head.Position - floor).Magnitude > 12 then
			self:mark(floor + Vector3.yAxis * 2.5, "Dig here", W.gold, false)
		end
		return "Break your first block", action .. " on the dirt floor"
	elseif step == "Return" then
		return "Try your new gear", action .. " to break a block"
	elseif gathering then
		return "Mine a haul for Speed", (gold + haul) .. " / " .. price .. " G toward your upgrade"
	end
	local ore, face = self:visibleOre(head)
	if ore then
		local name = if Ores.byName[ore.Name].secret and not p:GetAttribute("Found" .. ore.Name)
			then "Ore"
			else ore.Name
		self:mark(face, name, W.aqua, false)
		return "Collect your first ore", action .. " on the marked mineral"
	end
	return "Find your first ore",
		if depth < Config.DirtLayers
			then "Dig through two layers of dirt to reach stone"
			else "Look for black coal nodules in the stone"
end

function Guide:update(head, inMine, depth, mobile, full)
	local step = self.player:GetAttribute("ExpeditionStep")
	if not step or step == "Done" or step == "Skipped" then
		self:hide()
		return
	end
	if step ~= self.lastStep or not self.nextUpdate or os.clock() >= self.nextUpdate then
		self.lastStep, self.nextUpdate = step, os.clock() + 0.2
		self.pin.Enabled = false
		self.title, self.help = self:objective(head, inMine, depth, mobile, full, step)
		local direction = self:bearing(head)
		if direction then
			self.help = direction .. " for the " .. self.label.Text:split("\n")[1] .. " marker"
		end
	end
	return self.title, self.help
end

return Guide
