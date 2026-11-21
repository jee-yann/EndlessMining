-- Original music and Foley for It Knocked Back. The instrument loops are cut
-- from Roblox's bundled sounds. Their periods tune each voice. The film has
-- its own melody, envelopes and percussion.
local Score = {}
local function sample(name, file, first, last, gain, attack, release)
	return { name = name, file = file, first = first, last = last, gain = gain, attack = attack, release = release }
end
local function instrument(name, file, first, last, rootHz, gain, attack, release)
	local s = sample(name, file, first, last, gain, attack, release)
	s.loop, s.rootHz, s.music = true, rootHz, true
	return s
end

local bank = {
	-- A measured 11 ms grain supplies the warm fundamental and its upper partials.
	bow = instrument("Bowed stone", "action_jump_land.mp3", 0.079, 0.090, 1 / 0.011, 1.40, 0.43, 0.32),
	airString = instrument("Air strings", "action_footsteps_plastic.mp3", 0.081, 0.090, 1 / 0.009, 2.45, 0.34, 0.34),
	reed = instrument("Cove reed", "action_get_up.mp3", 0.180, 0.188, 1 / 0.008, 3.35, 0.16, 0.22),
	pluck = instrument("Bridge harp", "action_jump_land.mp3", 0.083, 0.094, 1 / 0.011, 1.60, 0.012, 0.16),
	glass = sample("Glass harmonics", "volume_slider.ogg", 0.015, 0.66, 0.48, 0.012, 0.14),
	bass = instrument("Low string pulse", "action_jump_land.mp3", 0.079, 0.090, 1 / 0.011, 2.55, 0.025, 0.11),

	wind = sample("Thin upper air", "action_falling.ogg", 0.56, 5.40, 3.0, 0.33, 0.27),
	hot = sample("Atmospheric friction", "impact_water.mp3", 0.54, 1.17, 0.36, 1.8, 0.10),
	rumble = sample("Approach rumble", "impact_explosion_03.mp3", 0.47, 0.93, 0.16, 1.6, 0.09),
	hit = sample("Landfall", "action_jump_land.mp3", 0.035, 0.18, 3.85, 0.003, 0.035),
	snap = sample("Crust shear", "impact_water.mp3", 0.041, 0.16, 0.88, 0.003, 0.035),
	wave = sample("Pressure front", "impact_explosion_03.mp3", 0.265, 1.43, 0.64, 0.028, 0.65),
	ash = sample("Ash over shore", "impact_water.mp3", 0.34, 1.36, 0.61, 0.21, 0.48),
	scatter = sample("Loose stones", "action_footsteps_plastic.mp3", 0.036, 0.121, 1.65, 0.003, 0.042),
	surf = sample("Tide through crater", "action_swim.mp3", 0.25, 3.87, 2.2, 0.62, 0.75),
	rain = sample("Rain in the canopy", "impact_water.mp3", 0.42, 1.17, 0.52, 0.60, 0.59),
	bird = sample("Shore bird", "volume_slider.ogg", 0.045, 0.10, 0.18, 0.036, 0.054),
	wood = sample("Decking mallet", "action_footsteps_plastic.mp3", 0.032, 0.132, 2.45, 0.006, 0.032),
	rope = sample("Rope through pulley", "action_jump.mp3", 0.06, 0.21, 1.15, 0.035, 0.07),
	cart = sample("Ore cart bearings", "action_get_up.mp3", 0.115, 0.310, 1.43, 0.19, 0.30),
	lamp = sample("Lantern wick", "action_jump.mp3", 0.085, 0.159, 0.86, 0.005, 0.055),

	tap = sample("Survey knock", "action_jump_land.mp3", 0.040, 0.149, 3.92, 0.003, 0.032),
	tapMetal = sample("Hammer head", "volume_slider.ogg", 0.018, 0.075, 0.33, 0.004, 0.044),
	reply = sample("Returned knock", "action_footsteps_plastic.mp3", 0.034, 0.155, 4.30, 0.014, 0.12),
	chamber = sample("Gallery resonance", "action_jump_land.mp3", 0.079, 0.090, 2.15, 0.022, 0.56),
	pick = sample("Pick bites basalt", "action_jump_land.mp3", 0.034, 0.172, 3.95, 0.002, 0.071),
	split = sample("Fracture", "action_get_up.mp3", 0.175, 0.28, 1.86, 0.006, 0.08),
	shard = sample("Starfall resonance", "volume_slider.ogg", 0.040, 0.67, 0.76, 0.018, 0.35),
	lead = sample("Survey lead voice", "action_swim.mp3", 0.273, 0.280, 3.18, 0.025, 0.060),
	player = sample("Explorer voice", "action_get_up.mp3", 0.180, 0.188, 3.22, 0.020, 0.056),
	vowel = sample("Vocal overtone", "volume_slider.ogg", 0.094, 0.099, 0.19, 0.023, 0.049),
}
Score.bank = bank
bank.glass.music, bank.glass.rootHz = true, 392
bank.pluck.decay, bank.bass.decay = 4.3, 3.2
for _, key in { "wind", "hot", "rumble", "surf", "rain", "bird", "cart", "chamber", "lead", "player", "vowel" } do
	bank[key].loop = true
end
-- SoundEffect levels are in dB. A dry foreground leaves room for the long,
-- darker gallery tail when the rhythm comes back.
bank.bow.eq, bank.airString.eq = { 1, -1, -7 }, { -3, 1, -4 }
bank.reed.eq, bank.pluck.eq, bank.bass.eq = { -2, 2, -5 }, { 1, 0, -3 }, { 2, 0, -10 }
bank.airString.chorus, bank.bow.chorus = true, true
bank.glass.room, bank.airString.room, bank.reed.room = { 1.75, -13 }, { 1.3, -16 }, { 0.85, -18 }
bank.hot.eq, bank.rumble.eq, bank.wave.eq = { -10, -2, 0 }, { 4, -10, -24 }, { 4, -3, -13 }
bank.bird.room, bank.wood.room, bank.lamp.room = { 0.48, -20 }, { 0.32, -21 }, { 0.55, -18 }
bank.reply.eq, bank.chamber.eq = { 3, -2, -12 }, { 3, -1, -16 }
bank.reply.room, bank.chamber.room, bank.shard.room = { 1.2, -12 }, { 2.1, -10 }, { 1.9, -9 }
bank.lead.eq, bank.player.eq, bank.vowel.eq = { -8, 2, -8 }, { -8, 3, -7 }, { -5, -1, -7 }
bank.tapMetal.at, bank.chamber.at = "bridge", "gallery"

function Score.compose(beats)
	local events = {}
	local function cue(key, t, length, rate, strength, endRate)
		table.insert(
			events,
			{ key = key, t = t, length = length, rate = rate, level = strength or 1, endRate = endRate or rate }
		)
	end
	local function note(key, t, pitch, length, strength)
		cue(key, t, length, 440 * 2 ^ ((pitch - 69) / 12) / bank[key].rootHz, strength)
	end
	local function chord(t, length, pitches, strength)
		note("bow", t, pitches[1], length, strength)
		note("airString", t + 0.07, pitches[2], length - 0.09, strength * 0.83)
		note("reed", t + 0.16, pitches[3], length - 0.16, strength * 0.66)
	end

	-- A descending fourth and a climbing fifth belong to the buried inclusion.
	-- They recur in the upper voice at the first lake and in the final cadence.
	chord(0.18, 3.28, { 50, 57, 64 }, 0.48)
	for _, n in { { 0.42, 74, 0.56 }, { 1.46, 69, 0.54 }, { 2.42, 76, 0.47 } } do
		note("glass", n[1], n[2], 1.12, n[3])
	end
	chord(3.31, 2.21, { 46, 53, 64 }, 0.58)
	chord(5.46, 2.03, { 45, 57, 61 }, 0.79)
	for _, n in
		{
			{ 2.84, 38, 0.51 },
			{ 3.86, 38, 0.52 },
			{ 4.71, 41, 0.57 },
			{ 5.43, 40, 0.60 },
			{ 6.04, 38, 0.65 },
			{ 6.54, 37, 0.69 },
			{ 6.94, 37, 0.76 },
			{ 7.24, 37, 0.70 },
		}
	do
		note("bass", n[1], n[2], 0.27, n[3])
	end
	cue("wind", 0.0, 7.70, 0.68, 0.48, 1.43)
	cue("rumble", 3.15, 4.57, 0.37, 0.82, 0.63)
	cue("hot", 4.34, 3.35, 0.75, 0.94, 1.51)
	local hit = beats.impact
	cue("hit", hit, 0.29, 0.73)
	cue("snap", hit + 0.028, 0.18, 1.43, 0.80)
	cue("wave", hit + 0.14, 2.05, 0.54, 1, 0.47)
	cue("ash", hit + 0.50, 1.68, 0.68, 0.78, 0.90)
	note("bow", hit + 0.19, 38, 1.45, 0.73)
	for _, p in
		{ { 0.48, 0.96, 0.76 }, { 0.63, 1.53, 0.58 }, { 0.91, 1.12, 0.69 }, { 1.18, 0.91, 0.47 }, { 1.45, 1.31, 0.36 }, {
			1.84,
			0.74,
			0.29,
		} }
	do
		cue("scatter", hit + p[1], 0.16, p[2], p[3])
	end
	cue("shard", hit + 2.13, 0.87, 0.94, 0.70)
	note("glass", hit + 2.24, 76, 0.92, 0.42)

	-- Water, canopy and then the work camp share a six-beat pulse. New parts
	-- enter as physical things appear in the same view, from the first plank to the last lantern.
	chord(11.65, 3.26, { 50, 57, 66 }, 0.61)
	chord(14.77, 2.32, { 43, 59, 66 }, 0.68)
	chord(16.96, 2.36, { 47, 57, 62 }, 0.74)
	chord(19.19, 2.31, { 43, 59, 64 }, 0.78)
	chord(21.38, 2.36, { 50, 57, 66 }, 0.83)
	chord(23.63, 2.38, { 45, 57, 64 }, 0.72)
	local bars = {
		{ 13.17, { 62, 69, 76, 74, 69, 66 } },
		{ 15.40, { 62, 67, 74, 78, 74, 71 } },
		{ 17.63, { 59, 66, 69, 74, 73, 69 } },
		{ 19.86, { 55, 62, 67, 71, 74, 76 } },
		{ 22.09, { 57, 62, 66, 69, 74, 78 } },
		{ 24.32, { 57, 64, 69, 73 } },
	}
	for i, bar in bars do
		for j, pitch in bar[2] do
			local accent = if j == 1 or j == 4 then 0.86 else 0.62
			note("pluck", bar[1] + (j - 1) * 0.372, pitch, 0.59, accent * math.min(1, 0.46 + i * 0.12))
		end
	end
	for _, n in
		{ { 14.08, 74 }, { 15.29, 69 }, { 16.84, 76 }, { 19.42, 71 }, { 21.39, 74 }, { 23.63, 78 }, { 25.31, 76 } }
	do
		note("glass", n[1], n[2], 0.81, 0.42)
	end
	cue("surf", 11.76, 7.0, 0.62, 0.81, 0.92)
	cue("rain", 15.70, 2.53, 1.36, 0.66, 0.99)
	for _, p in { { 18.42, 2.92, 3.50 }, { 18.66, 3.65, 3.06 }, { 19, 2.78, 3.10 } } do
		cue("bird", p[1], 0.15, p[2], 0.69, p[3])
	end
	cue("rope", 19.64, 0.32, 0.58, 1)
	for _, p in
		{
			{ 20.60, 0.70, 0.83 },
			{ 20.98, 0.93, 0.59 },
			{ 21.34, 0.80, 0.94 },
			{ 21.70, 1.12, 0.67 },
			{ 22.12, 0.74, 1 },
			{ 22.86, 0.84, 0.71 },
			{ 23.21, 1.10, 0.62 },
			{ 24.10, 0.74, 0.64 },
		}
	do
		cue("wood", p[1], 0.18, p[2], p[3])
	end
	cue("rope", 22.62, 0.37, 0.49, 0.91)
	cue("cart", 24.15, 0.98, 0.85, 0.79, 1.23)
	cue("lamp", 25.40, 0.12, 1.29, 0.70)
	-- After the wick lights, leave the taps and the pauses between them exposed.
	for i, t in beats.outbound do
		cue("tap", t, 0.17, if i == 3 then 0.85 else 0.96, if i == 3 then 1.08 else 0.95)
		cue("tapMetal", t + 0.014, 0.09, 1.76, 0.64)
	end
	for i, t in beats.returned do
		cue("reply", t, 0.27, if i == 3 then 0.60 else 0.71, 1)
		cue("chamber", t + 0.018, if i == 3 then 0.80 else 0.29, 0.99, 0.71, 0.85)
	end
	cue("pick", beats.pick, 0.29, 0.87)
	cue("split", beats.pick + 0.036, 0.22, 0.78, 0.84)
	-- A single low attack shares a long harmonic decay with the exposed shard.
	cue("reply", beats.answer, 0.32, 0.56, 1.14)
	cue("chamber", beats.answer + 0.014, 1.43, 1.22, 0.97, 0.81)
	cue("shard", beats.answer + 0.024, 1.14, 1.31, 0.93)
	note("airString", beats.answer + 0.06, 63, 1.85, 0.44)
	chord(40.50, 3.82, { 50, 57, 64 }, 0.47)
	note("glass", 41.18, 74, 0.93, 0.32)
	note("reed", 42.34, 69, 1.92, 0.58)
	cue("wind", 40.27, 4.18, 0.55, 0.25, 0.68)

	-- Short wordless inflections follow the first breath of each caption.
	-- Independent pitch glides for the body and upper formant distinguish the cast.
	for i, line in beats.dialogue do
		local lead = line[3] == "SURVEY LEAD"
		local voice = if lead then "lead" else "player"
		local open, close = if lead then 0.99 else 1.75, if lead then 1.12 else 1.55
		if i % 2 == 0 then
			open, close = close, open
		end
		local at = line[1] + 0.06
		for _, syllable in { { 0, 0.15, open, close, 0.83 }, { 0.205, 0.21, close, open * 0.92, 0.66 } } do
			local t, len = at + syllable[1], syllable[2]
			if t + len < line[2] then
				cue(voice, t, len, syllable[3], syllable[5], syllable[4])
				cue(
					"vowel",
					t + 0.009,
					len - 0.018,
					syllable[3] * (if lead then 1.10 else 0.91),
					syllable[5],
					syllable[4]
				)
			end
		end
	end
	table.sort(events, function(a, b)
		return a.t < b.t
	end)
	return events
end

local function smooth(x)
	local u = math.clamp(x, 0, 1)
	return u * u * (3 - 2 * u)
end
function Score.mix(event, age)
	local s = bank[event.key]
	local attack = math.min(s.attack, event.length * 0.41)
	local release = math.min(s.release, event.length * 0.60)
	local envelope = smooth(age / attack) * smooth((event.length - age) / release)
	if s.decay then
		envelope *= math.exp(-s.decay * math.max(0, age - attack))
	end
	local rate = event.rate + (event.endRate - event.rate) * smooth(age / event.length)
	return s.gain * event.level * envelope, rate
end
return Score
