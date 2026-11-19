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
for _, name in { "BlockPattern", "GameConfig", "Ores", "Upgrades", "Expeditions", "PassCatalog" } do
	shared:WaitForChild(name)
end
local Config, Ores, Upgrades = require(shared.GameConfig), require(shared.Ores), require(shared.Upgrades)
local Pattern = require(shared.BlockPattern)
local Hud, Effects, W = require(script.Hud), require(script.Effects), require(script.Widgets)
local mobile = UIS.PreferredInput == Enum.PreferredInput.Touch
local hud = Hud.new(player, net, mobile)
local Audio = require(script.HarborAudio)
local fx = Effects.new()
local Swing = require(script.PickSwing)
local held, firstHaul, rig = nil, false, nil
local target, targetSide, strokeStart
local aimPoint, aimSide, aimCount, aimMask, aimCells
local swinging = false
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local origin = net:GetAttribute("Origin")
local landing = net:GetAttribute("Landing")
task.spawn(require(script.Tramway), origin)
local function cancelStroke()
	if swinging then
		if rig then
			rig:stop()
		end
		net.Swing:FireServer(false)
		swinging = false
	end
	target, targetSide, strokeStart = nil, nil, nil
	hud.meter.Visible = false
	fx:damage(nil)
end
local function release()
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
		if player.Character == character and workspace.CurrentCamera then
			workspace.CurrentCamera.CFrame =
				CFrame.lookAt(root.Position + Vector3.new(0, 7, 16), root.Position + Vector3.new(0, 4, -22))
		end
	end
end
player.CharacterAdded:Connect(gotCharacter)
if player.Character then
	task.spawn(gotCharacter, player.Character)
end

UIS.InputBegan:Connect(function(input, processed)
	if processed or hud.overlay.Visible then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		held = input
	end
end)
hud.mine.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
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
	if kind == "loot" then
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
	elseif kind == "sale" then
		if a > 0 then
			fx:chime(1.2)
		end
		hud:notice(
			if a > 0 then "+" .. W.number(a) .. " gold" else "Your pack is empty",
			if a > 0 then "Ore sold at the exchange" else "Mine a seam to collect ore",
			W.gold
		)
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
	elseif kind == "upgrade" then
		fx:chime(1.55)
		hud:notice(a, "Workshop upgrade fitted", W.green)
	else
		hud:notice(a, "", W.gold)
	end
end)
net.Dust.OnClientEvent:Connect(function(point, spread, ore, finds, normal, loot)
	fx:labels(finds, loot, normal)
	fx:burst(point, spread, Ores.byName[ore], true)
end)

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
	face.Title.Text = if friendNote ~= "" then friendNote else "BLOCKS MINED"
end
net:WaitForChild("FriendsBoard").OnClientEvent:Connect(function(rows, note)
	friendRows, friendNote = rows, note
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

local function sampleAim()
	aimPoint, aimCells = nil, nil
	local camera = workspace.CurrentCamera
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head or not camera then
		hud:aimAt(nil)
		release()
		fx:aim(nil)
		return
	end
	local localPos = head.Position - origin
	local depth = math.max(0, math.floor(-localPos.Y))
	hud.depth.Text = if depth == 0 then "Surface" else depth .. " studs"
	hud.layer.Text = if depth == 0 and localPos.Z >= 0
		then string.upper(Config.SurfaceName)
		else string.upper(Config.layer(depth).name)
	hud.surface.Visible = depth > 2 or (head.Position - landing).Magnitude > 24
	if hud.overlay.Visible then
		hud:aimAt(nil)
		local station = if hud.menu.page == "Gear" then "Shop" elseif hud.menu.page == "Store" then "Store" else nil
		if station then
			local root = char:FindFirstChild("HumanoidRootPart")
			local pos = net:GetAttribute(station .. "Position")
			if not root or not pos or (root.Position - pos).Magnitude > net:GetAttribute(station .. "Range") then
				hud:setShop(false)
			end
		end
		fx:aim(nil)
		return
	end
	local ready = net:GetAttribute("Ready") and player:GetAttribute("ProfileReady")
	local screen = if mobile then camera.ViewportSize * 0.5 else UIS:GetMouseLocation()
	local ray = camera:ViewportPointToRay(screen.X, screen.Y)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * (Config.Reach + 48), params)
	local cap = Upgrades.items.Capacity.values[player:GetAttribute("Capacity") or 1]
	local space = cap - (player:GetAttribute("Used") or 0)
	local count = Upgrades.items.Radius.values[player:GetAttribute("Radius") or 1]
	local power = Upgrades.items.Power.values[player:GetAttribute("Power") or 1]
	local center, normal, cells, mask, locked = nil, nil, nil, 0, nil
	if ready and space > 0 and hit and hit.Instance.Parent:HasTag(Config.MineBlockTag) then
		normal = hit.Normal
		center = Config.blockCenter(origin, hit.Position, normal)
		local anchorPart = Pattern.visiblePart(head.Position, center, normal, params)
		if anchorPart and anchorPart.Parent:HasTag(Config.MineBlockTag) then
			local function probe(pos)
				local part = if pos == center
					then anchorPart
					else Pattern.visiblePart(head.Position, pos, normal, params)
				if part and part.Parent:HasTag(Config.MineBlockTag) then
					return Ores.byName[part.Name]
				end
				return nil
			end
			cells, mask, locked = Pattern.select(origin, center, normal, count, power, space, nil, probe)
		end
	end
	fx:aim(cells)
	local valid = mask ~= 0
	hud:aimAt(screen, valid, locked)
	hud.reticle.Visible = mobile
	if mobile then
		hud.reticle.BackgroundColor3 = if valid then W.aqua else W.white
	end
	if not ready then
		hud:guide("Opening the quarry…", "Preparing your pack and the mine", true)
	elseif space <= 0 then
		hud:guide("Backpack full", "Bring your haul to the amber Sell counter", true)
	elseif not valid and locked then
		hud:guide(locked.name .. " needs Power " .. locked.hardness, "Upgrade Power at the workshop", true)
	elseif valid or not firstHaul then
		local help = if mobile then "Hold MINE on the highlighted blocks" else "Hold the left mouse button to mine"
		local title = if valid
			then string.format("%d block%s selected", #cells, if #cells == 1 then "" else "s")
			elseif depth > 2 then "Aim at the wall or floor to keep digging"
			else "Follow the path to the crystal cave"
		hud:guide(title, help, true)
	else
		hud:guide("", "", false)
	end
	if valid then
		aimPoint, aimSide, aimCount, aimMask, aimCells = center, normal, count, mask, cells
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
		if strokeStart then
			cancelStroke()
		end
		return
	end
	local now = os.clock()
	if aimPoint ~= target or targetSide ~= aimSide then
		target, targetSide, strokeStart = aimPoint, aimSide, now
	end
	local duration = Upgrades.items.Speed.values[player:GetAttribute("Speed") or 1]
	if not swinging then
		net.Swing:FireServer(true, target)
		swinging = true
	end
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
	fx:damage(aimCells, aimSide, progress)
	if progress == 1 then
		net.Mine:FireServer(target, targetSide, aimCount, aimMask)
		fx:damage(nil)
		strokeStart = now
	end
end)
