-- Universal Roblox Script | Aimbot + Silent Aim + Wallhack + Speed/Jump/Fly
-- Executor: Delta / Xeno / Wave / Codex

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--========== CONFIG ==========
local CONFIG = {
    Speed = true, SpeedVal = 50,
    Jump = true, JumpVal = 100,
    Fly = false, FlySpeed = 60,

    ESP = true,
    ESPBox = true,
    ESPName = true,
    ESPHealth = true,
    ESPDist = true,
    ESPMaxDist = 1000,

    Aim = true,
    AimFOV = 150,
    AimSmooth = 0.2,
    AimPart = "Head",
    AimWallCheck = false,
    AimTeamCheck = true,
    AimHeld = false,
    AimKey = Enum.UserInputType.MouseButton2,

    Silent = true,
    SilentFOV = 200,
    SilentHitChance = 100,
    SilentWallCheck = false,
    SilentTeamCheck = true
}

local espCache = {}
local flyVel, flyGyro

--========== GUI ==========
local sg = Instance.new("ScreenGui")
sg.Name = "R_Universal"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = PlayerGui

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 50, 0, 50)
openBtn.Position = UDim2.new(0, 10, 0, 100)
openBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
openBtn.Text = "R"
openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openBtn.TextScaled = true
openBtn.Font = Enum.Font.GothamBold
openBtn.Parent = sg
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 260, 0, 480)
panel.Position = UDim2.new(0, 70, 0, 80)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = sg
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
header.BorderSizePixel = 0
header.Parent = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "R Universal | [R]"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Parent = header

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -46)
scroll.Position = UDim2.new(0, 5, 0, 42)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, 1200)
scroll.Parent = panel

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

local function makeToggle(text, default, cb)
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
        cb(state)
    end)
end

local function makeSlider(text, min, max, default, cb)
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
        cb(val)
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

--========== МЕНЮ ==========
makeSection("AIMBOT")
makeToggle("Aimbot", CONFIG.Aim, function(v) CONFIG.Aim = v end)
makeSlider("FOV", 10, 500, CONFIG.AimFOV, function(v) CONFIG.AimFOV = v end)
makeSlider("Smooth %", 1, 100, CONFIG.AimSmooth * 100, function(v) CONFIG.AimSmooth = v / 100 end)
makeToggle("Wall Check", CONFIG.AimWallCheck, function(v) CONFIG.AimWallCheck = v end)
makeToggle("Team Check", CONFIG.AimTeamCheck, function(v) CONFIG.AimTeamCheck = v end)

makeSection("SILENT AIM")
makeToggle("Silent Aim", CONFIG.Silent, function(v) CONFIG.Silent = v end)
makeSlider("Silent FOV", 10, 500, CONFIG.SilentFOV, function(v) CONFIG.SilentFOV = v end)
makeSlider("Hit Chance %", 0, 100, CONFIG.SilentHitChance, function(v) CONFIG.SilentHitChance = v end)
makeToggle("Silent Wall Check", CONFIG.SilentWallCheck, function(v) CONFIG.SilentWallCheck = v end)
makeToggle("Silent Team Check", CONFIG.SilentTeamCheck, function(v) CONFIG.SilentTeamCheck = v end)

makeSection("WALLHACK / ESP")
makeToggle("ESP", CONFIG.ESP, function(v) CONFIG.ESP = v end)
makeToggle("Box", CONFIG.ESPBox, function(v) CONFIG.ESPBox = v end)
makeToggle("Name", CONFIG.ESPName, function(v) CONFIG.ESPName = v end)
makeToggle("Health", CONFIG.ESPHealth, function(v) CONFIG.ESPHealth = v end)
makeToggle("Distance", CONFIG.ESPDist, function(v) CONFIG.ESPDist = v end)
makeSlider("Max Dist", 50, 5000, CONFIG.ESPMaxDist, function(v) CONFIG.ESPMaxDist = v end)

makeSection("MOVEMENT")
makeToggle("Speed", CONFIG.Speed, function(v) CONFIG.Speed = v end)
makeSlider("Speed Val", 16, 300, CONFIG.SpeedVal, function(v) CONFIG.SpeedVal = v end)
makeToggle("Jump", CONFIG.Jump, function(v) CONFIG.Jump = v end)
makeSlider("Jump Val", 50, 500, CONFIG.JumpVal, function(v) CONFIG.JumpVal = v end)
makeToggle("Fly", CONFIG.Fly, function(v)
    CONFIG.Fly = v
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if v then
        flyVel = Instance.new("BodyVelocity")
        flyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyVel.Velocity = Vector3.zero
        flyVel.Parent = root
        flyGyro = Instance.new("BodyGyro")
        flyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyGyro.CFrame = root.CFrame
        flyGyro.P = 1000
        flyGyro.Parent = root
    else
        if flyVel then flyVel:Destroy() flyVel = nil end
        if flyGyro then flyGyro:Destroy() flyGyro = nil end
    end
end)

-- Открытие/закрытие
openBtn.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
end)

-- Drag
local dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragStart = input.Position
        startPos = panel.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragStart = nil
    end
end)

--========== ЭКРАННЫЕ КНОПКИ ==========
local function makeHoldBtn(text, pos, onDown, onUp)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 70, 0, 70)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    btn.BackgroundTransparency = 0.3
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Parent = sg
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    btn.MouseButton1Down:Connect(onDown)
    btn.MouseButton1Up:Connect(onUp)
    btn.MouseLeave:Connect(onUp)
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then onDown() end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then onUp() end
    end)
end

makeHoldBtn("AIM", UDim2.new(0, 15, 0, 200),
    function() CONFIG.AimHeld = true end,
    function() CONFIG.AimHeld = false end)

--========== ЛОГИКА ==========
local function isTeammate(p, check)
    if not check then return false end
    return p.Team == LocalPlayer.Team and p.Team ~= nil
end

local function isVisible(p, wallCheck)
    if not wallCheck then return true end
    local char = p.Character
    if not char then return false end
    local part = char:FindFirstChild(CONFIG.AimPart) or char:FindFirstChild("HumanoidRootPart")
    if not part then return false end
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local res = Workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 2000, rp)
    if res then return res.Instance:IsDescendantOf(char) end
    return true
end

local function getClosest(fov, wallCheck, teamCheck)
    local closest, cd = nil, math.huge
    local center = Camera.ViewportSize / 2
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if isTeammate(p, teamCheck) then continue end
        local char = p.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local part = char:FindFirstChild(CONFIG.AimPart) or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        if not isVisible(p, wallCheck) then continue end
        local sp, on = Camera:WorldToViewportPoint(part.Position)
        if not on or sp.Z < 0 then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < fov and d < cd then cd = d; closest = p end
    end
    return closest
end

-- Aimbot
RunService.RenderStepped:Connect(function()
    if not CONFIG.Aim then return end
    local held = CONFIG.AimHeld or UserInputService:IsMouseButtonPressed(CONFIG.AimKey)
    if not held then return end
    local t = getClosest(CONFIG.AimFOV, CONFIG.AimWallCheck, CONFIG.AimTeamCheck)
    if not t then return end
    local char = t.Character
    local part = char and char:FindFirstChild(CONFIG.AimPart)
    if not part then return end
    local pos = part.Position + part.AssemblyLinearVelocity * 0.05
    Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, pos), CONFIG.AimSmooth)
end)

-- Wallhack / ESP
local function createESP(p)
    if p == LocalPlayer or espCache[p] then return end
    local box = Drawing.new("Square")
    box.Thickness = 1; box.Filled = false; box.Transparency = 1
    box.Color = Color3.fromRGB(255, 60, 60); box.Visible = false

    local nm = Drawing.new("Text")
    nm.Size = 14; nm.Center = true; nm.Outline = true
    nm.Color = Color3.fromRGB(255, 255, 255); nm.Visible = false

    local hb = Drawing.new("Square")
    hb.Thickness = 1; hb.Filled = true; hb.Transparency = 1
    hb.Color = Color3.fromRGB(0, 255, 0); hb.Visible = false

    local dt = Drawing.new("Text")
    dt.Size = 12; dt.Center = true; dt.Outline = true
    dt.Color = Color3.fromRGB(200, 200, 200); dt.Visible = false

    espCache[p] = {box = box, name = nm, healthBar = hb, distText = dt}
end

RunService.RenderStepped:Connect(function()
    for p, d in pairs(espCache) do
        local char = p.Character
        if not CONFIG.ESP or not char then
            d.box.Visible = false; d.name.Visible = false
            d.healthBar.Visible = false; d.distText.Visible = false
            continue
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not hum or not root or not head or hum.Health <= 0 then
            d.box.Visible = false; d.name.Visible = false
            d.healthBar.Visible = false; d.distText.Visible = false
            continue
        end
        local hp = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local hr = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))
        local dist = (Camera.CFrame.Position - root.Position).Magnitude
        if not hp.Z or hp.Z < 0 or dist > CONFIG.ESPMaxDist then
            d.box.Visible = false; d.name.Visible = false
            d.healthBar.Visible = false; d.distText.Visible = false
            continue
        end
        local h = math.abs(hp.Y - hr.Y); local w = h * 0.6
        if CONFIG.ESPBox then
            d.box.Size = Vector2.new(w, h)
            d.box.Position = Vector2.new(hp.X - w / 2, hp.Y)
            d.box.Visible = true
        else d.box.Visible = false end
        if CONFIG.ESPName then
            d.name.Position = Vector2.new(hp.X, hp.Y - 18)
            d.name.Text = p.Name; d.name.Visible = true
        else d.name.Visible = false end
        if CONFIG.ESPHealth then
            local pct = hum.Health / hum.MaxHealth
            d.healthBar.Size = Vector2.new(3, h * pct)
            d.healthBar.Position = Vector2.new(hp.X - w / 2 - 6, hp.Y + h * (1 - pct))
            d.healthBar.Color = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
            d.healthBar.Visible = true
        else d.healthBar.Visible = false end
        if CONFIG.ESPDist then
            d.distText.Position = Vector2.new(hp.X, hp.Y + h + 4)
            d.distText.Text = string.format("[%d studs]", math.floor(dist))
            d.distText.Visible = true
        else d.distText.Visible = false end
    end
end)

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)

-- Speed / Jump / Fly
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if CONFIG.Speed then hum.WalkSpeed = CONFIG.SpeedVal end
        if CONFIG.Jump then
            hum.UseJumpPower = true
            hum.JumpPower = CONFIG.JumpVal
        end
    end
end)

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

--========== SILENT AIM ==========
local mt = getrawmetatable(game)
if mt then
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if CONFIG.Silent and (method == "Fire" or method == "InvokeServer" or method == "FireServer") then
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
                return old(self, table.unpack(args))
            end
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end
