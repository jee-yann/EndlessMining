local Ores = require(game.ReplicatedStorage.Shared.Ores)
local Pickaxe = {}
-- RightGripAttachment points along the hand's tool axis. Match it at the wrapped
-- part of the shaft, with the steel head reaching forward from the palm at rest.
local tapeY = -0.54
local handleGrip = CFrame.new(0, tapeY, 0) * CFrame.Angles(0, math.rad(90), 0)
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
	if not hand or player.Character ~= char then
		return
	end
	local existing = char:FindFirstChild("Harbor pick")
	if existing then
		local oldGrip = existing:FindFirstChild("Grip", true)
		if oldGrip and oldGrip.Part0 == hand then
			return
		end
		existing:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "Harbor pick"
	local handle = Instance.new("Part")
	handle.Name, handle.Size, handle.Color = "Handle", Vector3.new(0.19, 1.9, 0.21), Color3.fromRGB(176, 106, 56)
	handle.Massless, handle.CanCollide, handle.CanTouch, handle.CanQuery = true, false, false, false
	local palm = hand:FindFirstChild("RightGripAttachment")
	local function palmOffset()
		return if palm then palm.CFrame else CFrame.new(0, -hand.Size.Y * 0.4, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
	end
	handle.CFrame = hand.CFrame * palmOffset() * handleGrip:Inverse()
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
		CFrame.new(0, tapeY, 0),
		Color3.fromRGB(42, 67, 80)
	)
	local grip = Instance.new("Weld")
	grip.Name, grip.Part0, grip.Part1 = "Grip", hand, handle
	grip.C0, grip.C1, grip.Parent = palmOffset(), handleGrip, handle
	local scaleChanged
	local function bindPalm()
		palm = hand:FindFirstChild("RightGripAttachment")
		if scaleChanged then
			scaleChanged:Disconnect()
		end
		grip.C0 = palmOffset()
		local changed = if palm then palm:GetPropertyChangedSignal("CFrame") else hand:GetPropertyChangedSignal("Size")
		scaleChanged = changed:Connect(function()
			grip.C0 = palmOffset()
		end)
	end
	local function attachmentChanged(child)
		if child.Name == "RightGripAttachment" then
			bindPalm()
		end
	end
	bindPalm()
	local added = hand.ChildAdded:Connect(attachmentChanged)
	local removed = hand.ChildRemoved:Connect(attachmentChanged)
	model.PrimaryPart, model.Parent = handle, char
	local function update()
		local level = player:GetAttribute("Power") or 1
		socket.Color = if level == 1 then Color3.fromRGB(255, 201, 72) else Ores.list[level + 1].color
	end
	update()
	local changed = player:GetAttributeChangedSignal("Power"):Connect(update)
	model.Destroying:Once(function()
		changed:Disconnect()
		scaleChanged:Disconnect()
		added:Disconnect()
		removed:Disconnect()
	end)
end
return Pickaxe
