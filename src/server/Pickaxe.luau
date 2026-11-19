local Ores = require(game.ReplicatedStorage.Shared.Ores)
local Pickaxe = {}
local grip = CFrame.new(0.36, -0.22, -0.32) * CFrame.Angles(math.rad(-20), 0, math.rad(-58))
local function component(model, root, name, size, offset, color)
	local part = Instance.new("Part")
	part.Name, part.Size, part.Color, part.Material = name, size, color, Enum.Material.Plastic
	part.Massless, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
	part.CFrame = root.CFrame * offset
	part.Parent = model
	local joint = Instance.new("WeldConstraint")
	joint.Part0, joint.Part1, joint.Parent = root, part, part
	return part
end
function Pickaxe.equip(player, char)
	local humanoid = char:WaitForChild("Humanoid", 8)
	if not humanoid then
		return
	end
	local hand = char:WaitForChild(if humanoid.RigType == Enum.HumanoidRigType.R15 then "RightHand" else "Right Arm", 8)
	if not hand or player.Character ~= char or char:FindFirstChild("Harbor pick") then
		return
	end
	local model = Instance.new("Model")
	model.Name = "Harbor pick"
	local handle = Instance.new("Part")
	handle.Name, handle.Size, handle.Color = "Handle", Vector3.new(0.19, 1.9, 0.21), Color3.fromRGB(176, 106, 56)
	handle.Massless, handle.CanCollide, handle.CanTouch, handle.CanQuery = true, false, false, false
	local offset = if humanoid.RigType == Enum.HumanoidRigType.R6 then CFrame.new(0, -0.63, 0) * grip else grip
	handle.CFrame = hand.CFrame * offset
	handle.Parent = model
	local pale = Color3.fromRGB(211, 234, 241)
	component(model, handle, "Steel", Vector3.new(1.05, 0.25, 0.28), CFrame.new(0, 0.95, 0), pale)
	for _, side in { -1, 1 } do
		component(
			model,
			handle,
			"Beak",
			Vector3.new(0.54, 0.19, 0.22),
			CFrame.new(side * 0.67, 0.85, 0) * CFrame.Angles(0, 0, math.rad(-side * 25)),
			pale
		)
	end
	local socket = component(
		model,
		handle,
		"Socket",
		Vector3.new(0.34, 0.42, 0.36),
		CFrame.new(0, 0.90, 0),
		Color3.fromRGB(255, 201, 72)
	)
	component(
		model,
		handle,
		"Grip tape",
		Vector3.new(0.215, 0.48, 0.23),
		CFrame.new(0, -0.54, 0),
		Color3.fromRGB(42, 67, 80)
	)
	local motor = Instance.new("Motor6D")
	motor.Name, motor.Part0, motor.Part1, motor.C0, motor.Parent = "Grip", hand, handle, offset, handle
	handle:SetAttribute("Rest", offset)
	model.PrimaryPart, model.Parent = handle, char
	local function update()
		local level = player:GetAttribute("Power") or 1
		socket.Color = if level == 1 then Color3.fromRGB(255, 201, 72) else Ores.list[level + 1].color
	end
	update()
	local changed = player:GetAttributeChangedSignal("Power"):Connect(update)
	model.Destroying:Once(function()
		changed:Disconnect()
	end)
end
return Pickaxe
