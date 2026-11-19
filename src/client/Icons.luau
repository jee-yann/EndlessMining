-- Each badge is drawn on a 32-unit canvas so its silhouette survives touch HUD scaling.
local W = require(script.Parent.Widgets)
local Icons = {}
function Icons.draw(parent, key, x, y, size, tint)
	local canvas = W.frame(parent, key .. " icon", x, y, 32, 32, W.ink)
	canvas.BackgroundTransparency = 1
	W.scale(canvas).Scale = size / 32
	local function shape(name, sx, sy, w, h, color, r, angle, outline)
		local f = W.frame(canvas, name, sx, sy, w, h, color, r)
		f.Rotation = angle or 0
		if outline then
			W.stroke(f, W.ink, 1.5)
		end
		return f
	end
	local light = W.white
	if key == "Coins" or key == "Sell" then
		for i = 1, 3 do
			local cx, cy = if i == 3 then 14 else 2, if i == 3 then 12 else 20 - i * 4
			shape("Gold rim", cx, cy, 16, 14, W.orange, 7, -12, true)
			shape("Gold face", cx + 2, cy, 12, 11, W.gold, 6, -12)
			shape("Mint mark", cx + 7, cy + 2, 2, 6, light, 1, 12)
		end
	elseif key == "Gear" or key == "Power" then
		shape("Handle", 13, 5, 5, 24, W.orange, 2, 38, true)
		shape("Pick head", 8, 5, 16, 6, light, 2, 20, true)
		shape("Pick tip", 21, 8, 7, 5, W.aqua, 1, 39, true)
		shape("Rear pick", 4, 6, 7, 4, W.aqua, 1, -23, true)
	elseif key == "Settings" then
		for i, xx in { 8, 16, 24 } do
			shape("Rail", xx - 1, 4, 3, 24, W.panel, 2)
			shape("Dial", xx - 4, if i == 2 then 17 else 8, 9, 7, light, 3, 0, true)
		end
	elseif key == "Jobs" then
		shape("Clipboard", 6, 5, 20, 24, W.gold, 3, -6, true)
		shape("Paper", 9, 9, 14, 16, light, 1, -6)
		shape("Clip", 11, 3, 9, 6, W.orange, 2, -6, true)
		for i = 0, 2 do
			shape("Entry", 11, 12 + i * 4, 9 - i, 2, W.panel, 1, -6)
		end
	elseif key == "Book" then
		shape("Binding", 2, 6, 28, 21, W.panel, 3, 0, true)
		shape("Left page", 4, 5, 11, 19, light, 2, 5, true)
		shape("Right page", 17, 5, 11, 19, light, 2, -5, true)
		for i = 0, 2 do
			shape("Entry", 6, 11 + i * 3, 6, 1, W.line, 1, 5)
		end
		shape("Gem print", 20, 11, 5, 7, W.green, 2, 25, true)
	elseif key == "Store" then
		shape("Shop", 5, 10, 22, 17, light, 2, 0, true)
		shape("Window", 8, 15, 7, 8, W.aqua, 1, 0, true)
		shape("Door", 18, 16, 5, 10, W.panel, 1)
		shape("Canopy", 2, 6, 28, 8, W.pink, 2, 0, true)
		for _, xx in { 7, 17 } do
			shape("Awning stripe", xx, 6, 5, 8, light, 1)
		end
	elseif key == "Capacity" or key == "Pack" then
		shape("Strap", 11, 3, 10, 8, W.gold, 3, 0, true)
		shape("Pack", 5, 8, 22, 21, W.orange, 5, 0, true)
		shape("Fold", 7, 8, 18, 7, W.gold, 3, 0, true)
		shape("Pocket", 9, 19, 14, 6, W.gold, 2, 0, true)
	elseif key == "Skills" then
		shape("Stem", 15, 9, 3, 16, W.panel, 1)
		shape("Fork", 6, 17, 20, 3, W.panel, 1)
		for _, p in { { 12, 3 }, { 2, 16 }, { 21, 16 }, { 12, 23 } } do
			shape("Talent", p[1], p[2], 8, 8, W.green, 3, 0, true)
		end
	elseif key == "Pets" then
		shape("Rock", 3, 10, 26, 17, W.muted, 6, -5, true)
		shape("Crown", 7, 6, 18, 7, light, 3, -4, true)
		for _, xx in { 9, 21 } do
			shape("Eye", xx, 14, 3, 4, W.ink, 1)
		end
		shape("Smile", 14, 20, 4, 2, W.ink, 1)
	elseif key == "Achievements" or key == "Titles" then
		shape("Ribbon", 9, 15, 6, 15, W.pink, 2, 19, true)
		shape("Ribbon", 18, 15, 6, 15, W.pink, 2, -19, true)
		shape("Medal", 6, 2, 20, 20, W.gold, 10, 0, true)
		shape("Star", 12, 8, 8, 8, light, 2, 45)
	elseif key == "Crew" then
		shape("Head", 10, 4, 12, 12, W.gold, 6, 0, true)
		shape("Coat", 5, 18, 22, 11, W.aqua, 5, 0, true)
	elseif key == "Speed" then
		for _, xx in { 8, 19 } do
			shape("Upper chevron", xx, 5, 6, 14, W.gold, 2, -40, true)
			shape("Lower chevron", xx, 14, 6, 14, W.gold, 2, 40, true)
		end
	else
		local col = tint or W.violet
		shape("Back shard", 4, 11, 11, 15, col:Lerp(W.ink, 0.22), 3, -27, true)
		shape("Crystal", 12, 4, 14, 22, col, 4, 22, true)
		shape("Facet", 16, 6, 4, 14, col:Lerp(light, 0.65), 2, 22)
	end
	return canvas
end
return Icons
