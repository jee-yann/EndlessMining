local Config = require(script.Parent.GameConfig)
local Pattern = {}
local layouts = {}

function Pattern.axes(normal)
	if normal.Y ~= 0 then
		return Vector3.xAxis, -normal.Y * Vector3.zAxis
	end
	return Vector3.yAxis:Cross(normal), Vector3.yAxis
end

function Pattern.dimensions(count)
	local width = math.ceil(math.sqrt(count))
	return width, count / width
end

local function layout(count)
	if layouts[count] then
		return layouts[count]
	end
	local w, h = Pattern.dimensions(count)
	local cells = {}
	for row = 0, h - 1 do
		for col = 0, w - 1 do
			table.insert(cells, Vector2.new(col - math.floor((w - 1) / 2), row - math.floor((h - 1) / 2)))
		end
	end
	table.sort(cells, function(a, b)
		if a.Magnitude ~= b.Magnitude then
			return a.Magnitude < b.Magnitude
		end
		if a.Y ~= b.Y then
			return a.Y < b.Y
		end
		return a.X < b.X
	end)
	layouts[count] = cells
	return cells
end

function Pattern.mineable(p)
	local c = Config.Cell
	return Config.inside(p)
		and p.X >= Config.Min.X + c
		and p.X < Config.Max.X - c
		and p.Y >= Config.Min.Y + c
		and p.Z >= Config.Min.Z + c
		and (p.Z < Config.Max.Z - c or p.Y >= -c)
end

-- Both ends trace to the centre of each face, including obstructions and reach.
function Pattern.visiblePart(eye, center, normal, params)
	local face = center + normal * (Config.Cell / 2)
	local delta = face - eye
	if delta.Magnitude < 0.05 or delta.Magnitude > Config.Reach or delta:Dot(normal) >= 0 then
		return nil
	end
	local hit = workspace:Raycast(eye, delta.Unit * (delta.Magnitude + 0.16), params)
	if hit and hit.Normal:Dot(normal) > 0.999 and (hit.Position - face).Magnitude < 0.12 then
		return hit.Instance
	end
	return nil
end

-- Bits identify particular cells in a fixed face layout. A stale preview can
-- lose cells to another miner, but it can never take a different cell as a substitute.
function Pattern.select(origin, anchor, normal, count, power, space, allowed, probe)
	local chosen, mask, locked = {}, 0, nil
	local anchorOre = probe(anchor)
	if not anchorOre or anchorOre.hardness > power then
		return chosen, 0, anchorOre
	end
	local across, up = Pattern.axes(normal)
	for i, offset in layout(count) do
		if #chosen >= space then
			break
		end
		local bit = bit32.lshift(1, i - 1)
		if allowed and bit32.band(allowed, bit) == 0 then
			continue
		end
		local center = anchor + (across * offset.X + up * offset.Y) * Config.Cell
		if not Pattern.mineable(center - origin) then
			continue
		end
		local ore = if center == anchor then anchorOre else probe(center)
		if ore and ore.hardness <= power then
			table.insert(chosen, center)
			mask = bit32.bor(mask, bit)
		elseif ore and (not locked or ore.hardness < locked.hardness) then
			locked = ore
		end
	end
	return chosen, mask, locked
end
return Pattern
