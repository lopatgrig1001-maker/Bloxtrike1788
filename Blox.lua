-- TOUCH AIM | Имитация касаний через VirtualInputManager
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
    Smooth = 0.15,
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
        local part = char:FindFirstChild(CONFIG.AimPart)
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

--===== TOUCH AIM через VirtualInputManager =====
-- Имитируем тач: двигаем "виртуальный палец" по экрану к цели
local VIM = nil
pcall(function()
    VIM = game:GetService("VirtualInputManager")
end)

local touchActive = false
local lastTouchX = 0
local lastTouchY = 0

local function sendTouch(x, y)
    if not VIM then return end
    pcall(function()
        if not touchActive then
            VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
            touchActive = true
        else
            VIM:SendMouseMoveEvent(x, y, game)
        end
        lastTouchX = x
        lastTouchY = y
    end)
end

local function endTouch()
    if not VIM or not touchActive then return end
    pcall(function()
        VIM:SendMouseButtonEvent(lastTouchX, lastTouchY, 0, false, game, 1)
    end)
    touchActive = false
end

-- Главный цикл — пока держишь AIM, ведём палец к цели
RunService.RenderStepped:Connect(function()
    circle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    circle.Radius = calcR()
    
    if not CONFIG.Enabled then return end
    
    local held = CONFIG.Held or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    
    if not held then
        if touchActive then endTouch() end
        return
    end
    
    local target = getTarget()
    if not target then
        if touchActive then endTouch() end
        return
    end
    
    -- Получаем экранные координаты головы врага
    local sp, on = Cam:WorldToViewportPoint(target.Position)
    if not on or sp.Z <= 0 then
        if touchActive then endTouch() end
        return
    end
    
    -- Плавно ведём палец к цели
    local targetX = sp.X
    local targetY = sp.Y
    
    local curX = lastTouchX
    local curY = lastTouchY
    
    if not touchActive then
        -- Начинаем с текущей позиции прицела (центр экрана)
        curX = Cam.ViewportSize.X / 2
        curY = Cam.ViewportSize.Y / 2
    end
    
    local newX = curX + (targetX - curX) * CONFIG.Smooth
    local newY = curY + (targetY - curY) * CONFIG.Smooth
    
    sendTouch(newX, newY)
end)

print("[R] TOUCH AIM loaded")
