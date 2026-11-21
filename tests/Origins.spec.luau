-- Studio RunScript check for camera continuity, slow streaming and private scenery.
local source = game.StarterPlayer.StarterPlayerScripts.Client.MineOrigins
local Beats, Film = require(source.Beats), require(source.Film)
local config = require(game.ReplicatedStorage.Shared.GameConfig)
local map = workspace.CitrineCove
local paths = map["Sand path and bridge"]
local portal = paths["Portal paving"]
local gate = portal.Position + Vector3.yAxis * (portal.Size.Y / 2 + 3.5)
local site = map:GetPivot().Position + Vector3.new(0, config.FloorY, (config.HallFront + config.HallBack) / 2)
local landing = paths.Landing.Position + Vector3.yAxis * 4
local initialClock = game.Lighting.ClockTime
local initialMapSize = #map:GetDescendants()

local function check(motion, replay)
	local stage, shelf = Instance.new("Folder"), Instance.new("Folder")
	local camera = Instance.new("Camera")
	camera.Parent, stage.Parent = workspace, camera
	local root = Instance.new("Part")
	root.Anchored = true
	root.Position = if replay then site - Vector3.yAxis * 80 else landing
	local start = root.Position
	local focus = CFrame.new(start + Vector3.yAxis * 2)
	local view = CFrame.lookAt(start + Vector3.new(4, 7, 14), focus.Position)
	local film = Film.new(shelf, stage, camera, site, gate, motion, initialClock, nil, {
		root = root,
		start = start,
		landing = landing,
		view = view,
		focus = focus,
		fov = 67,
	})
	assert(film:draw(0, false) == 1)
	local core = film.strike.meteor:FindFirstChild("Starfall core")
	assert(core and core:IsA("Model"))
	film:draw(Beats.impact - 0.01, false)
	local contact = core:GetPivot().Position
	film:draw(Beats.impact + 0.01, false)
	assert(core:IsDescendantOf(film.strike.crater) and (contact - core:GetPivot().Position).Magnitude < 7)
	local lastY = contact.Y
	for _, t in { Beats.section, 8.39, 9.10, 10.10, 10.84 } do
		film:draw(t, false)
		local y = core:GetPivot().Position.Y
		assert(y < lastY, "core must descend through the layers")
		lastY = y
	end
	assert(film.base.Position.Y - lastY > 175 and film.strike.section.root.Parent == film.strike.root)
	film:draw(Beats.surface, false)
	assert(not core.Parent and not film.history.root:FindFirstChild("Starfall core", true), "closed impact site")
	film:draw(Beats.history - 0.001, false)
	local crater = camera.CFrame
	assert(film:draw(Beats.history, false) == 0)
	assert((crater.Position - camera.CFrame.Position).Magnitude < 0.15, "cut drifted off the crater")
	assert(film.history.root.Parent == stage)
	local sky = film.sky
	local changes, previous = 0, -1
	local sawSun, sawMoon = false, false
	for n = 0, 126 do
		local age = n / 8
		film:draw(Beats.history + age, false)
		local count = #film.history.root:GetChildren()
		if count ~= previous then changes += 1 end
		previous = count
		sawSun = sawSun or sky.sun.Transparency < .1
		sawMoon = sawMoon or sky.face.ImageTransparency < .1
		film:draw(Beats.history + age + .049, false)
		assert(#film.history.root:GetChildren() == count, "construction changed between exposures")
	end
	assert(changes >= 50 and sawSun and (not motion or sawMoon), "hold-and-build montage with orbital light")
	film:draw(Beats.present - 0.001, false)
	local historicalView = camera.CFrame
	film:draw(Beats.present, false)
	assert(film.localPresent and film.history.root.Parent == stage, "missing finished local cove")
	assert((historicalView.Position - camera.CFrame.Position).Magnitude < 0.15, "jump at settlement match")
	film:draw(Beats.present + 0.5, true)
	assert(film.localPresent, "entrance changed halfway through a shot")
	film:draw(31.71, true)
	assert(not film.localPresent and not film.history, "ready entrance missed the next cut")
	for _, t in { 33.4, 35.7, 37.4, 39.3, Beats.pick, Beats.answer, 44.4, Beats.arrival, 47.7 } do
		assert(film:draw(t, true) == 0)
	end
	if replay then
		assert(film:draw(Beats.duration, true) == 1, "distant replay must cover the camera restore")
	else
		for _, t in { Beats.duration - 0.2, Beats.duration } do
			assert(film:draw(t, true) == 0)
			assert(camera.CFrame:FuzzyEq(view, 0.0002), "last frame differs from the playable camera")
			assert(camera.Focus:FuzzyEq(focus, 0.0002) and math.abs(camera.FieldOfView - 67) < 0.0002)
		end
	end
	assert(root.Position == start and #map:GetDescendants() == initialMapSize)
	film:Destroy()
	camera:Destroy()
	shelf:Destroy()
	root:Destroy()
end

check(true, false)
check(false, false)
check(true, true)
game.Lighting.ClockTime = initialClock
print("MINING_ORIGINS_TESTS_PASSED")
