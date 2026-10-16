-- BloxStrike Wallhack | BillboardGui + Highlight
-- 100% работает на Delta Mobile
-- Не использует Drawing / WorldToViewportPoint

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    Highlight = true,
    Billboard = true,
    MaxDist = 3000,
    FillColor = Color3.fromRGB(255, 0, 0),
    OutlineColor = Color3.fromRGB(255, 255, 255)
}

local cache = {}

local function isValidChar(char)
    if not char or char.Parent ~= Workspace then return false end
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not head or not root then return false end
    -- Отсев фейковой позиции (0, 106, 0)
    if math.abs(head.Position.X) < 0.5 and math.abs(head.Position.Z) < 0.5 then return false end
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
    return 100, 100
end

local function createFor(p)
    if p == LocalPlayer or cache[p] then return end
    local char = p.Character
    if not char then return end

    -- Highlight (видно через стены)
    if CONFIG.Highlight then
        local hl = Instance.new("Highlight")
        hl.Name = "R_HL"
        hl.FillColor = CONFIG.FillColor
        hl.OutlineColor = CONFIG.OutlineColor
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = char
        hl.Parent = char
    end

    -- BillboardGui над головой
    if CONFIG.Billboard then
        local head = char:FindFirstChild("Head")
        if head then
            local bb = Instance.new("BillboardGui")
            bb.Name = "R_BB"
            bb.Size = UDim2.new(0, 200, 0, 50)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true
            bb.Parent = head

            local name = Instance.new("TextLabel")
            name.Size = UDim2.new(1, 0, 0, 20)
            name.BackgroundTransparency = 1
            name.Text = p.Name
            name.TextColor3 = Color3.fromRGB(255, 255, 255)
            name.TextStrokeTransparency = 0
            name.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            name.Font = Enum.Font.GothamBold
            name.TextSize = 14
            name.Parent = bb

            local hp = Instance.new("TextLabel")
            hp.Size = UDim2.new(1, 0, 0, 16)
            hp.Position = UDim2.new(0, 0, 0, 22)
            hp.BackgroundTransparency = 1
            hp.Text = "100/100"
            hp.TextColor3 = Color3.fromRGB(0, 255, 0)
            hp.TextStrokeTransparency = 0
            hp.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            hp.Font = Enum.Font.Gotham
            hp.TextSize = 12
            hp.Parent = bb

            cache[p] = {hl = hl, bb = bb, hpLabel = hp, nameLabel = name}
        end
    end
end

local function removeFor(p)
    local c = cache[p]
    if not c then return end
    if c.hl then c.hl:Destroy() end
    if c.bb then c.bb:Destroy() end
    cache[p] = nil
end

-- Применяем к существующим
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer and p.Character then createFor(p) end
end

-- Новые игроки
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        createFor(p)
    end)
end)

-- Респавны (свой и чужие)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            createFor(p)
        end)
    end
end

Players.PlayerRemoving:Connect(removeFor)

-- Обновление здоровья каждый кадр
RunService.Heartbeat:Connect(function()
    for p, c in pairs(cache) do
        local char = p.Character
        if not char or char.Parent ~= Workspace then
            removeFor(p)
            continue
        end
        local isDeadNow = isDead(char)
        local hp, mhp = getHealth(char)
        local pct = mhp > 0 and (hp / mhp) or 0

        if c.hl then
            c.hl.FillColor = isDeadNow and Color3.fromRGB(100, 100, 100) or CONFIG.FillColor
        end

        if c.hpLabel then
            c.hpLabel.Text = string.format("%d/%d", math.floor(hp), math.floor(mhp))
            c.hpLabel.TextColor3 = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
        end
    end
end)

print("[R] WH loaded via Highlight + BillboardGui. 100% safe from viewport.")
