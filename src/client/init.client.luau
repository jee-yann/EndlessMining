local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local net = Rep:WaitForChild("EndlessMiningNet")
local shared = Rep:WaitForChild("Shared")
for _, name in { "Mine", "Action", "Feedback", "Dust", "Swing" } do
	net:WaitForChild(name)
end
for _, name in { "BlockPattern", "GameConfig", "Ores", "Upgrades", "Expeditions", "PassCatalog", "FieldGuide" } do
	shared:WaitForChild(name)
end
local Config, Ores, Upgrades = require(shared.GameConfig), require(shared.Ores), require(shared.Upgrades)
local Pattern = require(shared.BlockPattern)
local Hud, Effects, W = require(script.Hud), require(script.Effects), require(script.Widgets)
local mobile = UIS.PreferredInput == Enum.PreferredInput.Touch
local hud = Hud.new(player, net, mobile)
local Audio = require(script.HarborAudio)
local fx = Effects.new()
local tags = game:GetService("CollectionService")
local function shine(gradient)
	game:GetService("TweenService")
		:Create(
			gradient,
			TweenInfo.new(1.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 1.1),
			{ Offset = Vector2.new(1.3, 0) }
		)
		:Play()
end
tags:GetInstanceAddedSignal("MiningPadShine"):Connect(shine)
for _, gradient in tags:GetTagged("MiningPadShine") do
	shine(gradient)
end
local Swing = require(script.PickSwing)
local held, firstHaul, rig = nil, false, nil
local target, targetSide, strokeStart
local finishedCell, retryAt
local aimPoint, aimSide, aimOre, aimPart
local swinging = false
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local origin = net:GetAttribute("Origin")
local landing = net:GetAttribute("Landing")
local entrance = net:GetAttribute("Entrance")
local passage = require(script.Passage).new(player, net)
local receipt = require(script.SaleReceipt).new(hud)
task.spawn(require(script.Tramway), origin)
require(script.MineView).start(player, origin)
local function cancelStroke()
	if rig then
		rig:stop()
	end
	if swinging then
		net.Swing:FireServer(false)
		swinging = false
	end
	target, targetSide, strokeStart = nil, nil, nil
	hud.meter.Visible = false
	fx:clearDamage()
end
local function release()
	if held and not swinging then
		net.Swing:FireServer(false)
	end
	held = nil
	cancelStroke()
end
local function gotCharacter(character)
	release()
	if rig then
		rig:destroy()
	end
	rig, aimPoint = nil, nil
	params.FilterDescendantsInstances = { character }
	-- Face the mine approach when spawning in an empty place file.
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root then
		for _ = 1, 100 do
			if (root.Position - landing).Magnitude < 18 then
				break
			end
			task.wait(0.05)
		end
		while player.Character == character and not workspace.CurrentCamera do
			RunService.PreRender:Wait()
		end
		if player.Character == character then
			workspace.CurrentCamera.CFrame =
				CFrame.lookAt(root.Position + Vector3.new(0, 7, 16), root.Position + Vector3.new(0, 4, -22))
			character:SetAttribute("MiningViewReady", true)
		end
	end
end
player.CharacterAdded:Connect(gotCharacter)
if player.Character then
	task.spawn(gotCharacter, player.Character)
end

UIS.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.Tab and not player.PlayerGui:FindFirstChild("MiningLoading") then
		if hud.overlay.Visible and hud.menu.page == "Crew" then
			hud.menu:close()
		else
			hud:openPage("Crew")
		end
		return
	end
	if processed or player.PlayerGui:FindFirstChild("MiningLoading") or hud.overlay.Visible or passage.active then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		held = input
	end
end)
hud.mine.InputBegan:Connect(function(input)
	if
		not player.PlayerGui:FindFirstChild("MiningLoading")
		and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1)
	then
		held = input
	end
end)
UIS.InputEnded:Connect(function(input)
	if
		held == input
		or (
			held
			and held.UserInputType == Enum.UserInputType.MouseButton1
			and input.UserInputType == held.UserInputType
		)
	then
		release()
	end
end)
UIS.WindowFocusReleased:Connect(release)
GuiService.MenuOpened:Connect(release)
hud.overlay:GetPropertyChangedSignal("Visible"):Connect(release)
UIS:GetPropertyChangedSignal("PreferredInput"):Connect(function()
	mobile = UIS.PreferredInput == Enum.PreferredInput.Touch
	hud.mobile, hud.mine.Visible = mobile, mobile and not hud.overlay.Visible
	hud:placePanels(mobile)
	release()
end)

net.Feedback.OnClientEvent:Connect(function(kind, a, point, spread, finds, normal)
	if kind == "achievement" then
		hud:milestone("ACHIEVEMENT", a, W.gold)
	elseif kind == "loot" then
		firstHaul = true
		local best = Ores.byName.Dirt
		for name in a do
			local ore = Ores.byName[name]
			if ore.value > best.value then
				best = ore
			end
		end
		Audio.ore(a)
		fx:burst(point, spread, best)
		fx:labels(finds, a, normal)
	elseif kind == "milestone" then
		hud:milestone(a, point, spread)
	elseif kind == "depart" then
		release()
		passage:depart(a, point)
	elseif kind == "arrive" then
		passage:arrive(a)
	elseif kind == "sale" then
		if a > 0 then
			fx:chime(1.45)
			receipt:show(a, point, spread)
		else
			hud:notice("Your pack is empty", "Mine a block to start a haul", W.gold)
		end
	elseif kind == "away" then
		hud:setShop(false)
		hud:notice(
			"Visit the counter",
			if a == "Sell"
				then "Sell under the amber sign"
				elseif a == "Shop" then "Upgrades under the cyan sign"
				else "Outfitters at the pink stall",
			W.gold
		)
	elseif kind == "shop" then
		hud:setShop(true)
	elseif kind == "page" then
		hud:openPage(a)
	elseif kind == "close" then
		hud:setShop(false)
	elseif kind == "job" then
		fx:chime(1.65)
		hud:notice("+" .. W.number(point) .. " gold", a .. " completed", W.gold)
	elseif kind == "resetSoon" then
		hud:milestone("MINE RENEWAL", "New ore in " .. a .. " seconds", W.aqua)
		hud:notice("Mine renews in " .. a .. " seconds", "Your haul returns to the entrance with you", W.aqua)
	elseif kind == "upgrade" then
		fx:chime(1.55)
		hud:workshop(point, spread)
		hud:notice(a, Upgrades.describe(point, spread), W.green)
	else
		hud:notice(a, "", W.gold)
	end
end)
net.Dust.OnClientEvent:Connect(function(point, spread, ore, finds, normal, loot)
	fx:labels(finds, loot, normal, true)
	fx:burst(point, spread, Ores.byName[ore], true)
end)

local podiums = require(script.Podiums).new(player)
local friendRows, friendNote
local function drawFriends()
	local map = workspace:FindFirstChild("CitrineCove")
	local harbor = map and map:FindFirstChild("Harbor Plaza")
	local court = harbor and harbor:FindFirstChild("Miners Court")
	local board = court and court:FindFirstChild("Friends")
	local screen = board and board:FindFirstChild("Standings")
	local face = screen and screen:FindFirstChild("Lettering")
	if not face or not face:FindFirstChild("Row5") or not friendRows then
		return
	end
	for i = 1, 5 do
		face["Row" .. i].Text = friendRows[i] or ""
	end
	face.Title.Text = if friendNote ~= "" then friendNote else "DEEPEST DESCENT"
end
net:WaitForChild("FriendsBoard").OnClientEvent:Connect(function(rows, note, winners)
	friendRows, friendNote = rows, note
	podiums.friends = winners or {}
	drawFriends()
end)
workspace.DescendantAdded:Connect(function(obj)
	if obj.Name == "Row5" then
		task.defer(drawFriends)
	end
end)

Players.PlayerAdded:Connect(Swing.observe)
for _, other in Players:GetPlayers() do
	if other ~= player then
		Swing.observe(other)
	end
end

require(script.RockCompanions)()
local lastCoordinates
local function sampleAim()
	aimPoint, aimPart = nil, nil
	local camera = workspace.CurrentCamera
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not head or not root or not camera then
		hud:aimAt(nil)
		release()
		fx:aim(nil)
		return
	end
	local localPos = root.Position - origin
	local coords = Config.blockCoordinates(localPos)
	if coords ~= lastCoordinates then
		lastCoordinates = coords
		local depth = math.max(0, -coords.Y)
		local inHarbor = not Config.inMine(localPos)
		hud.coordinates.Text = string.format("X %d    Y %d    Z %d", coords.X, coords.Y, coords.Z)
		hud.depth.Text = if inHarbor then "Surface" elseif depth == 1 then "1 block" else depth .. " blocks"
		hud.layer.Text =
			string.upper(if inHarbor then Config.SurfaceName else Config.layer(Config.FloorY - localPos.Y).name)
	end
	hud.surface.Visible = not passage.active
		and (localPos.Y < -2 or localPos.Z < 0)
		and (root.Position - entrance).Magnitude > 7
	if hud.overlay.Visible or passage.active or player.PlayerGui:FindFirstChild("MiningLoading") then
		hud:aimAt(nil)
		local station = if hud.menu.page == "Gear" then "Shop" elseif hud.menu.page == "Store" then "Store" else nil
		if station then
			local pos = net:GetAttribute(station .. "Position")
			if not pos or (root.Position - pos).Magnitude > net:GetAttribute(station .. "Range") then
				hud:setShop(false)
			end
		end
		fx:aim(nil)
		return
	end
	local ready = net:GetAttribute("Ready") and player:GetAttribute("ProfileReady")
	local screen = if mobile then camera.ViewportSize * 0.5 else UIS:GetMouseLocation()
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	local reach = char:GetAttribute("PickReach") or Config.Reach
	local hit = workspace:Raycast(ray.Origin, ray.Direction * (reach + 48), params)
	local cap = Upgrades.items.Capacity.values[player:GetAttribute("Capacity") or 1]
	local space = cap - (player:GetAttribute("Used") or 0)
	local power = Upgrades.items.Power.values[player:GetAttribute("Power") or 1]
	local center, normal, cells, locked, required
	if ready and space > 0 and hit and hit.Instance.Parent:HasTag(Config.MineBlockTag) then
		normal = hit.Normal
		center = Config.blockCenter(origin, hit.Position, normal)
		local anchorPart = Pattern.visiblePart(head.Position, center, normal, params, reach)
		if anchorPart and anchorPart.Parent:HasTag(Config.MineBlockTag) then
			cells, locked, required = Pattern.select(origin, center, Ores.byName[anchorPart.Name], power, space)
		end
	end
	fx:aim(cells)
	local valid = cells ~= nil and #cells == 1
	hud:aimAt(screen, valid, locked)
	hud.reticle.Visible = mobile
	if mobile then
		hud.reticle.BackgroundColor3 = if valid then W.aqua else W.white
	end
	if not ready then
		hud:guide("Opening the mine…", "Preparing your pack and the mine", true)
	elseif space <= 0 then
		hud:guide("Backpack full", "Bring your haul to the amber Sell counter", true)
	elseif not valid and locked then
		hud:guide(
			(if locked.secret and not player:GetAttribute("Found" .. locked.name) then "???" else locked.name)
				.. " needs Power "
				.. required,
			"Upgrade Power at the workshop",
			true
		)
	elseif valid or not firstHaul then
		local help = if mobile then "Hold MINE on the highlighted blocks" else "Hold the left mouse button to mine"
		if valid then
			local ore = Ores.byName[hit.Instance.Name]
			local worth = if ore.secret and not player:GetAttribute("Found" .. ore.name)
				then "???"
				else W.number(ore.value * (if player:GetAttribute("DoubleGold") then 2 else 1)) .. " G"
			help = "Hold to mine  ·  Hardness " .. Config.strength(center.Y - origin.Y) .. "  ·  " .. worth
		end
		local title = if valid
			then "Mine " .. (if Ores.byName[hit.Instance.Name].secret
					and not player:GetAttribute("Found" .. hit.Instance.Name)
				then "???"
				else string.lower(hit.Instance.Name))
			elseif localPos.Y < -2 then "Aim at the wall or floor to keep digging"
			else "Follow the path to the crystal cave"
		hud:guide(title, help, true)
	else
		hud:guide("", "", false)
	end
	if valid then
		aimPoint, aimSide, aimOre = center, normal, Ores.byName[hit.Instance.Name]
		aimPart = hit.Instance
	end
end

local elapsed = 1
RunService.RenderStepped:Connect(function(dt)
	elapsed += dt
	if elapsed >= 1 / 30 then
		elapsed %= 1 / 30
		sampleAim()
	end
	if not held or not aimPoint or hud.overlay.Visible then
		if strokeStart or (rig and rig.playing) then
			cancelStroke()
		end
		return
	end
	local now = os.clock()
	if finishedCell == aimPoint and now < retryAt then
		return
	end
	if not swinging or aimPoint ~= target then
		if strokeStart and target ~= aimPoint then
			fx:clearDamage()
		end
		target, targetSide, strokeStart = aimPoint, aimSide, now
		net.Swing:FireServer(true, target, targetSide)
		swinging = true
	end
	local duration = Ores.cutTime(
		Upgrades.items.Speed.values[player:GetAttribute("Speed") or 1]
			* (if player:GetAttribute("SkillTempo") then 0.9 else 1),
		aimOre,
		Config.strength(target.Y - origin.Y)
	)
	if rig and not rig.shoulder:IsDescendantOf(workspace) then
		rig:destroy()
		rig = nil
	end
	rig = rig or Swing.new(player.Character)
	if rig and (not rig.playing or rig.duration ~= duration) then
		rig:play(duration)
	end
	local progress = math.clamp((now - strokeStart) / duration, 0, 1)
	hud.speech.Visible, hud.meter.Visible = true, true
	hud.swingFill.Size = UDim2.fromScale(progress, 1)
	hud.cursorPick.Rotation = -14 + 23 * math.sin(progress * math.pi * 6)
	hud.cursorEdge.Color = W.gold
	fx:damage(aimPart, progress)
	if progress == 1 then
		net.Mine:FireServer(target, aimSide, 1, 1)
		finishedCell, retryAt = target, now + 0.5
		hud.meter.Visible = false
		swinging = false
		strokeStart = nil
	end
end)

hud.root.Parent:SetAttribute("ControllerReady", true)
