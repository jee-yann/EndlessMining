-- Temporary survey and quarry work seen between the natural shoreline and the harbor.
local P = require(script.Parent.Props)
local Rig = require(script.Parent.RobloxRig)
local Worksite = {}
local V, CF, A, rgb = Vector3.new, CFrame.new, CFrame.Angles, Color3.fromHex
local function timber(m, name, from, to, width, tint)
	local d = to - from
	local mid = (from + to) * 0.5
	local up = if math.abs(d.Unit.Y) > 0.98 then Vector3.zAxis else Vector3.yAxis
	local p = P.part(m, name, V(width, width, d.Magnitude), CFrame.lookAt(mid, to, up), rgb(tint or "956F4B"))
	p.Material = Enum.Material.Wood
	return p
end

local function buildSkiff(shelf)
	local hull = P.model(shelf, "Survey cutter")
	local rim =
		{ { 0, -9.4 }, { 2.7, -6.4 }, { 3.15, 1.85 }, { 2.12, 7.1 }, { -2.12, 7.1 }, { -3.15, 1.85 }, { -2.7, -6.4 } }
	for i, v in rim do
		local w = rim[i % #rim + 1]
		local a, b = V(v[1], 1.9, v[2]), V(w[1], 1.9, w[2])
		local c, d = V(v[1] * 0.48, -0.43, v[2] * 0.82), V(w[1] * 0.48, -0.43, w[2] * 0.82)
		P.face(hull, a, b, d, rgb("AB6842"))
		P.face(hull, a, d, c, rgb("946044"))
		P.face(hull, a, b, V(0, 1.83, 0), rgb("CCAA76"))
		timber(hull, "Painted gunwale", a, b, 0.26, "E6B368")
	end
	for _, z in { -3.2, 0.5, 4.4 } do
		P.box(hull, "Thwart", V(0, 2.05, z), V(4.8, 0.32, 0.90), "785B45")
	end
	timber(hull, "Cutter mast", V(0, 1.8, -1), V(0, 14.8, -1), 0.38)
	timber(hull, "Gaff", V(0, 13.9, -1), V(1.3, 12.1, 5.1), 0.22)
	local tack, peak, clew, leech = V(0, 3.8, -1.1), V(0, 13.75, -1.1), V(1.5, 4.3, 5.3), V(1.3, 12.08, 5.1)
	local billow = V(2.63, 8.35, 2.0)
	for _, edge in
		{ { tack, peak, "E9C688" }, { peak, leech, "FFDE9C" }, { leech, clew, "E8AD67" }, { clew, tack, "EAC184" } }
	do
		P.face(hull, edge[1], edge[2], billow, rgb(edge[3]))
	end
	P.face(hull, V(0, 14.75, -1), V(0.24, 14.0, 2.1), V(0, 13.75, -1), rgb("F39448"))
	return hull
end

local function surveyJetty(shelf, register, dockCF)
	local function section(name, start, finish, build)
		local m = P.model(shelf, name)
		build(m)
		m:PivotTo(dockCF)
		m.WorldPivot = CFrame.identity
		register(m, start, finish, true)
	end
	for j = 0, 4 do
		section("First landing piles", 6.10 + j * 0.125, 9.5 + j * 0.125, function(m)
			for _, side in { -1, 1 } do
				timber(m, "Driven pile", V(side * 3.05, -7.2, j * 3.02), V(side * 3.05, 1.53, j * 3.02), 0.60)
			end
		end)
		section("Survey jetty boards", 6.38 + j * 0.125, 9.40 + j * 0.125, function(m)
			for k = 0, 2 do
				P.box(
					m,
					"Sawn board",
					V(0, 1.45, j * 3.02 + k * 0.91),
					V(6.92, 0.46, 0.86),
					"B4956E",
					nil,
					Enum.Material.Wood
				)
			end
		end)
	end
	section("Landing pennant", 6.98, 9.55, function(m)
		timber(m, "Survey flagstaff", V(2.95, 1.51, 11.31), V(2.95, 12.4, 11.31), 0.27)
		P.face(m, V(2.95, 12.29, 11.31), V(2.95, 9.35, 11.31), V(7.8, 10.95, 12.01), rgb("FFAC49"))
	end)
	section("Field survey shelter", 7.12, 9.35, function(m)
		local a, b = V(0, 6.65, 2), V(0, 6.65, 7.8)
		timber(m, "Ridgepole", a, b, 0.2)
		for _, p in { a, b } do
			for _, side in { -1, 1 } do
				timber(m, "Tripod", V(side * 2.88, 1.69, p.Z), p, 0.22)
			end
		end
		for _, side in { -1, 1 } do
			local lowA, lowB = V(side * 3.04, 1.75, 1.71), V(side * 3.04, 1.75, 8.05)
			P.face(m, a, lowA, b, rgb("BF764F"))
			P.face(m, b, lowA, lowB, rgb("D18B55"))
		end
	end)
end

-- A single wall is quarried in joined courses: pilot opening, enlargement,
-- dressing of the sides, then the voussoirs that exist in the playable mine.
local function quarry(shelf, register, spent)
	local cols = { -13.65, -8.25, -2.98, 2.97, 8.14, 13.74 }
	local heights = { -0.81, 4.55, 9.43, 15.24 }
	local function corner(c, r)
		local offset = if c == 1 or c == #cols then 0 else 0.44 * math.sin(c * 4.15 + r * 0.89)
		local top = if r == #heights then 0.87 * math.cos(c * 2.43) else 0.27 * math.sin(c * 2 + r * 1.93)
		return V(cols[c] + offset, heights[r] + top, 3.72 + 0.55 * math.sin(c * 3.7 + r * 1.27))
	end
	for c = 1, 5 do
		for r = 1, 3 do
			local block = P.model(shelf, "Basalt at the heading")
			local a, b, d, e = corner(c, r), corner(c + 1, r), corner(c, r + 1), corner(c + 1, r + 1)
			local tint = rgb("796860"):Lerp(rgb("9C8273"), 0.10 * r + 0.045 * ((c + r) % 3))
			P.face(block, a, b, e, tint)
			P.face(block, a, e, d, tint)
			for _, edge in { { a, d }, { d, e }, { e, b }, { b, a } } do
				local x, y = edge[1], edge[2]
				local w, v = x - V(0, 0, 7.7), y - V(0, 0, 7.7)
				P.face(block, x, y, w, rgb("5B5355"))
				P.face(block, y, v, w, rgb("665A59"))
			end
			register(block, 3.35, 11.98 + 0.27 * math.abs(3 - c) + 0.15 * math.abs(2 - r) + (0.12 * (c % 2)), true)
			spent(20)
		end
	end
	local works = P.model(shelf, "Temporary timber headframe")
	local crown = V(4.1, 19.82, 7.15)
	for _, at in { V(7.3, 0, 8.2), V(6.6, 0, 3.5), V(1.6, 0, 8.3) } do
		timber(works, "Shear leg", at, crown, 0.51)
	end
	timber(works, "Crossarm", crown, V(-3.8, 19.17, 6.12), 0.58)
	timber(works, "Backstay", crown, V(11.15, 0.20, 2.77), 0.16, "65564B")
	timber(works, "Hoist rope", V(0, 19.21, 6.5), V(0, 7.24, 6.5), 0.12, "65564B")
	register(works, 11.38, 14.81, true)
	for i = 1, 4 do
		local m = P.model(shelf, "Barrow of newly cut rock")
		for j = 1, 4 do
			local p = P.sphere(
				m,
				"Basalt spoil",
				V(
					-9.5 - i * 0.9 + math.cos(j * 2.1) * 1.56,
					0.65 + 0.32 * (j % 3),
					6 + i * 1.45 + math.sin(j * 2) * 1.6
				),
				V(2.9, 1.9, 3.3),
				"8F786D",
				Enum.Material.Slate
			)
			p.CFrame *= A(j * 0.13, 0.67 * j + i * 0.29, 0.18)
		end
		register(m, 11.88 + i * 0.23, 13.52 + i * 0.22, true)
	end
	-- Keep a shadowed throat behind the native jambs even without streamed rock.
	local throat = P.model(shelf, "Footwall and depth of the gallery")
	P.box(throat, "Depth behind the gallery", V(0, 5.58, -66.7), V(61, 11.55, 0.22), "49434B", nil, Enum.Material.Slate)
	P.box(throat, "Portal subgrade", V(0, -0.56, -4.2), V(61, 0.68, 8.6), "967A62", nil, Enum.Material.Slate)
	for _, side in { -1, 1 } do
		P.box(
			throat,
			"Inner jamb",
			V(side * 10.42, 5.51, -0.42),
			V(2.25, 11.6, 7.52),
			"675C59",
			nil,
			Enum.Material.Slate
		)
	end
	register(throat, 3.45, nil, true)
end

function Worksite.build(shelf, register, spent, dock)
	local outward = V(dock.X, 0, dock.Z - 14).Unit
	local launch = V(dock.X, -4.03, dock.Z)
	local dockCF = CFrame.lookAt(launch, launch - outward)
	surveyJetty(shelf, register, dockCF)
	local hull = buildSkiff(shelf)
	hull:ScaleTo(1.16)
	register(hull, 5.48, 8.08, false)
	quarry(shelf, register, spent)
	local foreman = Rig.new(shelf, "Quarry foreman")
	local mate = Rig.new(shelf, "Bridge carpenter")
	register(foreman.model, 11.47, 14.75, false)
	register(mate.model, 9.1, 10.82, false)
	return { hull = hull, dock = dockCF, foreman = foreman, mate = mate }
end

function Worksite.expose(work, t, base)
	if t >= 5.48 and t < 8.08 then
		local landing = math.clamp((t - 5.48) / 0.91, 0, 1)
		local leave = math.clamp((t - 7.48) / 0.58, 0, 1)
		local off = 1 - landing
		work.hull:PivotTo(
			base
				* work.dock
				* CF(-6.8 - off * 21 - 13 * leave, 0, 10.5 + off * 49 + leave * 40)
				* A(0, 0.32 - 0.48 * landing - 0.82 * leave, 0.031 * math.sin(t * 5.6))
		)
	end
	if t >= 9.1 and t < 10.82 then
		local u = math.clamp((t - 9.1) / 1.64, 0, 1)
		local bend = math.sin(math.pi * (math.floor((t - 9.10) * 8) % 4) / 4)
		work.mate:pose(base * CF(-2.8, 0.08, 39.5 - 13.5 * u) * A(0, -0.23, 0), {
			bob = -0.32 * bend,
			RootJoint = A(-0.46 * bend, 0, 0),
			RightShoulder = A(0.29 + 1.1 * bend, 0, 0.14),
			LeftShoulder = A(0.48, 0, -0.13),
			RightHip = A(-0.13, 0, 0),
			LeftHip = A(0.13, 0, 0),
		})
	end
	if t >= 11.47 and t < 14.75 then
		local strike = math.floor((t - 11.47) * 8) % 4 / 3
		local side = math.clamp((t - 12.15) / 1.62, 0, 1)
		work.foreman:pose(base * CF(-3.2 + side * 6.1, 0.06, 8.35) * A(0, -0.18, 0), {
			bob = -0.17 * strike,
			RootJoint = A(-0.28 * strike, 0, 0),
			RightShoulder = A(0.25 + 1.28 * (1 - strike), 0, 0.18),
			LeftShoulder = A(0.51, 0, -0.27),
			Neck = A(0.14 * strike, 0, 0),
		})
	end
end

return Worksite
