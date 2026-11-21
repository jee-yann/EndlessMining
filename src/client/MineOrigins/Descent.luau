-- The flight is continuous in world space. A locked intercept, a passing lens
-- and two tracking mounts give that single path very different screen speeds.
local V = Vector3.new
local Shot = {}
local cover = require(script.Parent.Crater).coverHeight
local vent = V(0, -0.205, -37.25)
local finishEye, finishLook = V(-28, 31, 41), V(0, -2, 0)

function Shot.frame(t, motion, path)
	local at = path(t)
	if t < 0.85 then
		local eye = path(1.17) + V(-3.3, 2.5, 5.5)
		local target = path(0.56) + V(0, 0.85, 0)
		return eye, target, if motion then 48 else 59, -0.14
	elseif t < 1.02 then
		-- Catch the wake as it crosses this second, stationary lens.
		local cross = path(0.94)
		return cross + V(-6, 2.2, 8.3), cross, 56, 0.22
	elseif t < 1.68 then
		-- Ride beside the fluted shell. The facet and the racing horizon move
		-- on different clocks; the framing locks before cutting to geography.
		return at + V(6.8, 3.2, 8.3), at + V(-0.6, 0.45, -0.2), 43, -0.23
	elseif t < 2.45 then
		return V(-247, 216, -114), V(24, 52, 25), 47, 0.035
	elseif t < 4.10 then
		local d = (path(t + 0.025) - at).Unit
		-- Tighten once on the diving line; hold the new mount to the cut.
		local notch = if motion and t >= 3.37 then 1 else 0
		local eye = at - d * (29 - 6 * notch) + V(12 - 3 * notch, 11, 4)
		return eye, at + d * (32 + 5 * notch) + V(2, -5, 0), 64 - notch * 6, 0.13 - 0.08 * notch
	elseif t < 5.55 then
		-- The incoming body crosses fixed basalt teeth. Let it pass the aim
		-- mark instead of centering it for the entire descent.
		return V(-68, 66, 38), path(4.92) - V(0, 4, 0), 29, -0.11
	elseif t < 6.50 then
		local insert = motion and t >= 6.16
		local eye = if insert then V(2.65, cover + 1.43, 3.67) else V(3.30, cover + 1.81, 5.65)
		return eye, V(0.09, cover + 1.48, -0.14), if insert then 42 else 50, -0.057
	elseif t < 6.93 then
		local eye, look = V(-17, cover + 8.6, 55), V(1.6, cover - 1.2, 0)
		if motion and t >= 6.76 then
			-- The camera takes two distinct knocks from the pressure front.
			local first = t < 6.833
			eye += if first then V(-2.8, 2.9, 3.2) else V(0.8, -0.6, 1.5)
			return eye, look + V(0, 2.9, 0), if first then 53 else 57, if first then -0.055 else 0.018
		end
		return eye, look, 58, -0.024
	elseif t < 7.78 then
		-- The entire raised crown and its side vent have room to silhouette.
		local eye, look = V(-24, 49, 91), V(3, 21.5, 0)
		local snap = motion and t >= 7.18 and t < 7.31
		return eye,
			look + (if snap then V(1.4, 1.8, 0) else Vector3.zero),
			if snap then 51 else 54,
			if snap then -0.042 else 0
	elseif t < 8.56 then
		return V(-21, 34, 58), V(4.2, 14, 0), 48, -0.045
	elseif t < 9.79 then
		return V(-10.7, 13.8, 14.2), V(0.3, -3.4, 0.3), 47, -0.10
	elseif t < 10.59 then
		-- Straight across the two rock lips: catch only the light slipping
		-- between them. The player's strike repeats this insert in the present.
		return V(3.5, 11.8, 5.6), V(1.32, -3.9, 0.27), 38, 0.068
	elseif t < 11.49 then
		local knock = motion and ((t >= 10.68 and t < 10.76) or (t >= 11.12 and t < 11.19))
		return V(-16, 18.5, 21.7) + (if knock then V(-0.52, 0.65, 0) else Vector3.zero),
			V(0.7, -3.4, 0),
			49,
			if knock then -0.032 else 0
	end
	return finishEye, finishLook, 52, 0
end

function Shot.surface(t, motion, eye, look, fov, roll)
	-- Cut out a full lens size on the sealed crater. Its surrounding cliffs
	-- register the location across the cut to the weathered geological set.
	if t < 13.04 then
		return vent + V(-62, 72, 102), vent + V(0, 7, 6), 54, 0
	end
	return eye, look, fov, roll
end

return Shot
