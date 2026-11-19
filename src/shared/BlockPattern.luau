local Config = require(script.Parent.GameConfig)
local Pattern = {}
function Pattern.axes(normal)
	if normal.Y ~= 0 then
		return Vector3.xAxis, -normal.Y * Vector3.zAxis
	end
	return Vector3.yAxis:Cross(normal), Vector3.yAxis
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
	if space < 1 or not ore or center.Y >= origin.Y + Config.FloorY then
		return {}, nil
	end
	local required = math.max(ore.hardness, Config.strength(center.Y - origin.Y))
	if required > power then
		return {}, ore, required
	end
	return { center }, nil
end
return Pattern
