local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Input = game:GetService("UserInputService")

local Audio = {}
local bus = Instance.new("Folder")
bus.Name, bus.Parent = "Harbor audio", SoundService
local function sound(name, asset, volume, pitch)
	local s = Instance.new("Sound")
	s.Name, s.SoundId, s.Volume, s.PlaybackSpeed, s.Parent = name, asset, volume, pitch, bus
	return s
end

-- Anthony Mawer, Prima Bossa Nova, from APM's Roblox Creator Store catalog.
local music = sound("Prima Bossa Nova", "rbxassetid://1837070127", 0, 1)
music.Looped = true
local enabled = true
local fade
local function fadeMusic(volume)
	if fade then
		fade:Cancel()
	end
	fade = TweenService:Create(music, TweenInfo.new(0.3), { Volume = volume })
	fade:Play()
end
music:Play()
fadeMusic(0.17)

function Audio.toggleMusic()
	enabled = not enabled
	if enabled then
		if not music.IsPlaying then
			music:Resume()
		end
		fadeMusic(0.17)
	else
		fadeMusic(0)
		fade.Completed:Once(function()
			if not enabled then
				music:Pause()
			end
		end)
	end
	return enabled
end

local pop = "rbxassetid://15675055424" -- Roblox UI Cute Pop
local voices = {
	Hover = sound("Hover pip", pop, 0.055, 1.52),
	Open = sound("Menu bubble", pop, 0.19, 1.13),
	Close = sound("Close bubble", "rbxassetid://15675081158", 0.15, 1.1),
	Buy = sound("Workshop pop", pop, 0.17, 1.18),
	Job = sound("Job pop", pop, 0.16, 1.31),
	Lift = sound("Lift pop", pop, 0.16, 0.97),
	Mine = sound("Grip pop", pop, 0.09, 0.78),
	Select = sound("Switch pop", pop, 0.15, 1.21),
	Reward = sound("Reward bubbles", pop, 0.18, 1.26),
}
for _, voice in voices do
	if voice.SoundId == pop then
		voice.PlaybackRegionsEnabled = true
		voice.PlaybackRegion = NumberRange.new(0, 0.24)
	end
end
local function play(key)
	local voice = voices[key]
	voice.TimePosition = 0
	voice:Play()
end
function Audio.reward(pitch)
	play("Open")
	task.delay(0.10, function()
		voices.Reward.PlaybackSpeed = pitch
		play("Reward")
	end)
end
-- Each ore has its own short attack. Gem finds finish with a rising pop cadence.
local signatures = {
	{ "Stone", 9118628948, 0.18, 1.12, 0.30 },
	{ "Coal", 9125869505, 0.16, 1.20, 0.38 },
	{ "Copper", 9118608006, 0.19, 1.45, 0.33 },
	{ "Iron", 9116673915, 0.14, 0.95, 0.40 },
	{ "Gold", 9113849492, 0.19, 1.18, 0.48 },
	{ "Diamond", 9116394545, 0.20, 1.34, 0.70 },
	{ "Emerald", 9116395089, 0.22, 1.08, 0.85 },
}
local oreVoices = {}
for _, cue in signatures do
	local s = sound(cue[1] .. " break", "rbxassetid://" .. cue[2], cue[3], cue[4])
	s.PlaybackRegionsEnabled = true
	s.PlaybackRegion = NumberRange.new(0, cue[5])
	oreVoices[cue[1]] = s
end
local notes = {}
for i = 1, 3 do
	local voice = voices.Reward:Clone()
	voice.Name, voice.PlaybackSpeed, voice.Parent = "Discovery note " .. i, 1.15 * 2 ^ ((i * 4) / 12), bus
	notes[i] = voice
end
local flourishEnd, flourishRank, flourishSerial = 0, 0, 0
function Audio.ore(loot)
	local delay, best = 0, 0
	for rank, cue in signatures do
		if loot[cue[1]] then
			best = rank
			local voice = oreVoices[cue[1]]
			task.delay(delay, function()
				voice.TimePosition = 0
				voice:Play()
			end)
			delay += 0.025
		end
	end
	local now = os.clock()
	if best < 5 or (now < flourishEnd and best <= flourishRank) then
		return
	end
	local noteCount = best - 4
	flourishRank, flourishEnd, flourishSerial = best, now + delay + noteCount * 0.09, flourishSerial + 1
	local serial = flourishSerial
	for note = 1, noteCount do
		task.delay(delay + note * 0.09, function()
			if flourishSerial == serial then
				local chime = notes[note]
				chime:Stop()
				chime:Play()
			end
		end)
	end
end
local lastHover = 0
function Audio.bind(button, cue)
	button.MouseEnter:Connect(function()
		if
			button.Interactable
			and Input.PreferredInput == Enum.PreferredInput.KeyboardAndMouse
			and os.clock() - lastHover > 0.09
		then
			lastHover = os.clock()
			play("Hover")
		end
	end)
	if cue == "Mine" then
		button.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				play(cue)
			end
		end)
	else
		button.Activated:Connect(function()
			play(cue or "Open")
		end)
	end
end
return Audio
