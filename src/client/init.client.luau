local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local net = Rep:WaitForChild("EndlessMiningNet")
local shared = Rep:WaitForChild("Shared")
for _, name in { "Mine", "Action", "Feedback", "Dust" } do
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
local fx = Effects.new()
local held, lastSend, firstHaul = nil, 0, false
local tapPending = false
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local origin = net:GetAttribute("Origin")
local landing = net:GetAttribute("Landing")
local function release()
	held, tapPending = nil, false
end
local function gotCharacter(character)
	release()
	params.FilterDescendantsInstances = { character }
	-- Face the mine approach when spawning in an empty place file.
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root then
		for _ = 1, 100 do
			if (root.Position - origin).Magnitude < 80 then
				break
			end
			task.wait(0.05)
		end
		if player.Character == character and workspace.CurrentCamera then
			workspace.CurrentCamera.CFrame =
				CFrame.lookAt(root.Position + Vector3.new(0, 6, 15), root.Position + Vector3.new(0, 7, -22))
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
		held, tapPending = input, true
	end
end)
hud.mine.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		held, tapPending = input, true
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
		held = nil
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

net.Feedback.OnClientEvent:Connect(function(kind, a, point, spread)
	if kind == "loot" then
		firstHaul = true
		fx:swing(player)
		local best = Ores.byName.Stone
		local pieces, value, lines = 0, 0, {}
		for _, ore in Ores.list do
			local n = a[ore.name]
			if n then
				pieces += n
				value += n * ore.value
				best = ore
				table.insert(lines, string.format("%d %s", n, ore.name))
			end
		end
		fx:burst(point, spread, best)
		local rare = best.hardness >= 4
		hud:notice(
			if rare then best.flash else "+" .. pieces .. " ore  ·  " .. value .. " G",
			table.concat(lines, "  +  ") .. (if rare then "  ·  " .. value .. " G" else ""),
			if rare then best.color else W.white
		)
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
	elseif kind == "shop" then
		hud:setShop(true)
	elseif kind == "page" then
		hud:openPage(a)
	elseif kind == "travel" then
		hud:setShop(false)
		hud:notice(a, "Lift arrived", W.aqua)
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
net.Dust.OnClientEvent:Connect(function(point, spread, ore, miner)
	fx:swing(miner)
	fx:burst(point, spread, Ores.byName[ore], true)
end)

local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
	elapsed += dt
	if elapsed < 1 / 30 then
		return
	end
	elapsed = 0
	local camera = workspace.CurrentCamera
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head or not camera then
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
					return if part.Name == "Turf" then Ores.byName.Stone else Ores.byName[part.Name]
				end
				return nil
			end
			cells, mask, locked = Pattern.select(origin, center, normal, count, power, space, nil, probe)
		end
	end
	fx:aim(cells, normal)
	local valid = mask ~= 0
	hud.reticle.Visible = mobile
	if mobile then
		hud.reticle.BackgroundColor3 = if valid then W.aqua else W.white
	end
	if not ready then
		hud:guide("Opening the quarry…", "Preparing your pack and the mine", true)
	elseif space <= 0 then
		hud:guide("Backpack full", "Tap SELL to cash in your haul", true)
	elseif not valid and locked then
		hud:guide(locked.name .. " needs Power " .. locked.hardness, "Upgrade Power at the workshop", true)
	elseif valid or not firstHaul then
		local help = if mobile then "Hold MINE on the highlighted blocks" else "Hold the left mouse button to mine"
		local title = if valid
			then string.format("%d block%s selected", #cells, if #cells == 1 then "" else "s")
			else "Follow the path to the crystal cave"
		hud:guide(title, help, true)
	else
		hud:guide("", "", false)
	end
	if (held or tapPending) and valid and os.clock() - lastSend >= 0.085 then
		lastSend = os.clock()
		net.Mine:FireServer(center, normal, count, mask)
	end
	tapPending = false
end)
