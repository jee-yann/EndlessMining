local paint = require(script.Parent.EjectaPaint)
local Plume = {}

local function palette(hex)
	local colors = {}
	for i = 0, 15 do
		local u = i / 15 * (#hex - 1)
		local j = math.min(#hex - 1, math.floor(u) + 1)
		colors[i] = Color3.fromHex(hex[j]):Lerp(Color3.fromHex(hex[j + 1]), math.min(1, u - (j - 1)))
	end
	return colors
end

local colors = {
	melt = palette({ "553B4D", "A24947", "EC7051", "FFAD5E", "FFE5A1", "FFF1BF" }),
	ash = palette({ "524452", "695D68", "8E7A7E", "AD9690", "CDB3A0", "E1C7AB" }),
}
local templates = {}

-- Build each painted cloud once. Splitting a scanline at the midpoint keeps
-- both color and density below Roblox's per-sequence keypoint limit.
local function template(kind)
	if templates[kind] then
		return templates[kind]
	end
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.AlwaysOnTop, gui.LightInfluence = "Painted " .. kind, false, 0
	gui.Brightness = if kind == "melt" then 1.45 else 0.96
	local canvas = Instance.new("CanvasGroup")
	canvas.Name, canvas.BackgroundTransparency, canvas.BorderSizePixel = "Density", 1, 0
	canvas.Size, canvas.Parent = UDim2.fromScale(1, 1), gui
	local rows = paint[kind]
	for y, row in rows do
		for segment = 0, 1 do
			local opacity, shade = {}, {}
			local ink = false
			for i = 0, 16 do
				local j = 1 + 2 * (segment * 16 + i)
				local alpha = tonumber(row:sub(j, j), 16) / 15
				local light = tonumber(row:sub(j + 1, j + 1), 16)
				ink = ink or alpha > 0
				table.insert(opacity, NumberSequenceKeypoint.new(i / 16, 1 - alpha))
				table.insert(shade, ColorSequenceKeypoint.new(i / 16, colors[kind][light]))
			end
			if ink then
				local band = Instance.new("Frame")
				band.Name, band.BackgroundColor3, band.BorderSizePixel = "Scan", Color3.new(1, 1, 1), 0
				band.Position = UDim2.fromScale(0.5 * segment, (y - 1) / #rows)
				band.Size = UDim2.fromScale(0.5, 1 / #rows)
				local grad = Instance.new("UIGradient")
				grad.Color, grad.Transparency = ColorSequence.new(shade), NumberSequence.new(opacity)
				grad.Parent, band.Parent = band, canvas
			end
		end
	end
	templates[kind] = gui
	return gui
end

function Plume.mount(anchor, kind)
	local gui = template(kind):Clone()
	gui.Enabled = false
	gui.Parent = anchor
	local canvas = gui.Density
	return gui, { canvas = canvas, bands = canvas:GetChildren(), level = -1 }
end

-- Billboard rendering on some clients does not composite CanvasGroup opacity.
-- Modulate its gradient bands directly and remove the card at zero coverage.
function Plume.show(gui, ink, rotation, opacity)
	local level = math.clamp(math.floor(opacity * 18 + 0.5), 0, 18)
	gui.Enabled = level > 0
	if level > 0 then
		ink.canvas.Rotation = rotation
	end
	if level ~= ink.level then
		ink.level = level
		if level > 0 then
			for _, band in ink.bands do
				band.BackgroundTransparency = 1 - level / 18
			end
		end
	end
end

return Plume
