local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local function rock(folder)
	local model = Instance.new("Model")
	model.Name = "Pocket rock"
	local function piece(name, size, at, color, turn)
		local part = Instance.new("Part")
		part.Name, part.Size, part.Color = name, size, color
		part.Material = Enum.Material.Slate
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
		part.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(turn or 0))
		part.Parent = model
		return part
	end
	local stone = Color3.fromRGB(137, 147, 163)
	local face = piece("River stone", Vector3.new(1.55, 0.92, 1.12), Vector3.zero, stone, -4)
	piece("Crown", Vector3.new(1.16, 0.35, 0.84), Vector3.new(-0.09, 0.46, 0.01), Color3.fromRGB(159, 170, 183), -7)
	for _, side in { -1, 1 } do
		piece(
			"Foot",
			Vector3.new(0.46, 0.22, 0.55),
			Vector3.new(side * 0.42, -0.46, -0.05),
			Color3.fromRGB(85, 96, 116)
		)
		piece("Eye", Vector3.new(0.16, 0.22, 0.12), Vector3.new(side * 0.35, 0.1, -0.60), Color3.fromRGB(30, 38, 54))
		piece("Glint", Vector3.one * 0.067, Vector3.new(side * 0.35 - 0.025, 0.15, -0.67), Color3.new(1, 1, 1))
	end
	piece("Smile", Vector3.new(0.22, 0.075, 0.08), Vector3.new(0, -0.10, -0.59), Color3.fromRGB(51, 54, 66))
	local tag = Instance.new("BillboardGui")
	tag.Name, tag.Size, tag.StudsOffsetWorldSpace, tag.MaxDistance =
		"Pet name", UDim2.fromOffset(85, 15), Vector3.yAxis, 22
	tag.Adornee, tag.Parent = face, model
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency, label.Size, label.TextSize, label.Font =
		1, UDim2.fromScale(1, 1), 12, Enum.Font.FredokaOne
	label.TextColor3, label.TextStrokeTransparency, label.Parent = Color3.fromRGB(255, 231, 188), 0.25, tag
	model.PrimaryPart = face
	model.Parent = folder
	return model, label
end
return function()
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Rock companions", workspace
	local pets = {}
	local ray = RaycastParams.new()
	ray.RespectCanCollide = true
	local function clear(p)
		if pets[p] then
			pets[p].model:Destroy()
			pets[p] = nil
		end
	end
	Players.PlayerRemoving:Connect(clear)
	Run.RenderStepped:Connect(function(dt)
		local eye = workspace.CurrentCamera
		if not eye then
			return
		end
		local now = os.clock()
		for _, p in Players:GetPlayers() do
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if p:GetAttribute("Pet") ~= "Rock" or not root or (root.Position - eye.CFrame.Position).Magnitude > 125 then
				clear(p)
				continue
			end
			local pet = pets[p]
			if not pet then
				local model, label = rock(folder)
				pet = { model = model, label = label, at = root.CFrame, nextProbe = 0 }
				pets[p] = pet
			end
			pet.label.Text = p:GetAttribute("PetName") or "Pebble"
			if now >= pet.nextProbe then
				pet.nextProbe = now + 0.1
				ray.FilterDescendantsInstances = { p.Character, folder }
				local from = root.Position - Vector3.yAxis * 0.35
				local delta = root.CFrame:VectorToWorldSpace(Vector3.new(1.9, 0, 2.6))
				local wall = workspace:Spherecast(from, 0.72, delta, ray)
				local at = from + delta.Unit * (if wall then math.max(0, wall.Distance - 0.12) else delta.Magnitude)
				local ground = workspace:Raycast(at + Vector3.yAxis * 0.25, -Vector3.yAxis * 4, ray)
				pet.goal = Vector3.new(at.X, if ground then ground.Position.Y + 0.70 else at.Y - 0.6, at.Z)
			end
			local t = now * 5 + p.UserId % 11
			local goal = pet.goal + Vector3.yAxis * (0.08 + 0.10 * math.sin(t))
			local target = CFrame.new(goal) * root.CFrame.Rotation * CFrame.Angles(0, 0, 0.055 * math.sin(t))
			local distance = (pet.at.Position - goal).Magnitude
			if distance > 16 then
				pet.at = target
			else
				pet.at = pet.at:Lerp(target, 1 - math.exp(-dt * 9))
			end
			pet.model:PivotTo(pet.at)
		end
	end)
end
