-- SILENT AIM | hookfunction на Camera.ViewportPointToRay
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera
local PG = LP:WaitForChild("PlayerGui")

local CONFIG = {
    Enabled = true,
    FOV = 300
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

-- Хукаем ViewportPointToRay через hookfunction
local hooked = false

pcall(function()
    local oldFunc = Cam.ViewportPointToRay
    local newFunc = newcclosure(function(self, ...)
        local args = {...}
        
        if CONFIG.Enabled then
            local target = getTarget()
            if target then
                -- Считаем экранные координаты головы
                local sp = Cam:WorldToViewportPoint(target.Position)
                if sp then
                    -- Возвращаем Ray направленный в голову
                    return Ray.new(Cam.CFrame.Position, target.Position - Cam.CFrame.Position)
                end
            end
        end
        
        return oldFunc(self, table.unpack(args))
    end)
    
    hookfunction(oldFunc, newFunc)
    hooked = true
    print("[R] SILENT hooked OK")
end)

if not hooked then
    warn("[R] hookfunction failed")
end

-- UI
local sg = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.Parent = PG

local dbg = Instance.new("TextLabel")
dbg.Size = UDim2.new(0, 400, 0, 30)
dbg.Position = UDim2.new(0, 20, 0, 60)
dbg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dbg.BackgroundTransparency = 0.3
dbg.TextColor3 = Color3.fromRGB(255, 255, 255)
dbg.TextXAlignment = Enum.TextXAlignment.Left
dbg.Font = Enum.Font.Code
dbg.TextSize = 14
dbg.Text = "SILENT: " .. tostring(hooked)
dbg.Parent = sg

local aimBtn = Instance.new("TextButton")
aimBtn.Size = UDim2.new(0, 120, 0, 120)
aimBtn.Position = UDim2.new(0, 20, 0, 200)
aimBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
aimBtn.BackgroundTransparency = 0.25
aimBtn.Text = "AIM"
aimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
aimBtn.TextScaled = true
aimBtn.Font = Enum.Font.GothamBold
aimBtn.Parent = sg
Instance.new("UICorner", aimBtn).CornerRadius = UDim.new(1, 0)

local HOLD = false
aimBtn.MouseButton1Down:Connect(function()
    CONFIG.Enabled = true
    aimBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
end)
aimBtn.MouseButton1Up:Connect(function()
    CONFIG.Enabled = false
    aimBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
end)

RunService.RenderStepped:Connect(function()
    circle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    circle.Radius = calcR()
end)

print("[R] SILENT ready")
