-- Run in Studio edit mode. The clone simulates the published client's permission
-- failure after image allocation while exercising the real pixels and GUI renderer.
local source = game.StarterPlayer.StarterPlayerScripts.Client.FieldKit
local remote = Instance.new("Frame")
local expected = "rbxassetid://" .. assert(source:GetAttribute("ImageId"))
local uploaded = require(source)
for i, key in { "Inventory", "Skills", "Achievements", "Book", "Settings" } do
	uploaded.draw(remote, key)
	local label = remote["Field Kit"]
	assert(label:IsA("ImageLabel") and label.Image == expected and label.ImageRectSize == Vector2.one * 256)
	assert(label.ImageRectOffset == Vector2.new((i - 1) % 3, math.floor((i - 1) / 3)) * 256)
	label:Destroy()
end
remote:Destroy()
local probe = source:Clone()
probe:SetAttribute("ImageId", nil)
local replacement = [[
local Assets = { CreateEditableImage = function()
	assert(not script:GetAttribute("Allocated"), "Retried the denied image for another icon")
	script:SetAttribute("Allocated", true)
	return {
		WritePixelsBuffer = function() error("EditableImage is not accessible") end,
		Destroy = function() script:SetAttribute("Released", true) end,
	}
end }
]]
local instrumented, edits = source.Source:gsub('local Assets = game:GetService%("AssetService"%)', replacement, 1)
assert(edits == 1)
probe.Source = instrumented
local renderer = require(probe)
local container = Instance.new("Frame")
for _, key in { "Inventory", "Skills", "Achievements", "Book", "Settings", "Pack", "Capacity", "Titles" } do
	assert(renderer.draw(container, key))
	local icon = container["Field Kit"]
	assert(icon:IsA("Frame") and #icon:GetChildren() > 25 and icon:FindFirstChildWhichIsA("UIGradient", true), key)
	local rows = {}
	for _, strip in icon:GetChildren() do
		rows[strip.Position.Y.Scale] = true
	end
	local count = 0
	for _ in rows do
		count += 1
	end
	assert(count >= 80, key .. " lost its full-detail artwork")
	icon:Destroy()
end
assert(probe:GetAttribute("Allocated") and probe:GetAttribute("Released"))
assert(not renderer.draw(container, "Power"))
container:Destroy()
probe:Destroy()
print("PASS published Field Kit write denial, all five icons and three aliases")
