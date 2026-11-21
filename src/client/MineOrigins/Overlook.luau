local ease = require(script.Parent.Props).ease
local V = Vector3.new
local Overlook = {}

-- One camera watches both banks, the landing compass and the rock above the
-- gallery. A phone backs off along the same sightline to keep the shores in view.
function Overlook.frame(age, aspect, motion)
	local look = V(0, 47, 16)
	local eye = V(-122, 136, 317)
	local narrow = math.clamp((1.15 - aspect) / 0.69, 0, 1)
	eye = look + (eye - look) * (1.10 + 0.04 * narrow)
	local settle = if motion then ease(age, 0.8, 14.3) else 0
	eye += V(8.5, 2, -4) * settle
	local finish = ease(age, 14.68, 16.96)
	local gateEye, gateLook = V(-32, 29, 66), V(5, 8, 1)
	if not motion then
		finish = if age >= 15.96 then 1 else 0
	end
	return eye:Lerp(gateEye, finish) + V(0, 9 * math.sin(math.pi * finish), 0),
		look:Lerp(gateLook, finish),
		45 + 12 * finish,
		-0.035 * finish
end

return Overlook
