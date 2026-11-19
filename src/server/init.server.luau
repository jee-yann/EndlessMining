local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local Config, Upgrades = require(Rep.Shared.GameConfig), require(Rep.Shared.Upgrades)
local World, Quarry = require(script.MineWorld), require(script.Quarry)
local Data, Profile, Mining =
	require(script.DataService), require(script.Profile), require(script.MiningService)

local surface = workspace:WaitForChild("CitrineCove")
local world = World.new(Config.Seed, surface)
local site = Quarry.bind(surface, world)
local landing = site.spawn.Position + Vector3.yAxis * 4
local net = Instance.new("Folder")
net.Name = "EndlessMiningNet"
net:SetAttribute("Origin", world.origin)
net:SetAttribute("Landing", landing)
net:SetAttribute("Ready", false)
for _, name in { "Mine", "Action", "Feedback", "Dust" } do
	local event = Instance.new(if name == "Dust" then "UnreliableRemoteEvent" else "RemoteEvent")
	event.Name, event.Parent = name, net
end
net.Parent = Rep

local sessions, loading, closing, nextAction = {}, {}, {}, {}
local shuttingDown = false
local function sync(player, p)
	player:SetAttribute("Gold", p.gold)
	player:SetAttribute("Used", Profile.used(p))
	player:SetAttribute("BagValue", Profile.value(p.bag))
	for _, key in Upgrades.order do
		player:SetAttribute(key, p.levels[key])
	end
	player.leaderstats.Gold.Value = p.gold
	player.leaderstats.Depth.Value = p.bestDepth
end
local function toSurface(player, character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		character:PivotTo(CFrame.new(landing))
	end
end
local function onCharacter(player, character)
	if not character:WaitForChild("HumanoidRootPart", 10) or player.Character ~= character then
		return
	end
	toSurface(player, character)
	local lamp = Instance.new("PointLight")
	lamp.Name, lamp.Color, lamp.Range, lamp.Brightness =
		"Mining lamp", Color3.fromRGB(255, 232, 198), 32, 1.65
	lamp.Parent = character:FindFirstChild("Head") or character.HumanoidRootPart
end
local function join(player)
	if loading[player] or sessions[player] or shuttingDown then
		return
	end
	loading[player] = true
	player.RespawnLocation = site.spawn
	player.CharacterAdded:Connect(function(char)
		onCharacter(player, char)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
	local session = Data.open(player)
	if player.Parent ~= Players or shuttingDown then
		Data.save(player, session, true)
		loading[player] = nil
		return
	end
	local board = Instance.new("Folder")
	board.Name = "leaderstats"
	for _, name in { "Gold", "Depth" } do
		local stat = Instance.new("IntValue")
		stat.Name, stat.Parent = name, board
	end
	board.Parent = player
	sessions[player], loading[player] = session, nil
	sync(player, session.profile)
	player:SetAttribute("ProfileReady", true)
end
local function leave(player)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player], closing[player], nextAction[player] = nil, true, nil
	Data.save(player, session, true)
	closing[player] = nil
end

local function action(player, key, option)
	local s = sessions[player]
	if not s or type(key) ~= "string" then
		return
	end
	local now = os.clock()
	if key ~= "Surface" and key ~= "Sell" and key ~= "Buy" then
		return
	end
	local times = nextAction[player]
	if not times then
		times = {}
		nextAction[player] = times
	end
	if now < (times[key] or 0) then
		return
	end
	times[key] = now + 0.18
	local p = s.profile
	if key == "Surface" then
		toSurface(player, player.Character)
	elseif key == "Sell" then
		-- The HUD calls the exchange from any depth, just like the physical counter.
		local gold = Profile.sell(p)
		sync(player, p)
		net.Feedback:FireClient(player, "sale", gold)
	elseif key == "Buy" and type(option) == "string" and Upgrades.items[option] then
		local ok, msg = Profile.buy(p, option)
		sync(player, p)
		net.Feedback:FireClient(player, if ok then "upgrade" else "hint", msg)
	end
end
net.Action.OnServerEvent:Connect(action)
for name, prompt in site.stations do
	prompt.Triggered:Connect(function(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if
			not root
			or (root.Position - prompt.Parent.Position).Magnitude > prompt.MaxActivationDistance + 4
		then
			return
		end
		if name == "Sell" then
			action(player, "Sell")
		else
			net.Feedback:FireClient(player, "shop")
		end
	end)
end
Mining.start(world, net, sessions, sync)
Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(leave)
for _, player in Players:GetPlayers() do
	task.spawn(join, player)
end

task.spawn(function()
	world:generate()
	net:SetAttribute("Ready", true)
end)
task.spawn(function()
	while task.wait(0.5) do
		for player, s in sessions do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not root then
				continue
			end
			local localPos = root.Position - world.origin
			if
				localPos.Y < Config.Min.Y - 10
				or math.abs(localPos.X) > 150
				or localPos.Z > 120
				or localPos.Z < Config.Min.Z - 25
			then
				toSurface(player, player.Character)
			elseif Config.inside(localPos) then
				local d = math.floor(-localPos.Y)
				if d > s.profile.bestDepth then
					s.profile.bestDepth = d
					player.leaderstats.Depth.Value = d
				end
			elseif localPos.Y < -35 then
				toSurface(player, player.Character)
			end
		end
	end
end)
task.spawn(function()
	while task.wait(Config.AutosaveSeconds) do
		for player, s in sessions do
			task.spawn(Data.save, player, s, false)
		end
	end
end)
game:BindToClose(function()
	shuttingDown = true
	for player in sessions do
		task.spawn(leave, player)
	end
	while next(sessions) or next(loading) or next(closing) do
		task.wait()
	end
end)
