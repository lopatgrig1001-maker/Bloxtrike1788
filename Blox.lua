-- SILENT AIM | hook FindPartOnRayWithIgnoreList
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera

local CONFIG = {
    Enabled = true,
    FOV = 250
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

local mt = getrawmetatable(game)
if mt then
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        
        -- FindPartOnRayWithIgnoreList возвращает (Part, Position, Normal, Material)
        -- Мы подменяем возврат — говорим игре "попадание в голову"
        if CONFIG.Enabled and method == "FindPartOnRayWithIgnoreList" then
            local args = {...}
            local target = getTarget()
            if target then
                -- Меняем origin/direction так чтобы луч летел в голову
                if typeof(args[1]) == "Ray" then
                    local ray = args[1]
                    local newDir = (target.Position - ray.Origin)
                    args[1] = Ray.new(ray.Origin, newDir)
                end
            end
            return oldNamecall(self, table.unpack(args))
        end
        
        return oldNamecall(self, ...)
    end)
    
    setreadonly(mt, true)
    print("[R] SILENT hooked on FindPartOnRayWithIgnoreList")
end

print("[R] SILENT loaded v2")
