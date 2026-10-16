-- SILENT через ViewportPointToRay — подмена ВОЗВРАТА (не аргумента)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

local CONFIG = {
    Enabled = true,
    FOV = 300
}

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

RunService.RenderStepped:Connect(function()
    circle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    circle.Radius = calcR()
end)

-- Хук на ViewportPointToRay — подменяем возвращаемый Ray
local mt = getrawmetatable(game)
if mt then
    local oldNC = mt.__namecall
    setreadonly(mt, false)
    
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        
        if CONFIG.Enabled and method == "ViewportPointToRay" and self == Cam then
            local target = getTarget()
            if target then
                -- Считаем направление от камеры к голове
                local origin = Cam.CFrame.Position
                local dir = (target.Position - origin)
                -- Возвращаем НОВЫЙ Ray — от камеры к голове
                return Ray.new(origin, dir)
            end
        end
        
        return oldNC(self, ...)
    end)
    
    setreadonly(mt, true)
    print("[R] SILENT hooked ViewportPointToRay RETURN")
end

print("[R] SILENT v3 loaded")
