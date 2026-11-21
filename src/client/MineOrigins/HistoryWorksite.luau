local P = require(script.Parent.Props)
local Rig = require(script.Parent.RobloxRig)

local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
local rgb, ease = Color3.fromHex, P.ease
local Worksite = {}

-- The center sits beneath today's gallery, 37.25 studs north of the portal paving.
local impact = V(0, -0.205, -37.25)
local function setVisible(model, stage, shelf, visible)
	local parent = if visible then stage else shelf
	if model.Parent ~= parent then
		model.Parent = parent
	end
end

-- The crater is continuous across six contour lines. The thin bands on its walls
-- are truncated beds; the exposed leading edge remains visible as the lake fills.
function Worksite.crater(shelf, spent)
	local model = P.model(shelf, "Strata at the impact site")
	local shore = P.model(model, "Cut through the crater wall")
	local rings = {}
	local strata = {
		{ 1.1, -0.27, "54415E" },
		{ 3.4, -0.46, "76616F" },
		{ 6.4, 0.30, "926D68" },
		{ 8.8, 1.02, "C4987F" },
		{ 10.2, 1.19, "6F5D69" },
		{ 11.9, 1.66, "B08A78" },
		{ 14.0, 2.20, "A17C72" },
		{ 18.9, 0.30, "967773" },
		{ 47, -1.57, "856B69" },
	}
	local n = 14
	for level, v in strata do
		local ring = {}
		for i = 1, n do
			local az = i * 2 * math.pi / n
			local radius = v[1]
			local reach = radius
				* (
					1
					+ math.sin(3 * az + level * 0.13) * 0.11
					+ math.cos(2 * az - 0.65) * 0.09
					+ math.sin(5 * az) * 0.05
				)
			-- A low spillway and a tilted west bank break the symmetrical crater rim.
			local spillway = ((1 + math.cos(az - 0.62)) * 0.5) ^ 12
			local shoulder = math.sin(math.pi * math.clamp((radius - 2) / 21, 0, 1))
			ring[i] = V(
				math.cos(az) * reach * 1.11 + radius * 0.035,
				v[2] + (math.sin(az * 3 - 0.6) * 0.40 + math.cos(az + 0.7) * 0.47 - spillway * 2.07) * shoulder,
				math.sin(az) * reach * 0.87 - radius * 0.045
			)
		end
		if level == 1 then
			for i, p in ring do
				P.face(shore, V(0, -0.48, 0), p, ring[i % n + 1], rgb(v[3]))
				spent(2)
			end
		else
			local last = rings[level - 1]
			for i, p in ring do
				local j = i % n + 1
				local tint = rgb(v[3]):Lerp(rgb("D0A58B"), 0.045 * ((i + level) % 3))
				P.face(shore, p, ring[j], last[j], tint)
				P.face(shore, p, last[j], last[i], tint)
				spent(4)
			end
		end
		table.insert(rings, ring)
	end
	local lip = rings[#rings]
	for i, p in lip do
		local next = lip[i % n + 1]
		local bottom = V(p.X * 1.04, -7.0, p.Z * 1.04)
		local nextBottom = V(next.X * 1.04, -7.0, next.Z * 1.04)
		P.face(shore, p, next, nextBottom, rgb("7A6470"))
		P.face(shore, p, nextBottom, bottom, rgb("77646A"))
		spent(4)
	end
	for _, facet in shore:GetChildren() do
		facet.Material = Enum.Material.Slate
	end

	-- The flying core is already underground. Its last pale glint sits within
	-- a single split in the ash, between plates carried over from the blast.
	local shard = P.crystal(model, Vector3.zero, 0.55)
	local impactArt = script.Parent.ImpactSculptures
	for i, at in { V(-2.3, -0.43, 0.3), V(1.20, -0.43, -1.32), V(4.84, -0.08, 0.75), V(-5.80, 0.18, -0.9) } do
		local rock = impactArt[if i % 2 == 0 then "Slag blade" else "Spall"]:Clone()
		rock.Name = "Overturned impact glass"
		rock:ScaleTo(0.55 + i * 0.085)
		rock:PivotTo(CF(at) * A(0.33 * i, -0.58 * i, 0.19))
		rock.Parent = model
		spent(36)
	end
	local seams = {}
	local cleft = {
		V(-3.3, -0.30, -1.01),
		V(-1.58, -0.30, -0.85),
		V(-0.74, -0.26, -0.12),
		V(0.28, -0.29, 0.07),
		V(1.03, -0.32, 0.58),
		V(2.73, -0.30, 0.72),
	}
	for i = 2, #cleft do
		P.rod(model, "Buried fracture", cleft[i - 1], cleft[i], 0.12, rgb("4B3B52"))
		if i >= 3 and i <= 5 then
			local edge = P.rod(
				model,
				"Last glint",
				cleft[i - 1] + V(0, 0.047, 0),
				cleft[i] + V(0, 0.043, 0),
				0.045,
				rgb("DCA7D3")
			)
			edge.Material = Enum.Material.Neon
			table.insert(seams, edge)
		end
	end

	-- A shallow tongue follows the breach as the spring fills. Two joined
	-- shoreline contours give the shallows a muddy margin and a deeper center.
	local lake = P.model(model, "Crater spring and shallows")
	local inner, outer = {}, {}
	for i = 1, n do
		local a = i * 2 * math.pi / n
		local tongue = ((1 + math.cos(a - 0.62)) * 0.5) ^ 14
		local radius = 8.9 + 1.35 * math.sin(3 * a - 0.47) + 0.72 * math.cos(5 * a) + 3.4 * tongue
		outer[i] = V(math.cos(a) * radius * 1.19, 0, math.sin(a) * radius * 0.91)
		inner[i] = V(-0.68 + outer[i].X * (0.73 + 0.07 * math.sin(a)), 0.019, -0.36 + outer[i].Z * 0.73)
	end
	for i, p in outer do
		local j = i % n + 1
		P.face(lake, V(-0.4, 0.028, 0), inner[i], inner[j], rgb("53878C"))
		P.face(lake, p, outer[j], inner[j], rgb("82A49B"))
		P.face(lake, p, inner[j], inner[i], rgb("7B9F99"))
		spent(6)
	end
	for _, facet in lake:GetChildren() do
		facet.CastShadow = false
		facet.Reflectance = 0.055
	end
	return { model = model, shard = shard, lake = lake, seams = seams }
end

-- Thin, sculpted cloud banks cross the peaks at different speeds. Their shadowed
-- undersides and uneven sunlit crests also read as silhouettes against the dawn.
function Worksite.weather(shelf, spent)
	local banks = {}
	for k = 1, 3 do
		local cloud = P.model(shelf, "Coastal cloud bank")
		local previous
		for j, h in { 0.12, 0.55, 0.42, 1.0, 0.71, 0.82, 0.48, 0.32, 0.04 } do
			local x = (j - 5) * (6.7 + k)
			local edge = V(x, -0.2 + 0.8 * math.sin(j * 0.47), 2.5 * h)
			local shoulder = V(x + 1, h * 4.9, 0.4 + h * 1.5)
			local crest = V(x - 0.4, h * 6.2, -1.9)
			if previous then
				local function quad(a, b, c, d, tone)
					P.face(cloud, a, b, c, tone)
					P.face(cloud, a, c, d, tone)
				end
				quad(previous[1], edge, shoulder, previous[2], rgb("C4C6CE"))
				quad(previous[2], shoulder, crest, previous[3], rgb("F6E5CF"))
				spent(8)
			end
			previous = { edge, shoulder, crest }
		end
		table.insert(banks, cloud)
	end
	return banks
end

local function spar(parent, name, a, b, width, tone)
	local p = P.rod(parent, name, a, b, width, rgb(tone))
	p.Material = Enum.Material.Wood
	return p
end

function Worksite.builders(shelf)
	local site = P.model(shelf, "First geological survey")
	local stake = P.model(site, "Survey pennant")
	local shaft = P.box(stake, "Ash survey staff", V(0, 2.7, 0), V(0.16, 5.4, 0.16), "694744")
	shaft.Material = Enum.Material.Wood
	local silk = P.model(site, "Signal cloth")
	P.face(silk, V(0, 0, 0), V(1.15, -0.17, 0.17), V(0, -1.13, 0), rgb("FFB14F"))
	P.face(silk, V(1.15, -0.17, 0.17), V(2.94, -0.28, -0.13), V(0, -1.13, 0), rgb("E88647"))
	local tails = P.model(site, "Sight tripod")
	for i = 1, 3 do
		local a = i * 2 * math.pi / 3
		spar(tails, "Tripod leg", V(math.cos(a) * 0.93, 0, math.sin(a) * 0.93), V(0, 2.85, 0), 0.16, "9C7253")
	end
	P.box(tails, "Sight frame", V(0, 2.93, 0), V(0.71, 0.39, 0.67), "E8C470", nil, Enum.Material.Metal)
	spar(tails, "Telescope", V(0, 3.28, -0.88), V(0, 3.28, 0.90), 0.34, "3B5C60").Material = Enum.Material.Metal
	local miner = Rig.new(shelf, "First surveyor")
	local hoist = P.model(shelf, "Timber shear legs and gantry")
	local crown = V(3.6, 19.5, 6.7)
	for _, foot in { V(5.7, 0, 7.8), V(7.6, 0, 3.5), V(1.9, 0, 8.7) } do
		spar(hoist, "Shear leg", foot, crown, 0.44, "B3845F")
		P.box(hoist, "Cast shoe", foot + V(0, 0.22, 0), V(0.85, 0.44, 0.85), "525962", nil, Enum.Material.Metal)
	end
	spar(hoist, "Tie beam", V(5.2, 3.5, 7.5), V(6.9, 3.5, 4.5), 0.33, "936949")
	spar(hoist, "Gin pole", crown - V(0, 3.7, 0), V(0.02, 19.55, 4.35), 0.45, "90674E")
	spar(hoist, "Head beam", crown, V(-0.51, 19.55, 4.35), 0.40, "C39A77")
	local wheel = P.cylinder(hoist, "Head sheave", V(0, 19.45, 4.35), 0.57, 0.24, "4F6970", Enum.Material.Metal)
	wheel.CFrame = CF(0, 19.45, 4.35)
	P.rod(hoist, "Standing line", V(6.6, 1.55, 4.6), crown, 0.08, rgb("685444"))
	local runner = P.model(shelf, "Fall and slings")
	local line = P.part(runner, "Lift line", Vector3.one, CF(), rgb("55464A"))
	local slings = {}
	for i = 1, 2 do
		slings[i] = P.part(runner, "Canvas sling", Vector3.one, CF(), rgb("BFA778"))
	end
	return {
		site = site,
		stake = stake,
		silk = silk,
		tripod = tails,
		miner = miner,
		hoist = hoist,
		runner = runner,
		line = line,
		slings = slings,
	}
end

local function connect(p, a, b, width)
	local length = (a - b).Magnitude
	local up = if math.abs((b - a).Unit.Y) > 0.98 then Vector3.zAxis else Vector3.yAxis
	p.CFrame = CFrame.lookAt((a + b) * 0.5, b, up)
	p.Size = V(width, width, math.max(0.02, length))
end

function Worksite.drawCrater(c, stage, shelf, base, t)
	setVisible(c.model, stage, shelf, t < 7.45)
	if t >= 7.45 then
		return
	end
	local burial = ease(t, 0.12, 2.48)
	local anchor = base * CF(impact)
	c.model:PivotTo(anchor)
	c.shard:PivotTo(anchor * CF(0.12, -0.20 - burial * 1.34, 0.08) * A(0.46 + burial * 0.18, 0.33, -0.69))
	c.lake:ScaleTo(math.max(0.016, burial))
	c.lake:PivotTo(anchor * CF(0, -0.84 + burial * 1.55, 0))
	for _, seam in c.seams do
		seam.Transparency = burial
	end
end

function Worksite.drawWeather(banks, stage, shelf, base, t, motion)
	for k, cloud in banks do
		setVisible(cloud, stage, shelf, t < 9.75)
		if t < 9.75 then
			local u = if motion then t / 9.75 else 0.42 + t * 0.018
			local x = -197 + (k - 1) * 113 + (120 + 12 * k) * u
			cloud:PivotTo(base * CF(x, 67 + k * 4.7, -187 + k * 10) * A(0, 0.05 * k, 0))
		end
	end
end

function Worksite.signOffset(t)
	local lift = ease(t, 14.90, 16.59)
	return V(3.0 * (1 - lift), -11.25 * (1 - lift), 1.9 * (1 - lift))
end

function Worksite.drawBuilders(b, stage, shelf, base, t)
	local surveying, lifting = t >= 9.35 and t < 17.3, t >= 12.55 and t < 17.76
	setVisible(b.site, stage, shelf, surveying)
	setVisible(b.miner.model, stage, shelf, surveying)
	setVisible(b.hoist, stage, shelf, lifting)
	setVisible(b.runner, stage, shelf, t >= 14.90 and t < 17.1)
	if surveying then
		local arrive = ease(t, 9.35, 10.8)
		local crossing = ease(t, 11.5, 14.7)
		local depart = ease(t, 16.15, 17.3)
		local plant = ease(t, 10.12, 10.9)
		local flag = base * CF(-5.15, -0.29 - (1 - plant) * 3.55, 39.0)
		b.stake:PivotTo(flag)
		b.silk:PivotTo(flag * CF(0, 5.3, 0) * A(0, 0.21 * math.sin(t * 7), 0))
		b.tripod:PivotTo(base * CF(-7.8, -0.19 - 3.8 * (1 - plant), 40.5) * A(0, 0.22 + plant * 0.31, 0))
		local lane = V(-6.3 + 2.6 * crossing + 5.1 * depart, -0.12, 47.8 - arrive * 8.8 - 31 * crossing - depart * 13)
		local travel = (1 - arrive) + math.sin(crossing * math.pi) + depart
		local step = math.sin(t * 13.1) * math.min(1, travel)
		local gesture = ease(t, 10.30, 10.80) * (1 - ease(t, 11.05, 11.60))
		local foot = base * CF(lane) * A(0, -0.10 - 0.57 * gesture, 0)
		b.miner:pose(foot, {
			bob = math.abs(step) * 0.14 - 0.14 * gesture,
			RootJoint = A(-0.07 - 0.18 * gesture, 0, 0),
			Neck = A(-0.10 + 0.24 * gesture, 0.43 * gesture, 0),
			RightHip = A(0.54 * step, 0, 0.045),
			LeftHip = A(-0.54 * step, 0, -0.045),
			RightShoulder = A(-0.47 * step + 0.82 * gesture, 0, 0.06),
			LeftShoulder = A(0.47 * step, 0, -0.09),
		})
	end
	if lifting then
		local up = ease(t, 12.55, 13.69) * (1 - ease(t, 17.10, 17.76))
		b.hoist:PivotTo(base * CF(5.3, 0, 6.7) * A((1 - up) * 1.32, 0, -0.04 * (1 - up)) * CF(-5.3, 0, -6.7))
	end
	if t >= 14.90 and t < 17.1 then
		local f = Worksite.signOffset(t)
		local joint = V(f.X, 17.4 + f.Y, 4.3 + f.Z)
		local function world(v)
			return base:PointToWorldSpace(v)
		end
		connect(b.line, world(V(0, 19.4, 4.3)), world(joint), 0.09)
		for i, sling in b.slings do
			connect(sling, world(joint), world(joint + V(if i == 1 then -3.7 else 3.7, -1.68, 0)), 0.10)
		end
	end
end

return Worksite
