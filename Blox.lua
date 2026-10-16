-- AIM INSTANT | Camera мгновенно на голову
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera
local PG = LP:WaitForChild("PlayerGui")

local FOV = 300
local HOLD = false

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

local sg = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.Parent = PG

local aimBtn = Instance.new("TextButton")
aimBtn.Size = UDim2.new(0, 110, 0, 110)
aimBtn.Position = UDim2.new(0, 20, 0, 250)
aimBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
aimBtn.BackgroundTransparency = 0.3
aimBtn.Text = "AIM"
aimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
aimBtn.TextScaled = true
aimBtn.Font = Enum.Font.GothamBold
aimBtn.Parent = sg
Instance.new("UICorner", aimBtn).CornerRadius = UDim.new(1, 0)
aimBtn.MouseButton1Down:Connect(function() HOLD = true end)
aimBtn.MouseButton1Up:Connect(function() HOLD = false end)
aimBtn.MouseLeave:Connect(function() HOLD = false end)

RunService.RenderStepped:Connect(function()
    circle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    circle.Radius = calcR()
    
    local held = HOLD or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if not held then return end
    
    local target = getTarget()
    if not target then return end
    
    -- МГНОВЕННО без сглаживания
    Cam.CFrame = CFrame.lookAt(Cam.CFrame.Position, target.Position)
end)

print("[R] INSTANT AIM loaded")
