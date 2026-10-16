-- BloxStrike Wallhack | FINAL
-- Executor: Delta Mobile / Xeno
-- Рисует живых игроков в зоне стриминга

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--========== CONFIG ==========
local CONFIG = {
    ESP = true,
    Box = true,
    Name = true,
    Health = true,
    Distance = true,
    MaxDist = 3000,

    BoxColor = Color3.fromRGB(255, 60, 60),
    NameColor = Color3.fromRGB(255, 255, 255),
    DistColor = Color3.fromRGB(220, 220, 220)
}

local espCache = {}

--========== ХЕЛПЕРЫ ==========
local function isValidPos(pos)
    -- (0, 106, 0) = фейковая позиция вне стриминга
    if math.abs(pos.X) < 0.5 and math.abs(pos.Z) < 0.5 then return false end
    -- Улетевшие координаты
    if math.abs(pos.X) > 20000 or math.abs(pos.Y) > 20000 or math.abs(pos.Z) > 20000 then return false end
    return true
end

local function isDead(char)
    local deadAttr = char:GetAttribute("Dead")
    if deadAttr ~= nil then return deadAttr end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health <= 0 end
    return false
end

local function getHealth(char)
    local h = char:GetAttribute("Health")
    local mh = char:GetAttribute("MaxHealth")
    if h and mh then return h, mh end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health, hum.MaxHealth end
    return nil, nil
end

--========== ESP ==========
local function createESP(p)
    if p == LocalPlayer or espCache[p] then return end

    local box = Drawing.new("Square")
    box.Thickness = 1; box.Filled = false; box.Transparency = 1
    box.Color = CONFIG.BoxColor; box.Visible = false

    local outline = Drawing.new("Square")
    outline.Thickness = 2; outline.Filled = false; outline.Transparency = 0.5
    outline.Color = Color3.fromRGB(0, 0, 0); outline.Visible = false

    local nm = Drawing.new("Text")
    nm.Size = 14; nm.Center = true; nm.Outline = true
    nm.Color = CONFIG.NameColor; nm.Visible = false

    local hbBg = Drawing.new("Square")
    hbBg.Thickness = 1; hbBg.Filled = true; hbBg.Transparency = 0.6
    hbBg.Color = Color3.fromRGB(0, 0, 0); hbBg.Visible = false

    local hb = Drawing.new("Square")
    hb.Thickness = 1; hb.Filled = true; hb.Transparency = 1
    hb.Color = Color3.fromRGB(0, 255, 0); hb.Visible = false

    local dt = Drawing.new("Text")
    dt.Size = 12; dt.Center = true; dt.Outline = true
    dt.Color = CONFIG.DistColor; dt.Visible = false

    espCache[p] = {box = box, outline = outline, name = nm, hbBg = hbBg, hb = hb, dist = dt}
end

local function hide(d)
    d.box.Visible = false
    d.outline.Visible = false
    d.name.Visible = false
    d.hbBg.Visible = false
    d.hb.Visible = false
    d.dist.Visible = false
end

RunService.RenderStepped:Connect(function()
    local vp = Camera.ViewportSize

    for p, d in pairs(espCache) do
        if not CONFIG.ESP then hide(d) continue end

        local char = p.Character
        if not char then hide(d) continue end
        -- Character вне Workspace = вне зоны стриминга
        if char.Parent ~= Workspace then hide(d) continue end

        local head = char:FindFirstChild("Head")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not head or not root then hide(d) continue end

        -- Мёртвых не рисуем
        if isDead(char) then hide(d) continue end

        -- Отсев фейковых координат
        if not isValidPos(head.Position) or not isValidPos(root.Position) then
            hide(d); continue
        end

        local dist = (Camera.CFrame.Position - root.Position).Magnitude
        if dist > CONFIG.MaxDist then hide(d) continue end

        local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local feetPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))

        if not onScreen or headPos.Z <= 0 or headPos.Z > 10000 then hide(d) continue end
        if headPos.X < -300 or headPos.Y < -300 or headPos.X > vp.X + 300 or headPos.Y > vp.Y + 300 then
            hide(d); continue
        end

        local h = math.abs(feetPos.Y - headPos.Y)
        if h < 8 then h = 8 end
        if h > 800 then hide(d) continue end
        local w = h * 0.55
        local boxX = headPos.X - w / 2
        local boxY = headPos.Y

        -- Box + outline
        if CONFIG.Box then
            d.outline.Size = Vector2.new(w + 2, h + 2)
            d.outline.Position = Vector2.new(boxX - 1, boxY - 1)
            d.outline.Visible = true

            d.box.Size = Vector2.new(w, h)
            d.box.Position = Vector2.new(boxX, boxY)
            d.box.Visible = true
        else
            d.box.Visible = false
            d.outline.Visible = false
        end

        -- Name
        if CONFIG.Name then
            d.name.Position = Vector2.new(headPos.X, boxY - 20)
            d.name.Text = p.Name
            d.name.Visible = true
        else
            d.name.Visible = false
        end

        -- Health bar
        if CONFIG.Health then
            local hp, mhp = getHealth(char)
            if hp and mhp and mhp > 0 then
                local pct = math.clamp(hp / mhp, 0, 1)
                d.hbBg.Size = Vector2.new(3, h)
                d.hbBg.Position = Vector2.new(boxX - 7, boxY)
                d.hbBg.Visible = true

                d.hb.Size = Vector2.new(3, h * pct)
                d.hb.Position = Vector2.new(boxX - 7, boxY + h * (1 - pct))
                d.hb.Color = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
                d.hb.Visible = true
            else
                d.hbBg.Visible = false
                d.hb.Visible = false
            end
        else
            d.hbBg.Visible = false
            d.hb.Visible = false
        end

        -- Distance
        if CONFIG.Distance then
            d.dist.Position = Vector2.new(headPos.X, boxY + h + 4)
            d.dist.Text = string.format("[%d]", math.floor(dist))
            d.dist.Visible = true
        else
            d.dist.Visible = false
        end
    end
end)

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
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

--========== МЕНЮ ==========
local sg = Instance.new("ScreenGui")
sg.Name = "R_ESP_Final"
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
panel.Size = UDim2.new(0, 340, 0, 420)
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
title.Text = "Wallhack | [R]"
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
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local dd = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + dd.X, startPos.Y.Scale, startPos.Y.Offset + dd.Y)
    end
end)
game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragStart = nil
    end
end)
