local Tags = game:GetService("CollectionService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Art, Ores = require(Shared.MineralRelief), require(Shared.Ores)
local Config = require(Shared.GameConfig)
local normals = Enum.NormalId:GetEnumItems()

local function faceCFrame(block, face)
	local normal = Vector3.FromNormalId(face)
	local at = block.Position + normal * block.Size * 0.5
	local axis = if normal.Y ~= 0 then Vector3.zAxis else Vector3.yAxis
	local p = (block.Position / Config.Cell):Floor()
	local turn = (p.X * 7 + p.Y * 13 + p.Z * 3 + face.Value) % 4
	return CFrame.lookAt(at, at - normal, axis) * CFrame.Angles(0, 0, turn * math.pi / 2)
end

return function()
	local folders, luminous, lights = {}, {}, {}

	local function removeFace(model)
		luminous[model], lights[model] = nil, nil
		model:Destroy()
	end

	local function watchFolder(folder)
		if folders[folder] or not folder:IsDescendantOf(workspace) then
			return
		end
		local blocks = {}
		local function watchBlock(block)
			local mineral = Art.matrix[block.Name] ~= nil
			if blocks[block] or not block:IsA("BasePart") or not (mineral or block.Name == "Stone") then
				return
			end
			local name = if mineral then block.Name else "Calcite"
			local ore = Ores.byName[name]
			local faces = {}
			local function refresh()
				local mask = block:GetAttribute("OpenFaces") or 0
				if not mineral then
					mask = bit32.band(mask, block:GetAttribute("CalciteFaces") or 0)
				end
				for _, face in normals do
					local model = faces[face]
					if bit32.btest(mask, 2 ^ face.Value) then
						if not model then
							local cf = faceCFrame(block, face)
							model = Art.face(name, cf)
							model.Parent, faces[face] = block, model
							if ore and ore.hardness >= 5 then
								luminous[model] = { position = cf.Position, color = ore.color }
							end
						end
					elseif model then
						removeFace(model)
						faces[face] = nil
					end
				end
			end
			local exposed = block:GetAttributeChangedSignal("OpenFaces"):Connect(refresh)
			local calcite = not mineral and block:GetAttributeChangedSignal("CalciteFaces"):Connect(refresh)
			blocks[block] = function()
				exposed:Disconnect()
				if calcite then
					calcite:Disconnect()
				end
				for _, model in faces do
					removeFace(model)
				end
			end
			refresh()
		end
		local function forgetBlock(block)
			if blocks[block] then
				blocks[block]()
				blocks[block] = nil
			end
		end
		local added = folder.ChildAdded:Connect(watchBlock)
		local removed = folder.ChildRemoved:Connect(forgetBlock)
		folders[folder] = function()
			added:Disconnect()
			removed:Disconnect()
			for block in blocks do
				forgetBlock(block)
			end
		end
		for _, block in folder:GetChildren() do
			watchBlock(block)
		end
	end

	Tags:GetInstanceAddedSignal(Config.MineBlockTag):Connect(watchFolder)
	Tags:GetInstanceRemovedSignal(Config.MineBlockTag):Connect(function(folder)
		if folders[folder] then
			folders[folder]()
			folders[folder] = nil
		end
	end)
	for _, folder in Tags:GetTagged(Config.MineBlockTag) do
		watchFolder(folder)
	end

	-- Only the two closest gem faces cast light. Their relief stays on the rock.
	while task.wait(0.32) do
		local camera = workspace.CurrentCamera
		if not camera then
			continue
		end
		local first, second
		local nearest, runnerUp = 20, 20
		for model, gem in luminous do
			local distance = (camera.CFrame.Position - gem.position).Magnitude
			if distance < nearest then
				second, runnerUp, first, nearest = first, nearest, model, distance
			elseif distance < runnerUp then
				second, runnerUp = model, distance
			end
		end
		for model, light in lights do
			if model ~= first and model ~= second then
				light:Destroy()
				lights[model] = nil
			end
		end
		for _, model in { first, second } do
			if not lights[model] then
				local light = Instance.new("PointLight")
				light.Name, light.Color, light.Range, light.Brightness = "Mineral glow", luminous[model].color, 7, 0.33
				light.Parent = model:FindFirstChildWhichIsA("BasePart")
				lights[model] = light
			end
		end
	end
end
