--==================================================================
--  [R] ULTRA FRAMEWORK for BloxStrike
--  Executor: Delta Mobile / Xeno / Wave
--  Всё в одном: WH + Aimbot + Silent + Hooks + Diagnostics
--==================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--================== CONFIG ==================
local CONFIG = {
    -- ESP
    ESP = true, ESPBox = true, ESPName = true, ESPHealth = true, ESPDist = true,
    ESPMaxDist = 500, ESPColor = Color3.fromRGB(255, 60, 60),
    ESPTracer = false, ESPHeadDot = true,
    -- Hitbox
    Hitbox = false, HitboxSize = 8, HitboxTransparency = 0.3,
    Column = false, ColumnHeight = 500, ColumnWidth = 5,
    -- Aimbot
    Aim = true, AimFOV = 120, AimSmooth = 0.2, AimPart = "Head",
    AimWallCheck = false, AimTeamCheck = true, AimHeld = false,
    AimKey = Enum.UserInputType.MouseButton2,
    -- Silent
    Silent = true, SilentFOV = 200, SilentHitChance = 100,
    SilentWallCheck = false, SilentTeamCheck = true,
    -- Movement
    Speed = true, SpeedVal = 50,
    Jump = true, JumpVal = 150,
    Fly = false, FlySpeed = 80,
    -- Hooks
    HookRemotes = true,
    -- Visual
    DrawFOV = true
}

local espCache = {}
local hitboxCache = {}
local columnCache = {}
local flyVel, flyGyro
local remoteLog = {}
local discoveredRemotes = {}

--================== UTILS ===================
local function isValidChar(char)
    if not char then return false end
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
    return head ~= nil and root ~= nil
end

local function getValidPos(char)
    local head = char and char:FindFirstChild("Head")
    if not head then return nil end
    local p = head.Position
    -- отсев (0, 106, 0)
    if math.abs(p.X) < 0.5 and math.abs(p.Z) < 0.5 then return nil end
    if math.abs(p.X) > 20000 or math.abs(p.Y) > 20000 or math.abs(p.Z) > 20000 then return nil end
    return p
end

local function isTeammate(p, enabled)
    if not enabled then return false end
    return p.Team ~= nil and p.Team == LocalPlayer.Team
end

local function isDead(char)
    local d = char:GetAttribute("Dead")
    if d ~= nil then return d end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health <= 0 end
    return false
end

local function getHP(char)
    local h, mh = char:GetAttribute("Health"), char:GetAttribute("MaxHealth")
    if h and mh then return h, mh end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health, hum.MaxHealth end
    return 100, 100
end

local function getScreenCenter()
    local vp = Camera.ViewportSize
    return Vector2.new(vp.X / 2, vp.Y / 2), vp
end

local function fovToPixels(deg)
    local vp = Camera.ViewportSize
    local diag = math.sqrt(vp.X^2 + vp.Y^2)
    return (deg / 90) * (diag / 2)
end

--================== SCAN REMOTES ===================
local function scanRemotes()
    local found = {}
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("UnreliableRemoteEvent") then
            table.insert(found, obj:GetFullName())
        end
    end
    return found
end

--================== HOOKS ===================
local function installHooks()
    local mt = getrawmetatable(game)
    if not mt then
        return false, "getrawmetatable недоступен"
    end

    local oldNamecall = mt.__namecall
    local oldIndex = mt.__index

    setreadonly(mt, false)

    -- namecall hook — ловит все вызовы методов через двоеточие
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()

        -- Лог ремоутов (для отладки)
        if CONFIG.HookRemotes and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
            local name = self:GetFullName()
            if not discoveredRemotes[name] then
                discoveredRemotes[name] = true
                table.insert(remoteLog, name)
            end
        end

        -- SILENT AIM
        if CONFIG.Silent and (method == "Fire" or method == "FireServer" or method == "InvokeServer") then
            local args = {...}
            if typeof(args[1]) == "Vector3" or typeof(args[1]) == "CFrame" then
                local target = getClosest(CONFIG.SilentFOV, CONFIG.SilentWallCheck, CONFIG.SilentTeamCheck)
                if target and math.random(1, 100) <= CONFIG.SilentHitChance then
                    local char = target.Character
                    local part = char and (char:FindFirstChild(CONFIG.AimPart) or char:FindFirstChild("HumanoidRootPart"))
                    if part then
                        if typeof(args[1]) == "Vector3" then
                            args[1] = part.Position
                        elseif typeof(args[1]) == "CFrame" then
                            args[1] = CFrame.new(part.Position)
                        end
                    end
                end
                return oldNamecall(self, table.unpack(args))
            end
        end

        return oldNamecall(self, ...)
    end)

    -- index hook — ловит прямые вызовы .Fire()
    mt.__index = newcclosure(function(self, key)
        local val = oldIndex(self, key)
        if CONFIG.HookRemotes and typeof(val) == "function" and (key == "Fire" or key == "FireServer" or key == "InvokeServer") then
            if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                local name = self:GetFullName()
                if not discoveredRemotes[name] then
                    discoveredRemotes[name] = true
                    table.insert(remoteLog, name)
                end
            end
        end
        return val
    end)

    setreadonly(mt, true)
    return true, "hooks installed"
end

--================== GET CLOSEST ===================
function getClosest(fovDeg, wallCheck, teamCheck)
    local center, vp = getScreenCenter()
    local fovPx = fovToPixels(fovDeg)
    local closest, cd = nil, math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if isTeammate(p, teamCheck) then continue end
        local char = p.Character
        if not isValidChar(char) then continue end
        if isDead(char) then continue end

        local pos = getValidPos(char)
        if not pos then continue end

        local part = char:FindFirstChild(CONFIG.AimPart) or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end

        local sp, on = Camera:WorldToViewportPoint(part.Position)
        if not on or sp.Z <= 0 or sp.Z > 10000 then continue end
        if sp.X < -500 or sp.Y < -500 or sp.X > vp.X + 500 or sp.Y > vp.Y + 500 then continue end

        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < fovPx and d < cd then cd = d; closest = p end
    end
    return closest
end

--================== ESP ===================
local function createESP(p)
    if p == LocalPlayer or espCache[p] then return end
    local box = Drawing.new("Square")
    box.Thickness = 1; box.Filled = false; box.Transparency = 1; box.Visible = false
    local outline = Drawing.new("Square")
    outline.Thickness = 2; outline.Filled = false; outline.Transparency = 0.4
    outline.Color = Color3.fromRGB(0, 0, 0); outline.Visible = false
    local nm = Drawing.new("Text")
    nm.Size = 14; nm.Center = true; nm.Outline = true; nm.Visible = false
    local hb = Drawing.new("Square")
    hb.Thickness = 1; hb.Filled = true; hb.Transparency = 1; hb.Visible = false
    local dt = Drawing.new("Text")
    dt.Size = 12; dt.Center = true; dt.Outline = true; dt.Visible = false
    local tracer = Drawing.new("Line")
    tracer.Thickness = 1; tracer.Transparency = 0.7; tracer.Visible = false
    local dot = Drawing.new("Circle")
    dot.Radius = 4; dot.Filled = true; dot.Transparency = 1; dot.Visible = false
    espCache[p] = {box = box, outline = outline, name = nm, hb = hb, dist = dt, tracer = tracer, dot = dot}
end

local function hideESP(d)
    d.box.Visible = false; d.outline.Visible = false; d.name.Visible = false
    d.hb.Visible = false; d.dist.Visible = false; d.tracer.Visible = false; d.dot.Visible = false
end

RunService.RenderStepped:Connect(function()
    for p, d in pairs(espCache) do
        if not CONFIG.ESP then hideESP(d) continue end
        local char = p.Character
        if not isValidChar(char) or isDead(char) then hideESP(d) continue end
        local head = char:FindFirstChild("Head")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not head or not root then hideESP(d) continue end

        local dist = (Camera.CFrame.Position - root.Position).Magnitude
        if dist > CONFIG.ESPMaxDist then hideESP(d) continue end

        local hp, on = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local fp = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))
        local vp = Camera.ViewportSize

        if not on or hp.Z <= 0 or hp.Z > 10000 then hideESP(d) continue end
        if hp.X < -300 or hp.Y < -300 or hp.X > vp.X + 300 or hp.Y > vp.Y + 300 then hideESP(d) continue end

        local h = math.abs(fp.Y - hp.Y)
        if h < 8 then h = 8 end
        if h > 800 then hideESP(d) continue end
        local w = h * 0.55
        local bx, by = hp.X - w / 2, hp.Y

        if CONFIG.ESPBox then
            d.outline.Size = Vector2.new(w + 2, h + 2)
            d.outline.Position = Vector2.new(bx - 1, by - 1)
            d.outline.Visible = true
            d.box.Size = Vector2.new(w, h)
            d.box.Position = Vector2.new(bx, by)
            d.box.Color = CONFIG.ESPColor
            d.box.Visible = true
        else d.box.Visible = false; d.outline.Visible = false end

        if CONFIG.ESPName then
            d.name.Position = Vector2.new(hp.X, by - 20)
            d.name.Text = p.Name
            d.name.Color = CONFIG.ESPColor
            d.name.Visible = true
        else d.name.Visible = false end

        if CONFIG.ESPHealth then
            local chp, mhp = getHP(char)
            local pct = mhp > 0 and math.clamp(chp / mhp, 0, 1) or 0
            d.hb.Size = Vector2.new(3, h * pct)
            d.hb.Position = Vector2.new(bx - 7, by + h * (1 - pct))
            d.hb.Color = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
            d.hb.Visible = true
        else d.hb.Visible = false end

        if CONFIG.ESPDist then
            d.dist.Position = Vector2.new(hp.X, by + h + 4)
            d.dist.Text = string.format("[%d]", math.floor(dist))
            d.dist.Visible = true
        else d.dist.Visible = false end

        if CONFIG.ESPTracer then
            d.tracer.From = Vector2.new(vp.X / 2, vp.Y)
            d.tracer.To = Vector2.new(hp.X, by + h)
            d.tracer.Color = CONFIG.ESPColor
            d.tracer.Visible = true
        else d.tracer.Visible = false end

        if CONFIG.ESPHeadDot then
            d.dot.Position = Vector2.new(hp.X, hp.Y)
            d.dot.Color = CONFIG.ESPColor
            d.dot.Visible = true
        else d.dot.Visible = false end
    end
end)

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p)
    local d = espCache[p]
    if d then for _, v in pairs(d) do if v.Remove then v:Remove() end end espCache[p] = nil end
end)

--================== HITBOX ===================
local function applyHitbox(p)
    if p == LocalPlayer then return end
    local char = p.Character
    if not isValidChar(char) then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    pcall(function()
        head.Size = Vector3.new(CONFIG.HitboxSize, CONFIG.HitboxSize, CONFIG.HitboxSize)
        head.Transparency = CONFIG.HitboxTransparency
        head.CanCollide = false
        head.Material = Enum.Material.Neon
        head.BrickColor = BrickColor.new("Bright red")
    end)
    hitboxCache[p] = true
end

local function resetHitbox(p)
    local char = p.Character
    local head = char and char:FindFirstChild("Head")
    if head then
        pcall(function()
            head.Size = Vector3.new(2, 1, 1)
            head.Transparency = 0
            head.CanCollide = true
            head.Material = Enum.Material.Plastic
        end)
    end
    hitboxCache[p] = nil
end

--================== COLUMN ===================
local function applyColumn(p)
    if p == LocalPlayer or columnCache[p] then return end
    local char = p.Character
    if not isValidChar(char) then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local col = Instance.new("Part")
    col.Name = "R_Col_" .. p.Name
    col.Size = Vector3.new(CONFIG.ColumnWidth, CONFIG.ColumnHeight, CONFIG.ColumnWidth)
    col.Anchored = true
    col.CanCollide = false
    col.CanQuery = false
    col.CanTouch = false
    col.Material = Enum.Material.Neon
    col.Color = CONFIG.ESPColor
    col.Transparency = 0.3
    col.Position = head.Position + Vector3.new(0, CONFIG.ColumnHeight / 2, 0)
    col.Parent = Workspace
    columnCache[p] = col
end

local function removeColumn(p)
    local c = columnCache[p]
    if c and c.Parent then c:Destroy() end
    columnCache[p] = nil
end

--================== MAIN LOOP ===================
RunService.Heartbeat:Connect(function()
    -- Hitbox
    if CONFIG.Hitbox then
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            if isValidChar(p.Character) and not hitboxCache[p] then applyHitbox(p) end
        end
        for p in pairs(hitboxCache) do
            if not isValidChar(p.Character) then resetHitbox(p) end
        end
    end

    -- Column
    if CONFIG.Column then
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local char = p.Character
            if isValidChar(char) and not columnCache[p] then applyColumn(p) end
        end
        for p, col in pairs(columnCache) do
            local char = p.Character
            if not isValidChar(char) then removeColumn(p) continue end
            local head = char:FindFirstChild("Head")
            if head and col.Parent then
                col.Position = head.Position + Vector3.new(0, CONFIG.ColumnHeight / 2, 0)
            end
        end
    else
        for p in pairs(columnCache) do removeColumn(p) end
    end

    -- Speed / Jump
    local myChar = LocalPlayer.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if myHum then
        if CONFIG.Speed then myHum.WalkSpeed = CONFIG.SpeedVal end
        if CONFIG.Jump then
            myHum.UseJumpPower = true
            myHum.JumpPower = CONFIG.JumpVal
        end
    end
end)

--================== AIMBOT ===================
RunService.RenderStepped:Connect(function()
    if not CONFIG.Aim then return end
    local held = CONFIG.AimHeld or UserInputService:IsMouseButtonPressed(CONFIG.AimKey)
    if not held then return end
    local target = getClosest(CONFIG.AimFOV, CONFIG.AimWallCheck, CONFIG.AimTeamCheck)
    if not target then return end
    local char = target.Character
    local part = char and char:FindFirstChild(CONFIG.AimPart)
    if not part then return end
    local pos = part.Position + part.AssemblyLinearVelocity * 0.05
    Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, pos), CONFIG.AimSmooth)
end)

--================== FLY ===================
local function startFly()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    flyVel = Instance.new("BodyVelocity")
    flyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyVel.Velocity = Vector3.zero
    flyVel.Parent = root
    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyGyro.CFrame = root.CFrame
    flyGyro.P = 1000
    flyGyro.Parent = root
end

local function stopFly()
    if flyVel then flyVel:Destroy() flyVel = nil end
    if flyGyro then flyGyro:Destroy() flyGyro = nil end
end

RunService.RenderStepped:Connect(function()
    if not CONFIG.Fly or not flyVel or not flyGyro then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local move = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0, 1, 0) end
    flyVel.Velocity = move.Magnitude > 0 and move.Unit * CONFIG.FlySpeed or Vector3.zero
    flyGyro.CFrame = Camera.CFrame
end)

--================== GUI ===================
local sg = Instance.new("ScreenGui")
sg.Name = "R_Ultra"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = PlayerGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 60, 0, 60)
toggleBtn.Position = UDim2.new(0, 20, 0, 180)
toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
toggleBtn.BackgroundTransparency = 0.15
toggleBtn.Text = "R"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = sg
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 380, 0, 620)
panel.Position = UDim2.new(0, 100, 0, 120)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = sg
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
header.BorderSizePixel = 0
header.Parent = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "[R] ULTRA | BloxStrike"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = header

-- табы
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -16, 0, 36)
tabBar.Position = UDim2.new(0, 8, 0, 54)
tabBar.BackgroundTransparency = 1
tabBar.Parent = panel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabBar

local pages = {}
local currentPage = nil
local function switchTab(name)
    for n, page in pairs(pages) do
        page.Visible = (n == name)
    end
    currentPage = name
end

local function makeTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = tabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -16, 1, -106)
    page.Position = UDim2.new(0, 8, 0, 98)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 5
    page.CanvasSize = UDim2.new(0, 0, 0, 1500)
    page.Visible = false
    page.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    pages[name] = page

    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    return page
end

local function makeToggle(parent, text, default, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -8, 0, 38)
    f.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    f.BorderSizePixel = 0
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 15, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.Parent = f
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 56, 0, 26)
    btn.Position = UDim2.new(1, -70, 0.5, -13)
    btn.BackgroundColor3 = default and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(60, 60, 70)
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = f
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local s = default
    btn.MouseButton1Click:Connect(function()
        s = not s
        btn.Text = s and "ON" or "OFF"
        btn.BackgroundColor3 = s and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(60, 60, 70)
        cb(s)
    end)
end

local function makeSlider(parent, text, min, max, default, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -8, 0, 58)
    f.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    f.BorderSizePixel = 0
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 22)
    lbl.Position = UDim2.new(0, 15, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. default
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.Parent = f
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -30, 0, 10)
    bar.Position = UDim2.new(0, 15, 0, 34)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    bar.BorderSizePixel = 0
    bar.Parent = f
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local dragging = false
    local function setVal(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = text .. ": " .. val
        cb(val)
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; setVal(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setVal(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function makeSection(parent, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -8, 0, 28)
    l.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    l.Text = "  " .. text
    l.TextColor3 = Color3.fromRGB(180, 180, 255)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    l.BorderSizePixel = 0
    l.Parent = parent
    Instance.new("UICorner", l).CornerRadius = UDim.new(0, 5)
end

--===== ESP TAB =====
local espPage = makeTab("ESP")
makeSection(espPage, "ОСНОВА")
makeToggle(espPage, "ESP включён", CONFIG.ESP, function(v) CONFIG.ESP = v end)
makeToggle(espPage, "Box", CONFIG.ESPBox, function(v) CONFIG.ESPBox = v end)
makeToggle(espPage, "Name", CONFIG.ESPName, function(v) CONFIG.ESPName = v end)
makeToggle(espPage, "Health", CONFIG.ESPHealth, function(v) CONFIG.ESPHealth = v end)
makeToggle(espPage, "Distance", CONFIG.ESPDist, function(v) CONFIG.ESPDist = v end)
makeToggle(espPage, "Head Dot", CONFIG.ESPHeadDot, function(v) CONFIG.ESPHeadDot = v end)
makeToggle(espPage, "Tracer", CONFIG.ESPTracer, function(v) CONFIG.ESPTracer = v end)
makeSection(espPage, "ДАЛЬНОСТЬ")
makeSlider(espPage, "Max Distance", 50, 2000, CONFIG.ESPMaxDist, function(v) CONFIG.ESPMaxDist = v end)

--===== HITBOX TAB =====
local hitPage = makeTab("Hitbox")
makeToggle(hitPage, "Большая голова", CONFIG.Hitbox, function(v)
    CONFIG.Hitbox = v
    if not v then for p in pairs(hitboxCache) do resetHitbox(p) end end
end)
makeSlider(hitPage, "Размер головы", 3, 30, CONFIG.HitboxSize, function(v) CONFIG.HitboxSize = v end)
makeSlider(hitPage, "Прозрачность %", 0, 100, CONFIG.HitboxTransparency * 100, function(v) CONFIG.HitboxTransparency = v / 100 end)
makeToggle(hitPage, "Красный столб", CONFIG.Column, function(v) CONFIG.Column = v end)
makeSlider(hitPage, "Высота столба", 50, 2000, CONFIG.ColumnHeight, function(v) CONFIG.ColumnHeight = v end)
makeSlider(hitPage, "Ширина столба", 1, 30, CONFIG.ColumnWidth, function(v) CONFIG.ColumnWidth = v end)

--===== AIMBOT TAB =====
local aimPage = makeTab("Aimbot")
makeToggle(aimPage, "Aimbot", CONFIG.Aim, function(v) CONFIG.Aim = v end)
makeSlider(aimPage, "FOV", 10, 500, CONFIG.AimFOV, function(v) CONFIG.AimFOV = v end)
makeSlider(aimPage, "Smooth %", 1, 100, CONFIG.AimSmooth * 100, function(v) CONFIG.AimSmooth = v / 100 end)
makeToggle(aimPage, "Wall Check", CONFIG.AimWallCheck, function(v) CONFIG.AimWallCheck = v end)
makeToggle(aimPage, "Team Check", CONFIG.AimTeamCheck, function(v) CONFIG.AimTeamCheck = v end)

--===== SILENT TAB =====
local silPage = makeTab("Silent")
makeToggle(silPage, "Silent Aim", CONFIG.Silent, function(v) CONFIG.Silent = v end)
makeSlider(silPage, "FOV", 10, 500, CONFIG.SilentFOV, function(v) CONFIG.SilentFOV = v end)
makeSlider(silPage, "Hit Chance %", 0, 100, CONFIG.SilentHitChance, function(v) CONFIG.SilentHitChance = v end)
makeToggle(silPage, "Wall Check", CONFIG.SilentWallCheck, function(v) CONFIG.SilentWallCheck = v end)
makeToggle(silPage, "Team Check", CONFIG.SilentTeamCheck, function(v) CONFIG.SilentTeamCheck = v end)

--===== MOVE TAB =====
local movePage = makeTab("Move")
makeToggle(movePage, "Speed", CONFIG.Speed, function(v) CONFIG.Speed = v end)
makeSlider(movePage, "Speed Val", 16, 300, CONFIG.SpeedVal, function(v) CONFIG.SpeedVal = v end)
makeToggle(movePage, "High Jump", CONFIG.Jump, function(v) CONFIG.Jump = v end)
makeSlider(movePage, "Jump Power", 50, 500, CONFIG.JumpVal, function(v) CONFIG.JumpVal = v end)
makeToggle(movePage, "Fly", CONFIG.Fly, function(v)
    CONFIG.Fly = v
    if v then startFly() else stopFly() end
end)
makeSlider(movePage, "Fly Speed", 20, 300, CONFIG.FlySpeed, function(v) CONFIG.FlySpeed = v end)

--===== INFO TAB =====
local infoPage = makeTab("Info")
makeSection(infoPage, "РЕМОУТЫ (лог)")
local remoteLabel = Instance.new("TextLabel")
remoteLabel.Size = UDim2.new(1, -8, 0, 400)
remoteLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
remoteLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
remoteLabel.TextXAlignment = Enum.TextXAlignment.Left
remoteLabel.TextYAlignment = Enum.TextYAlignment.Top
remoteLabel.Font = Enum.Font.Code
remoteLabel.TextSize = 12
remoteLabel.TextWrapped = true
remoteLabel.BorderSizePixel = 0
remoteLabel.Parent = infoPage
Instance.new("UICorner", remoteLabel).CornerRadius = UDim.new(0, 6)

task.spawn(function()
    while true do
        remoteLabel.Text = "Найдено ремоутов: " .. #remoteLog .. "\n\n"
        for i, r in ipairs(remoteLog) do
            remoteLabel.Text = remoteLabel.Text .. i .. ". " .. r .. "\n"
        end
        task.wait(2)
    end
end)

switchTab("ESP")

-- Drag
local dragStart, startPos
header.InputBegan:Connect(function(i)
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
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragStart = nil
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
end)

--========== INSTALL ===========
task.spawn(function()
    local ok, msg = installHooks()
    if not ok then warn("[R] hooks:", msg) end
end)

print("[R] ULTRA loaded | remotes found:", #scanRemotes())
