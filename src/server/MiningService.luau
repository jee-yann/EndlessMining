local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config, Ores = require(Shared.GameConfig), require(Shared.Ores)
local Profile = require(script.Parent.Profile)
local Mining = {}

function Mining.validPoint(v)
	return typeof(v) == "Vector3" and v.Magnitude < 1e6
end

function Mining.target(world, character, point)
	if not Mining.validPoint(point) or not character then
		return nil
	end
	local head, human = character:FindFirstChild("Head"), character:FindFirstChildOfClass("Humanoid")
	if not head or not human or human.Health <= 0 then
		return nil
	end
	local delta = point - head.Position
	if delta.Magnitude < 0.1 or delta.Magnitude > Config.Reach then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local hit = workspace:Raycast(head.Position, delta.Unit * (delta.Magnitude + 4), params)
	if not hit or hit.Instance ~= workspace.Terrain or (hit.Position - point).Magnitude > 5 then
		return nil
	end
	local center = Config.brushCenter(world.origin, hit.Position, hit.Normal)
	if Config.inside(center - world.origin) then
		return center
	end
	return nil
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

	net.Mine.OnServerEvent:Connect(function(player, point)
		local now = os.clock()
		if now < (nextInput[player] or 0) then
			return
		end
		nextInput[player] = now + 0.055
		if not world.ready or not sessions[player] or not Mining.validPoint(point) then
			return
		end
		if now < (nextPulse[player] or 0) or pending[player] then
			return
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or (point - root.Position).Magnitude > Config.Reach + 3 then
			return
		end
		pending[player] = { point = point, time = now }
		table.insert(queue, player)
	end)

	local function pulse(player, profile, point, now)
		local space = Profile.stat(profile, "Capacity") - Profile.used(profile)
		if space <= 0 then
			hint(player, "Pack full • sell your ore", now)
			return
		end
		local center = Mining.target(world, player.Character, point)
		if not center then
			return
		end
		local radius = Profile.stat(profile, "Radius")
		local loot, locked = world:excavate(center, radius, Profile.stat(profile, "Power"), space)
		if not next(loot) then
			hint(
				player,
				if locked
					then locked.name .. " needs Power " .. locked.hardness
					else "Try another part of the seam",
				now
			)
			return
		end
		local best = Ores.byName.Stone
		for name, count in loot do
			profile.bag[name] = (profile.bag[name] or 0) + count
			profile.mined += count
			if Ores.byName[name].value > best.value then
				best = Ores.byName[name]
			end
		end
		sync(player, profile)
		net.Feedback:FireClient(player, "loot", loot, center, radius)
		for _, other in Players:GetPlayers() do
			local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
			if other ~= player and root and (root.Position - center).Magnitude < 72 then
				net.Dust:FireClient(other, center, radius, best.name)
			end
		end
	end

	RunService.Heartbeat:Connect(function(dt)
		credit = math.min(Config.BurstCells, credit + Config.CellBudget * dt)
		for _ = 1, 2 do
			local player = queue[1]
			if not player then
				break
			end
			local session, request = sessions[player], pending[player]
			local now = os.clock()
			if session and request and now - request.time < 1 then
				local p = session.profile
				local cost = (math.floor(Profile.stat(p, "Radius") / Config.Cell) * 2 + 1) ^ 3
				if credit < cost then
					break
				end
				credit -= cost
				nextPulse[player] = now + Profile.stat(p, "Speed")
				pulse(player, p, request.point, now)
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
