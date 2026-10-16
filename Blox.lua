print("[R] test Drawing")
local d = Drawing.new("Square")
print("[R] Drawing.new OK")
d.Visible = false
d.Size = Vector2.new(100, 100)
d.Position = Vector2.new(100, 100)
d.Color = Color3.fromRGB(255, 0, 0)
d.Thickness = 2
d.Filled = false
d.Visible = true
print("[R] Drawing properties OK")
