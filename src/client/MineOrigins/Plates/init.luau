local Assets = game:GetService("AssetService")
local Encoding = game:GetService("EncodingService")
local Plates = {}
Plates.__index = Plates
local width, height = 552, 368

local function texture(pixels)
	local image = Assets:CreateEditableImage({ Size = Vector2.new(width, height) })
	if not image then
		return
	end
	local label = Instance.new("ImageLabel")
	local ok = pcall(function()
		local rgba = buffer.create(width * height * 4)
		for i = 0, width * height - 1 do
			local index = buffer.readu8(pixels, 1024 + i)
			buffer.writeu32(rgba, i * 4, buffer.readu32(pixels, index * 4))
		end
		image:WritePixelsBuffer(Vector2.zero, Vector2.new(width, height), rgba)
		label.ImageContent = Content.fromObject(image)
	end)
	if ok then
		return label, image
	end
	label:Destroy()
	image:Destroy()
end

-- Some published places disallow editable images. Sample the same painting
-- into native GUI gradients there, including the hand and the dark lighthouse.
local function paper(pixels)
	local group = Instance.new("CanvasGroup")
	local palette = {}
	for index = 0, 255 do
		local offset = index * 4
		palette[index] = Color3.fromRGB(
			buffer.readu8(pixels, offset),
			buffer.readu8(pixels, offset + 1),
			buffer.readu8(pixels, offset + 2)
		)
	end
	local cols, rows = 140, 92
	for y = 0, rows - 1 do
		local row = math.floor((y + 0.5) * height / rows) * width
		for start = 0, cols - 1, 20 do
			local strip = Instance.new("Frame")
			strip.Size, strip.Position = UDim2.new(20 / cols, 1, 1 / rows, 1), UDim2.fromScale(start / cols, y / rows)
			strip.BackgroundColor3, strip.BorderSizePixel = Color3.new(1, 1, 1), 0
			local stops = {}
			for dx = 0, 19 do
				local x = math.floor((start + dx + 0.5) * width / cols)
				table.insert(stops, ColorSequenceKeypoint.new(dx / 19, palette[buffer.readu8(pixels, 1024 + row + x)]))
			end
			local gradient = Instance.new("UIGradient")
			gradient.Color, gradient.Parent = ColorSequence.new(stops), strip
			strip.Parent = group
		end
	end
	return group
end

function Plates.new(board)
	return setmetatable({ board = board, visible = {}, editable = true }, Plates)
end
function Plates:get(name)
	if self.visible[name] then
		return self.visible[name]
	end
	local bytes = Encoding:DecompressBuffer(
		Encoding:Base64Decode(buffer.fromstring(script:WaitForChild(name).Value)),
		Enum.CompressionAlgorithm.Zstd
	)
	local label, image
	if self.editable then
		local ok
		ok, label, image = pcall(texture, bytes)
		self.editable = ok and label ~= nil
	end
	if not self.editable then
		label = paper(bytes)
	end
	label.Name, label.Size, label.BackgroundTransparency = name, UDim2.fromScale(1, 1), 1
	label.Parent = self.board
	local plate = { label = label, image = image }
	self.visible[name] = plate
	return plate
end
function Plates:draw(first, second, mix)
	-- Keep at most the two sides of a dissolve in the graphics memory budget.
	for name, plate in self.visible do
		if name ~= first and name ~= second then
			plate.label:Destroy()
			if plate.image then
				plate.image:Destroy()
			end
			self.visible[name] = nil
		end
	end
	for i, name in { first, second } do
		local plate = self:get(name)
		plate.label.ZIndex = i
		local alpha = if i == 2 then 1 - mix else 0
		if plate.image then
			plate.label.ImageTransparency = alpha
		else
			plate.label.GroupTransparency = alpha
		end
	end
end
return Plates
