local Lighting = game:GetService("Lighting")
local P, Strike, Survey, Crew =
	require(script.Parent.Props),
	require(script.Parent.Strike),
	require(script.Parent.Survey),
	require(script.Parent.Crew)
local V, CF, A, ease = Vector3.new, CFrame.new, CFrame.Angles, P.ease
local Film = {}
Film.__index = Film
Film.duration = 36.5

local dialogue = {
	{ 1.05, 4.2, "ABOVE CITRINE COVE", "" },
	{ 17.65, 20.9, "CITRINE COVE  /  TODAY", "“Three knocks. Quick tunnel check.”" },
	{ 23.57, 26.12, "SURVEY LEAD", "“Three back? Nobody’s down there.”" },
	{ 26.29, 28.48, "YOU", "“My turn. Just one.”" },
	{ 30.20, 32.10, "SURVEY LEAD", "“Starfall! It copied you.”" },
	{ 32.42, 35.00, "YOU", "“That last one came from deeper down. Come on!”" },
}
local function envelope(t, a, b, edge)
	return ease(t, a, a + edge) * (1 - ease(t, b - edge, b))
end
function Film.caption(t)
	for _, cue in dialogue do
		if t >= cue[1] and t < cue[2] then
			return cue[3], cue[4], envelope(t, cue[1], cue[2], 0.15)
		end
	end
	return "", "", 0
end
function Film.card(t)
	if t >= 15.62 and t < 17.55 then
		return "8 MILLION YEARS LATER", envelope(t, 15.62, 17.55, 0.22)
	elseif t >= 35.30 then
		return "IT KNOCKED BACK", envelope(t, 35.30, Film.duration, 0.16)
	end
	return "", 0
end

function Film.new(shelf, stage, camera, site, gate, motion, clock, character)
	local base = CF(site + V(0, 3200, 0))
	local ancientStorage = Instance.new("Folder")
	ancientStorage.Parent = shelf
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
	elseif t < 10.08 then
		local flight = math.clamp((Strike.impactTime - t) / 1.98, 0, 1)
		local age = math.max(0, t - Strike.impactTime)
		local shock = if self.motion then math.exp(-3.8 * age) * math.sin(age * 29) else 0
		local recoil = if self.motion then ease(age, 0, 0.55) * (1 - 0.38 * ease(age, 0.6, 2)) else 0
		local eye = V(19 + 3 * recoil, 6.8 + 1.8 * recoil + 0.55 * shock, 44 + 4 * recoil)
		local target = at:Lerp(V(0, 4.0 + 6.6 * ease(age, 0, 0.76), 0), 1 - 0.60 * flight)
		self:frame(base, eye, target, 55 + 3 * recoil, shock * 0.021)
	elseif t < 13.12 then
		local age = t - Strike.impactTime
		local u = if self.motion then ease(age, 0.18, 2.7) else 0.46
		local shock = if self.motion then math.exp(-3.2 * age) * math.sin(age * 34) else 0
		-- Cut inside the pressure wave on the flash, then rise with the ejecta.
		local eye = V(-10 - 3 * u, 4.5 + 7 * u + shock * 0.65, 24 + 9 * u)
		self:frame(base, eye, V(0, 4.6 + 5.9 * ease(age, 0.18, 0.98) - 6 * ease(age, 1.8, 3.1), 0), 57, shock * 0.031)
	else
		local u = if self.motion then ease(t, 13.12, 15.50) else 0.54
		self:frame(base, V(3, 6.8, 13):Lerp(V(0.9, 3.7, 6.2), u), V(0.15, -0.55, 0), 42)
	end
end

function Film:mountPresent(live)
	local frame = if live then self.gateBase else self.base
	if not self.crew then
		self.crew = Crew.new(self.shelf, self.character)
		self.survey = Survey.new(self.shelf)
	end
	if self.modernBase ~= frame then
		self.crew.root:PivotTo(frame)
		self.survey.root:PivotTo(frame)
		self.crew.root.Parent, self.survey.root.Parent = self.stage, self.stage
		if not live then
			self.standIn = Survey.standIn(self.stage, frame)
		elseif self.standIn then
			self.standIn:Destroy()
			self.standIn = nil
		end
		self.modernBase = frame
	end
end

local presentCuts = { 18.78, 20.19, 22.04, 24.36, 26.16, 28.78, 31.52, 33.03 }

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
		local u = travel(17.43, 18.78)
		if self.standIn then
			self:frame(base, V(-12 + 3 * u, 9, 34), V(0, 3, 5), 54)
		else
			self:frame(base, V(-32 + 16 * u, 29 - 9 * u, 66 - 13 * u), V(5, 8, 1), 57, -0.035 + 0.026 * u)
		end
	elseif shot == 2 then
		local u = travel(18.78, 20.19)
		self:frame(base, Survey.pad + V(-3.45 + 0.6 * u, 2.05, 5 - 0.5 * u), Survey.pad + V(0, 1.2, 0), 42)
	elseif shot == 3 then
		-- Skim the bridge after the outgoing signal, straight through the market toward the arch.
		local u = travel(20.19, 22.04)
		self:frame(
			base,
			V(0.4 - 1.6 * u, 1.04 + 1.4 * u, 24.8 - 13 * u),
			V(-2.7, 1.1 + 1.6 * u, 7.5 - 3 * u),
			61 - 0.8 * u,
			-0.035 * (1 - u)
		)
	elseif shot == 4 then
		local at = localAt(self.crew.receiverAim)
		local u = travel(22.04, 24.36)
		self:frame(base, at + V(1.50 - 0.4 * u, 0.74, 3.4 - 0.4 * u), at, 37)
	elseif shot == 5 then
		local u = travel(24.36, 26.16)
		self:frame(base, V(-2.8 + 1.1 * u, 4.15, 13.6 - 0.7 * u), V(-0.85, 3.35, 5.5), 48)
	elseif shot == 6 then
		local u = travel(26.16, 28.78)
		-- Leave room for the pick's overhead arc and keep its point and the stone in frame at contact.
		self:frame(
			base,
			V(-2.90 - 0.38 * u, 3.32 + 0.28 * u, 1.40 + 0.22 * u),
			V(1.22, 3.22 - 0.82 * ease(t, 28.24, 28.7), 5.58),
			55
		)
	elseif shot == 7 then
		local u = travel(28.78, 31.52)
		self:frame(base, rock + V(-1.12 + 0.36 * u, 1.02 - 0.25 * u, -3.44 + 0.52 * u), rock + V(0, 0.04, 0), 41)
	elseif shot == 8 then
		local u = travel(31.52, 33.03)
		self:frame(
			base,
			V(-3.6 + 0.82 * u, 1.35 + 0.5 * u, 10 - 2.8 * u),
			V(0.35, 2.7 - 0.95 * u, 4.8 - 7 * u),
			53,
			-0.044 * (1 - u)
		)
	else
		local u = travel(33.03, 35.17)
		local runner = localAt(self.crew.playerAim)
		self:frame(
			base,
			runner + V(-3.6 + 1.9 * u, 1.4 - 0.52 * u, 6.3 - 0.84 * u),
			runner + V(0.16, -0.10, -2.4),
			56 + 4 * u
		)
	end
end

function Film:draw(t, liveReady)
	if t < 15.55 then
		Lighting.ClockTime = 6.10 + 1.35 * ease(t, 0.7, Strike.impactTime)
		self.strike:draw(t, self.base, self.motion)
		self:entry(t)
	else
		if self.strike then
			-- The blackout is also the scene change. Release both the visible coast
			-- and its parked effects before loading the avatar and the modern crew.
			self.strike.root:Destroy()
			self.strike.shelf:Destroy()
			self.strike = nil
		end
		-- If streaming finishes late, change sets at a camera cut rather than mid-shot.
		local shot = #presentCuts + 1
		for i, cut in presentCuts do
			if t < cut then
				shot = i
				break
			end
		end
		if self.modernShot ~= shot then
			self:mountPresent(liveReady or (self.modernBase ~= nil and not self.standIn))
			self.modernShot = shot
		end
		Lighting.ClockTime = self.clock
		self.crew:draw(t, self.modernBase, self.motion)
		self.survey:draw(t, self.modernBase)
		self:present(t, shot)
	end
	local opening = 1 - ease(t, 0.45, 1.02)
	local timeCut = ease(t, 15.30, 15.55) * (1 - ease(t, 17.34, 17.78))
	return math.max(opening, timeCut, ease(t, 35.04, 35.33))
end
return Film
