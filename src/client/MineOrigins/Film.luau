local Scenery = require(script.Parent.Scenery)
local Plates = require(script.Parent.Plates)
local Film = {}
Film.__index = Film
local V, rgb = Vector3.new, Color3.fromHex
local IMPACT, BENCH, HARBOR = 8.4, 32.2, 39.2
Film.duration = 46.5

-- The second half is the keeper's account. Leave a breath between each line.
local captions = {
	{ 0.45, 5.05, "Before the tides", "A star died. One piece of its heart kept burning." },
	{ 5.50, 10.15, "The first shore", "It struck the ground where our mine stands today." },
	{
		10.55,
		16.60,
		"Eight million years",
		"The sea rolled over it. Silt settled, layer upon layer, and turned to stone.",
	},
	{ 17.05, 21.75, "Six generations ago", "The first fishers found a loose chip shining on the beach." },
	{ 22.05, 27.15, "Beacon Point", "They set it in a lantern. That one chip guided six generations home." },
	{ 27.55, 31.95, "Last night", "I climbed the tower in the dark. The wick was stone cold." },
	{
		32.50,
		38.85,
		"Citrine Mine  /  First bore",
		"This morning the drill crew brought me a core. Violet light, right through the cut.",
	},
	{
		39.55,
		46.05,
		"Citrine Cove  /  Present day",
		"Mum’s boat is due by dusk. I’m going down for another piece.",
	},
}

local function progress(t, a, b)
	return math.clamp((t - a) / (b - a), 0, 1)
end
local function ease(t, a, b)
	local p = progress(t, a, b)
	return p * p * (3 - 2 * p)
end
local function show(m, parent)
	if m.Parent ~= parent then
		m.Parent = parent
	end
end
local function pose(m, cf)
	if m:GetPivot() ~= cf then
		m:PivotTo(cf)
	end
end

local function practicals(board)
	local glint = Instance.new("ImageLabel")
	glint.Name, glint.Image = "Wick light", "rbxasset://textures/particles/sparkles_main.dds"
	glint.AnchorPoint, glint.BackgroundTransparency = Vector2.new(0.5, 0.5), 1
	glint.ImageColor3, glint.ZIndex, glint.Parent = rgb("FFDAFF"), 4, board
	local beam = Instance.new("Frame")
	beam.Name, beam.BorderSizePixel, beam.BackgroundColor3 = "Lantern sweep", 0, rgb("FFDBFF")
	beam.ZIndex, beam.Parent = 4, board
	local feather = Instance.new("UIGradient")
	feather.Transparency, feather.Parent = NumberSequence.new(0.35, 1), beam
	local dust = {}
	for i = 1, 18 do
		local puff = Instance.new("ImageLabel")
		puff.Name, puff.Image = "Basalt dust", "rbxasset://textures/particles/smoke_main.dds"
		puff.BackgroundTransparency, puff.AnchorPoint = 1, Vector2.new(0.5, 0.5)
		puff.ImageColor3, puff.Rotation = rgb(if i % 2 == 0 then "E7B58A" else "D0A3AF"), i * 39
		puff.ZIndex, puff.Visible, puff.Parent = 4, false, board
		table.insert(dust, puff)
	end
	return glint, beam, feather, dust
end

function Film.new(screen, view, board, motion)
	-- Park off-camera sets under the GUI so a skip also destroys hidden scenery.
	local shelf = Instance.new("Folder")
	shelf.Name, shelf.Parent = "Offstage", screen
	local lens = Instance.new("Camera")
	lens.Name, lens.FieldOfView, lens.Parent = "Cinematic lens", 37, view
	view.CurrentCamera = lens
	local space, heart = Scenery.space(shelf)
	local glint, beam, feather, dust = practicals(board)
	return setmetatable({
		view = view,
		lens = lens,
		board = board,
		plates = Plates.new(board),
		glint = glint,
		beam = beam,
		feather = feather,
		dust = dust,
		shelf = shelf,
		space = space,
		heart = heart,
		coast = Scenery.landfall(shelf),
		motion = motion,
	}, Film)
end

function Film:exposure(t)
	local lit = t >= 23.2 and t < 28.85
	local find = t >= 18.7 and t <= 20.9
	local sample = t >= 34.3 and t < HARBOR
	local impact = t >= IMPACT and t < IMPACT + 1.5
	local glint, beam = self.glint, self.beam
	glint.Visible, beam.Visible = lit or find or impact or sample, lit
	if lit then
		local sweep = if self.motion then math.sin((t - 23.2) * 1.3 + 0.6) else -0.8
		local reach = 0.43 * sweep
		-- Positions are registered to the lantern room in the harbor painting.
		beam.AnchorPoint = Vector2.new(if reach > 0 then 0 else 1, 0.5)
		beam.Position = UDim2.fromScale(0.762, 0.285)
		beam.Size = UDim2.fromScale(math.abs(reach), 0.008)
		beam.BackgroundTransparency = 0.37
		self.feather.Rotation = if reach > 0 then 0 else 180
		glint.Position, glint.Size = beam.Position, UDim2.fromScale(0.13, 0.195)
		glint.ImageTransparency = 0.2 * math.abs(sweep)
	elseif find then
		glint.Position, glint.Size = UDim2.fromScale(0.51, 0.596), UDim2.fromScale(0.073, 0.11)
		glint.ImageTransparency = 0.40
	elseif impact then
		local burst = (1 - progress(t, IMPACT, IMPACT + 1.5)) ^ 2
		glint.Position = UDim2.fromScale(0.5, 0.49)
		glint.Size = UDim2.fromScale(0.09 + 0.28 * burst, 0.13 + 0.42 * burst)
		glint.ImageTransparency = 1 - burst
	elseif sample then
		glint.Position, glint.Size = UDim2.fromScale(0.482, 0.738), UDim2.fromScale(0.067, 0.10)
		glint.ImageTransparency = 1 - 0.85 * ease(t, 34.3, 35.2)
	end
	local age = t - IMPACT
	for i, puff in self.dust do
		puff.Visible = age >= 0 and age < 2.2 and self.motion
		if puff.Visible then
			local spread = 1 - math.exp(-age * 2.35)
			local angle = i * 2.4
			local size = 0.02 + spread * (0.10 + 0.025 * math.sin(i))
			puff.Position = UDim2.fromScale(
				0.5 + math.cos(angle) * 0.19 * spread,
				0.50 + math.sin(angle) * 0.044 * spread - age * 0.012
			)
			puff.Size = UDim2.fromScale(size, size * 0.72)
			puff.ImageTransparency = progress(age, 0.35, 2.2)
		end
	end
	-- Move into the tower as the light fails. The registered rock teeth stay
	-- locked throughout the earlier geological dissolves.
	local push = if self.motion and t < BENCH then ease(t, 26.1, 30.7) else 0
	local scale = 1 + 0.52 * push
	local sampleMove = if self.motion and t >= BENCH then ease(t, BENCH, HARBOR) else 0
	scale += 0.12 * sampleMove
	self.board.UIScale.Scale = scale
	local base = self.board.Size
	self.board.Position =
		UDim2.new(0.5, -0.258 * base.X.Offset * (0.52 * push), 0.5, base.Y.Offset * (0.108 * push - 0.022 * sampleMove))
end

function Film:frame(eye, focus, width)
	local size = self.view.AbsoluteSize
	local aspect = size.X / math.max(1, size.Y)
	local offset = eye - focus
	local distance =
		math.max(offset.Magnitude, width / (2 * math.tan(math.rad(self.lens.FieldOfView / 2)) * math.max(aspect, 0.5)))
	self.lens.CFrame = CFrame.lookAt(focus + offset.Unit * distance, focus)
end
function Film:cosmos(t)
	local u = if self.motion then ease(t, 0, 5.3) else 0.5
	self.view.Ambient, self.view.LightColor = rgb("A892AD"), rgb("FFEAC6")
	self:frame(V(2.5 - u * 1.8, 1.1 - u * 0.6, 16 - u * 2.3), V(0, 0.4, 0), 11)
	pose(self.heart, CFrame.new(0, 0.18 * u, 0) * CFrame.Angles(0.1, 0.3 + u * 1.45, -0.41 + u * 0.32))
end
function Film:landfall(t)
	local s, shelf = self.coast, self.shelf
	self.view.Ambient, self.view.LightColor = rgb("BBA5A5"), rgb("FFE8C8")
	self:frame(V(0, 9, 45), V(0, 0, 0), 1)
	show(s.trail, if t < IMPACT then s.root else shelf)
	local strike = progress(t, 5.25, IMPACT) ^ 2
	if t < IMPACT then
		pose(s.trail, CFrame.new(V(-15, 15, -2):Lerp(V(0, 0.65, 0), strike)))
	end
	local age = t - IMPACT
	show(s.impact, if age >= 0 and age < 2.45 and self.motion then s.root else shelf)
	if s.impact.Parent == s.root then
		for i, stone in s.stones do
			local p = stone.velocity * age - V(0, 10 * age * age, 0)
			stone.part.CFrame = CFrame.new(p) * CFrame.Angles(age * 2, i + age, age * 3)
			stone.part.Transparency = if p.Y < 0 then 1 else progress(age, 0.9, 1.8)
		end
	end
	show(s.scar, if age >= 0 then s.root else shelf)
end

-- Registered landscape dissolves keep the cleft and arch in the same part of
-- the frame. Only the fisher's insert leaves that axis during the time-lapse.
local transitions = {
	{ 0, 0, "Orbit" },
	{ 5.3, 5.3, "Basalt" },
	{ 10.7, 12.35, "Tide" },
	{ 13.8, 16.25, "Meadow" },
	{ 18.25, 18.7, "Find" },
	{ 20.9, 21.45, "Meadow" },
	{ 21.5, 23.65, "Harbor" },
	{ BENCH, BENCH, "Workshop" },
}
local function painting(t)
	for i = #transitions, 1, -1 do
		local cut = transitions[i]
		if t >= cut[1] then
			if t < cut[2] then
				return transitions[i - 1][3], cut[3], ease(t, cut[1], cut[2])
			end
			return cut[3], nil, 0
		end
	end
end

function Film:draw(t, live)
	local inSpace, strike = t < 5.3, t >= 5.3 and t < 11.6
	show(self.space, if inSpace then self.view else self.shelf)
	show(self.coast.root, if strike then self.view else self.shelf)
	self.view.Visible = inSpace or strike
	local first, second, mix = painting(t)
	if t >= HARBOR then
		first = if live then nil else "Harbor"
	end
	self.plates:draw(first, second, mix)
	local harbor = self.plates.visible.Harbor
	if harbor then
		local night = ease(t, 26.9, 29.8)
		local tint = Color3.new(1, 1, 1):Lerp(rgb("78789A"), night)
		if harbor.image then
			harbor.label.ImageColor3 = tint
		else
			harbor.label.GroupColor3 = tint
		end
	end
	self:exposure(t)
	if inSpace then
		self:cosmos(t)
	elseif strike then
		self:landfall(t)
	end
	local black = math.max(1 - ease(t, 0, 0.7), ease(t, 45.9, Film.duration))
	for _, cut in { 5.3, BENCH, HARBOR } do
		black = math.max(black, if t < cut then ease(t, cut - 0.28, cut) else 1 - ease(t, cut, cut + 0.35))
	end
	return t >= HARBOR and live, black
end

function Film.caption(t)
	for _, cue in captions do
		if t >= cue[1] and t <= cue[2] then
			local opacity = math.min(ease(t, cue[1], cue[1] + 0.18), 1 - ease(t, cue[2] - 0.2, cue[2]))
			return string.upper(cue[3]), cue[4], opacity
		end
	end
	return "", "", 0
end
return Film
