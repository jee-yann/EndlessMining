local Arrival = require(script.Parent.Arrival)
local History = require(script.Parent.History)
local Beats = require(script.Parent.Beats)
local Lighting = game:GetService("Lighting")
local P, Strike, Survey, Crew =
	require(script.Parent.Props),
	require(script.Parent.Strike),
	require(script.Parent.Survey),
	require(script.Parent.Crew)
local V, CF, A, ease = Vector3.new, CFrame.new, CFrame.Angles, P.ease
local Film = {}
Film.__index = Film
Film.duration = Beats.duration

local eras = {
	{ 0.65, 3.40, "8 MILLION YEARS AGO" },
	{ 14.70, 18.80, "OVER MILLIONS OF YEARS" },
	{ 19.65, 22.05, "THE FIRST SURVEY" },
	{ 25.45, 27.50, "CITRINE COVE  /  TODAY" },
}
local function envelope(t, a, b, edge)
	return ease(t, a, a + edge) * (1 - ease(t, b - edge, b))
end
function Film.caption(t)
	for _, cue in Beats.dialogue do
		if t >= cue[1] and t < cue[2] then
			return cue[3], cue[4], envelope(t, cue[1], cue[2], 0.15)
		end
	end
	return "", "", 0
end
function Film.era(t)
	for _, cue in eras do
		if t >= cue[1] and t < cue[2] then
			return cue[3], envelope(t, cue[1], cue[2], 0.24)
		end
	end
	return "", 0
end

function Film.card(t)
	return "IT KNOCKED BACK", envelope(t, 41.65, 44.35, 0.46)
end

function Film.new(shelf, stage, camera, site, gate, motion, clock, character, handoff)
	local base = CF(site + V(0, 3200, 0))
	local ancientStorage = Instance.new("Folder")
	ancientStorage.Parent = shelf
	local historyBase = base + (gate - V(0, 3.5, 0) - site)
	local strike = Strike.new(ancientStorage)
	strike.root:PivotTo(base)
	strike.root.Parent = stage
	return setmetatable({
		stage = stage,
		shelf = shelf,
		camera = camera,
		base = base,
		gateBase = CF(gate - V(0, 3.5, 0)),
		motion = motion,
		clock = clock,
		character = character,
		historyBase = historyBase,
		history = History.new(stage, historyBase),
		handoff = handoff,
		strike = strike,
	}, Film)
end

function Film:frame(base, eye, look, fov, roll)
	local cam = self.camera
	cam.CFrame = base * CFrame.lookAt(eye, look) * A(0, 0, if self.motion then roll or 0 else 0)
	cam.Focus = base * CF(look)
	local viewport = cam.ViewportSize
	local aspect = viewport.X / math.max(1, viewport.Y)
	cam.FieldOfView =
		math.min(97, math.deg(2 * math.atan(math.tan(math.rad(fov / 2)) * math.max(1, 1.28 / math.max(0.35, aspect)))))
end

function Film:entry(t)
	local at = Strike.position(t)
	local base = self.base
	if t < 5.55 then
		-- Hold the rock on the same side of the frame as the camera overtakes it.
		local u = if self.motion then ease(t, 0.45, 5.55) else 0.38
		local eye = at + V(16 - 27 * u, 8 - 4 * u, 44 - 25 * u)
		self:frame(base, eye, at + V(2.0 - 4 * u, 1.0, 0), 49 + 2 * u, 0.085 - 0.17 * u)
	elseif t < 7.92 then
		-- Cross behind it. The nose, wake and coastline now sit on one flight line.
		local dir = (Strike.position(t + 0.04) - at).Unit
		local u = if self.motion then ease(t, 5.55, 7.92) else 0.5
		self:frame(base, at - dir * (18 + 9 * u) + V(8 + 3 * u, 4, 10), at + dir * (6 + 8 * u), 64 + 5 * u, -0.045)
	elseif t < 10.18 then
		local flight = math.clamp((Strike.impactTime - t) / 1.98, 0, 1)
		local age = math.max(0, t - Strike.impactTime)
		local waveAge = math.max(0, age - 0.13)
		local shock = if self.motion then math.exp(-3.8 * waveAge) * math.sin(waveAge * 29) else 0
		local recoil = if self.motion then ease(age, 0, 0.55) * (1 - 0.38 * ease(age, 0.6, 2)) else 0
		local eye = V(19 + 3 * recoil, 6.8 + 1.8 * recoil + 0.55 * shock, 44 + 4 * recoil)
		local target = at:Lerp(V(0, 4.0 + 6.6 * ease(age, 0, 0.76), 0), 1 - 0.60 * flight)
		self:frame(base, eye, target, 55 + 3 * recoil, shock * 0.021)
	elseif t < 12.10 then
		local age = t - Strike.impactTime
		local u = if self.motion then ease(age, 0.18, 2.7) else 0.46
		local shock = if self.motion then math.exp(-3.2 * age) * math.sin(age * 34) else 0
		-- Cut inside the pressure wave on the flash, then rise with the ejecta.
		local eye = V(-10 - 3 * u, 4.5 + 7 * u + shock * 0.65, 24 + 9 * u)
		self:frame(
			base,
			eye,
			V(0.7, 4.8 + 3.5 * ease(age, 0.18, 0.95) - 6.2 * ease(age, 1.4, 2.18), 0.8),
			57,
			shock * 0.031
		)
	else
		-- Pull out along the same ray as the first view of the crater lake.
		local u = ease(t, 12.10, 13.80)
		local eye = V(1.6, 3.9, 6.5):Lerp(V(4.8, 6.455, 10.20), u)
		self:frame(base, eye, V(0.1, -0.48, 0):Lerp(V(0, -0.045, 0), u), 41 + 3 * u)
	end
end

function Film:mountPresent(live)
	local frame = if live then self.gateBase else self.historyBase
	if not self.crew then
		self.crew = Crew.new(self.shelf, self.character)
		self.survey = Survey.new(self.shelf)
	end
	if self.modernBase ~= frame then
		if live then
			if self.history then
				self.history:Destroy()
				self.history = nil
			end
		else
			self.history:draw(19, self.motion, self.clock)
		end
		self.crew.root:PivotTo(frame)
		self.survey.root:PivotTo(frame)
		self.crew.root.Parent, self.survey.root.Parent = self.stage, self.stage
		self.modernBase, self.localPresent = frame, not live
	end
end

local presentCuts = { 27.36, 29.04, 30.83, 32.96, 34.91, 37.56, 40.02 }

function Film:present(t, shot)
	local base = self.modernBase
	local function travel(a, b)
		return if self.motion then ease(t, a, b) else 0.55
	end
	local function localAt(point)
		return base:PointToObjectSpace(point)
	end
	local rock = localAt(self.crew.coreAim)
	if shot == 1 then
		local u = if self.motion then ease(t, Beats.present, presentCuts[1]) else 0
		self:frame(base, V(-32 + 16 * u, 29 - 9 * u, 66 - 13 * u), V(5, 8, 1), 57, -0.035 + 0.026 * u)
	elseif shot == 2 then
		local u = travel(27.36, 29.04)
		self:frame(
			base,
			Survey.pad + V(-3.9 + 1.15 * u, 3.0 - 0.55 * u, 7.3 - 1.15 * u),
			Survey.pad + V(-0.82, 2.12, 0),
			48
		)
	elseif shot == 3 then
		-- Skim the bridge after the outgoing signal, straight through the market toward the arch.
		local u = travel(29.04, 30.83)
		self:frame(
			base,
			V(0.4 - 1.6 * u, 1.04 + 1.4 * u, 24.8 - 13 * u),
			V(-2.7, 1.1 + 1.6 * u, 7.5 - 3 * u),
			61 - 0.8 * u,
			-0.035 * (1 - u)
		)
	elseif shot == 4 then
		local at = localAt(self.crew.receiverAim)
		local u = travel(30.83, 32.96)
		self:frame(base, at + V(1.50 - 0.4 * u, 0.74, 3.4 - 0.4 * u), at, 37)
	elseif shot == 5 then
		local u = travel(32.96, 34.91)
		self:frame(base, V(-2.8 + 1.1 * u, 4.15, 13.6 - 0.7 * u), V(-0.85, 3.35, 5.5), 48)
	elseif shot == 6 then
		local u = travel(34.91, 37.56)
		-- Leave room for the pick's overhead arc and keep its point and the stone in frame at contact.
		self:frame(
			base,
			V(-2.90 - 0.38 * u, 3.32 + 0.28 * u, 1.40 + 0.22 * u),
			V(1.22, 3.22 - 0.82 * ease(t, 36.99, Beats.pick), 5.58),
			55
		)
	elseif shot == 7 then
		local u = travel(37.56, 40.02)
		self:frame(base, rock + V(-1.12 + 0.36 * u, 1.02 - 0.25 * u, -3.44 + 0.52 * u), rock + V(0, 0.04, 0), 41)
	else
		-- Follow the answering vibration from the split stone into the doorway.
		local u = travel(40.02, Beats.arrival)
		self:frame(base, V(-2.1 + 0.65 * u, 1.65 - 0.30 * u, 9 + u), V(0.1, 1.15, 3 - 5 * u), 54)
	end
end

-- Dolly back along the actual route from the mine sill to the landing compass.
-- Both the last rendered transform and the focus match the camera the player will own.
function Film:arrive(t)
	local handoff = self.handoff
	local gate = self.gateBase
	local u = ease(t, Beats.arrival, Beats.duration - 0.22)
	local landing = if handoff then handoff.landing else gate:PointToWorldSpace(V(0, 4, 87.75))
	if not self.arrival then
		self.arrival = Arrival.new(self.stage, gate, landing - V(0, 3.5, 0))
	end
	self.arrival:draw(t)

	local root = handoff and handoff.root
	local nearSpawn = root ~= nil and (root.Position - landing).Magnitude < 38
	local anchor = if nearSpawn then root.Position else landing
	local goal = if nearSpawn
		then handoff.view + (anchor - handoff.start)
		else CFrame.lookAt(anchor + V(0, 5, 13), anchor + V(0, 2, -5))
	local focus = if nearSpawn then handoff.focus + (anchor - handoff.start) else CF(anchor + V(0, 2, 0))
	local firstEye = gate:PointToWorldSpace(V(-1.45, 1.35, 10))
	local firstLook = gate:PointToWorldSpace(V(0.1, 1.15, -2))
	local arc = math.sin(u * math.pi)
	local eye = firstEye:Lerp(goal.Position, u) + V(-4.3, 8.6, 0) * arc
	local look = firstLook:Lerp(focus.Position, u) + V(-1.2, 1.4, -5) * arc
	local endView = ease(t, 43.1, Beats.duration - 0.22)
	local rotation = CFrame.lookAt(eye, look).Rotation:Lerp(goal.Rotation, endView)
	if not self.motion or self.localPresent then
		-- A stationary landing shot lets the wave arrive without a long tracking move.
		eye, rotation, look = goal.Position, goal.Rotation, focus.Position
	end
	self.camera.CFrame = rotation + eye
	self.camera.Focus = CF(look):Lerp(focus, endView)
	local fov = if handoff then handoff.fov else 70
	self.camera.FieldOfView = 54 + (fov - 54) * (if self.motion and not self.localPresent then u else 1)
	-- A replay started underground returns to its original view during a short fade.
	return if nearSpawn or not handoff then 0 else ease(t, 44.24, 44.69)
end

function Film:draw(t, liveReady)
	if t < Beats.history then
		local flight = t + (Beats.flightImpact - Beats.impact) * ease(t, 0, Beats.impact)
		Lighting.ClockTime = 6.10 + 1.35 * ease(flight, 0.7, Strike.impactTime)
		-- Spread the island across the flight even when a phone renders fewer frames.
		local frameTime = t - (self.previousFlightFrame or t)
		self.history:prepare(math.clamp(math.ceil(260 * frameTime), 8, 32))
		self.previousFlightFrame = t
		self.strike:draw(flight, self.base, self.motion)
		self:entry(flight)
		return 1 - ease(t, 0.08, 0.44)
	end
	if self.strike then
		self.strike.root:Destroy()
		self.strike.shelf:Destroy()
		self.strike = nil
	end
	if t < Beats.present then
		local age = (t - Beats.history) * 19 / (Beats.present - Beats.history)
		self:frame(self.historyBase, self.history:draw(age, self.motion, self.clock))
		return 0
	end
	Lighting.ClockTime = self.clock
	local shot = #presentCuts + 1
	for i, cut in presentCuts do
		if t < cut then
			shot = i
			break
		end
	end
	if self.modernShot ~= shot and t < Beats.arrival then
		self:mountPresent(liveReady or (self.modernBase ~= nil and not self.localPresent))
		self.modernShot = shot
	end
	if self.crew and t < 42.25 then
		self.crew:draw(t, self.modernBase, self.motion)
		self.survey:draw(t, self.modernBase)
	elseif self.crew then
		self.crew.root:Destroy()
		self.survey.root:Destroy()
		if self.history then
			self.history:Destroy()
			self.history = nil
		end
		self.crew, self.survey = nil, nil
	end
	if t >= Beats.arrival then
		return self:arrive(t)
	end
	self:present(t, shot)
	return 0
end

function Film:Destroy()
	if self.arrival then
		self.arrival:Destroy()
	end
	if self.history then
		self.history:Destroy()
		self.history = nil
	end
end

return Film
