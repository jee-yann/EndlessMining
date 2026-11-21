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
	strata = sample("Shearing beds", "action_get_up.mp3", 0.10, 0.41, 1.70, 0.022, 0.20),
	core = sample("Descending core", "volume_slider.ogg", 0.042, 0.74, 0.92, 0.016, 0.31),
	deep = instrument("Subsurface pressure", "action_jump_land.mp3", 0.079, 0.090, 1 / 0.011, 2.4, 0.13, 0.64),
	surf = sample("Tide through crater", "action_swim.mp3", 0.25, 3.87, 2.2, 0.62, 0.75),
	rain = sample("Rain in the canopy", "impact_water.mp3", 0.42, 1.17, 0.52, 0.60, 0.59),
	bird = sample("Shore bird", "volume_slider.ogg", 0.045, 0.10, 0.18, 0.036, 0.054),
	wood = sample("Decking mallet", "action_footsteps_plastic.mp3", 0.032, 0.132, 2.45, 0.006, 0.032),
	rail = sample("Siding spike", "volume_slider.ogg", 0.018, 0.105, 0.44, 0.004, 0.055),
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
bank.strata.eq, bank.core.eq, bank.deep.eq = { 3, -4, -15 }, { 0, -3, -8 }, { 4, -3, -18 }
bank.strata.room, bank.core.room, bank.deep.room = { 0.60, -18 }, { 1.42, -11 }, { 1.7, -14 }
bank.deep.music = false
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
	local hit = beats.impact
	chord(3.16, 1.93, { 46, 53, 64 }, 0.58)
	chord(hit - 1.56, 1.49, { 45, 57, 61 }, 0.79)
	for _, n in
		{
			{ 3.66, 38, 0.51 },
			{ 2.82, 38, 0.52 },
			{ 2.07, 41, 0.57 },
			{ 1.43, 40, 0.60 },
			{ 0.93, 38, 0.65 },
			{ 0.53, 37, 0.69 },
			{ 0.21, 37, 0.76 },
		}
	do
		note("bass", hit - n[1], n[2], 0.23, n[3])
	end
	cue("wind", 0.0, hit - 0.10, 0.68, 0.48, 1.43)
	cue("rumble", hit - 4.02, 3.97, 0.37, 0.82, 0.63)
	cue("hot", hit - 3.05, 2.98, 0.75, 0.94, 1.51)
	cue("hit", hit, 0.29, 0.73)
	cue("snap", hit + 0.028, 0.18, 1.43, 0.80)
	cue("wave", hit + 0.14, 2.05, 0.54, 1, 0.47)
	cue("ash", hit + 0.50, 1.68, 0.68, 0.78, 0.90)
	note("bow", hit + 0.19, 38, 1.45, 0.73)
	for _, p in
		{
			{ 0.48, 0.96, 0.76 },
			{ 0.63, 1.53, 0.58 },
			{ 0.91, 1.12, 0.69 },
			{ 1.18, 0.91, 0.47 },
			{ 1.45, 1.31, 0.36 },
			{
				1.84,
				0.74,
				0.29,
			},
		}
	do
		cue("scatter", hit + p[1], 0.16, p[2], p[3])
	end
	-- The bright core stays audible through chalk, shale and basalt. Each stratum
	-- folds the same falling interval lower until only a slow, filtered tail remains.
	cue("core", hit + 1.08, 0.74, 1.46, 0.71, 1.20)
	for _, bed in
		{
			{ 1.89, 1.17, 0.78, 56 },
			{ 2.60, 0.88, 0.72, 50 },
			{ 3.60, 0.56, 0.65, 45 },
		}
	do
		cue("strata", hit + bed[1], 0.43, bed[2], bed[3], bed[2] * 0.71)
		note("deep", hit + bed[1] + 0.025, bed[4], 0.76, 0.52)
	end
	cue("core", hit + 4.31, 1.03, 0.57, 0.76, 0.43)
	note("deep", hit + 4.32, 38, 1.08, 0.82)
	cue("strata", hit + 4.72, 0.53, 0.50, 0.48, 0.37)

	-- The build plays in sixes. Its hammer accents follow the jetty, bridge,
	-- siding and last rail pin. A whole bar clears for the survey at the end.
	local history = beats.history
	for _, bar in
		{
			{ 0.0, 2.62, { 50, 57, 66 }, 0.54 },
			{ 2.60, 2.43, { 43, 59, 66 }, 0.58 },
			{ 5.0, 2.43, { 47, 57, 62 }, 0.65 },
			{ 7.4, 2.43, { 43, 59, 64 }, 0.73 },
			{ 9.8, 2.43, { 50, 57, 66 }, 0.80 },
			{ 12.2, 2.43, { 45, 57, 64 }, 0.72 },
			{ 14.6, 2.02, { 50, 57, 64 }, 0.53 },
		}
	do
		chord(history + bar[1], bar[2], bar[3], bar[4])
	end
	local phrases = {
		{ 62, 69, 76, 74, 69, 66 },
		{ 62, 67, 74, 78, 74, 71 },
		{ 59, 66, 69, 74, 73, 69 },
		{ 55, 62, 67, 71, 74, 76 },
		{ 57, 62, 66, 69, 74, 78 },
		{ 57, 64, 69, 73 },
	}
	for bar, pitches in phrases do
		for j, pitch in pitches do
			local accent = if j == 1 or j == 4 then 0.86 else 0.62
			note(
				"pluck",
				history + 2.6 + (bar - 1) * 2.4 + (j - 1) * 0.40,
				pitch,
				0.54,
				accent * math.min(1, 0.38 + bar * 0.13)
			)
		end
	end
	for _, n in { { 2.19, 74 }, { 3.85, 69 }, { 5.60, 76 }, { 7.20, 71 }, { 9.10, 74 }, { 12.0, 78 }, { 15.49, 76 } } do
		note("glass", history + n[1], n[2], 0.75, 0.39)
	end
	cue("surf", history + 0.21, 7.1, 0.62, 0.75, 0.92)
	cue("rain", history + 2.20, 2.95, 1.36, 0.55, 0.93)
	for _, p in { { 4.53, 2.92, 3.50 }, { 4.81, 3.65, 3.06 }, { 5.13, 2.78, 3.10 } } do
		cue("bird", history + p[1], 0.15, p[2], 0.64, p[3])
	end
	cue("rope", history + 6.05, 0.33, 0.63, 0.87)
	for _, mallet in
		{
			{ 6.35, 0.81 },
			{ 6.59, 0.92 },
			{ 6.86, 1.12 },
			{ 9.10, 0.64 },
			{ 9.35, 0.76 },
			{ 9.73, 0.91 },
			{ 10.15, 0.82 },
			{ 11.08, 1.24 },
			{ 11.55, 1.10 },
			{ 11.93, 1.22 },
			{ 13.02, 0.73 },
			{ 13.37, 0.85 },
			{ 13.62, 1.05 },
		}
	do
		cue("wood", history + mallet[1], 0.16, mallet[2], 0.77)
	end
	cue("scatter", history + 7.74, 0.17, 0.59, 0.81)
	cue("strata", history + 8.55, 0.65, 0.72, 0.46, 0.53)
	cue("snap", history + 12, 0.26, 0.76, 0.54)
	cue("scatter", history + 12.35, 0.19, 0.89, 0.65)
	cue("scatter", history + 12.83, 0.2, 0.56, 0.72)
	cue("rope", history + 12.99, 0.38, 0.49, 0.91)
	cue("rail", history + 14.15, 0.10, 2.15, 0.53)
	cue("cart", history + 14.21, 0.77, 0.68, 0.61, 1.2)
	cue("lamp", history + 15.40, 0.12, 1.29, 0.66)
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
	chord(beats.arrival - 0.15, 3.82, { 50, 57, 64 }, 0.47)
	note("glass", beats.arrival + 0.53, 74, 0.93, 0.32)
	note("reed", beats.arrival + 1.69, 69, 1.92, 0.58)
	cue("wind", beats.arrival - 0.38, 4.18, 0.55, 0.25, 0.68)

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
