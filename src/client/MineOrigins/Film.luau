local Lighting = game:GetService("Lighting")
local P = require(script.Parent.Props)
local Space, Shore, Workshop =
	require(script.Parent.Space), require(script.Parent.Shore), require(script.Parent.Workshop)
local Film = {}
Film.__index = Film
local V, CF, A, ease = Vector3.new, CFrame.new, CFrame.Angles, P.ease
Film.duration = 46.5
local captions = {
	{ 0.45, 5.0, "Before the tides", "When the old star broke, one piece kept burning." },
	{ 5.5, 10.1, "The first shore", "It struck the headland where our mine stands." },
	{
		10.55,
		16.6,
		"Eight million years",
		"The sea buried the wound. Long after the water fell, the stone was still warm.",
	},
	{ 17.1, 21.85, "Six generations ago", "At low tide, a fisher found the first chip. She named it Starfall." },
	{ 22.05, 27.1, "Beacon Point", "One chip in a lantern. For six generations its light brought our boats home." },
	{ 27.5, 31.95, "Last night", "I reached for the wick. For the first time, it was cold." },
	{
		32.45,
		38.85,
		"The first bore",
		"At dawn the drill crew split a core. The same violet fire ran straight through it.",
	},
	{ 39.55, 46.05, "Citrine Cove · Today", "Mum’s boat is due by dusk. I’m going down for another piece." },
}
function Film.caption(t)
	for _, cue in captions do
		if t >= cue[1] and t <= cue[2] then
			return cue[3], cue[4], math.min(ease(t, cue[1], cue[1] + 0.17), 1 - ease(t, cue[2] - 0.18, cue[2]))
		end
	end
	return "", "", 0
end

function Film.new(screen, stage, camera, site, motion, clock)
	local shelf = Instance.new("Folder")
	shelf.Name, shelf.Parent = "Offstage", screen
	local base = CF(site + V(0, 3200, 0))
	local space, shore, workshop = Space.new(shelf), Shore.new(shelf), Workshop.new(shelf)
	for _, set in { space, shore, workshop } do
		set.root:PivotTo(base)
	end
	return setmetatable({
		stage = stage,
		shelf = shelf,
		camera = camera,
		base = base,
		motion = motion,
		clock = clock,
		space = space,
		shore = shore,
		workshop = workshop,
	}, Film)
end
function Film:activate(set)
	if self.active == set then
		return
	end
	if self.active then
		self.active.root.Parent = self.shelf
	end
	if set then
		set.root.Parent = self.stage
	end
	self.active = set
end
function Film:frame(eye, look, fov, roll, origin)
	local camera = self.camera
	local base = origin or self.base
	camera.CFrame = base * CFrame.lookAt(eye, look) * A(0, 0, if self.motion then roll or 0 else 0)
	camera.Focus = base * CF(look)
	local viewport = camera.ViewportSize
	local aspect = math.max(0.35, viewport.X / math.max(viewport.Y, 1))
	camera.FieldOfView =
		math.min(93, math.deg(2 * math.atan(math.tan(math.rad(fov * 0.5)) * math.max(1, 1.38 / aspect))))
end
function Film:draw(t, liveReady, site, gate)
	local function travel(start, finish)
		return if self.motion then ease(t, start, finish) else 0.5
	end
	local base = self.base
	local live = t >= 39.2 and liveReady
	if t < 5.3 then
		self:activate(self.space)
		Lighting.ClockTime = 2.5
		self.space:draw(t, base)
		local u = travel(0, 5.3)
		self:frame(V(-3.4 + 6 * u, 1.5 - u, 11.8 - 3.5 * u), V(0, 0.13, 0), 44, -0.045 + 0.07 * u)
	elseif t < 32.2 or (t >= 39.2 and not live) then
		self:activate(self.shore)
		self.shore:draw(t, base, self.shelf, self.motion)
		Lighting.ClockTime = if t >= 39.2
			then 8.3
			else 7.4 + 4 * ease(t, 10, 17.2) + 5.6 * ease(t, 21, 26.8) + 1.6 * ease(t, 26.8, 29.15)
		if t < 8.4 then
			local u = travel(5.3, 8.4)
			local fall = math.clamp((t - 5.15) / 3.25, 0, 1) ^ 1.45
			local at = V(-32, 34, -10) * (1 - fall) + V(0, 1.35, 0)
			self:frame(
				V(-23 + 31 * u, 18 - 10 * u, 28 + 5 * u),
				at:Lerp(V(0, 2, 0), 0.20 + 0.20 * u),
				52,
				-0.055 * (1 - u)
			)
		elseif t < 17.05 then
			local u = travel(8.4, 17.05)
			local shake = if self.motion then math.exp(-5 * (t - 8.4)) * math.sin((t - 8.4) * 29) else 0
			self:frame(V(8 + 9 * u, 7.8 + 6 * u + shake * 0.48, 33 + 7 * u), V(-1.4, 1.8, 0), 51, 0.018 * shake)
		elseif t < 19.05 then
			local u = travel(17.05, 19.05)
			self:frame(V(-6.7 + 1.6 * u, 3.1 - 0.7 * u, 19.8 - 1.7 * u), V(-3.0, 1.25, 13.25), 39)
		elseif t < 22.05 then
			local u = travel(19.05, 22.05)
			self:frame(
				V(-2.0 + 1.2 * u, 1.98 + 1.2 * u, 16.2 + 0.5 * u),
				V(-2.88, 1.03 + 1.72 * ease(t, 19, 20.65), 13.55),
				37
			)
		elseif t < 27.1 or t >= 39.2 then
			local u = travel(22.05, 27.1)
			self:frame(V(-20 + 29 * u, 7 + 7 * u, 38 - 8 * u), V(2, 4.8, 0), 54)
		elseif t < 30.1 then
			local u = travel(27.1, 32.2)
			self:frame(V(11.6 - 2 * u, 11.5 + 0.1 * u, 6.7 - 1.7 * u), V(6.6, 10.93, -0.85), 41)
		else
			local u = travel(30.1, 32.2)
			self:frame(V(4.6 - 0.45 * u, 11.4 + 0.2 * u, -0.65), V(13.4 + 0.8 * u, 2.6 - 0.7 * u, 21.6 + 1.5 * u), 43)
		end
	elseif t < 39.2 then
		self:activate(self.workshop)
		Lighting.ClockTime = 8.1
		self.workshop:draw(t, base)
		if t < 34.65 then
			local u = travel(32.2, 34.65)
			self:frame(V(-3.55 + 0.78 * u, 2.3 + 0.46 * u, 4.75 - 0.48 * u), V(-1.0, 2.73, 1.18), 34)
		else
			local u = travel(34.65, 39.2)
			self:frame(V(2.6 - 0.9 * u, 3.0 + 0.34 * u, 6.1 - 1.63 * u), V(-0.58 + 0.45 * u, 2.62 + 0.12 * u, 0.72), 37)
		end
	else
		self:activate(nil)
		Lighting.ClockTime = self.clock
		local u = travel(39.2, 46.5)
		local focus = gate:Lerp(site, 0.24) + V(0, 3.4, 0)
		local eye = gate + V(12 - 9 * u, 12 - 7 * u, 42 - 23 * u)
		self:frame(eye, focus, 56, 0, CFrame.identity)
	end
	local black = math.max(1 - ease(t, 0, 0.37), ease(t, 45.92, Film.duration))
	if t >= 39.0 and t < 39.63 then
		black = math.max(black, if t < 39.2 then ease(t, 39, 39.2) else 1 - ease(t, 39.2, 39.63))
	end
	return black
end
return Film
