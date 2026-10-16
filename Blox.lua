-- FINAL AIMBOT | Работает. Без хуков. Без silent.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera
local PG = LP:WaitForChild("PlayerGui")

local CONFIG = {
    Enabled = true,
    FOV = 300,
    Smooth = 0.5,
    AimPart = "Head",
    Held = false
}

-- FOV круг
local circle = Drawing.new("Circle")
circle.Thickness = 2
circle.NumSides = 60
circle.Filled = false
circle.Color = Color3.fromRGB(255, 60, 60)
circle.Transparency = 0.8
circle.Visible = true

local function calcR()
    return (CONFIG.FOV / 90) * (math.sqrt(Cam.ViewportSize.X^2 + Cam.ViewportSize.Y^2) / 2)
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
        local part = char:FindFirstChild(CONFIG.AimPart) or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        local pos = part.Position
        if math.abs(pos.X) < 0.5 and math.abs(pos.Z) < 0.5 then continue end
        local sp, on = Cam:WorldToViewportPoint(pos)
        if not on or sp.Z <= 0 then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < rad and d < bd then bd = d; best = part end
    end
    return best
end

-- UI
local sg = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.Parent = PG

local aimBtn = Instance.new("TextButton")
aimBtn.Size = UDim2.new(0, 120, 0, 120)
aimBtn.Position = UDim2.new(0, 20, 0, 250)
aimBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
aimBtn.BackgroundTransparency = 0.25
aimBtn.Text = "AIM"
aimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
aimBtn.TextScaled = true
aimBtn.Font = Enum.Font.GothamBold
aimBtn.Parent = sg
Instance.new("UICorner", aimBtn).CornerRadius = UDim.new(1, 0)

aimBtn.MouseButton1Down:Connect(function()
    CONFIG.Held = true
    aimBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
end)
aimBtn.MouseButton1Up:Connect(function()
    CONFIG.Held = false
    aimBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
end)
aimBtn.MouseLeave:Connect(function()
    CONFIG.Held = false
    aimBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
end)

-- FOV слайдер
local fovFrame = Instance.new("Frame")
fovFrame.Size = UDim2.new(0, 280, 0, 80)
fovFrame.Position = UDim2.new(0, 160, 0, 260)
fovFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
fovFrame.BorderSizePixel = 0
fovFrame.Parent = sg
Instance.new("UICorner", fovFrame).CornerRadius = UDim.new(0, 10)

local fovLbl = Instance.new("TextLabel")
fovLbl.Size = UDim2.new(1, -20, 0, 26)
fovLbl.Position = UDim2.new(0, 10, 0, 6)
fovLbl.BackgroundTransparency = 1
fovLbl.Text = "FOV: " .. CONFIG.FOV
fovLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
fovLbl.TextXAlignment = Enum.TextXAlignment.Left
fovLbl.Font = Enum.Font.GothamBold
fovLbl.TextSize = 14
fovLbl.Parent = fovFrame

local fovBar = Instance.new("Frame")
fovBar.Size = UDim2.new(1, -20, 0, 12)
fovBar.Position = UDim2.new(0, 10, 0, 44)
fovBar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
fovBar.BorderSizePixel = 0
fovBar.Parent = fovFrame
Instance.new("UICorner", fovBar).CornerRadius = UDim.new(1, 0)

local fovFill = Instance.new("Frame")
fovFill.Size = UDim2.new((CONFIG.FOV-50)/450, 0, 1, 0)
fovFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
fovFill.BorderSizePixel = 0
fovFill.Parent = fovBar
Instance.new("UICorner", fovFill).CornerRadius = UDim.new(1, 0)

local dragging = false
local function setFov(x)
    local rel = math.clamp((x - fovBar.AbsolutePosition.X) / fovBar.AbsoluteSize.X, 0, 1)
    CONFIG.FOV = math.floor(50 + rel * 450)
    fovFill.Size = UDim2.new(rel, 0, 1, 0)
    fovLbl.Text = "FOV: " .. CONFIG.FOV
end
fovBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true; setFov(i.Position.X)
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        setFov(i.Position.X)
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
    
    if not CONFIG.Enabled then return end
    
    local held = CONFIG.Held or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if not held then return end
    
    local target = getTarget()
    if not target then return end
    
    local pos = target.Position + target.AssemblyLinearVelocity * 0.05
    local newCF = CFrame.lookAt(Cam.CFrame.Position, pos)
    Cam.CFrame = Cam.CFrame:Lerp(newCF, CONFIG.Smooth)
end)

print("[R] FINAL AIMBOT loaded")
