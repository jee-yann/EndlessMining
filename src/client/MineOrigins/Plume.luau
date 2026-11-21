local Assets = game:GetService("AssetService")
local Encoding = game:GetService("EncodingService")

local Plume = {}
local attempted, atlas = false, nil
local tile = Vector2.new(256, 256)

local function getAtlas()
	if not attempted then
		attempted = true
		local image
		local bound = pcall(function()
			image = Assets:CreateEditableImage({ Size = Vector2.new(512, 256) })
			if image then
				local pixels = Encoding:DecompressBuffer(
					Encoding:Base64Decode(buffer.fromstring(script.Parent.EjectaRaster.Value)),
					Enum.CompressionAlgorithm.Zstd
				)
				image:WritePixelsBuffer(Vector2.zero, Vector2.new(512, 256), pixels)
				atlas = Content.fromObject(image)
			end
		end)
		if not bound and image then
			image:Destroy()
		end
	end
	return atlas
end

local function brushCanvas(gui, kind)
	local frame = Instance.new("Frame")
	frame.Name, frame.Size, frame.BackgroundTransparency = "Fitted density", UDim2.fromScale(1, 1), 1
	frame.Parent = gui
	local brushes = {}
	for i, stroke in require(script.Parent.EjectaBrushes)[kind] do
		local dab = Instance.new("ImageLabel")
		dab.Name, dab.AnchorPoint, dab.BackgroundTransparency = "Volcanic pigment", Vector2.one * 0.5, 1
		dab.Position, dab.Size = UDim2.fromScale(stroke[1], stroke[2]), UDim2.fromScale(stroke[3], stroke[4])
		dab.Rotation, dab.ZIndex = stroke[5], i
		dab.Image, dab.ImageColor3 =
			"rbxasset://textures/particles/explosion01_implosion_main.dds", Color3.fromHex(stroke[7])
		dab.ImageTransparency, dab.Parent = 1 - stroke[6], frame
		brushes[i] = { label = dab, alpha = stroke[6] }
	end
	return { canvas = frame, brushes = brushes }
end

function Plume.mount(anchor, kind)
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.AlwaysOnTop, gui.LightInfluence = "Ejecta density", false, 0.12
	gui.Brightness = if kind == "melt" then 1.4 else 0.94
	gui.Enabled, gui.Parent = false, anchor
	local texture = getAtlas()
	if not texture then
		return gui, brushCanvas(gui, kind)
	end
	local image = Instance.new("ImageLabel")
	image.Name, image.Size, image.BackgroundTransparency = "Filtered volcanic vapor", UDim2.fromScale(1, 1), 1
	image.ImageContent = texture
	image.ImageRectOffset = if kind == "melt" then Vector2.zero else Vector2.new(256, 0)
	image.ImageRectSize, image.Parent = tile, gui
	return gui, { canvas = image, image = image }
end

function Plume.show(gui, render, rotation, opacity)
	gui.Enabled = opacity > 0.008
	if not gui.Enabled then
		return
	end
	render.canvas.Rotation = rotation
	if render.image then
		render.image.ImageTransparency = 1 - math.clamp(opacity, 0, 1)
	else
		-- Some clients skip CanvasGroup compositing inside a world billboard.
		-- Scale optical density per brush for correct overlapping transparency.
		local level = math.clamp(math.round(opacity * 48), 0, 48)
		if level ~= render.last then
			render.last = level
			local density = level / 48
			for _, dab in render.brushes do
				dab.label.ImageTransparency = 1 - dab.alpha * density
			end
		end
	end
end

return Plume
