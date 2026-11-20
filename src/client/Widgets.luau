local TweenService = game:GetService("TweenService")
local Audio = require(script.Parent.HarborAudio)
local W = {}
local rgb = Color3.fromRGB
W.ink, W.panel, W.card, W.line = rgb(18, 24, 44), rgb(30, 41, 65), rgb(48, 61, 89), rgb(77, 95, 127)
W.white, W.muted, W.gold, W.aqua, W.green =
	rgb(255, 253, 245), rgb(206, 220, 234), rgb(255, 209, 76), rgb(88, 224, 252), rgb(110, 236, 150)
W.pink, W.violet, W.orange = rgb(255, 128, 191), rgb(186, 149, 255), rgb(255, 165, 90)
W.ruby, W.ocean, W.grape = rgb(183, 63, 48), rgb(9, 115, 150), rgb(121, 66, 177)
local off = UDim2.fromOffset
function W.round(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius, c.Parent = UDim.new(0, r), obj
end
function W.stroke(obj, color, width)
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode, s.Color, s.Thickness, s.Parent = Enum.ApplyStrokeMode.Border, color, width, obj
	return s
end
function W.gradient(obj, top, bottom, angle)
	local g = Instance.new("UIGradient")
	g.Color, g.Rotation, g.Parent = ColorSequence.new(top, bottom), angle or 90, obj
	return g
end
function W.frame(parent, name, x, y, w, h, color, r)
	local f = Instance.new("Frame")
	f.Name, f.Position, f.Size, f.BackgroundColor3, f.BorderSizePixel = name, off(x, y), off(w, h), color, 0
	if r then
		W.round(f, r)
	end
	f.Parent = parent
	return f
end
function W.fadeGroup(parent, name, width, height)
	local group = Instance.new("CanvasGroup")
	group.Name, group.Size = name, off(width, height)
	group.BackgroundTransparency, group.BorderSizePixel, group.Parent = 1, 0, parent
	return group
end
function W.text(parent, value, x, y, w, h, size, color, left)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency, l.Text, l.TextSize, l.Font, l.TextColor3 =
		1, value, size, Enum.Font.BuilderSansBold, color
	l.TextXAlignment = if left then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
	l.Position, l.Size, l.Parent = off(x, y), off(w, h), parent
	return l
end
function W.title(parent, value, x, y, w, h, size, color, left)
	local l = W.text(parent, value, x, y, w, h, size, color, left)
	l.Font = Enum.Font.FredokaOne
	return l
end
function W.enamel(obj, top, bottom)
	obj.BackgroundColor3 = Color3.new(1, 1, 1)
	return W.gradient(obj, top, bottom, 34)
end
function W.outlineText(label, thickness)
	if thickness then
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode, stroke.Color, stroke.Thickness = Enum.ApplyStrokeMode.Contextual, W.ink, thickness
		stroke.Parent = label
	else
		label.TextStrokeColor3, label.TextStrokeTransparency = W.ink, 0.15
	end
end
function W.clearButton(parent, name, x, y, w, h, cue)
	local b = Instance.new("TextButton")
	b.Name, b.Text, b.BackgroundTransparency = name, "", 1
	b.Position, b.Size, b.Parent = off(x, y), off(w, h), parent
	Audio.bind(b, cue)
	return b
end
function W.button(parent, name, x, y, w, h, tint, label, cue)
	local b = Instance.new("TextButton")
	b.Name, b.Position, b.Size, b.BackgroundColor3, b.BorderSizePixel = name, off(x, y), off(w, h), tint, 0
	b.Text, b.TextColor3, b.TextSize, b.Font = label, W.ink, 16, Enum.Font.FredokaOne
	W.round(b, 10)
	W.stroke(b, W.ink, 2)
	W.gradient(b, Color3.new(1, 1, 1), rgb(203, 192, 217), 78)
	local gleam = W.frame(b, "Enamel highlight", 8, 2, w - 16, 2, W.white, 1)
	gleam.BackgroundTransparency = 0.48
	b.Parent = parent
	Audio.bind(b, cue)
	return b
end
function W.scale(obj)
	local s = Instance.new("UIScale")
	s.Parent = obj
	return s
end
function W.anchor(obj, x, y, pos)
	obj.AnchorPoint, obj.Position = Vector2.new(x, y), pos
end
function W.tween(obj, d, props)
	local t = TweenService:Create(obj, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end
function W.goldAmount(n)
	local grouped = string.format("%.0f", n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return grouped
end
function W.number(n)
	if n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	end
	if n >= 10000 then
		return string.format("%.1fk", n / 1000)
	end
	return tostring(n)
end
return W
