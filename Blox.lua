print("[R] test A")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
print("[R] test B")
local sg = Instance.new("ScreenGui")
sg.Parent = LP:WaitForChild("PlayerGui")
print("[R] test C")
local f = Instance.new("Frame")
f.Size = UDim2.new(0, 200, 0, 200)
f.Position = UDim2.new(0, 100, 0, 100)
f.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
f.Parent = sg
print("[R] test D — GUI создан")
