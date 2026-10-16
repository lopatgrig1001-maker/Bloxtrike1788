-- BloxStrike Mobile | Собственное меню | Aimbot + Silent Aim + ESP + Bhop
-- Executor: Delta Mobile / Xeno Mobile

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CONFIG = {
    AimEnabled = true,
    AimSmoothness = 0.15,
    AimFOV = 120,
    AimPart = "Head",
    WallCheck = true,
    TeamCheck = true,
    AimHeld = false,

    SilentAimEnabled = true,
    SilentAimHitChance = 100,
    SilentAimFOV = 150,

    ESPEnabled = true,
    ESPBox = true,
    ESPName = true,
    ESPHealth = true,
    ESPDistance = true,
    ESPMaxDistance = 500,

    BhopEnabled = true,
    BhopSpeed = 18,
    BhopHeld = false
}

local espCache = {}
local bhopConn = nil

--========== МЕНЮ ==========
local sg = Instance.new("ScreenGui")
sg.Name = "R_Menu"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = PlayerGui

-- Кнопка открытия/закрытия
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 50, 0, 50)
toggleBtn.Position = UDim2.new(0, 10, 0, 100)
toggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
toggleBtn.Text = "R"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = sg
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

-- Главная панель
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 280, 0, 420)
main.Position = UDim2.new(0, 70, 0, 100)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.BorderSizePixel = 0
main.Visible = false
main.Parent = sg
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

-- Заголовок (перетаскивание)
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
header.BorderSizePixel = 0
header.Parent = main
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "BloxStrike | [R]"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = header

-- Скролл
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -50)
scroll.Position = UDim2.new(0, 5, 0, 45)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, 900)
scroll.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local function makeSection(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 26)
    lbl.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    lbl.Text = "  " .. text
    lbl.TextColor3 = Color3.fromRGB(180, 180, 255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.BorderSizePixel = 0
    lbl.Parent = scroll
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 5)
end

local function makeToggle(text, key, default, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 32)
    f.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    f.BorderSizePixel = 0
    f.Parent = scroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.Parent = f

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 44, 0, 22)
    btn.Position = UDim2.new(1, -54, 0.5, -11)
    btn.BackgroundColor3 = default and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(60, 60, 70)
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = f
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(60, 60, 70)
        if cb then cb(state) end
    end)
end

local function makeSlider(text, key, min, max, default, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 52)
    f.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    f.BorderSizePixel = 0
    f.Parent = scroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. default
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.Parent = f

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 10)
    bar.Position = UDim2.new(0, 10, 0, 32)
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
        if cb then cb(val) end
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setVal(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setVal(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Перетаскивание меню
local dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragStart = nil end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Открыть/закрыть
toggleBtn.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
end)

--========== НАПОЛНЕНИЕ МЕНЮ ==========
makeSection("AIMBOT")
makeToggle("Aimbot", "aim", CONFIG.AimEnabled, function(v) CONFIG.AimEnabled = v end)
makeSlider("FOV", "fov", 10, 360, CONFIG.AimFOV, function(v) CONFIG.AimFOV = v end)
makeSlider("Smoothness %", "sm", 1, 100, math.floor(CONFIG.AimSmoothness * 100), function(v) CONFIG.AimSmoothness = v / 100 end)
makeToggle("Wall Check", "wc", CONFIG.WallCheck, function(v) CONFIG.WallCheck = v end)
makeToggle("Team Check", "tc", CONFIG.TeamCheck, function(v) CONFIG.TeamCheck = v end)

makeSection("SILENT AIM")
makeToggle("Silent Aim", "sa", CONFIG.SilentAimEnabled, function(v) CONFIG.SilentAimEnabled = v end)
makeSlider("Hit Chance %", "hc", 0, 100, CONFIG.SilentAimHitChance, function(v) CONFIG.SilentAimHitChance = v end)
makeSlider("Silent FOV", "sf", 10, 360, CONFIG.SilentAimFOV, function(v) CONFIG.SilentAimFOV = v end)

makeSection("ESP")
makeToggle("ESP", "e", CONFIG.ESPEnabled, function(v) CONFIG.ESPEnabled = v end)
makeToggle("Box", "eb", CONFIG.ESPBox, function(v) CONFIG.ESPBox = v end)
makeToggle("Name", "en", CONFIG.ESPName, function(v) CONFIG.ESPName = v end)
makeToggle("Health", "eh", CONFIG.ESPHealth, function(v) CONFIG.ESPHealth = v end)
makeToggle("Distance", "ed", CONFIG.ESPDistance, function(v) CONFIG.ESPDistance = v end)
makeSlider("Max Dist", "emd", 50, 2000, CONFIG.ESPMaxDistance, function(v) CONFIG.ESPMaxDistance = v end)

makeSection("MOVEMENT")
makeToggle("Bunny Hop", "bh", CONFIG.BhopEnabled, function(v) CONFIG.BhopEnabled = v end)
makeSlider("Bhop Speed", "bs", 10, 50, CONFIG.BhopSpeed, function(v) CONFIG.BhopSpeed = v end)

--========== ЭКРАННЫЕ КНОПКИ ==========
local function makeHoldBtn(text, pos, onDown, onUp)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 75, 0, 75)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    btn.BackgroundTransparency = 0.25
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Parent = sg
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    btn.MouseButton1Down:Connect(onDown)
    btn.MouseButton1Up:Connect(onUp)
    btn.MouseLeave:Connect(onUp)
    btn.TouchLongPress:Connect(onDown)
    btn.MouseButton1Click:Connect(function() onDown(); task.wait(0.1); onUp() end)
end

makeHoldBtn("AIM", UDim2.new(0, 15, 0, 200),
    function() CONFIG.AimHeld = true end,
    function() CONFIG.AimHeld = false end)

makeHoldBtn("JUMP", UDim2.new(0, 15, 0, 290),
    function() CONFIG.BhopHeld = true end,
    function() CONFIG.BhopHeld = false end)

--========== ЛОГИКА ==========
local function isTeammate(p)
    if not CONFIG.TeamCheck then return false end
    return p.Team == LocalPlayer.Team
end

local function isVisible(p)
    if not CONFIG.WallCheck then return true end
    local char = p.Character
    if not char then return false end
    local part = char:FindFirstChild(CONFIG.AimPart) or char:FindFirstChild("HumanoidRootPart")
    if not part then return false end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local res = Workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000, rp)
    if res then return res.Instance:IsDescendantOf(char) end
    return true
end

local function getClosest(fov)
    local closest, cd = nil, math.huge
    local center = Camera.ViewportSize / 2
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or isTeammate(p) then continue end
        local char = p.Character
        if not char then continue end
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local part = char:FindFirstChild(CONFIG.AimPart) or char:FindFirstChild("HumanoidRootPart")
        if not part or not isVisible(p) then continue end
        local sp, on = Camera:WorldToViewportPoint(part.Position)
        if not on then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < fov and d < cd then cd = d; closest = p end
    end
    return closest
end

local function updateAimbot()
    if not CONFIG.AimEnabled or not CONFIG.AimHeld then return end
    local t = getClosest(CONFIG.AimFOV)
    if t then
        local char = t.Character
        local part = char and char:FindFirstChild(CONFIG.AimPart)
        if part then
            local pos = part.Position + part.Velocity * 0.05
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, pos), CONFIG.AimSmoothness)
        end
    end
end

-- ESP
local function createESP(p)
    if p == LocalPlayer or espCache[p] then return end
    local box = Drawing.new("Square"); box.Thickness = 1; box.Filled = false; box.Transparency = 1; box.Visible = false
    local nm = Drawing.new("Text"); nm.Size = 14; nm.Center = true; nm.Outline = true; nm.Visible = false
    local hb = Drawing.new("Square"); hb.Thickness = 1; hb.Filled = true; hb.Transparency = 1; hb.Visible = false
    local dt = Drawing.new("Text"); dt.Size = 12; dt.Center = true; dt.Outline = true; dt.Visible = false
    espCache[p] = {box = box, name = nm, healthBar = hb, distText = dt}
end

local function updateESP()
    for p, d in pairs(espCache) do
        local char = p.Character
        if not CONFIG.ESPEnabled or not char then
            d.box.Visible = false; d.name.Visible = false; d.healthBar.Visible = false; d.distText.Visible = false
            continue
        end
        local hum = char:FindFirstChild("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not hum or not root or not head or hum.Health <= 0 then
            d.box.Visible = false; d.name.Visible = false; d.healthBar.Visible = false; d.distText.Visible = false
            continue
        end
        local hp = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local hr = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2, 0))
        local dist = (Camera.CFrame.Position - root.Position).Magnitude
        if not hp.Z or hp.Z < 0 or dist > CONFIG.ESPMaxDistance then
            d.box.Visible = false; d.name.Visible = false; d.healthBar.Visible = false; d.distText.Visible = false
            continue
        end
        local h = math.abs(hp.Y - hr.Y); local w = h * 0.6
        if CONFIG.ESPBox then
            d.box.Size = Vector2.new(w, h); d.box.Position = Vector2.new(hp.X - w / 2, hp.Y); d.box.Visible = true
        else d.box.Visible = false end
        if CONFIG.ESPName then
            d.name.Position = Vector2.new(hp.X, hp.Y - 18); d.name.Text = p.Name; d.name.Visible = true
        else d.name.Visible = false end
        if CONFIG.ESPHealth then
            local pct = hum.Health / hum.MaxHealth
            d.healthBar.Size = Vector2.new(3, h * pct)
            d.healthBar.Position = Vector2.new(hp.X - w / 2 - 6, hp.Y + h * (1 - pct))
            d.healthBar.Color = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
            d.healthBar.Visible = true
        else d.healthBar.Visible = false end
        if CONFIG.ESPDistance then
            d.distText.Position = Vector2.new(hp.X, hp.Y + h + 4)
            d.distText.Text = string.format("[%d studs]", math.floor(dist))
            d.distText.Visible = true
        else d.distText.Visible = false end
    end
end

-- Bhop
local function startBhop()
    if bhopConn then bhopConn:Disconnect() end
    bhopConn = RunService.Heartbeat:Connect(function()
        if not CONFIG.BhopEnabled or not CONFIG.BhopHeld then return end
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not root or not hum then return end
        local rp = RaycastParams.new()
        rp.FilterDescendantsInstances = {char}
        rp.FilterType = Enum.RaycastFilterType.Exclude
        if Workspace:Raycast(root.Position, Vector3.new(0, -4, 0), rp) then hum.Jump = true end
    end)
end

--========== INIT ==========
for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)

RunService.RenderStepped:Connect(function()
    updateAimbot()
    updateESP()
end)

startBhop()

-- Silent Aim
local mt = getrawmetatable(game)
if mt then
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if CONFIG.SilentAimEnabled and (method == "Fire" or method == "InvokeServer") then
            local args = {...}
            if typeof(args[1]) == "Vector3" or typeof(args[1]) == "CFrame" then
                local target, cd = nil, math.huge
                local center = Camera.ViewportSize / 2
                for _, p in ipairs(Players:GetPlayers()) do
                    if p == LocalPlayer or isTeammate(p) then continue end
                    local char = p.Character
                    if not char then continue end
                    local hum = char:FindFirstChild("Humanoid")
                    if not hum or hum.Health <= 0 then continue end
                    local part = char:FindFirstChild(CONFIG.AimPart) or char:FindFirstChild("HumanoidRootPart")
                    if not part then continue end
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if not on then continue end
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < CONFIG.SilentAimFOV and d < cd then cd = d; target = part end
                end
                if target and math.random(1, 100) <= CONFIG.SilentAimHitChance then
                    if typeof(args[1]) == "Vector3" then args[1] = target.Position
                    elseif typeof(args[1]) == "CFrame" then args[1] = CFrame.new(target.Position) end
                end
                return old(self, table.unpack(args))
            end
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end
