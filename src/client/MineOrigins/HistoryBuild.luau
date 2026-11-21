-- A builder's stroke has a direction: sills run along the shore, timber rises
-- from a footing, canvas unfurls between its posts, masonry settles onto a
-- course. The transforms finish at the exact authored gameplay coordinates.
local Build = {}
local V, C = Vector3.new, CFrame
local laid = {
	["Footbridge deck boards"] = true,
	["Footbridge deck"] = true,
	["Boardwalk"] = true,
	["Way into the mine"] = true,
	["Path from the landing"] = true,
	["Graded plaza paving"] = true,
	["Track sleepers"] = true,
	["Rail into the siding"] = true,
	["Footbridge handrails"] = true,
	["Landing compass"] = true,
	["Dock planking"] = true,
	["Ridge trail"] = true,
	["Court foundations"] = true,
}
local erected = {
	["Tower footings"] = true,
	["Cableway trestles"] = true,
	["Harbor beacon"] = true,
	["Loading crane"] = true,
	["Footbridge posts"] = true,
	["Bridge bearers"] = true,
	["Dock pilings"] = true,
	["Boardwalk piles"] = true,
	["Boardwalk rails"] = true,
	["Gallery floor and headers"] = true,
	["Miners Court"] = true,
}
function Build.new()
	return { groups = {}, active = {} }
end
function Build.group(motion, model, trade, age)
	if age <= 0 or age >= 16 then
		return
	end
	local mode
	if trade == "Ore wagons" then
		mode = "railcar"
	elseif laid[trade] then
		mode = "lay"
	elseif erected[trade] or string.find(trade, "workshop", 1, true) then
		mode = "erect"
	elseif trade == "Dressed arch stones" then
		mode = "hoist"
	elseif
		trade == "Meadow in blossom"
		or trade == "Planted beds"
		or string.find(trade, "pine")
		or string.find(trade, "Pines")
		or trade == "Coastal grove"
	then
		mode = "plant"
	elseif
		trade == "Benches and gardens"
		or trade == "Mine sign"
		or trade == "Entrance fittings"
		or trade == "Market lanterns"
		or trade == "Gallery lamps"
	then
		mode = "set"
	else
		return
	end
	local g = {
		time = age,
		span = if mode == "railcar"
			then 15.94 - age
			elseif mode == "hoist" then 0.47
			elseif mode == "plant" then 0.53
			else 0.32,
		reverse = trade == "Rail into the siding",
		strokes = {},
	}
	for _, part in model:GetChildren() do
		local cf, size = part.CFrame, part.Size
		local direction, index
		local x, y, z = size.X, size.Y, size.Z
		if
			part:IsA("WedgePart")
			or mode == "railcar"
			or mode == "set"
			or mode == "hoist"
			or (mode == "plant" and part.Shape == Enum.PartType.Ball)
		then
			direction = Vector3.yAxis
			index = 0
		else
			-- Measure the member in its own basis; rotated uprights, roof
			-- strakes and beams extend along their original direction.
			index = if x >= y and x >= z then 1 elseif y >= z then 2 else 3
			if mode == "plant" then
				index = 2
			end
			direction = if index == 1 then Vector3.xAxis elseif index == 2 then Vector3.yAxis else Vector3.zAxis
		end
		table.insert(g.strokes, { p = part, cf = cf, size = size, axis = direction, index = index })
	end
	g.mode = mode
	motion.groups[model] = g
end

local function pose(g, u)
	if u == g.u then
		return
	end
	g.u = u
	local s = u * u * (3 - 2 * u)
	for _, k in g.strokes do
		local p, cf, size = k.p, k.cf, k.size
		if u == 1 then
			p.CFrame, p.Size = cf, size
		elseif g.mode == "railcar" then
			local time = g.time + u * g.span
			local depart = math.clamp((time - 14.68) / 1.26, 0, 1)
			local distance = 28 * (1 - depart * depart * (3 - 2 * depart))
			local loaded = math.clamp((time - g.time) / 0.24, 0, 1)
			local height = 1 - loaded
			p.CFrame = cf + V(0, height * 2, distance)
			p.Size = size * (0.78 + 0.22 * loaded)
		elseif k.index == 0 then
			local left = 1 - s
			local h = if g.mode == "hoist" then 3.8 elseif g.mode == "plant" then -2.2 else 1.3
			p.CFrame = (cf + Vector3.yAxis * h * left)
				* C.Angles(0, 0, left * (if g.mode == "hoist" then -0.13 else 0.067))
			local scale = if g.mode == "plant" then math.max(0.07, s) else 0.78 + 0.22 * s
			p.Size = size * scale
		else
			local grip = math.max(0.035, s)
			local length = if k.index == 1 then size.X elseif k.index == 2 then size.Y else size.Z
			local dim = size - (k.axis * length * (1 - grip))
			p.Size = V(math.max(0.025, dim.X), math.max(0.025, dim.Y), math.max(0.025, dim.Z))
			p.CFrame = cf * C.new(k.axis * (length * (grip - 1) / 2) * (if g.reverse then -1 else 1))
		end
	end
end

function Build.activate(motion, model)
	local group = motion.groups[model]
	if group then
		motion.active[group] = true
	end
end
function Build.seek(motion, t)
	table.clear(motion.active)
	for _, g in motion.groups do
		if t >= g.time and t < g.time + g.span then
			motion.active[g] = true
		elseif t >= g.time + g.span then
			pose(g, 1)
		else
			g.u = nil
		end
	end
end
function Build.update(motion, t)
	for g in motion.active do
		local u = math.clamp((t - g.time) / g.span, 0, 1)
		pose(g, u)
		if u >= 1 then
			motion.active[g] = nil
		end
	end
end
return Build
