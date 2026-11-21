-- Cues are cut on motion. All cameras see the same physical trajectory.
local P = require(script.Parent.Props)
local V, ease = Vector3.new, P.ease
local Shot = {}
local cover = require(script.Parent.Crater).coverHeight
local vent = V(0, -0.205, -37.25)
local finishEye, finishLook = V(-28, 31, 41), V(0, -2, 0)

function Shot.frame(t, motion, path)
	local at = path(t)
	if t < 1.05 then
		-- Put the lens just off the flight path. The speck swells and passes
		-- beneath the right side of frame before cutting out on its wake.
		local aim = path(0.88)
		local eye = aim + V(16.5, -5.8, 12.4)
		local follow = at:Lerp(aim + V(-3, 1, 0), if motion then 0.24 else 0.10)
		return eye, follow, 49 - (if motion then 5 * ease(t, 0.1, 0.89) else 0), if motion then -0.095 else 0
	elseif t < 2.45 then
		local u = if motion then ease(t, 1.05, 2.45) else 0.38
		return at + V(9 + 12 * u, 3 + 6 * u, 21 + 15 * u),
			at + V(-4 - 4 * u, 2.1 + u, -0.3),
			49 + 7 * u,
			if motion then -0.19 + 0.12 * u else 0
	elseif t < 4.03 then
		local d = (path(t + 0.015) - at).Unit
		local u = if motion then ease(t, 2.45, 4.03) else 0.55
		local eye = at - d * (24 + 11 * u) + V(13 + 8 * u, 12 + 5 * u, 5)
		return eye, at + d * (18 + 22 * u) + V(2, -5 - u * 2, 0), 66 + 5 * u, if motion then 0.18 - 0.17 * u else 0
	elseif t < 5.54 then
		local u = ease(t, 4.03, 5.54)
		local eye = V(40, 30, 65) + V(-5.5, 2, -7) * (if motion then u else 0)
		return eye, at:Lerp(V(0, 5, 0), 0.28 + 0.25 * u), 60 - 9 * u, if motion then -0.065 * (1 - u) else 0
	elseif t < 6.50 then
		-- At ground level grit lifts into the long arriving shadow; blank sky
		-- no longer occupies the center while sound winds down to the hit.
		local u = if motion then ease(t, 5.54, 6.27) else 0.45
		return V(3.1 - u * 0.8, cover + 1.65 + u * 0.18, 5.0 - u * 0.75),
			V(0.18, cover + 1.05 + 0.62 * u, -0.07),
			48 - 7 * u,
			if motion then -0.055 else 0
	elseif t < 8.56 then
		local s = t - 6.50
		local pull = if motion then ease(s, 0.12, 0.62) else 0.65
		local lead = ease(s, 0.10, 1.13)
		local roll = 0
		local kick = V(0, 0, 0)
		if motion then
			local q = math.max(0, s - 0.27)
			local amplitude = if s >= 0.27 then math.exp(-5.1 * q) else 0
			kick = V(math.sin(q * 40) * 1.58, math.sin(q * 57) * 0.94, math.sin(q * 32) * 1.35) * amplitude
			roll = 0.043 * math.sin(q * 43) * amplitude - 0.026
		end
		local elevated = (cover - 17.8) * (1 - ease(s, 0.13, 0.91))
		return V(-13 - pull * 7, 23.5 + pull * 15 + elevated, 42 + pull * 11) + kick,
			V(3.5 + lead * 3, 18.5 + lead * 7 + elevated, 0),
			59 + pull * 8,
			roll
	else
		local drift = if motion then ease(t, 8.56, 10.24) else 0.65
		local exit = ease(t, 10.96, 12.12)
		local eye = V(-9.7 - 2.2 * drift, 14.3 + 1.6 * drift, 15.1 - 2 * drift):Lerp(finishEye, exit)
		local target = V(1.1 - 0.7 * drift, -3.25, 0.33):Lerp(finishLook, exit)
		return eye, target, 49 + 3 * exit, if motion then -0.08 * (1 - exit) else 0
	end
end

function Shot.surface(t, motion, eye, look, fov, roll)
	local u = ease(t, 12.12, 13.60)
	if not motion then
		return eye, look, fov, roll
	end
	return (vent + finishEye):Lerp(eye, u) + V(0, 7 * math.sin(math.pi * u), 0),
		(vent + finishLook):Lerp(look, u),
		52 + (fov - 52) * u,
		(roll or 0) * u
end
return Shot
