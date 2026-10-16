-- BloxStrike Wallhack | FINAL FINAL
-- Запускать в ЖИВОМ МАТЧЕ, не в лобби

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CONFIG = {
    Enabled = true,
    Highlight = true,
    Billboard = true,
    HPBar = true,
    MaxDist = 3000,
    FillColor = Color3.fromRGB(255, 40, 40)
}

local cache = {}

local function isDead(char)
    local d = char:GetAttribute("Dead")
    if d ~= nil then return d end
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

local function isValid(char)
    if not char or char.Parent ~= Workspace then return false end
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not head or not root then return false end
    -- Отсев (0, 106, 0)
    if math.abs(head.Position.X) < 0.5 and math.abs(head.Position.Z) < 0.5 then return false end
    return true
end

local function removeESP(p)
    local c = cache[p]
    if not c then return end
    if c.hl and c.hl.Parent then c.hl:Destroy() end
    if c.bb and c.bb.Parent then c.bb:Destroy() end
    cache[p] = nil
end

local function createESP(p)
    if p == LocalPlayer or cache[p] then return end
    local char = p.Character
    if not isValid(char) then return end

    local hl, bb, hpLabel

    if CONFIG.Highlight then
        hl = Instance.new("Highlight")
        hl.FillColor = CONFIG.FillColor
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = char
        hl.Parent = char
    end

    if CONFIG.Billboard then
        local head = char:FindFirstChild("Head")
        if head then
            bb = Instance.new("BillboardGui")
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

            hpLabel = Instance.new("TextLabel")
            hpLabel.Size = UDim2.new(1, 0, 0, 16)
            hpLabel.Position = UDim2.new(0, 0, 0, 22)
            hpLabel.BackgroundTransparency = 1
            hpLabel.Text = "100/100"
            hpLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            hpLabel.TextStrokeTransparency = 0
            hpLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            hpLabel.Font = Enum.Font.Gotham
            hpLabel.TextSize = 12
            hpLabel.Parent = bb
        end
    end

    cache[p] = {hl = hl, bb = bb, hpLabel = hpLabel}
end

-- Существующие
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function()
            task.wait(0.3)
            removeESP(p)
            createESP(p)
        end)
        if p.Character then createESP(p) end
    end
end

-- Новые
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.3)
        removeESP(p)
        createESP(p)
    end)
end)

Players.PlayerRemoving:Connect(removeESP)

-- Постоянная проверка (чтобы ловило всех живых)
RunService.Heartbeat:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        if isValid(char) and not cache[p] then
            createESP(p)
        end
        if not isValid(char) and cache[p] then
            removeESP(p)
        end
    end

    -- Обновляем HP
    for p, c in pairs(cache) do
        local char = p.Character
        if not char then continue end
        local hp, mhp = getHealth(char)
        local pct = mhp > 0 and (hp / mhp) or 0
        if c.hpLabel and c.hpLabel.Parent then
            c.hpLabel.Text = string.format("%d/%d", math.floor(hp), math.floor(mhp))
            c.hpLabel.TextColor3 = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
        end
        if c.hl and c.hl.Parent then
            c.hl.FillColor = isDead(char) and Color3.fromRGB(100, 100, 100) or CONFIG.FillColor
        end
    end
end)

print("[R] WH loaded. Жди игроков в Workspace.")
