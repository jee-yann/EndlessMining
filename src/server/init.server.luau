local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local Config, Upgrades = require(Rep.Shared.GameConfig), require(Rep.Shared.Upgrades)
local World, MineSite = require(script.MineWorld), require(script.MineSite)
local Ores = require(Rep.Shared.Ores)
local Preferences = require(Rep.Shared.Preferences)
local Passes = require(script.Passes)
local equipKit = require(script.ProspectorKit)
local Pickaxe = require(script.Pickaxe)
local Data, Profile, Mining = require(script.DataService), require(script.Profile), require(script.MiningService)

local surface = workspace:WaitForChild("CitrineCove")
local seeds = Random.new()
local studioSeed = if game:GetService("RunService"):IsStudio() then script:GetAttribute("StudioMineSeed") else nil
local world = World.new(studioSeed or seeds:NextInteger(1, 2147483646), surface)
local site = MineSite.bind(surface, world)
local landing = site.spawn.Position + Vector3.yAxis * 4
local minePath = surface["Sand path and bridge"]["Mine path"]
local entrance = minePath.Position + Vector3.yAxis * (minePath.Size.Y / 2 + 3.5)
local net = Instance.new("Folder")
net.Name = "EndlessMiningNet"
net:SetAttribute("Origin", world.origin)
net:SetAttribute("Landing", landing)
net:SetAttribute("Entrance", entrance)
net:SetAttribute("Ready", false)
for _, name in { "Mine", "Action", "Feedback", "Dust", "FriendsBoard", "Swing" } do
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
	player:SetAttribute("Mined", p.mined)
	player:SetAttribute("MiningXP", p.xp)
	player:SetAttribute("Jobs", p.jobs)
	for _, ore in Ores.list do
		player:SetAttribute("Held" .. ore.name, p.bag[ore.name] or 0)
		player:SetAttribute("Found" .. ore.name, p.discoveries[ore.name] == true)
	end
	for _, key in Upgrades.order do
		player:SetAttribute(key, p.levels[key])
	end
	player.leaderstats.Gold.Value = p.gold
	player.leaderstats.Depth.Value = Config.depthInBlocks(p.bestDepth)
end
local function moveCharacter(character, destination)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		character:PivotTo(destination)
	end
end
local loadingRoots = {}
local function enter(player)
	player:SetAttribute("EnteredMineSite", true)
	local root = loadingRoots[player]
	if root and root.Parent then
		root.Anchored = false
	end
	loadingRoots[player] = nil
end
local function onCharacter(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or player.Character ~= character then
		return
	end
	moveCharacter(character, CFrame.new(landing))
	if not player:GetAttribute("EnteredMineSite") then
		root.Anchored = true
		loadingRoots[player] = root
		task.delay(18, function()
			if loadingRoots[player] == root and player.Parent == Players then
				enter(player)
			end
		end)
	end
	-- Avatar appearance can replace the head after spawn. Keep the light on the rig.
	if not root:FindFirstChild("Lamp mount") then
		local mount = Instance.new("Attachment")
		local head = character:FindFirstChild("Head")
		mount.Name = "Lamp mount"
		mount.Position = if head then root.CFrame:PointToObjectSpace(head.Position) else Vector3.new(0, 1.5, 0)
		local lamp = Instance.new("PointLight")
		lamp.Name, lamp.Color, lamp.Range, lamp.Brightness = "Mining lamp", Color3.fromRGB(255, 232, 198), 20, 0.75
		lamp.Shadows = true
		lamp.Parent, mount.Parent = mount, root
	end
	task.spawn(equipKit, player, character)
	task.spawn(Pickaxe.equip, player, character)
end
local function join(player)
	if loading[player] or sessions[player] or shuttingDown then
		return
	end
	loading[player] = true
	Passes.join(player)
	player.RespawnLocation = site.spawn
	player.CharacterAppearanceLoaded:Connect(function(char)
		task.spawn(equipKit, player, char)
		Pickaxe.equip(player, char)
	end)
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
	for key, value in session.profile.preferences do
		player:SetAttribute(key, value)
	end
	sync(player, session.profile)
	player:SetAttribute("ProfileReady", true)
end
local function leave(player)
	loadingRoots[player] = nil
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player], closing[player], nextAction[player] = nil, true, nil
	Data.save(player, session, true)
	closing[player] = nil
end

local function atCounter(player, prompt)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	return root
		and humanoid
		and humanoid.Health > 0
		and (root.Position - prompt.Parent.Position).Magnitude <= prompt.MaxActivationDistance + 1
end

local counterFor = { Sell = "Sell", Buy = "Shop", PreviewPass = "Store", Pass = "Store" }
local function action(player, key, option, value)
	if key == "Entered" then
		enter(player)
		return
	end
	local s = sessions[player]
	if not s or type(key) ~= "string" then
		return
	end
	if key == "ReturnReady" then
		local travel = s.travel
		if travel and travel.id == option then
			s.travel = nil
			if player.Character == travel.character then
				moveCharacter(travel.character, CFrame.lookAt(entrance, entrance + Vector3.zAxis))
			end
			net.Feedback:FireClient(player, "arrive", option)
		end
		return
	end
	if key == "Preference" then
		if Preferences.valid(option, value) and s.profile.preferences[option] ~= value then
			s.profile.preferences[option] = value
			player:SetAttribute(option, value)
		end
		return
	end
	local now = os.clock()
	if
		key ~= "Surface"
		and key ~= "Sell"
		and key ~= "Buy"
		and key ~= "Job"
		and key ~= "PreviewPass"
		and key ~= "Pass"
	then
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
	local station = counterFor[key]
	if station and not atCounter(player, site.stations[station]) then
		net.Feedback:FireClient(player, "away", station)
		return
	end
	local p = s.profile
	if key == "Surface" then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if s.travel or not root then
			return
		end
		s.tripId = (s.tripId or 0) + 1
		local travel = { id = s.tripId, character = character }
		s.travel = travel
		local depth = math.max(0, Config.depthInBlocks(world.origin.Y + Config.FloorY - root.Position.Y))
		net.Feedback:FireClient(player, "depart", travel.id, depth)
		task.delay(10, function()
			if s.travel == travel then
				s.travel = nil
				if player.Parent == Players then
					net.Feedback:FireClient(player, "arrive", travel.id)
				end
			end
		end)
	elseif key == "Sell" then
		local quantity = Profile.used(p)
		local gold = Profile.sell(p, if player:GetAttribute("DoubleGold") then 2 else 1)
		sync(player, p)
		net.Feedback:FireClient(player, "sale", gold, quantity, p.gold)
	elseif key == "Buy" and type(option) == "string" and Upgrades.items[option] then
		local ok, msg = Profile.buy(p, option)
		sync(player, p)
		net.Feedback:FireClient(player, if ok then "upgrade" else "hint", msg, option, p.levels[option])
	elseif key == "Job" then
		local job = Profile.claimJob(p, option)
		if job then
			sync(player, p)
			net.Feedback:FireClient(player, "job", job.title, job.reward)
		end
	elseif key == "PreviewPass" then
		Passes.preview(player, option)
	elseif key == "Pass" then
		Passes.prompt(player, option)
	end
end
net.Action.OnServerEvent:Connect(action)
for name, prompt in site.stations do
	if name == "Shop" or name == "Store" then
		net:SetAttribute(name .. "Position", prompt.Parent.Position)
		net:SetAttribute(name .. "Range", prompt.MaxActivationDistance + 1)
	end
	prompt.Triggered:Connect(function(player)
		if not atCounter(player, prompt) then
			return
		end
		if name == "Sell" then
			action(player, "Sell")
		elseif name == "Shop" then
			net.Feedback:FireClient(player, "shop")
		else
			net.Feedback:FireClient(player, "page", name)
		end
	end)
end
Mining.start(world, net, sessions, sync)
require(script.Standings).start(site.court, net.FriendsBoard)
Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(leave)
for _, player in Players:GetPlayers() do
	task.spawn(join, player)
end

task.spawn(function()
	while true do
		world:generate()
		net:SetAttribute("Ready", true)
		repeat
			task.wait(1)
		until world.removed >= Config.ResetAfter
		net.Feedback:FireAllClients("resetSoon", Config.ResetWarning)
		task.wait(Config.ResetWarning)
		world.ready = false
		net:SetAttribute("Ready", false)
		for _, player in Players:GetPlayers() do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and Config.inMine(root.Position - world.origin) then
				moveCharacter(char, CFrame.lookAt(entrance, entrance - Vector3.zAxis))
			end
		end
		local oldSeed = world.seed
		repeat
			world.seed = seeds:NextInteger(1, 2147483646)
		until world.seed ~= oldSeed
	end
end)
task.spawn(function()
	while task.wait(0.5) do
		for player, s in sessions do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not root then
				continue
			end
			local localPos = root.Position - world.origin
			local mining = Config.inMine(localPos)
			if mining and localPos.Y < Config.FloorY then
				local cell = world.grid:cellAt(root.Position)
				local chunk, index = world.grid:slot(cell, false)
				mining = (chunk ~= nil and chunk[index] ~= nil)
					or Config.inHall(localPos) and localPos.Y >= Config.FloorY - Config.BenchRows * Config.Cell
			end
			if mining then
				local depthStuds = math.floor(Config.FloorY - localPos.Y)
				if depthStuds > s.profile.bestDepth then
					s.profile.bestDepth = depthStuds
					player.leaderstats.Depth.Value = Config.depthInBlocks(depthStuds)
				end
			elseif
				localPos.Y < -35
				or math.abs(localPos.X) > Config.SurfaceMax.X + 12
				or localPos.Z > Config.SurfaceMax.Z + 12
				or localPos.Z < Config.SiteMin.Z - 25
			then
				moveCharacter(player.Character, CFrame.new(landing))
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
