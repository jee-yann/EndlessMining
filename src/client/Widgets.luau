local TweenService = game:GetService("TweenService")
local W = {}
local rgb = Color3.fromRGB
W.ink, W.panel, W.card, W.line = rgb(33, 41, 49), rgb(54, 65, 73), rgb(232, 233, 221), rgb(114, 124, 129)
W.white, W.muted, W.gold, W.aqua, W.green =
	rgb(255, 253, 236), rgb(206, 213, 210), rgb(255, 210, 74), rgb(149, 207, 255), rgb(147, 214, 103)
W.chrome, W.blue = rgb(184, 192, 194), rgb(39, 85, 148)
local off = UDim2.fromOffset
function W.round(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius, c.Parent = UDim.new(0, r), obj
end
function W.stroke(obj, color, width)
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode, s.Color, s.Thickness, s.Parent = Enum.ApplyStrokeMode.Border, color, width, obj
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
function W.text(parent, value, x, y, w, h, size, color, left)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency, l.Text, l.TextSize, l.Font, l.TextColor3 =
		1, value, size, Enum.Font.BuilderSansBold, color
	l.TextXAlignment = if left then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
	l.Position, l.Size, l.Parent = off(x, y), off(w, h), parent
	return l
end
function W.bevel(obj)
	local top = W.frame(obj, "Top edge", 3, 2, 1, 1, Color3.new(1, 1, 1))
	top.Size, top.BackgroundTransparency = UDim2.new(1, -6, 0, 1), 0.40
	local bottom = W.frame(obj, "Bottom edge", 3, 0, 1, 2, W.ink)
	bottom.Position, bottom.Size, bottom.BackgroundTransparency =
		UDim2.new(0, 3, 1, -3), UDim2.new(1, -6, 0, 2), 0.52
end
function W.goldBrick(parent, x, y)
	local face = W.frame(parent, "Gold brick", x, y, 32, 17, W.gold, 2)
	W.stroke(face, W.ink, 1)
	W.bevel(face)
	for _, left in { 4, 19 } do
		local stud = W.frame(face, "Stud", left, -4, 8, 5, W.gold, 1)
		W.stroke(stud, W.ink, 1)
	end
end
function W.button(parent, name, x, y, w, h, tint, label)
	local b = Instance.new("TextButton")
	b.Name, b.Position, b.Size, b.BackgroundColor3, b.BorderSizePixel = name, off(x, y), off(w, h), tint, 0
	b.Text, b.TextColor3, b.TextSize, b.Font = label, W.ink, 16, Enum.Font.BuilderSansExtraBold
	W.round(b, 4)
	W.stroke(b, W.ink, 2)
	W.bevel(b)
	b.Parent = parent
	return b
end
function W.scale(obj)
	local s = Instance.new("UIScale")
	s.Parent = obj
	return s
end
function W.tween(obj, d, props)
	local t =
		TweenService:Create(obj, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
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
