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

function Swing:pose(t)
	local rise = math.sin(math.min(t / 0.72, 1) * math.pi * 0.5)
	local strike = math.clamp((t - 0.72) / 0.28, 0, 1) ^ 2
	local axes = self.shoulder.C0.Rotation
	local lift = CFrame.Angles(math.rad(150 * rise - 117 * strike), 0, math.rad(9 * rise))
	self.shoulderOffset = axes:Inverse() * lift * axes
	self.elbowOffset = CFrame.Angles(math.rad(30 * rise * (1 - strike)), 0, 0)
	if self.afterAnimator then
		return
	end
	-- Remove our previous layer before the animator runs, including on throttled rigs.
	self.beforeAnimator = RunService.PreAnimation:Connect(function()
		self:restore()
	end)
	self.afterAnimator = RunService.PreSimulation:Connect(function()
		self.baseShoulder = self.shoulder.Transform
		self.shoulder.Transform = self.shoulderOffset * self.baseShoulder
		self.lastShoulder = self.shoulder.Transform
		if self.elbow then
			self.baseElbow = self.elbow.Transform
			self.elbow.Transform = self.baseElbow * self.elbowOffset
			self.lastElbow = self.elbow.Transform
		end
	end)
end

function Swing:reset()
	if self.afterAnimator then
		self.beforeAnimator:Disconnect()
		self.afterAnimator:Disconnect()
		self.afterAnimator = nil
		self:restore()
	end
end
return Swing
