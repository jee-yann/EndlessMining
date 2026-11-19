local RunService = game:GetService("RunService")
local Swing = {}
Swing.__index = Swing

local function joint(character, name, legacyName)
	local found = character:FindFirstChild(name, true) or (legacyName and character:FindFirstChild(legacyName, true))
	if found and (found:IsA("AnimationConstraint") or found:IsA("Motor6D")) then
		return found
	end
	return nil
end

function Swing.new(character)
	local shoulder = character and joint(character, "RightShoulder", "Right Shoulder")
	if not shoulder then
		return nil
	end
	return setmetatable({ shoulder = shoulder, elbow = joint(character, "RightElbow") }, Swing)
end

function Swing:restore()
	if self.shoulder.Transform == self.lastShoulder then
		self.shoulder.Transform = self.baseShoulder
	end
	if self.elbow and self.elbow.Transform == self.lastElbow then
		self.elbow.Transform = self.baseElbow
	end
end

function Swing:destroy()
	if self.afterAnimator then
		self.beforeAnimator:Disconnect()
		self.afterAnimator:Disconnect()
		self.afterAnimator = nil
		self:restore()
	end
end

function Swing:play(duration)
	-- Several short taps can contribute to a single mining cut.
	local taps = math.max(1, math.round(duration / 0.24))
	self.duration, self.period = duration, duration / taps
	self.playing = true
	if self.afterAnimator then
		return
	end
	self.phase, self.weight = 0, 0
	self.beforeAnimator = RunService.PreAnimation:Connect(function()
		self:restore()
	end)
	self.afterAnimator = RunService.PreSimulation:Connect(function(dt)
		if not self.shoulder:IsDescendantOf(workspace) then
			self:destroy()
			return
		end
		self.phase = (self.phase + dt / self.period) % 1
		self.weight = math.clamp(self.weight + (if self.playing then 14 else -11) * dt, 0, 1)
		if self.weight == 0 and not self.playing then
			self:destroy()
			return
		end
		-- Lift over the shoulder, snap through contact, then settle into the next swing.
		local arc = if self.phase < 0.55
			then self.phase / 0.55
			elseif self.phase < 0.82 then 1 - (self.phase - 0.55) / 0.27
			else 0
		local recoil = if self.phase > 0.82 then math.sin((self.phase - 0.82) / 0.18 * math.pi) else 0
		local lift = (1 - math.cos(arc * math.pi)) * 0.5
		local pitch = math.rad(39 + 94 * lift - 12 * recoil) * self.weight
		local axes = self.shoulder.C0.Rotation
		local offset =
			CFrame.Angles(pitch, math.rad(-14 * lift + 5 * recoil) * self.weight, math.rad(17 * lift - 5) * self.weight)
		self.baseShoulder = self.shoulder.Transform
		self.shoulder.Transform = axes:Inverse() * offset * axes * self.baseShoulder
		self.lastShoulder = self.shoulder.Transform
		if self.elbow then
			self.baseElbow = self.elbow.Transform
			self.elbow.Transform = self.baseElbow * CFrame.Angles(math.rad(36 * lift - 6 * recoil) * self.weight, 0, 0)
			self.lastElbow = self.elbow.Transform
		end
	end)
end

function Swing:stop()
	self.playing = false
end

function Swing.observe(player)
	local function bind(character)
		local rig
		local function changed()
			local duration = character:GetAttribute("MiningSwing")
			if duration then
				rig = rig or Swing.new(character)
				if rig then
					rig:play(duration)
				end
			elseif rig then
				rig:stop()
			end
		end
		character:GetAttributeChangedSignal("MiningSwing"):Connect(changed)
		changed()
	end
	player.CharacterAdded:Connect(bind)
	if player.Character then
		bind(player.Character)
	end
end
return Swing
