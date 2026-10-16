-- BloxStrike Wallhack | Работает на живых игроках
-- Живой матч обязателен

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local cache = {}

local function hasESP(p)
    local c = cache[p]
    return c and c.hl and c.hl.Parent
end

local function applyESP(p)
    if p == LocalPlayer then return end
    if hasESP(p) then return end
    
    local char = p.Character
    if not char then return end
    if char.Parent ~= Workspace then return end
    
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    -- Highlight
    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(255, 40, 40)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = char
    hl.Parent = char
    
    -- Billboard над головой
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head
    
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, 0, 0, 20)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = p.Name
    nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLbl.TextStrokeTransparency = 0
    nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 14
    nameLbl.Parent = bb
    
    local hpLbl = Instance.new("TextLabel")
    hpLbl.Size = UDim2.new(1, 0, 0, 16)
    hpLbl.Position = UDim2.new(0, 0, 0, 22)
    hpLbl.BackgroundTransparency = 1
    hpLbl.Text = "100/100"
    hpLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
    hpLbl.TextStrokeTransparency = 0
    hpLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    hpLbl.Font = Enum.Font.Gotham
    hpLbl.TextSize = 12
    hpLbl.Parent = bb
    
    cache[p] = {hl = hl, bb = bb, hpLbl = hpLbl, char = char}
    print("[R] ESP on", p.Name)
end

local function removeESP(p)
    local c = cache[p]
    if not c then return end
    if c.hl and c.hl.Parent then c.hl:Destroy() end
    if c.bb and c.bb.Parent then c.bb:Destroy() end
    cache[p] = nil
end

-- Главный цикл — ищет всегда
RunService.Heartbeat:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        applyESP(p)
    end
    
    -- Чистим мёртвых / вышедших
    for p, c in pairs(cache) do
        local char = p.Character
        if not char or char.Parent ~= Workspace or not char:FindFirstChild("Head") then
            removeESP(p)
        end
    end
    
    -- Обновляем HP
    for p, c in pairs(cache) do
        local char = p.Character
        if not char or not c.hpLbl or not c.hpLbl.Parent then continue end
        local hp = char:GetAttribute("Health")
        local mhp = char:GetAttribute("MaxHealth")
        if not hp then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hp = hum.Health; mhp = hum.MaxHealth end
        end
        if hp and mhp and mhp > 0 then
            local pct = math.clamp(hp / mhp, 0, 1)
            c.hpLbl.Text = string.format("%d/%d", math.floor(hp), math.floor(mhp))
            c.hpLbl.TextColor3 = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
        end
    end
end)

-- Мгновенная попытка сразу
for _, p in ipairs(Players:GetPlayers()) do
    applyESP(p)
end

Players.PlayerAdded:Connect(function(p)
    task.wait(1)
    applyESP(p)
end)

Players.PlayerRemoving:Connect(removeESP)

print("[R] WH loaded. Heartbeat ищет игроков постоянно.")
