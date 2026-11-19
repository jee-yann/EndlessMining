local Config = require(script.Parent.GameConfig)
local Pattern = {}
function Pattern.axes(normal)
	if normal.Y ~= 0 then
		return Vector3.xAxis, -normal.Y * Vector3.zAxis
	end
	return Vector3.yAxis:Cross(normal), Vector3.yAxis
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

function Pattern.select(origin, center, ore, power, space)
	if space < 1 or not ore or not Pattern.mineable(center - origin) then
		return {}, nil
	end
	if ore.hardness > power then
		return {}, ore
	end
	return { center }, nil
end
return Pattern
