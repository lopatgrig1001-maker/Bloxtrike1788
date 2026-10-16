-- TOUCH AIM через VIM | Палец сам ведёт к голове врага
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera
local PG = LP:WaitForChild("PlayerGui")

local CONFIG = {
    Enabled = true,
    FOV = 300,
    Smooth = 0.25,
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
aimBtn.Size = UDim2.new(0, 130, 0, 130)
aimBtn.Position = UDim2.new(0, 30, 0, 350)
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

-- VIM состояния
local touchDown = false
local curX, curY = 0, 0

local function startTouch(x, y)
    pcall(function()
        VIM:SendMouseButtonEvent(math.floor(x), math.floor(y), 0, true, game, 1)
    end)
    touchDown = true
    curX, curY = x, y
end

local function moveTouch(x, y)
    pcall(function()
        VIM:SendMouseMoveEvent(math.floor(x), math.floor(y), game)
    end)
    curX, curY = x, y
end

local function endTouch()
    pcall(function()
        VIM:SendMouseButtonEvent(math.floor(curX), math.floor(curY), 0, false, game, 1)
    end)
    touchDown = false
end

-- Главный цикл
RunService.RenderStepped:Connect(function()
    circle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    circle.Radius = calcR()
    
    if not CONFIG.Enabled then
        if touchDown then endTouch() end
        return
    end
    
    if not CONFIG.Held then
        if touchDown then endTouch() end
        return
    end
    
    local target = getTarget()
    if not target then
        if touchDown then endTouch() end
        return
    end
    
    -- Экранные координаты головы
    local sp, on = Cam:WorldToViewportPoint(target.Position)
    if not on or sp.Z <= 0 then
        if touchDown then endTouch() end
        return
    end
    
    -- Если тач не активен — начинаем с текущей позиции (центр экрана)
    if not touchDown then
        local startX = Cam.ViewportSize.X / 2
        local startY = Cam.ViewportSize.Y / 2
        startTouch(startX, startY)
    end
    
    -- Плавно ведём палец
    local newX = curX + (sp.X - curX) * CONFIG.Smooth
    local newY = curY + (sp.Y - curY) * CONFIG.Smooth
    moveTouch(newX, newY)
end)

print("[R] TOUCH AIM via VIM loaded")
