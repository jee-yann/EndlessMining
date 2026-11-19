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
	local loading = p.PlayerGui:WaitForChild("MiningLoading", 6)
	assert(loading and loading.Cover.BackgroundTransparency == 0, "opaque loading screen")
	local cover = loading.Cover
	local sawReveal, prematureReveal = false, false
	local monitor = cover:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
		if cover.BackgroundTransparency > 0 and cover.BackgroundTransparency < 1 then
			sawReveal = true
			if cover["Load panel"]["Loading bar"].Status.Text ~= "Ready to dig" then
				prematureReveal = true
			end
		end
	end)
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
	assert(kit and kit["Miner title"].TextLabel.Text:find("Noob Miner", 1, true), "starter backpack and title")
	local packSize = kit["Field pack"].Size
	local harbor = game.SoundService:WaitForChild("Harbor audio", 8)
	local song = harbor:WaitForChild("Prima Bossa Nova", 5)
	assert(not song.IsPlaying and song.Volume < 0.1, "test music must stay muted")
	waitFor(function()
		return gui:GetAttribute("ControllerReady") and not p.PlayerGui:FindFirstChild("MiningLoading")
	end, 18, "loading screen dismisses")
	monitor:Disconnect()
	assert(sawReveal and not prematureReveal, "loading fades only after readiness")
	local ownerVision
	if p.UserId == 45241447 then
		ownerVision = p.PlayerGui:WaitForChild("OwnerOreVision", 3)
		assert(ownerVision and not ownerVision.ResetOnSpawn, "Pixelii receives ore vision")
	else
		assert(not p.PlayerGui:FindFirstChild("OwnerOreVision"), "ore vision granted to another player")
	end
	local mount = p.Character.HumanoidRootPart:FindFirstChild("Lamp mount")
	assert(
		mount and mount:FindFirstChildOfClass("PointLight") and p.Character:GetAttribute("MiningViewReady"),
		"spawn camera and character light on reveal"
	)
	local gallery = workspace.CitrineCove["Citrine Mine"]:FindFirstChild("Gallery glow")
	assert(gallery and gallery:FindFirstChildOfClass("PointLight"), "gallery lighting on reveal")
	local centerLamp = workspace.CitrineCove["Working gallery"]["Center lantern"]
	local light = centerLamp:FindFirstChildOfClass("SurfaceLight")
	assert(
		light and light.Enabled and light.Face == Enum.NormalId.Bottom and light.Brightness >= 0.94,
		"central work light on reveal"
	)
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
			assert(not seenIds[voice.SoundId .. voice.PlaybackSpeed], "duplicate ore sound")
			seenIds[voice.SoundId .. voice.PlaybackSpeed] = true
			local played, notes = false, 0
			local strike = voice.Played:Connect(function()
				played = true
			end)
			local flourishes = {}
			for i = 1, 5 do
				table.insert(
					flourishes,
					harbor["Discovery note " .. i].Played:Connect(function()
						notes += 1
					end)
				)
			end
			audio.ore({ [ore.name] = 1 })
			waitFor(function()
				return played
					and notes
						== (if ore.name == "Starfall"
							then 5
							elseif ore.name == "Emberglass" then 4
							else math.max(0, ore.hardness - 3))
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
	local roster = gui.SafeArea["Server leaderboard"]
	assert(not game.StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList))
	local me = roster.Miners:WaitForChild(tostring(p.UserId), 3)
	assert(me and me.Level.Text == "1" and me.Gold.Text == "0" and me.Title.Text == "Noob Miner")
	assert(gui.SafeArea.Wallet["Level progress"]["XP track"]["XP fill"])
	assert(gui.SafeArea["Action dock"]:FindFirstChild("Achievements"))
	assert(not menu["Inventory tabs"]:FindFirstChild("Achievements"))
	for _, page in
		{ "Pack", "Settings", "Inventory", "Pets", "Skills", "Achievements", "Gear", "Jobs", "Book", "Store" }
	do
		if counters[page] then
			visit(page, true)
		else
			r:FireServer("openPage", page)
		end
		local listing = ({
			Settings = "Music volume",
			Inventory = "Prismatic Excavator",
			Pets = "Pocket Rock",
			Skills = "Skill map",
			Achievements = "Once Is Luck, Twice Is Skill",
			Gear = "Speed",
			Jobs = "First strike",
			Book = "Stone",
			Pack = "Stone",
			Store = "Double Gold",
		})[page]
		waitFor(function()
			return overlay.Visible and menu.Listings:FindFirstChild(listing)
		end, 5, "open " .. page)
		if page == "Achievements" then
			assert(not menu["Inventory tabs"].Visible)
			assert(menu.Listings:FindFirstChild("Practicing My Scales"))
		end
		if page == "Pets" then
			n.Action:FireServer("Pet", "Rock")
			waitFor(function()
				return workspace["Rock companions"]:FindFirstChild("Pocket rock")
			end, 4, "equipped follower")
			n.Action:FireServer("PetName", "Flint")
			waitFor(function()
				return p:GetAttribute("PetName") == "Flint"
			end, 3, "renamed rock")
			n.Action:FireServer("Pet", "")
		elseif page == "Inventory" then
			n.Action:FireServer("Title", 6)
			task.wait(0.2)
			assert(p:GetAttribute("EquippedTitle") == 1)
		end
		if page == "Book" then
			assert(menu.Listings["Iron Shelf"].Depth.Text == "27–89 blocks", "index depth in blocks")
			assert(menu.Listings:FindFirstChild("Rock hardness"), "index depth and Power guide")
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
			return location.Coordinates.Text == "X -1    Y 0    Z -4"
				and location.Depth.Text == "0 blocks"
				and location.Region.Text == "SUNSTONE HOLLOW"
				and p.leaderstats.Depth.Value == 0
		end, 8, "block coordinates and region on the hut floor")
		assert(location.Coordinates.TextFits and location.Depth.TextFits, "location readout clipped")
	end
	if r:GetAttribute("CheckSwing") then
		assert(p.CameraMaxZoomDistance <= 28)
		r:FireServer("gateApproach")
		local origin = n:GetAttribute("Origin")
		waitFor(function()
			return (p.Character.HumanoidRootPart.Position - origin - Vector3.new(0, 3, 2)).Magnitude < 5
		end, 5, "approach")
		p.Character.Humanoid:MoveTo(origin + Vector3.new(0, 0, -12))
		waitFor(function()
			local at = p.Character.HumanoidRootPart.Position - origin
			return at.Z < -8 and at.Y > 0 and at.Y < 5
		end, 5, "walk through the narrow gate")
	end
	r:FireServer("position")
	local origin = n:GetAttribute("Origin")
	waitFor(function()
		local pos = p.Character.Head.Position - origin
		return pos.Z < 0 and math.abs(pos.Y - 4) < 3
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
		-- Inspect six surfaces, including an isolated block that can be viewed from every side.
		local painter = require(p.PlayerScripts.Client.Effects).new()
		local cube = Instance.new("Part")
		cube.Anchored, cube.Size, cube.Position, cube.Parent =
			true, Vector3.one * 5, head.Position + Vector3.yAxis * 48, workspace
		cube:SetAttribute("OpenFaces", 63)
		painter:damage(cube, 0.15)
		local overlays = cube.Fractures:GetChildren()
		assert(#overlays == 6)
		for _, surface in overlays do
			local growing = 0
			for _, line in surface:GetChildren() do
				if line.Visible and line.Name == "Vein" then
					growing += 1
				end
			end
			assert(
				growing == 3 and not surface.AlwaysOnTop and surface.ZOffset == 0 and surface.Adornee == cube,
				"early cracks did not radiate together"
			)
		end
		painter:damage(cube, 1)
		for _, surface in overlays do
			local visible = 0
			for _, line in surface:GetChildren() do
				if line.Visible then
					visible += 1
				end
			end
			assert(visible >= 48)
		end
		cube:Destroy()
		for _, surface in overlays do
			assert(not surface.Parent, "orphan crack")
		end
		painter:clearDamage()
		painter.preview:Destroy()
		painter.sparkOrigin:Destroy()
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
		local visionBadge
		local function pressX()
			input:SendKey(true, Enum.KeyCode.X)
			input:SendKey(false, Enum.KeyCode.X)
		end
		if ownerVision then
			visionBadge = gui.SafeArea.Location:WaitForChild("Ore vision status", 3)
			assert(visionBadge and not visionBadge.Visible, "ore vision starts off")
			pressX()
			waitFor(function()
				return visionBadge.Visible
			end, 2, "X enables ore vision")
			assert(not ownerVision:FindFirstChildWhichIsA("BoxHandleAdornment"), "fresh dirt floor marked as ore")
		end
		-- Drill the two starter shafts through the real cut protocol before aiming at ore.
		for _, x in { -2.5, 2.5 } do
			for _, y in { -2.5, -7.5 } do
				local at = origin + Vector3.new(x, y, -12.5)
				local used = p:GetAttribute("Used")
				n.Swing:FireServer(true, at, Vector3.yAxis)
				task.wait(ores.cutTime(0.8, ores.byName.Dirt) + 0.18)
				n.Mine:FireServer(at, Vector3.yAxis, 1, 1)
				waitFor(function()
					return p:GetAttribute("Used") == used + 1
				end, 3, "floor dirt awarded")
			end
		end
		local startingHaul = p:GetAttribute("Used")
		local aim, aimNormal = visibleOre("Coal")
		assert(aim, "expected visible coal in the test field")
		local coalMarker
		if ownerVision then
			waitFor(function()
				for _, box in ownerVision:GetChildren() do
					if
						box:IsA("BoxHandleAdornment")
						and box.Adornee
						and box.Adornee.Position == aim
						and box.AlwaysOnTop
					then
						coalMarker = box
						return true
					end
				end
				return false
			end, 3, "newly exposed coal marked through walls")
		end
		camera.CameraType = Enum.CameraType.Scriptable
		local root = p.Character.HumanoidRootPart
		local eye = root.Position + Vector3.yAxis * math.min(1.3, root.Size.Y * 0.6)
		local face = aim + aimNormal * 2.5
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
		camera.CFrame = CFrame.lookAt(head.Position, aim + aimNormal * 2.5)
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
		assert(
			not p.PlayerGui:FindFirstChild("Inside rock") and p.Character:FindFirstChild("Head clearance", true),
			"head collision guard"
		)
		local pick = p.Character["Harbor pick"]
		local palm = hand:FindFirstChild("RightGripAttachment")
		local function gripError()
			local expected = if palm
				then palm.WorldPosition
				else hand.CFrame:PointToWorldSpace(Vector3.new(0, -hand.Size.Y * 0.4, 0))
			return (pick["Grip tape"].Position - expected).Magnitude
		end
		-- Measure the arm's arc relative to the torso across avatar sizes and idle poses.
		local arm = p.Character:FindFirstChild("RightUpperArm") or hand
		local torso = p.Character:FindFirstChild("UpperTorso") or p.Character.Torso
		local function armPose()
			return torso.CFrame:ToObjectSpace(arm.CFrame).Rotation
		end
		local idlePose = armPose()
		local function swingAngle()
			local _, angle = idlePose:ToObjectSpace(armPose()):ToAxisAngle()
			return math.deg(angle)
		end
		assert(gripError() < 0.035, "idle hand grip")
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, true)
		waitFor(function()
			return meter.Visible and meter.Charge.Size.X.Scale > 0.1 and swingAngle() > 60
		end, 3, "raised pick and progress")
		assert(workspace.CitrineCove.MineBlocks:FindFirstChild("Fractures", true) ~= nil, "visible impact cracks")
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, false)
		waitFor(function()
			return not meter.Visible and swingAngle() < 20
		end, 3, "cancelled swing")
		assert(p:GetAttribute("Used") == startingHaul, "early release spent a block")
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, true)
		local peaks, high, maxGap, replicated = 0, false, 0, false
		local deadline = os.clock() + 3
		repeat
			game:GetService("RunService").PostSimulation:Wait()
			maxGap = math.max(maxGap, gripError())
			replicated = replicated or p.Character:GetAttribute("MiningSwing") ~= nil
			local angle = swingAngle()
			if not high and angle > 85 then
				high = true
				peaks += 1
			elseif high and angle < 55 then
				high = false
			end
		until p:GetAttribute("Used") > startingHaul or os.clock() > deadline
		input:SendMouseButton(xy, Enum.UserInputType.MouseButton1, false)
		assert(p:GetAttribute("Used") == startingHaul + 1, "completed cut")
		if ownerVision then
			waitFor(function()
				return not coalMarker.Parent
			end, 2, "mined ore marker clears")
			pressX()
			waitFor(function()
				return not visionBadge.Visible and not ownerVision:FindFirstChildWhichIsA("BoxHandleAdornment")
			end, 2, "X removes remaining ore markers")
			pressX()
			waitFor(function()
				return ownerVision:FindFirstChild("Copper") ~= nil
			end, 2, "X marks already loaded ore")
			pressX()
		end
		assert(not workspace.CitrineCove.MineBlocks:FindFirstChild("Fractures", true), "completed cracks lingered")
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
			(popup.WorldPosition - aim).Magnitude < 2.6 and popup["Ore popup"].TextLabel.Text == "+1 Coal",
			"popup location and label"
		)
		waitFor(function()
			return not popup.Parent
		end, 2, "popup fades out")
		local copper, copperNormal = visibleOre("Copper")
		assert(copper, "visible locked copper")
		camera.CFrame = CFrame.lookAt(head.Position, copper + copperNormal * 2.5)
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
				and not workspace.CitrineCove.MineBlocks:FindFirstChild("Fractures", true),
			"locked ore started a cut"
		)
		local at = aim - Vector3.zAxis * config.Cell
		r:FireServer("walk")
		waitFor(function()
			return not root.Anchored
		end, 3, "walking enabled")
		p.Character.Humanoid:MoveTo(aim)
		waitFor(function()
			return (root.Position - aim).Magnitude < 1.8
		end, 6, "enter the shaft mined from above")
		local hit = workspace:Raycast(head.Position, at - head.Position, params)
		assert(hit and hit.Instance.Position == at and hit.Instance.Name == "Stone", "underground workface")
		local target = hit.Instance
		n.Swing:FireServer(true, at, Vector3.zAxis)
		task.wait(ores.cutTime(0.8, ores.byName[target.Name]) + 0.15)
		n.Mine:FireServer(at, Vector3.zAxis, 1, 1)
		waitFor(function()
			return not target.Parent
		end, 3, "single block doorway")
		p.Character.Humanoid:MoveTo(at)
		waitFor(function()
			return (root.Position - at).Magnitude < 1.8
		end, 5, "avatar fits one five-stud cut")
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
	local quantity, total, earnedXP = 0, 0, 0
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
		earnedXP += held * ore.xp
	end
	assert(quantity == 36 and total == value, "pack quantities and value")
	assert(p:GetAttribute("MiningXP") == earnedXP, "XP from each material in the first haul")
	local level = require(rep.Shared.Expeditions).level(earnedXP)
	assert(p:GetAttribute("Level") == level and gui.SafeArea.Wallet.Equipment.Power.Visible, "level and equipment HUD")
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
	n.Action:FireServer("Job", 2)
	n.Action:FireServer("Job", 1)
	waitFor(function()
		return p:GetAttribute("Jobs") == 2 and p:GetAttribute("ClaimedJobs") == 3
	end, 5, "two eligible jobs claimed back to back in reverse order")
	local afterJob = p:GetAttribute("Gold")
	assert(afterJob == value - 24 + 80 + 25)
	task.wait(0.25)
	n.Action:FireServer("Job", 2)
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
	r:FireServer("minedShaft")
	waitFor(function()
		local blocks = p:GetAttribute("TestShaftDepth")
		return blocks
			and blocks >= 1
			and gui.SafeArea.Location.Depth.Text == (if blocks == 1 then "1 block" else blocks .. " blocks")
	end, 4, "return starts inside the mined shaft")
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
