local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Config = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Skills = require(game:GetService("ReplicatedStorage").Shared.Skills)
local Flare = {}

-- Search the geological field without exposing blocks or generating chunks.
function Flare.findCave(geology, cell, range)
	range = range or 10
	if geology:isCave(cell) then
		return cell
	end
	local best, distance = nil, range ^ 2 + 1
	for radius = 1, range do
		for x = -radius, radius do
			for z = -radius, radius do
				local step = if math.max(math.abs(x), math.abs(z)) == radius then 1 else 2 * radius
				for y = -radius, radius, step do
					local squared = x * x + y * y + z * z
					if squared < distance then
						local candidate = cell + Vector3.new(x, y, z)
						if geology:isCave(candidate) then
							best, distance = candidate, squared
						end
					end
				end
			end
		end
		if distance <= (radius + 1) ^ 2 then
			break
		end
	end
	return best
end

function Flare.place(world, character, owned)
	owned = owned or {}
	local head = character and character:FindFirstChild("Head")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local human = character and character:FindFirstChildOfClass("Humanoid")
	if
		not world.ready
		or not head
		or not root
		or not human
		or human.Health <= 0
		or not Config.inMine(root.Position - world.origin)
	then
		return false, "Use a survey flare inside the mine"
	end
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character }
	params.RespectCanCollide = true
	local forward = root.CFrame.LookVector * (if owned.FlareThrow then 16 else 8)
	local wall = workspace:Raycast(head.Position, forward, params)
	local castEnd = if wall then wall.Position + wall.Normal * 0.4 else head.Position + forward
	local floor = workspace:Raycast(castEnd, -Vector3.yAxis * 12, params)
	if not floor then
		return false, "Face a tunnel floor within reach"
	end
	local landing = floor.Position + Vector3.yAxis * 0.6
	if not Config.inMine(landing - world.origin) then
		return false, "Aim the flare into the mine"
	end
	local cell = world.grid:cellAt(landing)
	local range = if owned.CaveEcho then 15 else 10
	local cave = Flare.findCave(world.grid.geology, cell, range)
	local stick = Instance.new("Part")
	stick.Name, stick.Size = "Survey flare", Vector3.new(0.36, 1.2, 0.36)
	stick.Material, stick.Color = Enum.Material.Neon, Color3.fromRGB(105, 248, 218)
	stick.Anchored, stick.CanCollide, stick.CanQuery, stick.CanTouch = true, false, false, false
	stick.Position, stick.Parent = head.Position, world.flares
	local toss = TweenService:Create(stick, TweenInfo.new(0.16, Enum.EasingStyle.Linear), { Position = castEnd })
	toss.Completed:Once(function(state)
		if state == Enum.PlaybackState.Completed and stick.Parent then
			TweenService
				:Create(
					stick,
					TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Position = landing }
				)
				:Play()
		end
	end)
	toss:Play()
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows, light.Parent = stick.Color, 30, 1.7, true, stick
	Debris:AddItem(stick, 30 + Skills.bonus(owned, "burn"))
	if not cave then
		return true, string.format("Flare lit • no cave within %d blocks", range)
	elseif cave == cell then
		return true, "Flare lit • you're inside a natural cave"
	end
	local direction = (world.grid:center(cave) - landing).Unit
	for i = 1, 3 do
		local spark = Instance.new("Part")
		spark.Name, spark.Shape, spark.Size = "Echo", Enum.PartType.Ball, Vector3.one * (0.32 - 0.04 * i)
		spark.Anchored, spark.CanCollide, spark.CanQuery, spark.CanTouch = true, false, false, false
		spark.Material, spark.Color = Enum.Material.Neon, stick.Color
		local start = landing + Vector3.yAxis * 0.45 + direction * i * 0.65
		spark.Position, spark.Parent = start, stick
		TweenService
			:Create(spark, TweenInfo.new(1.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false, 0.3), {
				Position = start + direction * 2.5,
				Transparency = 1,
			})
			:Play()
	end
	return true, string.format("Follow the flare pulses • cave %d blocks away", math.ceil((cave - cell).Magnitude))
end
return Flare
