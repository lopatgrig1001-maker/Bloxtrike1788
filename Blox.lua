-- SILENT AIM | через Camera.CFrame — БЕЗ ХУКОВ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

local CONFIG = {
    Enabled = true,
    FOV = 250,
    ShootKey = Enum.UserInputType.MouseButton1 -- левая кнопка = выстрел
}

-- FOV круг
local circle = Drawing.new("Circle")
circle.Thickness = 2
circle.NumSides = 60
circle.Filled = false
circle.Color = Color3.fromRGB(255, 60, 60)
circle.Transparency = 0.8
circle.Visible = true

local function calcRadius()
    return (CONFIG.FOV / 90) * (math.sqrt(Cam.ViewportSize.X^2 + Cam.ViewportSize.Y^2) / 2)
end

RunService.RenderStepped:Connect(function()
    circle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    circle.Radius = calcRadius()
end)

local function getTarget()
    local vp = Cam.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)
    local rad = calcRadius()
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
        local sp, on = Cam:WorldToViewportPoint(head.Position)
        if not on or sp.Z <= 0 then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < rad and d < bd then bd = d; best = head end
    end
    return best
end

-- Запоминаем настоящий CFrame
local realCamCF = Cam.CFrame
RunService.RenderStepped:Connect(function()
    -- если стреляем — НЕ восстанавливаем, чтобы выстрел ушёл в цель
    if not _G.R_SILENT_HOLD then
        realCamCF = Cam.CFrame
    end
end)

-- Хук на нажатие мыши
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not CONFIG.Enabled then return end
    if input.UserInputType == CONFIG.ShootKey then
        local target = getTarget()
        if not target then return end
        -- На один кадр поворачиваем камеру в голову
        local saved = Cam.CFrame
        Cam.CFrame = CFrame.lookAt(Cam.CFrame.Position, target.Position)
        _G.R_SILENT_HOLD = true
        -- Ждём пока выстрел уйдёт
        task.wait()
        task.wait()
        -- Возвращаем назад
        Cam.CFrame = saved
        _G.R_SILENT_HOLD = false
    end
end)

print("[R] SILENT via Camera.CFrame loaded")
