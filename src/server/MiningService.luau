local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local Pattern = require(Shared.BlockPattern)
local Profile = require(script.Parent.Profile)
local Mining = {}

function Mining.validPoint(v)
	return typeof(v) == "Vector3" and v.Magnitude < 1e6
end

function Mining.target(world, character, point, normal)
	if not Mining.validPoint(point) or typeof(normal) ~= "Vector3" or not character then
		return nil
	end
	if normal:Abs() ~= Vector3.xAxis and normal:Abs() ~= Vector3.yAxis and normal:Abs() ~= Vector3.zAxis then
		return nil
	end
	local head, human = character:FindFirstChild("Head"), character:FindFirstChildOfClass("Humanoid")
	if not head or not human or human.Health <= 0 then
		return nil
	end
	local anchor = world.origin + (((point - world.origin) / Config.Cell):Floor() + Vector3.one * 0.5) * Config.Cell
	if (anchor - point).Magnitude > 0.03 or not Config.inside(anchor - world.origin) then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character }
	local part = Pattern.visiblePart(head.Position, anchor, normal, params)
	if not part or part.Parent ~= world.grid.folder then
		return nil
	end
	return anchor
end

function Mining.selection(world, character, point, normal, power, space)
	local center = Mining.target(world, character, point, normal)
	if not center then
		return {}
	end
	return Pattern.select(world.origin, center, world:oreAt(center), power, space)
end

function Mining.start(world, net, sessions, sync)
	local pending, nextPulse, nextInput, lastHint, queue = {}, {}, {}, {}, {}
	local credit = Config.BurstCells
	local function hint(player, message, now)
		if now >= (lastHint[player] or 0) then
			lastHint[player] = now + 1.4
			net.Feedback:FireClient(player, "hint", message)
		end
	end

	net.Swing.OnServerEvent:Connect(function(player, active, target)
		local character = player.Character
		if not character or type(active) ~= "boolean" then
			return
		end
		if not active then
			if character:GetAttribute("MiningSwing") then
				character:SetAttribute("MiningSwing", nil)
			end
			return
		end
		local session = sessions[player]
		local head = character:FindFirstChild("Head")
		-- This attribute animates nearby avatars. Only the mining request can remove ore.
		if
			session
			and world.ready
			and head
			and not character:GetAttribute("MiningSwing")
			and Mining.validPoint(target)
			and Config.inside(target - world.origin)
			and (head.Position - target).Magnitude <= Config.Reach + Config.Cell
		then
			character:SetAttribute("MiningSwing", Profile.stat(session.profile, "Speed"))
		end
	end)

	net.Mine.OnServerEvent:Connect(function(player, point, normal, count, mask)
		local now = os.clock()
		if now < (nextInput[player] or 0) then
			return
		end
		nextInput[player] = now + 0.055
		if not world.ready or not sessions[player] or not Mining.validPoint(point) then
			return
		end
		if count ~= 1 or mask ~= 1 or typeof(normal) ~= "Vector3" then
			return
		end
		if now + 0.07 < (nextPulse[player] or 0) or pending[player] then
			return
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or (point - root.Position).Magnitude > Config.Reach + 3 then
			return
		end
		pending[player] = { point = point, normal = normal, time = now }
		table.insert(queue, player)
	end)

	local function pulse(player, profile, request, now)
		local space = Profile.stat(profile, "Capacity") - Profile.used(profile)
		if space <= 0 then
			hint(player, "Pack full • sell your ore", now)
			return
		end
		local selected = Mining.selection(
			world,
			player.Character,
			request.point,
			request.normal,
			Profile.stat(profile, "Power"),
			space
		)
		if #selected == 0 then
			return
		end
		local loot, finds = world:excavate(selected)
		if not next(loot) then
			return
		end
		local center = selected[1]
		local spread = math.sqrt(#selected) * Config.Cell
		local best = Ores.byName.Dirt
		local discovery
		for name, count in loot do
			local ore = Ores.byName[name]
			if not ore.host and not profile.discoveries[name] and (not discovery or ore.value > discovery.value) then
				discovery = ore
			end
			profile.discoveries[name] = true
			profile.bag[name] = (profile.bag[name] or 0) + count
			profile.mined += count
			if Ores.byName[name].value > best.value then
				best = Ores.byName[name]
			end
		end
		sync(player, profile)
		net.Feedback:FireClient(player, "loot", loot, center, spread, finds, request.normal)
		if discovery then
			net.Feedback:FireClient(player, "milestone", "ORE DISCOVERED", discovery.name, discovery.color)
		end
		for _, other in Players:GetPlayers() do
			local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
			if other ~= player and root and (root.Position - center).Magnitude < 72 then
				net.Dust:FireClient(other, center, spread, best.name, finds, request.normal, loot)
			end
		end
	end

	RunService.Heartbeat:Connect(function(dt)
		credit = math.min(Config.BurstCells, credit + Config.CellBudget * dt)
		for _ = 1, math.min(2, #queue) do
			local player = queue[1]
			if not player then
				break
			end
			local session, request = sessions[player], pending[player]
			local now = os.clock()
			if request and now < (nextPulse[player] or 0) then
				-- Allow a slightly early packet to wait for the same server cooldown.
				table.remove(queue, 1)
				table.insert(queue, player)
				continue
			end
			if session and request and now - request.time < 1 then
				local p = session.profile
				if credit < 1 then
					break
				end
				credit -= 1
				nextPulse[player] = now + Profile.stat(p, "Speed")
				pulse(player, p, request, now)
			end
			pending[player] = nil
			table.remove(queue, 1)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		pending[player], nextPulse[player], nextInput[player], lastHint[player] = nil, nil, nil, nil
	end)
end
return Mining
