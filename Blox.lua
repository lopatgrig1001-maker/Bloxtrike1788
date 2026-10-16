-- AIMBOT | Быстрый поворот + стрельба после наводки
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera
local PG = LP:WaitForChild("PlayerGui")

local FOV = 300
local HOLD = false
local Smooth = 0.4

-- FOV круг
local circle = Drawing.new("Circle")
circle.Thickness = 2
circle.NumSides = 60
circle.Filled = false
circle.Color = Color3.fromRGB(255, 60, 60)
circle.Transparency = 0.8
circle.Visible = true

local function calcR()
    return (FOV / 90) * (math.sqrt(Cam.ViewportSize.X^2 + Cam.ViewportSize.Y^2) / 2)
end

local function getTarget()
    local vp = Cam.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)
    local rad = calcR()
    local best, bd = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local char = p.Character
        if not char then continue end
        if char:GetAttribute("Dead") then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then continue end
        local head = char:FindFirstChild("Head")
        if not head then continue end
        local pos = head.Position
        if math.abs(pos.X) < 0.5 and math.abs(pos.Z) < 0.5 then continue end
        local sp, on = Cam:WorldToViewportPoint(pos)
        if not on or sp.Z <= 0 then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < rad and d < bd then bd = d; best = head end
    end
    return best
end

-- UI
local sg = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.Parent = PG

local aimBtn = Instance.new("TextButton")
aimBtn.Size = UDim2.new(0, 120, 0, 120)
aimBtn.Position = UDim2.new(0, 20, 0, 300)
aimBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
aimBtn.BackgroundTransparency = 0.25
aimBtn.Text = "AIM"
aimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
aimBtn.TextScaled = true
aimBtn.Font = Enum.Font.GothamBold
aimBtn.Parent = sg
Instance.new("UICorner", aimBtn).CornerRadius = UDim.new(1, 0)

aimBtn.MouseButton1Down:Connect(function()
    HOLD = true
    aimBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
end)
aimBtn.MouseButton1Up:Connect(function()
    HOLD = false
    aimBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
end)
aimBtn.MouseLeave:Connect(function()
    HOLD = false
    aimBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
end)

-- Слайдер Smooth
local sf = Instance.new("Frame")
sf.Size = UDim2.new(0, 260, 0, 80)
sf.Position = UDim2.new(0, 160, 0, 310)
sf.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
sf.BorderSizePixel = 0
sf.Parent = sg
Instance.new("UICorner", sf).CornerRadius = UDim.new(0, 10)

local sl = Instance.new("TextLabel")
sl.Size = UDim2.new(1, -20, 0, 26)
sl.Position = UDim2.new(0, 10, 0, 6)
sl.BackgroundTransparency = 1
sl.Text = "Скорость: " .. math.floor(Smooth * 100) .. "%"
sl.TextColor3 = Color3.fromRGB(255, 255, 255)
sl.TextXAlignment = Enum.TextXAlignment.Left
sl.Font = Enum.Font.GothamBold
sl.TextSize = 14
sl.Parent = sf

local sbar = Instance.new("Frame")
sbar.Size = UDim2.new(1, -20, 0, 12)
sbar.Position = UDim2.new(0, 10, 0, 44)
sbar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
sbar.BorderSizePixel = 0
sbar.Parent = sf
Instance.new("UICorner", sbar).CornerRadius = UDim.new(1, 0)

local sfill = Instance.new("Frame")
sfill.Size = UDim2.new(Smooth, 0, 1, 0)
sfill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
sfill.BorderSizePixel = 0
sfill.Parent = sbar
Instance.new("UICorner", sfill).CornerRadius = UDim.new(1, 0)

local dragging = false
sbar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        local rel = math.clamp((i.Position.X - sbar.AbsolutePosition.X) / sbar.AbsoluteSize.X, 0, 1)
        Smooth = rel
        sfill.Size = UDim2.new(rel, 0, 1, 0)
        sl.Text = "Скорость: " .. math.floor(rel * 100) .. "%"
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local rel = math.clamp((i.Position.X - sbar.AbsolutePosition.X) / sbar.AbsoluteSize.X, 0, 1)
        Smooth = rel
        sfill.Size = UDim2.new(rel, 0, 1, 0)
        sl.Text = "Скорость: " .. math.floor(rel * 100) .. "%"
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ГЛАВНЫЙ ЦИКЛ
RunService.RenderStepped:Connect(function()
    circle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    circle.Radius = calcR()
    
    local held = HOLD or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if not held then return end
    
    local target = getTarget()
    if not target then return end
    
    -- Используем CFrame.lookAt каждый кадр
    local newCF = CFrame.lookAt(Cam.CFrame.Position, target.Position)
    Cam.CFrame = Cam.CFrame:Lerp(newCF, Smooth)
end)

print("[R] FAST AIMBOT loaded")
