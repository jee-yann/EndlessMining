local Lighting = game:GetService("Lighting")
local P = require(script.Parent.Props)
local V, rgb, ease = Vector3.new, Color3.fromHex, P.ease
local IslandSky = {}
IslandSky.__index = IslandSky

-- Continuous solar hours. The last revolution slows as the work on the mine ends.
local hours = {
	{ -1.48, 8.0 },
	{ 0, 8.25 },
	{ 1.2, 10 },
	{ 4.9, 34 },
	{ 8.65, 58 },
	{ 12.9, 82 },
	{ 14.75, 86.2 },
}
local function solarHour(age, finish, motion)
	if not motion then
		return 8 + (finish - 8) * ease(age, 0.5, 16.6)
	end
	for i = 2, #hours do
		local a, b = hours[i - 1], hours[i]
		if age <= b[1] then
			return a[2] + (b[2] - a[2]) * math.clamp((age - a[1]) / (b[1] - a[1]), 0, 1)
		end
	end
	return 86.2 + ((finish - 14.2 + 12) % 24 - 12) * ease(age, 14.75, 16.9)
end

local function skyCard(parent, name, diameter, texture)
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.Size, gui.LightInfluence = name, UDim2.fromScale(diameter, diameter), 0
	gui.AlwaysOnTop, gui.Parent = false, parent
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency, image.Size = 1, UDim2.fromScale(1, 1)
	image.Image, image.Parent = texture, gui
	return gui, image
end

local function anchor(parent, name)
	local part = P.box(parent, name, Vector3.zero, Vector3.one, "FFFFFF")
	part.Transparency, part.CastShadow = 1, false
	return part
end

local function horizonLight(root)
	local at = anchor(root, "Light beyond the strait")
	local sky = Instance.new("BillboardGui")
	sky.Name, sky.LightInfluence, sky.Parent = "Dusk", 0, at
	local wash = Instance.new("Frame")
	wash.Name, wash.Size = "Afterglow", UDim2.fromScale(1, 1)
	wash.BorderSizePixel, wash.BackgroundColor3, wash.BackgroundTransparency = 0, rgb("FFFFFF"), 1
	wash.Parent = sky
	local tint = Instance.new("UIGradient")
	tint.Rotation = 90
	tint.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rgb("7C82C4")),
		ColorSequenceKeypoint.new(0.37, rgb("E7A1A7")),
		ColorSequenceKeypoint.new(0.72, rgb("FFC984")),
		ColorSequenceKeypoint.new(1, rgb("FFD9A4")),
	})
	tint.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.28, 0.67),
		NumberSequenceKeypoint.new(0.66, 0.08),
		NumberSequenceKeypoint.new(0.94, 0.90),
		NumberSequenceKeypoint.new(1, 1),
	})
	tint.Parent = wash
	return { at = at, sky = sky, wash = wash }
end

-- Long exposures trace the last few degrees of the orbit, like a moving
-- brushstroke behind each body. Sample the orbit analytically on every frame.
local function orbitTrail(parent, name, color)
	local carrier = anchor(parent, name)
	local points, beams = {}, {}
	for i = 1, 7 do
		local point = Instance.new("Attachment")
		point.Parent, points[i] = carrier, point
		if i > 1 then
			local beam = Instance.new("Beam")
			beam.FaceCamera, beam.LightEmission, beam.LightInfluence = true, 0.68, 0
			beam.Color, beam.Attachment0, beam.Attachment1 = ColorSequence.new(rgb(color)), points[i - 1], point
			beam.Transparency = NumberSequence.new(0.36 + 0.53 * (i - 2) / 6, 0.36 + 0.53 * (i - 1) / 6)
			beam.Parent, beams[i - 1] = carrier, beam
		end
	end
	return { points = points, beams = beams }
end

function IslandSky.new(stage, originalHour)
	local root = P.model(stage, "Sky above the headland")
	local sun = P.sphere(root, "Sun", Vector3.zero, Vector3.one, "FFE4A4", Enum.Material.Neon)
	sun.CastShadow = false
	local corona, glow = skyCard(sun, "Solar corona", 60, "rbxasset://textures/particles/flare_main.dds")
	glow.ImageColor3, glow.ImageTransparency = rgb("FFE1A0"), 0.52
	local moon = anchor(root, "Moon")
	local disc, face = skyCard(moon, "Lunar maria", 35, "rbxasset://sky/moon.jpg")
	face.ImageRectOffset, face.ImageRectSize = Vector2.new(10, 9), Vector2.new(108, 108)
	face.ImageColor3 = rgb("DEEAFF")
	local limb = Instance.new("UICorner")
	limb.CornerRadius, limb.Parent = UDim.new(0.5, 0), face
	local stars = {}
	local random = Random.new(318)
	for i = 1, 46 do
		local s = P.sphere(
			root,
			"Night star",
			Vector3.zero,
			Vector3.one,
			if i % 4 == 0 then "FAE0B9" else "C8DFFA",
			Enum.Material.Neon
		)
		s.Transparency, s.CastShadow = 1, false
		stars[i] = {
			part = s,
			x = random:NextNumber(-1.17, 1.17),
			y = random:NextNumber(0.41, 1.04),
			size = random:NextNumber(0.55, 1.64),
		}
	end
	local sky = Lighting:FindFirstChildOfClass("Sky")
	local temporary = sky == nil
	if temporary then
		sky = Instance.new("Sky")
		sky.Name = "Cinematic sky"
	end
	local bodies = sky.CelestialBodiesShown
	sky.CelestialBodiesShown = false
	if temporary then
		sky.Parent = Lighting
	end
	local air = Lighting:FindFirstChildOfClass("Atmosphere")
	return setmetatable({
		root = root,
		sun = sun,
		moon = moon,
		corona = corona,
		glow = glow,
		disc = disc,
		face = face,
		solarTrail = orbitTrail(root, "Sun exposure", "FFD49D"),
		lunarTrail = orbitTrail(root, "Moon exposure", "A2C9FF"),
		afterglow = horizonLight(root),
		air = air,
		airColor = air and air.Color,
		decay = air and air.Decay,
		haze = air and air.Haze,
		stars = stars,
		stage = stage,
		sky = sky,
		temporary = temporary,
		bodies = bodies,
		hour = originalHour,
		ambient = Lighting.Ambient,
		outdoor = Lighting.OutdoorAmbient,
		brightness = Lighting.Brightness,
		top = Lighting.ColorShift_Top,
		latitude = Lighting.GeographicLatitude,
		exposure = Lighting.ExposureCompensation,
	}, IslandSky)
end

-- Put the orbit behind the miniature. The moon disappears behind the same
-- ridge the sun crossed; the parts and their shadows are local to this viewer.
function IslandSky:draw(age, camera, motion, axis, referenceFov)
	local hour = solarHour(age, self.hour, motion) % 24
	local phase = (hour - 6) / 12 * math.pi
	local altitude = math.sin(phase)
	local night = 1 - ease(altitude, -0.55, 0.15)
	local sunset = 1 - ease(math.abs(altitude - 0.03), 0.03, 0.54)
	local restore = ease(age, 13.7, 16.85)
	Lighting.ClockTime = hour
	Lighting.GeographicLatitude = 39 + (self.latitude - 39) * restore
	Lighting.Ambient = self.ambient:Lerp(rgb("697298"), night * (1 - restore))
	Lighting.OutdoorAmbient =
		self.outdoor:Lerp(rgb("93A2C5"), night * (1 - restore)):Lerp(rgb("D7B3A9"), 0.42 * sunset * (1 - restore))
	Lighting.ExposureCompensation = self.exposure + (0.47 * night + 0.20 * sunset) * (1 - restore)
	Lighting.ColorShift_Top = self.top:Lerp(rgb("FBA467"), sunset * (1 - restore))
	Lighting.Brightness = self.brightness + (0.48 * (1 - night) + 0.32 * night) * (1 - restore)
	if self.air then
		local dusk = sunset * (1 - restore)
		self.air.Color = self.airColor:Lerp(rgb("ACB6E4"), night * (1 - restore)):Lerp(rgb("FFD7AB"), 0.85 * dusk)
		self.air.Decay = self.decay:Lerp(rgb("7678A7"), night * (1 - restore)):Lerp(rgb("D99698"), dusk)
		self.air.Haze = self.haze + 0.60 * dusk
	end

	local viewport = camera.ViewportSize
	local aspect = math.clamp(viewport.X / math.max(1, viewport.Y), 0.32, 3.8)
	-- Keep the orbital plane fixed in the world as the camera leaves the wide shot.
	local distance = 750
	local halfY = distance * math.tan(math.rad(referenceFov) * 0.5)
	local halfX = halfY * aspect
	local stop = 1 - ease(age, 14.62, 15.72)
	if not self.starsPlaced or self.starsPlaced ~= aspect then
		self.starsPlaced = aspect
		for _, star in self.stars do
			star.part.Position = axis * V(halfX * star.x, halfY * star.y, -distance - 6)
			star.part.Size = Vector3.one * star.size * math.clamp(halfY / 334, 1, 1.5)
		end
	end
	for _, star in self.stars do
		star.part.Transparency = 1 - night * stop * 0.78
	end
	local horizon = -axis.LookVector.Y
		/ math.max(0.02, Vector2.new(axis.LookVector.X, axis.LookVector.Z).Magnitude)
		* distance
		/ halfY
	local top = math.min(0.77, horizon + 0.38)
	local veil = self.afterglow
	veil.at.Position = axis * V(0, halfY * (horizon + 0.048) * 1.8, -distance * 1.8)
	veil.sky.Size = UDim2.fromScale(halfX * 7.4, halfY * 0.84)
	veil.wash.BackgroundTransparency = 1 - 0.67 * sunset * stop
	local function position(arc)
		local height = math.sin(arc)
		return axis
			* V(halfX * math.cos(arc) * 0.79, halfY * (horizon - 0.008 + (top - horizon + 0.008) * height), -distance)
	end
	local function traverse(part, arc, trail)
		part.Position = position(arc)
		local visibility = ease(math.sin(arc), 0.02, 0.18) * stop
		local trace = motion and age > 0.82 and age < 14.85 and visibility > 0.02
		for i, beam in trail.beams do
			local u = i / #trail.beams
			local past = arc - 0.37 * u
			beam.Enabled = trace and math.sin(past) > 0.02
			if beam.Enabled then
				trail.points[i].WorldPosition = position(arc - 0.37 * (i - 1) / #trail.beams)
				trail.points[i + 1].WorldPosition = position(past)
				local size = halfY * 0.019 * ease(age, 0.82, 1.8) * (1 - ease(age, 12.9, 14.85)) * visibility
				beam.Width0, beam.Width1 = size * (1.16 - (i - 1) / #trail.beams), size * (1.16 - u)
			end
		end
		return visibility
	end
	local daylight = traverse(self.sun, phase, self.solarTrail)
	local moonlight = traverse(self.moon, phase + math.pi, self.lunarTrail)
	local diameter = halfY * math.clamp(aspect * 0.115, 0.058, 0.17)
	self.sun.Size = Vector3.one * diameter
	self.sun.Transparency = 1 - daylight
	self.sun.Color = rgb("FFB45E"):Lerp(rgb("FFF0B7"), ease(altitude, 0.1, 0.8))
	self.corona.Size = UDim2.fromScale(diameter * 2.9, diameter * 2.9)
	self.corona.Enabled, self.glow.ImageTransparency = daylight > 0.005, 1 - daylight * 0.46
	self.disc.Size = UDim2.fromScale(diameter * 1.02, diameter * 1.02)
	self.disc.Enabled, self.face.ImageTransparency = moonlight > 0.005, 1 - moonlight
end

function IslandSky:Destroy()
	self.root:Destroy()
	if self.temporary then
		self.sky:Destroy()
	else
		self.sky.CelestialBodiesShown = self.bodies
	end
	Lighting.ClockTime, Lighting.GeographicLatitude = self.hour, self.latitude
	Lighting.Ambient, Lighting.OutdoorAmbient = self.ambient, self.outdoor
	Lighting.ColorShift_Top, Lighting.Brightness = self.top, self.brightness
	Lighting.ExposureCompensation = self.exposure
	if self.air then
		self.air.Color, self.air.Decay, self.air.Haze = self.airColor, self.decay, self.haze
	end
end

return IslandSky
