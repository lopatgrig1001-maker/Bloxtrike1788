-- [R] FULL | ESP + Hitbox + Aimbot + Silent + Menu + Hooks
-- Запускать только если тесты 1 и 2 прошли без краша

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera
local PG = LP:WaitForChild("PlayerGui")

local CONFIG = {
    ESP = true, Box = true, Name = true, HP = true, Dist = true, MaxDist = 800,
    Hitbox = false, HitboxSize = 8,
    Column = false, ColumnHeight = 500,
    Aim = true, AimFOV = 150, AimSmooth = 0.2, AimHeld = false,
    Silent = true, SilentFOV = 200, SilentHit = 100,
    Speed = true, SpeedVal = 50,
    Jump = true, JumpVal = 150
}

local espCache = {}
local hitboxCache = {}
local columnCache = {}

local function ok(char)
    if not char then return false end
    return char:FindFirstChild("Head") and char:FindFirstChild("HumanoidRootPart")
end

local function dead(char)
    local d = char:GetAttribute("Dead")
    if d ~= nil then return d end
    local h = char:FindFirstChildOfClass("Humanoid")
    return h and h.Health <= 0 or false
end

local function getTarget(fov)
    local vp = Cam.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)
    local fovPx = (fov / 90) * (math.sqrt(vp.X^2 + vp.Y^2) / 2)
    local best, bd = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local char = p.Character
        if not ok(char) or dead(char) then continue end
        local part = char:FindFirstChild("Head")
        local sp, on = Cam:WorldToViewportPoint(part.Position)
        if not on or sp.Z <= 0 then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < fovPx and d < bd then bd = d; best = part end
    end
    return best
end

--===== ESP =====
local function mkESP(p)
    if p == LP or espCache[p] then return end
    local b = Drawing.new("Square"); b.Thickness = 1; b.Filled = false; b.Transparency = 1; b.Visible = false
    local o = Drawing.new("Square"); o.Thickness = 2; o.Filled = false; o.Transparency = 0.4; o.Color = Color3.fromRGB(0,0,0); o.Visible = false
    local n = Drawing.new("Text"); n.Size = 14; n.Center = true; n.Outline = true; n.Visible = false
    local h = Drawing.new("Square"); h.Thickness = 1; h.Filled = true; h.Transparency = 1; h.Visible = false
    local d = Drawing.new("Text"); d.Size = 12; d.Center = true; d.Outline = true; d.Visible = false
    espCache[p] = {b=b, o=o, n=n, h=h, d=d}
end

local function hide(d)
    d.b.Visible = false; d.o.Visible = false; d.n.Visible = false; d.h.Visible = false; d.d.Visible = false
end

RunService.RenderStepped:Connect(function()
    for p, d in pairs(espCache) do
        if not CONFIG.ESP then hide(d) continue end
        local char = p.Character
        if not ok(char) or dead(char) then hide(d) continue end
        local head = char:FindFirstChild("Head")
        local root = char:FindFirstChild("HumanoidRootPart")
        local dist = (Cam.CFrame.Position - root.Position).Magnitude
        if dist > CONFIG.MaxDist then hide(d) continue end
        local hp, on = Cam:WorldToViewportPoint(head.Position)
        local fp = Cam:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))
        if not on or hp.Z <= 0 then hide(d) continue end
        local hh = math.abs(fp.Y - hp.Y)
        if hh < 8 or hh > 800 then hide(d) continue end
        local w = hh * 0.55
        local bx, by = hp.X - w/2, hp.Y
        
        if CONFIG.Box then
            d.o.Size = Vector2.new(w+2, hh+2); d.o.Position = Vector2.new(bx-1, by-1); d.o.Visible = true
            d.b.Size = Vector2.new(w, hh); d.b.Position = Vector2.new(bx, by)
            d.b.Color = Color3.fromRGB(255, 50, 50); d.b.Visible = true
        else d.b.Visible = false; d.o.Visible = false end
        
        if CONFIG.Name then
            d.n.Position = Vector2.new(hp.X, by - 20); d.n.Text = p.Name
            d.n.Color = Color3.fromRGB(255, 255, 255); d.n.Visible = true
        else d.n.Visible = false end
        
        if CONFIG.HP then
            local chp = char:GetAttribute("Health") or (char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid").Health) or 100
            local mhp = char:GetAttribute("MaxHealth") or 100
            local pct = mhp > 0 and math.clamp(chp/mhp, 0, 1) or 1
            d.h.Size = Vector2.new(3, hh*pct); d.h.Position = Vector2.new(bx - 7, by + hh*(1-pct))
            d.h.Color = Color3.fromRGB(255*(1-pct), 255*pct, 0); d.h.Visible = true
        else d.h.Visible = false end
        
        if CONFIG.Dist then
            d.d.Position = Vector2.new(hp.X, by + hh + 4); d.d.Text = string.format("[%d]", math.floor(dist))
            d.d.Color = Color3.fromRGB(220, 220, 220); d.d.Visible = true
        else d.d.Visible = false end
    end
end)

for _, p in ipairs(Players:GetPlayers()) do mkESP(p) end
Players.PlayerAdded:Connect(mkESP)
Players.PlayerRemoving:Connect(function(p)
    local d = espCache[p]
    if d then for _, v in pairs(d) do if v.Remove then v:Remove() end end espCache[p] = nil end
end)

--===== HITBOX + COLUMN =====
RunService.Heartbeat:Connect(function()
    if CONFIG.Hitbox then
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            local char = p.Character
            if ok(char) then
                local head = char:FindFirstChild("Head")
                if head then pcall(function()
                    head.Size = Vector3.new(CONFIG.HitboxSize, CONFIG.HitboxSize, CONFIG.HitboxSize)
                    head.Transparency = 0.3; head.CanCollide = false
                    head.Material = Enum.Material.Neon
                    head.BrickColor = BrickColor.new("Bright red")
                end) end
            end
        end
    end
    
    if CONFIG.Column then
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            local char = p.Character
            if ok(char) and not columnCache[p] then
                local head = char:FindFirstChild("Head")
                if head then
                    local col = Instance.new("Part")
                    col.Name = "R_Col_" .. p.Name
                    col.Size = Vector3.new(4, CONFIG.ColumnHeight, 4)
                    col.Anchored = true; col.CanCollide = false; col.CanQuery = false; col.CanTouch = false
                    col.Material = Enum.Material.Neon; col.Color = Color3.fromRGB(255, 40, 40); col.Transparency = 0.3
                    col.Position = head.Position + Vector3.new(0, CONFIG.ColumnHeight/2, 0)
                    col.Parent = Workspace
                    columnCache[p] = col
                end
            end
        end
        for p, col in pairs(columnCache) do
            local char = p.Character
            if not ok(char) then
                if col.Parent then col:Destroy() end
                columnCache[p] = nil
            else
                local head = char:FindFirstChild("Head")
                if head and col.Parent then col.Position = head.Position + Vector3.new(0, CONFIG.ColumnHeight/2, 0) end
            end
        end
    end
    
    local myHum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if myHum then
        if CONFIG.Speed then myHum.WalkSpeed = CONFIG.SpeedVal end
        if CONFIG.Jump then myHum.UseJumpPower = true; myHum.JumpPower = CONFIG.JumpVal end
    end
end)

--===== AIMBOT =====
RunService.RenderStepped:Connect(function()
    if not CONFIG.Aim then return end
    if not (CONFIG.AimHeld or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then return end
    local target = getTarget(CONFIG.AimFOV)
    if not target then return end
    local pos = target.Position + target.AssemblyLinearVelocity * 0.05
    Cam.CFrame = Cam.CFrame:Lerp(CFrame.lookAt(Cam.CFrame.Position, pos), CONFIG.AimSmooth)
end)

--===== SILENT AIM HOOK =====
local mt = getrawmetatable(game)
if mt then
    local oldNC = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if CONFIG.Silent and (method == "Fire" or method == "FireServer" or method == "InvokeServer") then
            local args = {...}
            if typeof(args[1]) == "Vector3" or typeof(args[1]) == "CFrame" then
                local target = getTarget(CONFIG.SilentFOV)
                if target and math.random(1, 100) <= CONFIG.SilentHit then
                    if typeof(args[1]) == "Vector3" then
                        args[1] = target.Position
                    elseif typeof(args[1]) == "CFrame" then
                        args[1] = CFrame.new(target.Position)
                    end
                end
                return oldNC(self, table.unpack(args))
            end
        end
        return oldNC(self, ...)
    end)
    setreadonly(mt, true)
end

--===== GUI =====
local sg = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.Parent = PG

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 60, 0, 60)
openBtn.Position = UDim2.new(0, 20, 0, 180)
openBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
openBtn.BackgroundTransparency = 0.15
openBtn.Text = "R"
openBtn.TextColor3 = Color3.fromRGB(255,255,255)
openBtn.TextScaled = true
openBtn.Font = Enum.Font.GothamBold
openBtn.Parent = sg
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 320, 0, 520)
panel.Position = UDim2.new(0, 100, 0, 120)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = sg
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local hdr = Instance.new("Frame")
hdr.Size = UDim2.new(1, 0, 0, 48)
hdr.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
hdr.BorderSizePixel = 0
hdr.Parent = panel
Instance.new("UICorner", hdr).CornerRadius = UDim.new(0, 12)

local ttl = Instance.new("TextLabel")
ttl.Size = UDim2.new(1, -20, 1, 0)
ttl.Position = UDim2.new(0, 15, 0, 0)
ttl.BackgroundTransparency = 1
ttl.Text = "[R] FULL"
ttl.TextColor3 = Color3.fromRGB(255,255,255)
ttl.TextXAlignment = Enum.TextXAlignment.Left
ttl.Font = Enum.Font.GothamBold
ttl.TextSize = 18
ttl.Parent = hdr

local scr = Instance.new("ScrollingFrame")
scr.Size = UDim2.new(1, -16, 1, -60)
scr.Position = UDim2.new(0, 8, 0, 54)
scr.BackgroundTransparency = 1
scr.BorderSizePixel = 0
scr.ScrollBarThickness = 5
scr.CanvasSize = UDim2.new(0, 0, 0, 1200)
scr.Parent = panel

local lay = Instance.new("UIListLayout")
lay.Padding = UDim.new(0, 6)
lay.Parent = scr

local function mkSec(t)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -8, 0, 26)
    l.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    l.Text = "  " .. t
    l.TextColor3 = Color3.fromRGB(180, 180, 255)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    l.BorderSizePixel = 0
    l.Parent = scr
    Instance.new("UICorner", l).CornerRadius = UDim.new(0, 5)
end

local function mkT(t, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -8, 0, 36)
    f.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    f.BorderSizePixel = 0
    f.Parent = scr
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -80, 1, 0)
    l.Position = UDim2.new(0, 15, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = t
    l.TextColor3 = Color3.fromRGB(220, 220, 220)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Gotham
    l.TextSize = 14
    l.Parent = f
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 56, 0, 26)
    b.Position = UDim2.new(1, -70, 0.5, -13)
    b.BackgroundColor3 = def and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(60, 60, 70)
    b.Text = def and "ON" or "OFF"
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.BorderSizePixel = 0
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
    local s = def
    b.MouseButton1Click:Connect(function()
        s = not s
        b.Text = s and "ON" or "OFF"
        b.BackgroundColor3 = s and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(60, 60, 70)
        cb(s)
    end)
end

local function mkS(t, mn, mx, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -8, 0, 56)
    f.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    f.BorderSizePixel = 0
    f.Parent = scr
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -20, 0, 22)
    l.Position = UDim2.new(0, 15, 0, 4)
    l.BackgroundTransparency = 1
    l.Text = t .. ": " .. def
    l.TextColor3 = Color3.fromRGB(220, 220, 220)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Gotham
    l.TextSize = 14
    l.Parent = f
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -30, 0, 10)
    bar.Position = UDim2.new(0, 15, 0, 34)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    bar.BorderSizePixel = 0
    bar.Parent = f
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((def-mn)/(mx-mn), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local dragging = false
    local function setV(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = math.floor(mn + (mx-mn)*rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        l.Text = t .. ": " .. v
        cb(v)
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; setV(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setV(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

mkSec("ESP")
mkT("ESP", CONFIG.ESP, function(v) CONFIG.ESP = v end)
mkT("Box", CONFIG.Box, function(v) CONFIG.Box = v end)
mkT("Name", CONFIG.Name, function(v) CONFIG.Name = v end)
mkT("Health", CONFIG.HP, function(v) CONFIG.HP = v end)
mkT("Distance", CONFIG.Dist, function(v) CONFIG.Dist = v end)
mkS("Max Dist", 50, 2000, CONFIG.MaxDist, function(v) CONFIG.MaxDist = v end)

mkSec("HITBOX")
mkT("Big Head", CONFIG.Hitbox, function(v) CONFIG.Hitbox = v end)
mkS("Size", 3, 30, CONFIG.HitboxSize, function(v) CONFIG.HitboxSize = v end)
mkT("Column", CONFIG.Column, function(v) CONFIG.Column = v end)
mkS("Height", 50, 2000, CONFIG.ColumnHeight, function(v) CONFIG.ColumnHeight = v end)

mkSec("AIMBOT")
mkT("Aimbot", CONFIG.Aim, function(v) CONFIG.Aim = v end)
mkS("FOV", 10, 500, CONFIG.AimFOV, function(v) CONFIG.AimFOV = v end)
mkS("Smooth %", 1, 100, CONFIG.AimSmooth*100, function(v) CONFIG.AimSmooth = v/100 end)

mkSec("SILENT")
mkT("Silent", CONFIG.Silent, function(v) CONFIG.Silent = v end)
mkS("FOV", 10, 500, CONFIG.SilentFOV, function(v) CONFIG.SilentFOV = v end)
mkS("Hit %", 0, 100, CONFIG.SilentHit, function(v) CONFIG.SilentHit = v end)

mkSec("MOVE")
mkT("Speed", CONFIG.Speed, function(v) CONFIG.Speed = v end)
mkS("Speed Val", 16, 300, CONFIG.SpeedVal, function(v) CONFIG.SpeedVal = v end)
mkT("Jump", CONFIG.Jump, function(v) CONFIG.Jump = v end)
mkS("Jump Power", 50, 500, CONFIG.JumpVal, function(v) CONFIG.JumpVal = v end)

local dragStart, startPos
hdr.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragStart = i.Position; startPos = panel.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragStart and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragStart = nil end
end)

openBtn.MouseButton1Click:Connect(function() panel.Visible = not panel.Visible end)

-- AIM кнопка слева
local aimBtn = Instance.new("TextButton")
aimBtn.Size = UDim2.new(0, 70, 0, 70)
aimBtn.Position = UDim2.new(0, 20, 0, 260)
aimBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
aimBtn.BackgroundTransparency = 0.3
aimBtn.Text = "AIM"
aimBtn.TextColor3 = Color3.fromRGB(255,255,255)
aimBtn.TextScaled = true
aimBtn.Font = Enum.Font.GothamBold
aimBtn.Parent = sg
Instance.new("UICorner", aimBtn).CornerRadius = UDim.new(1, 0)
aimBtn.MouseButton1Down:Connect(function() CONFIG.AimHeld = true end)
aimBtn.MouseButton1Up:Connect(function() CONFIG.AimHeld = false end)
aimBtn.MouseLeave:Connect(function() CONFIG.AimHeld = false end)

print("[R] FULL loaded with hooks")
