-- FOV круг только | Без хуков
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera
local PG = LP:WaitForChild("PlayerGui")

local FOV = 200
local COLOR = Color3.fromRGB(255, 60, 60)

local circle = Drawing.new("Circle")
circle.Thickness = 2
circle.NumSides = 60
circle.Radius = (FOV / 90) * (math.sqrt(Cam.ViewportSize.X^2 + Cam.ViewportSize.Y^2) / 2)
circle.Filled = false
circle.Color = COLOR
circle.Transparency = 0.8
circle.Visible = true

RunService.RenderStepped:Connect(function()
    circle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    circle.Radius = (FOV / 90) * (math.sqrt(Cam.ViewportSize.X^2 + Cam.ViewportSize.Y^2) / 2)
end)

-- Небольшое меню
local sg = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.Parent = PG

local f = Instance.new("Frame")
f.Size = UDim2.new(0, 260, 0, 100)
f.Position = UDim2.new(0, 20, 0, 200)
f.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
f.BorderSizePixel = 0
f.Parent = sg
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(1, -20, 0, 26)
lbl.Position = UDim2.new(0, 10, 0, 6)
lbl.BackgroundTransparency = 1
lbl.Text = "FOV: " .. FOV
lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Font = Enum.Font.GothamBold
lbl.TextSize = 14
lbl.Parent = f

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, -20, 0, 12)
bar.Position = UDim2.new(0, 10, 0, 40)
bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
bar.BorderSizePixel = 0
bar.Parent = f
Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

local fill = Instance.new("Frame")
fill.Size = UDim2.new(0.4, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
fill.BorderSizePixel = 0
fill.Parent = bar
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

local dragging = false
local function setVal(x)
    local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
    FOV = math.floor(50 + rel * 450)
    fill.Size = UDim2.new(rel, 0, 1, 0)
    lbl.Text = "FOV: " .. FOV
    circle.Radius = (FOV / 90) * (math.sqrt(Cam.ViewportSize.X^2 + Cam.ViewportSize.Y^2) / 2)
end
bar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true; setVal(i.Position.X)
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        setVal(i.Position.X)
    end
end)
game:GetService("UserInputService").InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

print("[R] FOV circle loaded")
