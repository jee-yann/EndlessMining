local RunService = game:GetService("RunService")
local Audio = require(script.Parent.HarborAudio)
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
	return setmetatable(
		{
			character = character,
			shoulder = shoulder,
			elbow = joint(character, "RightElbow"),
			waist = joint(character, "Waist"),
		},
		Swing
	)
end

function Swing:restore()
	if self.shoulder.Transform == self.lastShoulder then
		self.shoulder.Transform = self.baseShoulder
	end
	if self.elbow and self.elbow.Transform == self.lastElbow then
		self.elbow.Transform = self.baseElbow
	end
	if self.waist and self.waist.Transform == self.lastWaist then
		self.waist.Transform = self.baseWaist
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
		local nextPhase = self.phase + dt / self.period
		local contact = (self.phase < 0.82 and nextPhase >= 0.82) or nextPhase >= 1.82
		self.phase = nextPhase % 1
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
		local root = self.character:FindFirstChild("HumanoidRootPart")
		if self.playing and contact and root then
			Audio.dig(self.ore or self.character:GetAttribute("MiningOre"), root)
		end
		local target = self.target or self.character:GetAttribute("MiningTarget")
		local aim = CFrame.identity
		if root and target then
			local dir = root.CFrame:PointToObjectSpace(target)
			local yaw = math.clamp(math.atan2(-dir.X, -dir.Z), -1.1, 1.1)
			local tilt = math.clamp(math.atan2(dir.Y, Vector2.new(dir.X, dir.Z).Magnitude), -0.65, 0.65)
			aim = CFrame.Angles(0, yaw * self.weight, 0) * CFrame.Angles(tilt * self.weight, 0, 0)
		end
		if self.waist then
			self.baseWaist = self.waist.Transform
			self.waist.Transform = self.baseWaist * aim
			self.lastWaist = self.waist.Transform
			aim = CFrame.identity
		end
		local offset =
			CFrame.Angles(pitch, math.rad(-14 * lift + 5 * recoil) * self.weight, math.rad(17 * lift - 5) * self.weight)
		self.baseShoulder = self.shoulder.Transform
		self.shoulder.Transform = axes:Inverse() * aim * offset * axes * self.baseShoulder
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
