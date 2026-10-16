-- BloxStrike Wallhack / ESP ONLY (FULL)
-- Executor: Delta / Xeno / Wave
-- Resolution: 2772x1280
-- Без ремоутов. Health check убран — рисует живых.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--========== CONFIG ==========
local CONFIG = {
    ESP = true,
    Box = true,
    Name = true,
    Health = true,
    Distance = true,
    Skeleton = false,
    MaxDist = 3000,
    TeamCheck = false,

    BoxColor = Color3.fromRGB(255, 60, 60),
    NameColor = Color3.fromRGB(255, 255, 255),
    DistColor = Color3.fromRGB(200, 200, 200),
    TeamColor = Color3.fromRGB(60, 255, 60)
}

local espCache = {}

--========== ХЕЛПЕРЫ ==========
local function isTeammate(p)
    if not CONFIG.TeamCheck then return false end
    return p.Team == LocalPlayer.Team and p.Team ~= nil
end

local function getColor(p)
    if isTeammate(p) then return CONFIG.TeamColor end
    return CONFIG.BoxColor
end

--========== ESP ==========
local function createESP(p)
    if p == LocalPlayer or espCache[p] then return end

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Transparency = 1
    box.Color = CONFIG.BoxColor
    box.Visible = false

    local outline = Drawing.new("Square")
    outline.Thickness = 3
    outline.Filled = false
    outline.Transparency = 0.4
    outline.Color = Color3.fromRGB(0, 0, 0)
    outline.Visible = false

    local name = Drawing.new("Text")
    name.Size = 16
    name.Center = true
    name.Outline = true
    name.Color = CONFIG.NameColor
    name.Visible = false

    local healthBar = Drawing.new("Square")
    healthBar.Thickness = 1
    healthBar.Filled = true
    healthBar.Transparency = 1
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Visible = false

    local healthBg = Drawing.new("Square")
    healthBg.Thickness = 1
    healthBg.Filled = true
    healthBg.Transparency = 0.6
    healthBg.Color = Color3.fromRGB(0, 0, 0)
    healthBg.Visible = false

    local distText = Drawing.new("Text")
    distText.Size = 14
    distText.Center = true
    distText.Outline = true
    distText.Color = CONFIG.DistColor
    distText.Visible = false

    local headDot = Drawing.new("Circle")
    headDot.Radius = 4
    headDot.Filled = true
    headDot.Transparency = 1
    headDot.Color = CONFIG.BoxColor
    headDot.Visible = false

    espCache[p] = {
        box = box,
        outline = outline,
        name = name,
        healthBar = healthBar,
        healthBg = healthBg,
        distText = distText,
        headDot = headDot
    }
end

local function hideESP(d)
    d.box.Visible = false
    d.outline.Visible = false
    d.name.Visible = false
    d.healthBar.Visible = false
    d.healthBg.Visible = false
    d.distText.Visible = false
    d.headDot.Visible = false
end

local function updateESP()
    local vp = Camera.ViewportSize

    for p, d in pairs(espCache) do
        if not CONFIG.ESP then
            hideESP(d)
            continue
        end

        local char = p.Character
        if not char then
            hideESP(d)
            continue
        end

        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")

        if not root or not head then
            hideESP(d)
            continue
        end

        -- Health check УБРАН. Рисуем всех живых и мёртвых.

        local dist = (Camera.CFrame.Position - root.Position).Magnitude
        if dist > CONFIG.MaxDist then
            hideESP(d)
            continue
        end

        local headWorld = head.Position + Vector3.new(0, 0.5, 0)
        local feetWorld = root.Position - Vector3.new(0, 2.8, 0)

        local headPos, headOn = Camera:WorldToViewportPoint(headWorld)
        local feetPos, feetOn = Camera:WorldToViewportPoint(feetWorld)

        if not headOn or not feetOn then
            hideESP(d)
            continue
        end

        if headPos.Z <= 0 or feetPos.Z <= 0 then
            hideESP(d)
            continue
        end

        if headPos.X < 0 or headPos.Y < 0 or headPos.X > vp.X or headPos.Y > vp.Y then
            hideESP(d)
            continue
        end

        local h = math.abs(feetPos.Y - headPos.Y)
        if h < 8 then h = 8 end
        local w = h * 0.55
        local boxX = headPos.X - w / 2
        local boxY = headPos.Y

        local col = getColor(p)

        -- Box + outline
        if CONFIG.Box then
            d.outline.Size = Vector2.new(w + 2, h + 2)
            d.outline.Position = Vector2.new(boxX - 1, boxY - 1)
            d.outline.Visible = true

            d.box.Size = Vector2.new(w, h)
            d.box.Position = Vector2.new(boxX, boxY)
            d.box.Color = col
            d.box.Visible = true
        else
            d.box.Visible = false
            d.outline.Visible = false
        end

        -- Name
        if CONFIG.Name then
            d.name.Position = Vector2.new(headPos.X, boxY - 24)
            d.name.Text = p.Name
            d.name.Color = col
            d.name.Visible = true
        else
            d.name.Visible = false
        end

        -- Health — не сбрасывается в 0 если Humanoid пустой
        if CONFIG.Health then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local pct = 1
            if hum and hum.MaxHealth and hum.MaxHealth > 0 then
                pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            end
            local barH = h * pct
            d.healthBg.Size = Vector2.new(5, h)
            d.healthBg.Position = Vector2.new(boxX - 10, boxY)
            d.healthBg.Visible = true

            d.healthBar.Size = Vector2.new(5, barH)
            d.healthBar.Position = Vector2.new(boxX - 10, boxY + h - barH)
            d.healthBar.Color = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
            d.healthBar.Visible = true
        else
            d.healthBar.Visible = false
            d.healthBg.Visible = false
        end

        -- Distance
        if CONFIG.Distance then
            d.distText.Position = Vector2.new(headPos.X, boxY + h + 6)
            d.distText.Text = string.format("[%d studs]", math.floor(dist))
            d.distText.Color = col
            d.distText.Visible = true
        else
            d.distText.Visible = false
        end

        -- Head dot
        if CONFIG.Skeleton then
            d.headDot.Position = Vector2.new(headPos.X, headPos.Y)
            d.headDot.Color = col
            d.headDot.Visible = true
        else
            d.headDot.Visible = false
        end
    end
end

--========== INIT ==========
for _, p in ipairs(Players:GetPlayers()) do
    createESP(p)
end

Players.PlayerAdded:Connect(createESP)

Players.PlayerRemoving:Connect(function(p)
    local d = espCache[p]
    if d then
        for _, v in pairs(d) do
            if typeof(v) == "userdata" and v.Remove then v:Remove() end
        end
        espCache[p] = nil
    end
end)

RunService.RenderStepped:Connect(updateESP)

--========== МЕНЮ ==========
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local sg = Instance.new("ScreenGui")
sg.Name = "R_ESP_Menu"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = PlayerGui

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 70, 0, 70)
openBtn.Position = UDim2.new(0, 30, 0, 200)
openBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
openBtn.BackgroundTransparency = 0.2
openBtn.Text = "ESP"
openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openBtn.TextScaled = true
openBtn.Font = Enum.Font.GothamBold
openBtn.Parent = sg
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 340, 0, 480)
panel.Position = UDim2.new(0, 120, 0, 150)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = sg
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
header.BorderSizePixel = 0
header.Parent = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Wallhack / ESP"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = header

local list = Instance.new("Frame")
list.Size = UDim2.new(1, -20, 1, -60)
list.Position = UDim2.new(0, 10, 0, 52)
list.BackgroundTransparency = 1
list.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local function mkToggle(text, default, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 40)
    f.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    f.BorderSizePixel = 0
    f.Parent = list
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 15, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 16
    lbl.Parent = f

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 28)
    btn.Position = UDim2.new(1, -75, 0.5, -14)
    btn.BackgroundColor3 = default and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(60, 60, 70)
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
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

mkToggle("ESP", CONFIG.ESP, function(v) CONFIG.ESP = v end)
mkToggle("Box", CONFIG.Box, function(v) CONFIG.Box = v end)
mkToggle("Name", CONFIG.Name, function(v) CONFIG.Name = v end)
mkToggle("Health", CONFIG.Health, function(v) CONFIG.Health = v end)
mkToggle("Distance", CONFIG.Distance, function(v) CONFIG.Distance = v end)
mkToggle("Team Check", CONFIG.TeamCheck, function(v) CONFIG.TeamCheck = v end)
mkToggle("Head Dot", CONFIG.Skeleton, function(v) CONFIG.Skeleton = v end)

openBtn.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
end)

-- Drag панели
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

print("[R] ESP loaded. Resolution: 2772x1280. No remotes used.")
