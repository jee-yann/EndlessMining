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
	return setmetatable({
		root = root,
		sun = sun,
		moon = moon,
		corona = corona,
		glow = glow,
		disc = disc,
		face = face,
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
	local sunset = (1 - ease(math.abs(altitude), 0.02, 0.42)) * 0.78
	local restore = ease(age, 13.7, 16.85)
	Lighting.ClockTime = hour
	Lighting.GeographicLatitude = 39 + (self.latitude - 39) * restore
	Lighting.Ambient = self.ambient:Lerp(rgb("8586A2"), night * (1 - restore))
	Lighting.OutdoorAmbient = self.outdoor:Lerp(rgb("95A8CA"), night * (1 - restore))
	Lighting.ExposureCompensation = self.exposure + 0.59 * night * (1 - restore)
	Lighting.ColorShift_Top = self.top:Lerp(rgb("FBA467"), sunset * (1 - restore))
	Lighting.Brightness = self.brightness + (0.48 * (1 - night) + 0.32 * night) * (1 - restore)

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
	local top = math.min(0.80, horizon + 0.36)
	local function traverse(part, arc)
		local height = math.sin(arc)
		local x = math.cos(arc) * 0.83
		part.Position = axis * V(halfX * x, halfY * (horizon - 0.095 + (top - horizon + 0.095) * height), -distance)
		return ease(height, -0.16, 0.03) * stop
	end
	local daylight = traverse(self.sun, phase)
	local moonlight = traverse(self.moon, phase + math.pi)
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
end

return IslandSky
