local RunService = game:GetService("RunService")
local W = require(script.Parent.Widgets)
local Receipt = {}
Receipt.__index = Receipt

function Receipt.new(hud)
	return setmetatable({ hud = hud, serial = 0 }, Receipt)
end

function Receipt:show(amount, quantity, balance, ore)
	self.serial += 1
	local serial = self.serial
	local hud = self.hud
	if self.panel then
		self.panel:Destroy()
	end
	local panel = W.frame(hud.root, "Sale receipt", 0, 0, 264, 88, W.panel)
	panel.BackgroundTransparency = 1
	self.panel = panel
	panel.ZIndex = 4
	local position = if hud.unlocks.playing then UDim2.new(0.5, 0, 0.41, 112) else UDim2.fromScale(0.5, 0.37)
	W.anchor(panel, 0.5, 0.5, position)
	local group = W.fadeGroup(panel, "Receipt face", 264, 88)
	local face = W.frame(group, "Payout card", 8, 8, 248, 72, W.panel, 15)
	W.stroke(face, W.gold, 2)
	W.enamel(face, Color3.fromRGB(133, 76, 43), W.panel)
	W.text(
		face,
		string.format("Sold %s %s", W.goldAmount(quantity), ore or (if quantity == 1 then "block" else "blocks")),
		5,
		4,
		238,
		22,
		16,
		W.white
	)
	local payout = W.title(face, "+" .. W.goldAmount(amount) .. " gold", 5, 25, 238, 40, 31, W.gold)
	W.outlineText(payout)
	local motion = hud.player:GetAttribute("MenuMotion") ~= false
	if motion then
		hud.countingGold = true
		local before = balance - amount
		local scale = W.scale(panel)
		scale.Scale = 0.86
		W.tween(scale, 0.20, { Scale = 1 })
		for i = 1, 5 do
			local coin = W.frame(panel, "Sale coin", 0, 0, 12, 12, W.gold, 8)
			coin.ZIndex = 2
			W.stroke(coin, W.orange, 2)
			coin.AnchorPoint = Vector2.new(0.5, 0.5)
			coin.Position = UDim2.fromScale((i - 0.5) / 5, 0.8)
			task.delay(0.22 + 0.045 * i, function()
				if self.serial == serial and coin.Parent then
					local dest = hud.gold.AbsolutePosition
						+ Vector2.new(12, hud.gold.AbsoluteSize.Y / 2)
						- panel.AbsolutePosition
					W.tween(coin, 0.4, { Position = UDim2.fromOffset(dest.X, dest.Y), BackgroundTransparency = 0.2 })
					task.delay(0.4, function()
						coin:Destroy()
					end)
				end
			end)
		end
		task.spawn(function()
			local start = os.clock()
			repeat
				local t = math.min((os.clock() - start) / 0.8, 1)
				hud.gold.Text = W.goldAmount(before + math.round(amount * (1 - (1 - t) ^ 2)))
				RunService.RenderStepped:Wait()
			until self.serial ~= serial or os.clock() - start >= 0.8
			if self.serial == serial then
				hud.countingGold = false
				hud:refresh()
			end
		end)
	else
		hud.countingGold = false
		hud:refresh()
	end
	task.delay(1.75, function()
		if self.serial ~= serial then
			return
		end
		if motion then
			W.tween(panel, 0.38, { Position = panel.Position - UDim2.fromOffset(0, 16) })
		end
		W.tween(group, 0.38, { GroupTransparency = 1 }).Completed:Once(function()
			if self.serial == serial then
				panel:Destroy()
				self.panel = nil
			end
		end)
	end)
end
return Receipt
