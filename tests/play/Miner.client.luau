local rep = game:GetService("ReplicatedStorage")
local p = game.Players.LocalPlayer
local r = rep:WaitForChild("MiningTestReport")
local function waitFor(check, seconds, msg)
	local start = os.clock()
	repeat
		if check() then
			return
		end
		task.wait(0.08)
	until os.clock() - start > seconds
	error(msg)
end
local function test()
	local n = rep:WaitForChild("EndlessMiningNet", 25)
	assert(n, "server bootstrap")
	waitFor(function()
		return n:GetAttribute("Ready")
			and p:GetAttribute("ProfileReady")
			and p.Character
			and p.Character:FindFirstChild("Head")
	end, 30, "profile/world readiness")
	local gui = p.PlayerGui:WaitForChild("MiningHUD", 10)
	assert(gui and gui.SafeArea:FindFirstChild("ShopOverlay"), "HUD did not mount")
	waitFor(function()
		return workspace:FindFirstChild("MiningSelection")
	end, 8, "aim controller did not start")
	assert(p:GetAttribute("SaveStatus") == "Practice session", "local data scope")
	waitFor(function()
		return p.Character:FindFirstChild("Harbor pick")
	end, 8, "equipped pickaxe")
	local kit = p.Character:FindFirstChild("Prospector kit", true)
	assert(kit and kit["Miner title"].TextLabel.Text == "Lamp Tender", "starter backpack and title")
	local packSize = kit["Field pack"].Size
	local harbor = game.SoundService:WaitForChild("Harbor audio", 8)
	local song = harbor:WaitForChild("Prima Bossa Nova", 5)
	assert(not song.IsPlaying and song.Volume < 0.1, "test music must stay muted")
	waitFor(function()
		return gui:GetAttribute("ControllerReady") and not p.PlayerGui:FindFirstChild("MiningLoading")
	end, 18, "loading screen dismisses")
	local mount = p.Character.HumanoidRootPart:FindFirstChild("Lamp mount")
	assert(
		mount and mount:FindFirstChildOfClass("PointLight") and p.Character:GetAttribute("MiningViewReady"),
		"spawn camera and character light on reveal"
	)
	local gallery = workspace.CitrineCove["Citrine Mine"]:FindFirstChild("Gallery glow")
	assert(gallery and gallery:FindFirstChildOfClass("PointLight"), "gallery lighting on reveal")
	local audio = require(p.PlayerScripts.Client.HarborAudio)
	for _, voice in harbor:GetChildren() do
		if voice == song then
			continue
		end
		waitFor(function()
			return voice.IsLoaded
		end, 8, voice.Name .. " failed to load")
	end
	if r:GetAttribute("CheckSwing") then
		local seenIds = {}
		for _, ore in require(rep.Shared.Ores).list do
			local voice = harbor[ore.name .. " break"]
			assert(not seenIds[voice.SoundId], "duplicate ore sound")
			seenIds[voice.SoundId] = true
			local played, notes = false, 0
			local strike = voice.Played:Connect(function()
				played = true
			end)
			local flourishes = {}
			for i = 1, 3 do
				table.insert(
					flourishes,
					harbor["Discovery note " .. i].Played:Connect(function()
						notes += 1
					end)
				)
			end
			audio.ore({ [ore.name] = 1 })
			waitFor(function()
				return played and notes == math.max(0, ore.hardness - 3)
			end, 2, ore.name .. " break and reward notes")
			strike:Disconnect()
			for _, signal in flourishes do
				signal:Disconnect()
			end
		end
	end
	local car = workspace.CitrineCove["Citrine Highlands"]["Moving cabins"]["Ore carrier 1"]
	local start = car:GetPivot().Position
	waitFor(function()
		return (car:GetPivot().Position - start).Magnitude > 0.12
	end, 4, "tram movement")
	local overlay = gui.SafeArea.ShopOverlay
	local menu = overlay["Harbor menu"]
	local map = workspace.CitrineCove
	local counters = {
		Sell = map["Shore market"].Sell["Service mat"],
		Gear = map["Shore market"].Upgrades["Service mat"],
		Store = map["Harbor Plaza"].Store.Counter,
		Book = map["Harbor Plaza"].Book.Counter,
	}
	local function visit(key, activate)
		local pad = counters[key]
		r:FireServer("station", key)
		waitFor(function()
			return (p.Character.HumanoidRootPart.Position - pad.Position).Magnitude < 7
		end, 5, "walk to " .. key)
		if activate then
			task.wait(0.25)
			pad.Service:InputHoldBegin()
			task.wait(pad.Service.HoldDuration + 0.15)
			pad.Service:InputHoldEnd()
		end
	end
	for _, page in { "Pack", "Settings", "Gear", "Jobs", "Book", "Store" } do
		if counters[page] then
			visit(page, true)
		else
			r:FireServer("openPage", page)
		end
		local listing = ({
			Settings = "Music volume",
			Gear = "Speed",
			Jobs = "First strike",
			Book = "Stone",
			Pack = "Stone",
			Store = "Double Gold",
		})[page]
		waitFor(function()
			return overlay.Visible and menu.Listings:FindFirstChild(listing)
		end, 5, "open " .. page)
		if page == "Book" then
			assert(menu.Listings["Iron Shelf"].Depth.Text == "27 blocks", "index depth in blocks")
		end
		task.wait(0.26)
		local left, top = menu.AbsolutePosition.X, menu.AbsolutePosition.Y
		local safe = gui.SafeArea
		assert(left >= safe.AbsolutePosition.X - 1 and top >= safe.AbsolutePosition.Y - 1, "menu origin")
		assert(
			menu.AbsoluteSize.X <= safe.AbsoluteSize.X + 1 and menu.AbsoluteSize.Y <= safe.AbsoluteSize.Y + 1,
			"menu bounds"
		)
	end
	r:FireServer("closePage")
	waitFor(function()
		return not overlay.Visible
	end, 5, "close")
	if not r:GetAttribute("CheckSwing") then
		r:FireServer("depthSample")
		local location = gui.SafeArea.Location
		waitFor(function()
			return location.Coordinates.Text == "X -1    Y -27    Z -3"
				and location.Depth.Text == "27 blocks"
				and location.Region.Text == "IRON SHELF"
				and p.leaderstats.Depth.Value == 27
		end, 8, "block coordinates, region and personal best at Iron Shelf")
		assert(location.Coordinates.TextFits and location.Depth.TextFits, "location readout clipped")
	end
	r:FireServer("position")
	local origin = n:GetAttribute("Origin")
	waitFor(function()
		local pos = p.Character.Head.Position - origin
		return pos.Z < 0 and math.abs(pos.Y - 5) < 4
	end, 8, "placement at starter seam")
	local first = os.clock()
	local discovered
	n.Feedback.OnClientEvent:Connect(function(kind, title, name)
		if kind == "milestone" then
			if title == "ORE DISCOVERED" then
				discovered = name
			end
		end
	end)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.CitrineCove:WaitForChild("MineBlocks") }
	local head = p.Character.Head
	local config = require(rep.Shared.GameConfig)
	local pattern = require(rep.Shared.BlockPattern)
	local ores = require(rep.Shared.Ores)
	if r:GetAttribute("CheckSwing") then
		local camera = workspace.CurrentCamera
		local input = game:GetService("UserInputService"):CreateVirtualInput()
		assert(input, "Studio virtual input unavailable")
		r:FireServer("openPage", "Settings")
		waitFor(function()
			return overlay.Visible and menu.Listings:FindFirstChild("Music volume")
		end, 4, "settings")
		task.wait(0.3)
		local function clickAt(xy)
			input:SendMousePosition(xy)
			task.wait(0.07)
			input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, true)
			task.wait(0.07)
			input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, false)
			task.wait(0.07)
		end
		local function adjust(row, value, key, group)
			local track = menu.Listings[row].Slider.Track
			local xy = track.AbsolutePosition
				+ track.AbsoluteSize * Vector2.new(value / 100, 0.5)
				+ game:GetService("GuiService"):GetGuiInset()
			clickAt(xy)
			waitFor(function()
				return p:GetAttribute(key) == value and math.abs(group.Volume - value / 100) < 0.011
			end, 2, row .. " slider")
		end
		adjust("Music volume", 0, "MusicVolume", song.SoundGroup)
		assert(harbor["Coal break"].SoundGroup.Volume > 0.5, "music muted effects")
		adjust("Sound effects", 23, "SfxVolume", harbor["Coal break"].SoundGroup)
		assert(song.SoundGroup.Volume == 0, "effects changed music")
		adjust("Music volume", 55, "MusicVolume", song.SoundGroup)
		adjust("Sound effects", 80, "SfxVolume", harbor["Coal break"].SoundGroup)
		r:FireServer("closePage")
		waitFor(function()
			return not overlay.Visible
		end, 2, "animated close")
		local hand = p.Character:FindFirstChild("RightHand") or p.Character:FindFirstChild("Right Arm")
		local defaultY = hand.Position.Y
		local function visibleOre(name)
			for _, part in workspace.CitrineCove.MineBlocks:GetChildren() do
				if part.Name ~= name or (part.Position - head.Position).Magnitude > 36 then
					continue
				end
				for _, normal in { Vector3.zAxis, Vector3.yAxis, Vector3.xAxis, -Vector3.xAxis, -Vector3.zAxis } do
					local half = part.Size * 0.5
					local at = config.blockCenter(origin, part.Position + normal * half, normal)
					if pattern.visiblePart(head.Position, at, normal, params) == part then
						return at, normal
					end
				end
			end
		end
		local aim, aimNormal = visibleOre("Coal")
		assert(aim, "expected visible coal in the test field")
		camera.CameraType = Enum.CameraType.Scriptable
		local root = p.Character.HumanoidRootPart
		local eye = root.Position + Vector3.yAxis * math.min(1.3, root.Size.Y * 0.6)
		local face = aim + aimNormal * 2
		local intoWall = CFrame.lookAt(face - aimNormal * 1.5, eye)
		local render = game:GetService("RunService")
		local attempted = false
		render:BindToRenderStep("Test wall camera", Enum.RenderPriority.Camera.Value + 1, function()
			camera.CFrame = intoWall
			attempted = true
		end)
		waitFor(function()
			return attempted and (camera.CFrame.Position - face):Dot(aimNormal) > 0.15
		end, 3, "camera clipped through an exposed face")
		render:UnbindFromRenderStep("Test wall camera")
		camera.CFrame = CFrame.lookAt(head.Position, aim + aimNormal * 2)
		local xy = camera.ViewportSize * 0.5
		input:SendMousePosition(xy)
		local meter = gui.SafeArea.Feedback["Mining progress"]
		local function outlined()
			local marker = workspace.MiningSelection:FindFirstChild("Selected block")
			if not marker or (marker:GetPivot().Position - aim).Magnitude > 0.02 or #marker:GetChildren() ~= 12 then
				return false
			end
			for _, edge in marker:GetChildren() do
				if not edge:IsA("BasePart") or edge.CanQuery or edge.CanCollide then
					return false
				end
			end
			return true
		end
		waitFor(outlined, 4, "depth-tested borders on the selected cell")
		local cursor = p.PlayerGui.MiningAim["Mining cursor"]
		assert(cursor.Visible and not cursor["No entry"].Visible, "mineable cursor")
		assert(game:GetService("StarterPlayer").LoadCharacterAppearance, "account appearance disabled")
		local pick = p.Character["Harbor pick"]
		local palm = hand:FindFirstChild("RightGripAttachment")
		local function gripError()
			local expected = if palm
				then palm.WorldPosition
				else hand.CFrame:PointToWorldSpace(Vector3.new(0, -hand.Size.Y * 0.4, 0))
			return (pick["Grip tape"].Position - expected).Magnitude
		end
		assert(gripError() < 0.035, "idle hand grip")
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, true)
		waitFor(function()
			return meter.Visible and meter.Charge.Size.X.Scale > 0.1 and hand.Position.Y > defaultY + 0.4
		end, 3, "raised pick and progress")
		assert(
			workspace.MiningSelection:FindFirstChild("Fractures")
				and #workspace.MiningSelection.Fractures:GetChildren() >= 1,
			"visible impact cracks"
		)
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, false)
		waitFor(function()
			return not meter.Visible and math.abs(hand.Position.Y - defaultY) < 0.48
		end, 3, "cancelled swing")
		assert(p:GetAttribute("Used") == 0, "early release spent a block")
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, true)
		local peaks, high, maxGap, replicated = 0, false, 0, false
		local deadline = os.clock() + 3
		repeat
			game:GetService("RunService").PostSimulation:Wait()
			maxGap = math.max(maxGap, gripError())
			replicated = replicated or p.Character:GetAttribute("MiningSwing") ~= nil
			local rise = hand.Position.Y - defaultY
			if not high and rise > 0.9 then
				high = true
				peaks += 1
			elseif high and rise < 0.5 then
				high = false
			end
		until p:GetAttribute("Used") >= 1 or os.clock() > deadline
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, false)
		assert(p:GetAttribute("Used") == 1, "completed cut")
		assert(peaks >= 2, "expected repeated swings during the first cut, saw " .. peaks)
		assert(maxGap < 0.035, "grip drift: " .. maxGap)
		assert(replicated, "swing start was not replicated")
		waitFor(function()
			return not p.Character:GetAttribute("MiningSwing")
		end, 3, "replicated swing release")
		local popup
		waitFor(function()
			popup = workspace.Terrain:FindFirstChild("Ore find")
			return popup and popup:FindFirstChild("Ore popup")
		end, 2, "world ore popup")
		assert(
			(popup.WorldPosition - aim).Magnitude < 2.1 and popup["Ore popup"].TextLabel.Text == "+1 Coal",
			"popup location and label"
		)
		waitFor(function()
			return not popup.Parent
		end, 2, "popup fades out")
		local copper, copperNormal = visibleOre("Copper")
		assert(copper, "visible locked copper")
		camera.CFrame = CFrame.lookAt(head.Position, copper + copperNormal * 2)
		waitFor(function()
			return cursor.Visible and cursor["No entry"].Visible
		end, 5, "locked copper cursor")
		local collected = p:GetAttribute("Used")
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, true)
		task.wait(0.85)
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, false)
		assert(
			p:GetAttribute("Used") == collected
				and not meter.Visible
				and not workspace.MiningSelection:FindFirstChild("Fractures"),
			"locked ore started a cut"
		)
		return string.format(
			"depth-tested faces, %d swings in one cut, grip error %.4f studs, early release",
			peaks,
			maxGap
		)
	end
	local gameRay = RaycastParams.new()
	gameRay.FilterDescendantsInstances = { p.Character }
	local normals = { Vector3.yAxis, Vector3.zAxis, Vector3.xAxis, -Vector3.xAxis, -Vector3.zAxis, -Vector3.yAxis }
	local function dig(count)
		-- Two miners deplete the same gallery. Re-aim at an exposed face each cut,
		-- including the sides and the floor that open up behind the original wall.
		local eye = head.Position
		local best, side, material, score = nil, nil, nil, math.huge
		for _, brick in workspace.CitrineCove.MineBlocks:GetChildren() do
			local ore = ores.byName[brick.Name]
			if not ore or ore.hardness > 1 then
				continue
			end
			local half = brick.Size * 0.5
			local near = (eye - brick.Position):Max(-half + Vector3.one * 0.01):Min(half - Vector3.one * 0.01)
			for _, normal in normals do
				local face = brick.Position + near * (Vector3.one - normal:Abs()) + half * normal
				local center = config.blockCenter(origin, face, normal)
				local distance = (eye - center).Magnitude
				local priority = distance - (if not discovered and not ore.host then 35 else 0)
				if
					distance <= config.Reach + 2
					and priority < score
					and pattern.visiblePart(eye, center, normal, gameRay) == brick
				then
					best, side, material, score = center, normal, ore, priority
				end
			end
		end
		if not best then
			return
		end
		n.Swing:FireServer(true, best, side)
		task.wait(ores.cutTime(0.8, material) + 0.05)
		n.Mine:FireServer(best, side, count, 2 ^ count - 1)
		n.Swing:FireServer(false)
	end
	for i = 1, 650 do
		dig(1)
		if p:GetAttribute("Used") == 36 then
			break
		end
		task.wait(0.12)
	end
	assert(p:GetAttribute("Used") == 36, "starter pack incomplete: " .. tostring(p:GetAttribute("Used")))
	waitFor(function()
		return discovered
	end, 4, "first ore discovery")
	local value = p:GetAttribute("BagValue")
	assert(value >= 36, "material valuation")
	local quantity, total = 0, 0
	for _, ore in ores.list do
		local held = p:GetAttribute("Held" .. ore.name)
		if held > 0 then
			assert(
				gui.SafeArea.Haul[ore.name].Visible and gui.SafeArea.Haul[ore.name].Quantity.Text == "×" .. held,
				"live haul row"
			)
		end
		quantity += held
		total += held * ore.value
	end
	assert(quantity == 36 and total == value, "pack quantities and value")
	n.Action:FireServer("Sell")
	task.wait(0.4)
	assert(p:GetAttribute("Used") == 36 and p:GetAttribute("Gold") == 0, "exchange must require a visit")
	visit("Sell", true)
	waitFor(function()
		return gui.SafeArea:FindFirstChild("Sale receipt")
	end, 4, "sale payout")
	waitFor(function()
		return p:GetAttribute("Gold") == value and p:GetAttribute("Used") == 0
	end, 6, "exchange")
	for _, ore in ores.list do
		assert(p:GetAttribute("Held" .. ore.name) == 0)
	end
	n.Action:FireServer("Buy", "Capacity")
	task.wait(0.4)
	assert(p:GetAttribute("Capacity") == 1 and p:GetAttribute("Gold") == value, "workshop must require a visit")
	visit("Gear", true)
	n.Action:FireServer("Buy", "Capacity")
	task.wait(0.28)
	if p:GetAttribute("Capacity") == 1 then
		n.Action:FireServer("Buy", "Capacity")
	end
	waitFor(function()
		return p:GetAttribute("Capacity") == 2 and p:GetAttribute("Gold") == value - 24
	end, 5, "purchase")
	assert(kit["Field pack"].Size.Magnitude > packSize.Magnitude, "pack grew after capacity upgrade")
	r:FireServer("position")
	waitFor(function()
		return (p.Character.Head.Position - origin).Z < 0 and not overlay.Visible
	end, 5, "leave workshop")
	for i = 1, 6 do
		dig(2)
		task.wait(0.12)
	end
	assert(p:GetAttribute("Used") == 0, "multi-block request was accepted")
	for i = 1, 100 do
		if p:GetAttribute("Used") == 2 then
			break
		end
		dig(1)
		task.wait(0.14)
	end
	assert(p:GetAttribute("Used") == 2, "single-block mining after upgrade")
	assert(p:GetAttribute("Found" .. discovered) and p:GetAttribute("Mined") == 38, "ore discovery and lifetime blocks")
	n.Action:FireServer("Job", 1)
	waitFor(function()
		return p:GetAttribute("Jobs") == 1
	end, 5, "first reward")
	local afterJob = p:GetAttribute("Gold")
	assert(afterJob == value - 24 + 25)
	task.wait(0.25)
	n.Action:FireServer("Job", 1)
	task.wait(0.3)
	assert(p:GetAttribute("Gold") == afterJob, "repeat claim")
	visit("Store", true)
	n.Action:FireServer("PreviewPass", "DoubleGold")
	waitFor(function()
		return p:GetAttribute("DoubleGold")
	end, 5, "studio pass preview")
	local double = p:GetAttribute("BagValue") * 2
	visit("Sell", true)
	waitFor(function()
		return p:GetAttribute("Gold") == afterJob + double
	end, 5, "double sale")
	visit("Store", true)
	n.Action:FireServer("PreviewPass", "PrismTrail")
	waitFor(function()
		return p.Character.HumanoidRootPart:FindFirstChild("Prism Ribbon")
	end, 5, "equipped trail")
	r:FireServer("depthSample")
	waitFor(function()
		return gui.SafeArea.Location.Depth.Text == "27 blocks"
	end, 4, "return starting depth")
	n.Action:FireServer("Surface")
	local passage = p.PlayerGui.SurfaceReturn
	waitFor(function()
		return passage.Enabled
	end, 2, "surface fade begins")
	local departed = os.clock()
	local landing = n:GetAttribute("Entrance")
	waitFor(function()
		return (p.Character.HumanoidRootPart.Position - landing).Magnitude < 8
	end, 5, "surface recall")
	waitFor(function()
		return not passage.Enabled
	end, 6, "surface fade completed")
	assert(os.clock() - departed > 0.6 and not song.IsPlaying, "depth travel and test mute")
	return string.format(
		"38 blocks, %d gold sale, larger pack, physical ore index, settings, entrance return (%.1fs)",
		value,
		os.clock() - first
	)
end
local ok, result = pcall(test)
r:FireServer(if ok then "passed" else "failed", tostring(result))
