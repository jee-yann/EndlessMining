-- Studio RunScript check for camera continuity, slow streaming and private scenery.
local source = game.StarterPlayer.StarterPlayerScripts.Client.MineOrigins
local Beats, Film = require(source.Beats), require(source.Film)
local Exposure = require(source.Exposure)
local config = require(game.ReplicatedStorage.Shared.GameConfig)
local map = workspace.CitrineCove
local paths = map["Sand path and bridge"]
local portal = paths["Portal paving"]
local gate = portal.Position + Vector3.yAxis * (portal.Size.Y / 2 + 3.5)
local site = map:GetPivot().Position + Vector3.new(0, config.FloorY, (config.HallFront + config.HallBack) / 2)
local landing = paths.Landing.Position + Vector3.yAxis * 4
local initialClock = game.Lighting.ClockTime
local air = game.Lighting:FindFirstChildOfClass("Atmosphere")
local originalAir = air and { air.Color, air.Decay, air.Haze }
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
	local screen = Instance.new("ScreenGui")
	local exposure = Exposure.new(screen, camera)
	film:draw(0.86, false)
	exposure:draw(0.86, film)
	assert(exposure.slip.Visible == motion and not exposure.plate.Visible)
	local core = film.strike.meteor:FindFirstChild("Starfall core")
	assert(core and core:IsA("Model"))
	film:draw(5.62, false)
	local gritView = camera.CFrame
	film:draw(6.10, false)
	assert(gritView:FuzzyEq(camera.CFrame, 0.0001), "the lens must hold while the stones lift")
	film:draw(6.22, false)
	assert(gritView:FuzzyEq(camera.CFrame, 0.0001) ~= motion, "the tighter insert follows the motion preference")
	film:draw(Beats.impact - 0.01, false)
	film:draw(Beats.impact + 0.01, false)
	exposure:draw(Beats.impact + 0.01, film)
	assert(exposure.plate.Visible == motion and not exposure.slip.Visible)
	local contactDrawing = exposure.lens.CFrame
	exposure:draw(Beats.impact + 0.07, film)
	assert(exposure.plate.Visible == motion and (exposure.lens.CFrame ~= contactDrawing) == motion,
		"contact and release have separate drawings")
	exposure:draw(Beats.impact + 0.18, film)
	assert(not exposure.plate.Visible, "contact drawing exceeded its exposure")
	assert(core:IsDescendantOf(film.strike.shelf) and film.strike.crown.Parent == film.strike.root)
	film:draw(6.98, false)
	local fire = film.strike.paint.planes[1]
	local clod = film.strike.ejecta[4].rock
	local heldFire, firstClod = fire.CFrame, clod:GetPivot().Position
	film:draw(7.13, false)
	assert(heldFire:FuzzyEq(fire.CFrame, 0.0001), "the crown holds its drawn silhouette")
	assert((clod:GetPivot().Position - firstClod).Magnitude > 0.25, "ejecta travel during the held exposure")
	film:draw(7.24, false)
	assert(not heldFire:FuzzyEq(fire.CFrame, 0.0001), "the side vent breaks the hold")
	local fault = film.strike.fissure
	film:draw(9.60, false)
	assert(fault.lamp.Brightness > 0.1 and not core:IsDescendantOf(stage), "light escapes the buried fault")
	film:draw(11.75, false)
	for _, path in fault.lightPaths do assert(path.violet.Transparency > 0.98, "fissure must seal") end
	assert((film.historyBase.Position - film.base.Position).Magnitude > 7000, "separate the two surface sets")
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
		if n == 46 then
			local boat = film.history.work.hull
			local firstPose = boat:GetPivot()
			film:draw(Beats.history + age + 0.02, false)
			assert(not boat:GetPivot():FuzzyEq(firstPose, 0.001), "the cutter moves between construction cues")
		end
	end
	assert(changes >= 45 and sawSun and (not motion or sawMoon), "continuous island construction and orbital light")
	film:draw(Beats.present - 0.001, false)
	local historicalView = camera.CFrame
	film:draw(Beats.present, false)
	assert(film.localPresent and film.history.root.Parent == stage, "missing finished local cove")
	assert((historicalView.Position - camera.CFrame.Position).Magnitude < 0.15, "jump at settlement match")
	film:draw(Beats.present + 0.5, true)
	assert(film.localPresent, "entrance changed halfway through a shot")
	film:draw(31.71, true)
	assert(not film.localPresent and not film.history, "ready entrance missed the next cut")
	for _, t in { 33.4, 35.7, 37.4, 39.3 } do
		assert(film:draw(t, true) == 0)
	end
	film:draw(40.90, true)
	local raised = film.crew.pickTip
	film:draw(41.30, true)
	assert((film.crew.pickTip - raised).Magnitude < 0.001, "pick holds at the top of the swing")
	film:draw(Beats.pick, true)
	local contact = film.modernBase * Vector3.new(0.17, 1.81, 4.79)
	assert((film.crew.pickTip - contact).Magnitude < 0.001, "pick hits the exposed stone on the strike")
	for _, t in { Beats.answer, 44.4, Beats.arrival, 47.7 } do
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
	if originalAir then
		assert(air.Color == originalAir[1] and air.Decay == originalAir[2] and air.Haze == originalAir[3])
	end
	film:Destroy()
	exposure:Destroy()
	assert(not camera:FindFirstChild("Starfall exposure"))
	screen:Destroy()
	camera:Destroy()
	shelf:Destroy()
	root:Destroy()
end

check(true, false)
check(false, false)
check(true, true)
game.Lighting.ClockTime = initialClock
print("MINING_ORIGINS_TESTS_PASSED")
