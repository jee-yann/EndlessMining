local Shared = game:GetService("ReplicatedStorage").Shared
local Art, Ores = require(Shared.MineralRelief), require(Shared.Ores)
local touch = game:GetService("UserInputService").TouchEnabled
local normals = Enum.NormalId:GetEnumItems()

return function()
	local live = {}
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local budget = if touch then 16 else 24
	while task.wait(0.32) do
		local camera = workspace.CurrentCamera
		local island = workspace:FindFirstChild("CitrineCove")
		local grid = island and island:FindFirstChild("MineBlocks")
		local candidates = {}
		if camera and grid then
			local eye = camera.CFrame.Position
			params.FilterDescendantsInstances = { grid }
			for _, block in workspace:GetPartBoundsInRadius(eye, 52, params) do
				if block.Parent ~= grid then
					continue
				end
				local mineral = Art.matrix[block.Name] ~= nil
				local mask = block:GetAttribute(if mineral then "OpenFaces" else "CalciteFaces") or 0
				if mask == 0 then
					continue
				end
				for _, face in normals do
					if not bit32.btest(mask, 2 ^ face.Value) then
						continue
					end
					local normal = Vector3.FromNormalId(face)
					local at = block.Position + normal * block.Size.X * 0.5
					local delta = eye - at
					if normal:Dot(delta) <= 0 or camera.CFrame.LookVector:Dot(-delta.Unit) < -0.24 then
						continue
					end
					table.insert(
						candidates,
						{
							block = block,
							face = face,
							normal = normal,
							at = at,
							name = if mineral then block.Name else "Calcite",
							distance = delta.Magnitude,
						}
					)
				end
			end
		end
		table.sort(candidates, function(a, b)
			return a.distance < b.distance
		end)
		local keep, added, lamps = {}, 0, 0
		for i = 1, math.min(#candidates, budget) do
			local c = candidates[i]
			local faces = live[c.block]
			if not faces then
				faces = {}
				live[c.block] = faces
			end
			local model = faces[c.face]
			if not model and added < 4 then
				local axis = if math.abs(c.normal.Y) > 0.5 then Vector3.zAxis else Vector3.yAxis
				local cf = CFrame.lookAt(c.at, c.at - c.normal, axis)
				local p = c.block.Position
				local turn = (
					math.floor(p.X / 6) * 7
					+ math.floor(p.Y / 6) * 13
					+ math.floor(p.Z / 6) * 3
					+ c.face.Value
				) % 4
				model = Art.face(c.name, cf * CFrame.Angles(0, 0, turn * math.pi / 2))
				model.Parent, faces[c.face] = c.block, model
				added += 1
			end
			if model then
				keep[model] = true
				local ore = Ores.byName[c.name]
				if not ore or ore.hardness < 5 then continue end
				local lit = c.distance < 20 and lamps < 2
				local light = model:FindFirstChild("Mineral glow", true)
				if lit then
					lamps += 1
					if not light then
						light = Instance.new("PointLight")
						light.Name, light.Color, light.Range, light.Brightness = "Mineral glow", ore.color, 7, 0.33
						light.Parent = model:FindFirstChildWhichIsA("BasePart")
					end
				elseif light then
					light:Destroy()
				end
			end
		end
		for block, faces in live do
			for face, model in faces do
				if not keep[model] then
					model:Destroy()
					faces[face] = nil
				end
			end
			if not next(faces) then
				live[block] = nil
			end
		end
	end
end
