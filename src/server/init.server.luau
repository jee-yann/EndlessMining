local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local Config, Upgrades = require(Rep.Shared.GameConfig), require(Rep.Shared.Upgrades)
local World, MineSite = require(script.MineWorld), require(script.MineSite)
local E, Guide = require(Rep.Shared.Expeditions), require(Rep.Shared.FieldGuide)
local Ores = require(Rep.Shared.Ores)
local Preferences = require(Rep.Shared.Preferences)
local Passes = require(script.Passes)
local equipKit = require(script.ProspectorKit)
local Pickaxe = require(script.Pickaxe)
local Data, Profile, Mining = require(script.DataService), require(script.Profile), require(script.MiningService)
local PIXELII_USER_ID = 45241447

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
net:SetAttribute("DigFloor", world.origin + Vector3.new(0, Config.FloorY, (Config.HallFront + Config.HallBack) / 2))
net:SetAttribute("DigFloorSize", Vector3.new(2 * Config.HallHalfWidth, Config.Cell, Config.HallFront - Config.HallBack))
net:SetAttribute("Ready", false)
for _, name in { "Mine", "Action", "Feedback", "Dust", "FriendsBoard", "Swing" } do
	local event = Instance.new(if name == "Dust" then "UnreliableRemoteEvent" else "RemoteEvent")
	event.Name, event.Parent = name, net
end
net.Parent = Rep

local sessions, loading, closing, nextAction = {}, {}, {}, {}
local shuttingDown = false
local function applySkills(player, p)
	local char = player.Character
	if not char then
		return
	end
	local human = char:FindFirstChildOfClass("Humanoid")
	if not human then
		return
	end
	char:SetAttribute(
		"PickReach",
		Config.Reach + (if p.skills.Reach then 5 else 0) + (if p.skills.ReachII then 5 else 0)
	)
	human.WalkSpeed = 16 + (if p.skills.Stride then 3 else 0) + (if p.skills.Scout then 3 else 0)
	human.JumpHeight = game.StarterPlayer.CharacterJumpHeight * (if p.skills.Spring then 1.25 else 1)
	human.JumpPower = game.StarterPlayer.CharacterJumpPower * (if p.skills.Spring then math.sqrt(1.25) else 1)
	local lamp = char:FindFirstChild("Mining lamp", true)
	if lamp then
		lamp.Range = 20 + (if p.skills.Lamp then 8 else 0) + (if p.skills.Lantern then 8 else 0)
	end
end
local function sync(player, p, awardName)
	player:SetAttribute("Level", E.level(p.xp))
	player:SetAttribute("EquippedTitle", Guide.selectedTitle(p))
	player:SetAttribute("Pet", p.pet)
	player:SetAttribute("PetName", p.petName)
	player:SetAttribute("SkillPoints", Guide.points(p.xp, p.skills))
	for _, node in Guide.skills do
		player:SetAttribute("Skill" .. node.id, p.skills[node.id] == true)
	end
	player.leaderstats.Level.Value = E.level(p.xp)
	player:SetAttribute("Gold", p.gold)
	player:SetAttribute("Used", Profile.used(p))
	player:SetAttribute("BagValue", Profile.value(p.bag))
	player:SetAttribute("Mined", p.mined)
	player:SetAttribute("MiningXP", p.xp)
	player:SetAttribute("Jobs", p.jobs)
	player:SetAttribute("ClaimedJobs", p.claimedJobs)
	for _, award in Guide.achievements do
		player:SetAttribute("Award" .. award.id, Guide.progress(p, award))
	end
	for _, ore in Ores.list do
		player:SetAttribute("Lifetime" .. ore.name, p.counts[ore.name] or 0)
		player:SetAttribute("Held" .. ore.name, p.bag[ore.name] or 0)
		player:SetAttribute("Found" .. ore.name, p.discoveries[ore.name] == true)
	end
	for _, key in Upgrades.order do
		player:SetAttribute(key, p.levels[key])
	end
	player.leaderstats.Gold.Value = p.gold
	player.leaderstats.Depth.Value = Config.depthInBlocks(p.bestDepth)
	if awardName then
		net.Feedback:FireClient(player, "achievement", awardName)
	end
end
local Ascent = require(script.Ascent)
local function moveCharacter(character, destination)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		local owner = Players:GetPlayerFromCharacter(character)
		local session = owner and sessions[owner]
		if session then
			session.climb = nil
		end
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
local function mineFit(char, inside)
	local base = char:GetAttribute("SurfaceScale")
	if inside and not base then
		base = char:GetScale()
		local head = char:FindFirstChild("Head")
		local foot = char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg")
		if head and foot then
			local height = head.Position.Y + head.Size.Y / 2 - foot.Position.Y + foot.Size.Y / 2
			char:SetAttribute("SurfaceScale", base)
			char:ScaleTo(base * math.min(1, 4.50 / math.max(height, 4.5)))
		end
	elseif not inside and base then
		char:ScaleTo(base)
		char:SetAttribute("SurfaceScale", nil)
	end
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
	if sessions[player] then
		applySkills(player, sessions[player].profile)
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
	for _, name in { "Level", "Gold", "Depth" } do
		local stat = Instance.new("IntValue")
		stat.Name, stat.Parent = name, board
	end
	board.Parent = player
	sessions[player], loading[player] = session, nil
	for key, value in session.profile.preferences do
		player:SetAttribute(key, value)
	end
	sync(player, session.profile)
	applySkills(player, session.profile)
	player:SetAttribute("ProfileReady", true)
	if player.UserId == PIXELII_USER_ID then
		local gui = Instance.new("ScreenGui")
		gui.Name, gui.ResetOnSpawn = "OwnerOreVision", false
		script.OwnerOreVision:Clone().Parent = gui
		gui.Parent = player:WaitForChild("PlayerGui")
	end
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
				mineFit(travel.character, false)
				applySkills(player, s.profile)
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
		and key ~= "Title"
		and key ~= "Skill"
		and key ~= "Pet"
		and key ~= "PetName"
		and key ~= "Pass"
	then
		return
	end
	local times = nextAction[player]
	if not times then
		times = {}
		nextAction[player] = times
	end
	local actionKey = key
	if key == "Job" then
		if type(option) ~= "number" or option % 1 ~= 0 or not E.jobs[option] then
			return
		end
		actionKey = "Job" .. option
	end
	if now < (times[actionKey] or 0) then
		return
	end
	times[actionKey] = now + 0.18
	local station = counterFor[key]
	if station and not atCounter(player, site.stations[station]) then
		net.Feedback:FireClient(player, "away", station)
		return
	end
	local p = s.profile
	if key == "Title" then
		if Profile.equipTitle(p, option) then
			sync(player, p)
		end
	elseif key == "Skill" then
		if type(option) == "string" then
			local learned, award = Profile.learn(p, option)
			if learned then
				sync(player, p, award)
				applySkills(player, p)
			end
		end
	elseif key == "Pet" then
		if option == "Rock" or option == "" then
			p.pet = option
			sync(player, p)
		end
	elseif key == "PetName" then
		if type(option) ~= "string" or #option > 80 then
			return
		end
		local name = option:match("^%s*(.-)%s*$")
		local length = utf8.len(name)
		if not length or length < 1 or length > 20 then
			net.Feedback:FireClient(player, "hint", "Choose a name with 1–20 characters")
			return
		end
		if s.filteringPetName then
			return
		end
		if not Guide.petNames[name] then
			s.filteringPetName = true
			local ok, filtered = pcall(function()
				local result = game:GetService("TextService"):FilterStringAsync(name, player.UserId)
				return result:GetNonChatStringForBroadcastAsync()
			end)
			s.filteringPetName = nil
			if sessions[player] ~= s then
				return
			end
			if not ok or not filtered or filtered == "" or filtered:find("#", 1, true) then
				net.Feedback:FireClient(player, "hint", "Try another name, or choose a suggested name")
				return
			end
			name = filtered
		end
		p.petName = name
		sync(player, p, if name ~= "Pebble" then Profile.unlock(p, "PetName") else nil)
	elseif key == "Surface" then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if s.travel or not root then
			return
		end
		s.tripId = (s.tripId or 0) + 1
		local travel = { id = s.tripId, character = character }
		s.climb = nil
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
		local gold, award = Profile.sell(p, if player:GetAttribute("DoubleGold") then 2 else 1)
		sync(player, p, award)
		net.Feedback:FireClient(player, "sale", gold, quantity, p.gold)
	elseif key == "Buy" and type(option) == "string" and Upgrades.items[option] then
		local ok, msg, award = Profile.buy(p, option)
		sync(player, p, award)
		net.Feedback:FireClient(player, if ok then "upgrade" else "hint", msg, option, p.levels[option])
	elseif key == "Job" then
		local job, award = Profile.claimJob(p, option)
		if job then
			sync(player, p, award)
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
				mineFit(char, false)
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
				s.climb = nil
				continue
			end
			local localPos = root.Position - world.origin
			local mining = Config.inMine(localPos)
			if mining and localPos.Y < Config.FloorY then
				local cell = world.grid:cellAt(root.Position)
				local chunk, index = world.grid:slot(cell, false)
				mining = chunk ~= nil and chunk[index] ~= nil
			end
			local char = player.Character
			local human = char:FindFirstChildOfClass("Humanoid")
			if s.travel or not world.ready or not human or human.Health <= 0 or s.profile.earned.Ascent then
				s.climb = nil
			elseif Ascent.sample(s, char, localPos, mining, os.clock()) then
				sync(player, s.profile, Profile.unlock(s.profile, "Ascent"))
			end
			if mining ~= (char:GetAttribute("SurfaceScale") ~= nil) then
				mineFit(char, mining)
				applySkills(player, s.profile)
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
				mineFit(player.Character, false)
				applySkills(player, s.profile)
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
