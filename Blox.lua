-- [R] WH + TRIGGERBOT + HITBOX + COLUMN | Полный
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera
local PG = LP:WaitForChild("PlayerGui")

local CONFIG = {
    -- ESP
    ESP = true, ESPBox = true, ESPName = true, ESPHP = true, ESPDist = true,
    ESPMaxDist = 800, ESPColor = Color3.fromRGB(255, 60, 60),
    -- Hitbox (большая голова)
    Hitbox = false, HitboxSize = 8, HitboxTransparency = 0.3,
    -- Column (красный столб)
    Column = false, ColumnHeight = 500, ColumnWidth = 5,
    -- Triggerbot
    TB = true, TBRadius = 60, TBDelay = 0.15,
    TBWallCheck = false,
    TBParts = {"Head", "UpperTorso", "Torso", "HumanoidRootPart", "LowerTorso"},
    -- Fire coords
    FIRE_X = 1650, FIRE_Y = 500
}

local espCache = {}
local hitboxCache = {}
local columnCache = {}
local lastShot = 0
local shooting = false

--========== HELPERS ==========
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
local function getHP(char)
    local h = char:GetAttribute("Health"); local m = char:GetAttribute("MaxHealth")
    if h and m then return h, m end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health, hum.MaxHealth end
    return 100, 100
end

--========== ESP ==========
local function mkESP(p)
    if p == LP or espCache[p] then return end
    local b = Drawing.new("Square"); b.Thickness = 1; b.Filled = false; b.Transparency = 1; b.Visible = false
    local o = Drawing.new("Square"); o.Thickness = 2; o.Filled = false; o.Transparency = 0.5; o.Color = Color3.fromRGB(0,0,0); o.Visible = false
    local n = Drawing.new("Text"); n.Size = 14; n.Center = true; n.Outline = true; n.Visible = false
    local h = Drawing.new("Square"); h.Thickness = 1; h.Filled = true; h.Transparency = 1; h.Visible = false
    local d = Drawing.new("Text"); d.Size = 12; d.Center = true; d.Outline = true; d.Visible = false
    espCache[p] = {b=b, o=o, n=n, h=h, d=d}
end
local function hideE(e)
    e.b.Visible = false; e.o.Visible = false; e.n.Visible = false; e.h.Visible = false; e.d.Visible = false
end

RunService.RenderStepped:Connect(function()
    for p, e in pairs(espCache) do
        if not CONFIG.ESP then hideE(e) continue end
        local char = p.Character
        if not ok(char) or dead(char) then hideE(e) continue end
        local head = char:FindFirstChild("Head")
        local root = char:FindFirstChild("HumanoidRootPart")
        local dist = (Cam.CFrame.Position - root.Position).Magnitude
        if dist > CONFIG.ESPMaxDist then hideE(e) continue end
        local hp, on = Cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local fp = Cam:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))
        if not on or hp.Z <= 0 then hideE(e) continue end
        local vp = Cam.ViewportSize
        if hp.X < -300 or hp.Y < -300 or hp.X > vp.X + 300 or hp.Y > vp.Y + 300 then hideE(e) continue end
        local hh = math.abs(fp.Y - hp.Y)
        if hh < 8 or hh > 800 then hideE(e) continue end
        local w = hh * 0.55
        local bx, by = hp.X - w/2, hp.Y
        if CONFIG.ESPBox then
            e.o.Size = Vector2.new(w+2, hh+2); e.o.Position = Vector2.new(bx-1, by-1); e.o.Visible = true
            e.b.Size = Vector2.new(w, hh); e.b.Position = Vector2.new(bx, by); e.b.Color = CONFIG.ESPColor; e.b.Visible = true
        else e.b.Visible = false; e.o.Visible = false end
        if CONFIG.ESPName then
            e.n.Position = Vector2.new(hp.X, by - 20); e.n.Text = p.Name; e.n.Color = CONFIG.ESPColor; e.n.Visible = true
        else e.n.Visible = false end
        if CONFIG.ESPHP then
            local chp, mhp = getHP(char)
            local pct = mhp > 0 and math.clamp(chp/mhp, 0, 1) or 1
            e.h.Size = Vector2.new(3, hh*pct); e.h.Position = Vector2.new(bx - 7, by + hh*(1-pct))
            e.h.Color = Color3.fromRGB(255*(1-pct), 255*pct, 0); e.h.Visible = true
        else e.h.Visible = false end
        if CONFIG.ESPDist then
            e.d.Position = Vector2.new(hp.X, by + hh + 4); e.d.Text = string.format("[%d]", math.floor(dist))
            e.d.Color = Color3.fromRGB(220, 220, 220); e.d.Visible = true
        else e.d.Visible = false end
    end
end)

for _, p in ipairs(Players:GetPlayers()) do mkESP(p) end
Players.PlayerAdded:Connect(mkESP)
Players.PlayerRemoving:Connect(function(p)
    local e = espCache[p]
    if e then for _, v in pairs(e) do if v.Remove then v:Remove() end end espCache[p] = nil end
end)

--========== HITBOX + COLUMN ==========
RunService.Heartbeat:Connect(function()
    -- Hitbox
    if CONFIG.Hitbox then
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            local char = p.Character
            if ok(char) then
                local head = char:FindFirstChild("Head")
                if head then
                    pcall(function()
                        head.Size = Vector3.new(CONFIG.HitboxSize, CONFIG.HitboxSize, CONFIG.HitboxSize)
                        head.Transparency = CONFIG.HitboxTransparency
                        head.CanCollide = false
                        head.Material = Enum.Material.Neon
                        head.BrickColor = BrickColor.new("Bright red")
                    end)
                    hitboxCache[p] = true
                end
            elseif hitboxCache[p] then
                hitboxCache[p] = nil
            end
        end
    else
        for p in pairs(hitboxCache) do
            local char = p.Character
            local head = char and char:FindFirstChild("Head")
            if head then
                pcall(function()
                    head.Size = Vector3.new(2, 1, 1)
                    head.Transparency = 0
                    head.CanCollide = true
                end)
            end
            hitboxCache[p] = nil
        end
    end
    
    -- Column
    if CONFIG.Column then
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            local char = p.Character
            if ok(char) and not columnCache[p] then
                local head = char:FindFirstChild("Head")
                if head then
                    local col = Instance.new("Part")
                    col.Name = "R_Col_" .. p.Name
                    col.Size = Vector3.new(CONFIG.ColumnWidth, CONFIG.ColumnHeight, CONFIG.ColumnWidth)
                    col.Anchored = true
                    col.CanCollide = false
                    col.CanQuery = false
                    col.CanTouch = false
                    col.Material = Enum.Material.Neon
                    col.Color = Color3.fromRGB(255, 40, 40)
                    col.Transparency = 0.3
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
                if head and col.Parent then
                    col.Position = head.Position + Vector3.new(0, CONFIG.ColumnHeight/2, 0)
                end
            end
        end
    else
        for p, col in pairs(columnCache) do
            if col.Parent then col:Destroy() end
            columnCache[p] = nil
        end
    end
end)

--========== TRIGGERBOT ==========
local function getTargetInCrosshair()
    local vp = Cam.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local char = p.Character
        if not ok(char) or dead(char) then continue end
        for _, partName in ipairs(CONFIG.TBParts) do
            local part = char:FindFirstChild(partName)
            if part then
                local sp, on = Cam:WorldToViewportPoint(part.Position)
                if on and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < CONFIG.TBRadius then
                        if CONFIG.TBWallCheck then
                            local rp = RaycastParams.new()
                            rp.FilterDescendantsInstances = {LP.Character, Cam}
                            rp.FilterType = Enum.RaycastFilterType.Exclude
                            local res = Workspace:Raycast(Cam.CFrame.Position, (part.Position - Cam.CFrame.Position), rp)
                            if res and not res.Instance:IsDescendantOf(char) then continue end
                        end
                        return part, p
                    end
                end
            end
        end
    end
    return nil
end

local function fireClick()
    if shooting then return end
    shooting = true
    task.spawn(function()
        pcall(function()
            VIM:SendMouseButtonEvent(CONFIG.FIRE_X, CONFIG.FIRE_Y, 0, true, game, 1)
        end)
        task.wait(0.05)
        pcall(function()
            VIM:SendMouseButtonEvent(CONFIG.FIRE_X, CONFIG.FIRE_Y, 0, false, game, 1)
        end)
        shooting = false
    end)
end

--========== GUI ==========
local sg = Instance.new("ScreenGui")
sg.Name = "R_WH_FULL"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = PG

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 60, 0, 60)
openBtn.Position = UDim2.new(0, 20, 0, 180)
openBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
openBtn.BackgroundTransparency = 0.15
openBtn.Text = "R"
openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openBtn.TextScaled = true
openBtn.Font = Enum.Font.GothamBold
openBtn.Parent = sg
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 360, 0, 800)
panel.Position = UDim2.new(0, 100, 0, 80)
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
ttl.Text = "[R] WH + Trigger + Hitbox"
ttl.TextColor3 = Color3.fromRGB(255, 255, 255)
ttl.TextXAlignment = Enum.TextXAlignment.Left
ttl.Font = Enum.Font.GothamBold
ttl.TextSize = 18
ttl.Parent = hdr

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -110)
scroll.Position = UDim2.new(0, 8, 0, 54)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.CanvasSize = UDim2.new(0, 0, 0, 2500)
scroll.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = scroll

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
    l.Parent = scroll
    Instance.new("UICorner", l).CornerRadius = UDim.new(0, 5)
end

local function mkT(t, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -8, 0, 38)
    f.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    f.BorderSizePixel = 0
    f.Parent = scroll
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
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    f.Size = UDim2.new(1, -8, 0, 58)
    f.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    f.BorderSizePixel = 0
    f.Parent = scroll
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
mkT("Box", CONFIG.ESPBox, function(v) CONFIG.ESPBox = v end)
mkT("Name", CONFIG.ESPName, function(v) CONFIG.ESPName = v end)
mkT("Health", CONFIG.ESPHP, function(v) CONFIG.ESPHP = v end)
mkT("Distance", CONFIG.ESPDist, function(v) CONFIG.ESPDist = v end)
mkS("Max Dist", 50, 2000, CONFIG.ESPMaxDist, function(v) CONFIG.ESPMaxDist = v end)

mkSec("HITBOX (большая голова)")
mkT("Hitbox", CONFIG.Hitbox, function(v) CONFIG.Hitbox = v end)
mkS("Размер головы", 3, 30, CONFIG.HitboxSize, function(v) CONFIG.HitboxSize = v end)
mkS("Прозрачность %", 0, 100, CONFIG.HitboxTransparency * 100, function(v) CONFIG.HitboxTransparency = v / 100 end)

mkSec("COLUMN (столб до неба)")
mkT("Column", CONFIG.Column, function(v) CONFIG.Column = v end)
mkS("Высота", 50, 2000, CONFIG.ColumnHeight, function(v) CONFIG.ColumnHeight = v end)
mkS("Ширина", 1, 30, CONFIG.ColumnWidth, function(v) CONFIG.ColumnWidth = v end)

mkSec("TRIGGERBOT")
mkT("Triggerbot", CONFIG.TB, function(v) CONFIG.TB = v end)
mkS("Радиус (px)", 5, 200, CONFIG.TBRadius, function(v) CONFIG.TBRadius = v end)
mkS("Задержка x100", 5, 50, math.floor(CONFIG.TBDelay*100), function(v) CONFIG.TBDelay = v/100 end)
mkT("Wall Check", CONFIG.TBWallCheck, function(v) CONFIG.TBWallCheck = v end)

mkSec("FIRE BUTTON POS")
mkS("Fire X", 0, 2800, CONFIG.FIRE_X, function(v) CONFIG.FIRE_X = v end)
mkS("Fire Y", 0, 1400, CONFIG.FIRE_Y, function(v) CONFIG.FIRE_Y = v end)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -16, 0, 40)
status.Position = UDim2.new(0, 8, 1, -50)
status.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
status.Text = "TB: жду"
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.Font = Enum.Font.Code
status.TextSize = 14
status.Parent = panel
Instance.new("UICorner", status).CornerRadius = UDim.new(0, 6)

local tbBtn = Instance.new("TextButton")
tbBtn.Size = UDim2.new(0, 100, 0, 100)
tbBtn.Position = UDim2.new(0, 20, 0, 260)
tbBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
tbBtn.BackgroundTransparency = 0.25
tbBtn.Text = "TB ON"
tbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tbBtn.TextScaled = true
tbBtn.Font = Enum.Font.GothamBold
tbBtn.Parent = sg
Instance.new("UICorner", tbBtn).CornerRadius = UDim.new(1, 0)
tbBtn.MouseButton1Click:Connect(function()
    CONFIG.TB = not CONFIG.TB
    tbBtn.Text = CONFIG.TB and "TB ON" or "TB OFF"
    tbBtn.BackgroundColor3 = CONFIG.TB and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(100, 30, 30)
end)

local hbBtn = Instance.new("TextButton")
hbBtn.Size = UDim2.new(0, 100, 0, 100)
hbBtn.Position = UDim2.new(0, 20, 0, 380)
hbBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
hbBtn.BackgroundTransparency = 0.25
hbBtn.Text = "HB OFF"
hbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hbBtn.TextScaled = true
hbBtn.Font = Enum.Font.GothamBold
hbBtn.Parent = sg
Instance.new("UICorner", hbBtn).CornerRadius = UDim.new(1, 0)
hbBtn.MouseButton1Click:Connect(function()
    CONFIG.Hitbox = not CONFIG.Hitbox
    hbBtn.Text = CONFIG.Hitbox and "HB ON" or "HB OFF"
    hbBtn.BackgroundColor3 = CONFIG.Hitbox and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(30, 30, 40)
end)

local colBtn = Instance.new("TextButton")
colBtn.Size = UDim2.new(0, 100, 0, 100)
colBtn.Position = UDim2.new(0, 20, 0, 500)
colBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
colBtn.BackgroundTransparency = 0.25
colBtn.Text = "COL OFF"
colBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
colBtn.TextScaled = true
colBtn.Font = Enum.Font.GothamBold
colBtn.Parent = sg
Instance.new("UICorner", colBtn).CornerRadius = UDim.new(1, 0)
colBtn.MouseButton1Click:Connect(function()
    CONFIG.Column = not CONFIG.Column
    colBtn.Text = CONFIG.Column and "COL ON" or "COL OFF"
    colBtn.BackgroundColor3 = CONFIG.Column and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(30, 30, 40)
end)

-- FIRE точка
local fireDot = Drawing.new("Circle")
fireDot.Radius = 10
fireDot.Filled = true
fireDot.Color = Color3.fromRGB(255, 200, 0)
fireDot.Transparency = 0.5
fireDot.Visible = true

-- Crosshair
local tbCircle = Drawing.new("Circle")
tbCircle.Thickness = 2
tbCircle.NumSides = 40
tbCircle.Filled = false
tbCircle.Color = Color3.fromRGB(0, 255, 100)
tbCircle.Transparency = 0.7
tbCircle.Visible = true
tbCircle.Radius = CONFIG.TBRadius

-- Drag
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

--========== MAIN LOOP ==========
RunService.RenderStepped:Connect(function()
    tbCircle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    tbCircle.Radius = CONFIG.TBRadius
    tbCircle.Visible = CONFIG.TB
    
    fireDot.Position = Vector2.new(CONFIG.FIRE_X, CONFIG.FIRE_Y)
    fireDot.Visible = CONFIG.TB
    
    if not CONFIG.TB then
        status.Text = "TB: OFF"
        status.TextColor3 = Color3.fromRGB(150, 150, 150)
        return
    end
    
    local target, player = getTargetInCrosshair()
    if target then
        status.Text = "ЦЕЛЬ: " .. (player and player.Name or "?")
        status.TextColor3 = Color3.fromRGB(0, 255, 100)
        local now = tick()
        if now - lastShot >= CONFIG.TBDelay and not shooting then
            lastShot = now
            fireClick()
        end
    else
        status.Text = "TB: жду цель"
        status.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

print("[R] WH + Trigger + Hitbox + Column loaded")
