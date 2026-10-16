-- BloxStrike Hitbox + Column | BIG HEAD + RED TOWER
-- Executor: Delta Mobile
-- Живой матч обязателен

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    HeadSize = 8,          -- во сколько раз увеличить голову
    ColumnHeight = 500,    -- высота столба в studs
    ColumnWidth = 6,       -- ширина столба
    ColumnColor = Color3.fromRGB(255, 40, 40),
    ColumnMaterial = Enum.Material.Neon,
    ColumnTransparency = 0.3
}

local cache = {}

local function isAlive(char)
    local dead = char:GetAttribute("Dead")
    if dead ~= nil then return not dead end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health > 0 end
    return true
end

local function buildFor(p)
    if p == LocalPlayer or cache[p] then return end
    local char = p.Character
    if not char or char.Parent ~= Workspace then return end

    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not head or not root then return end

    -- Увеличиваем голову
    local origHeadSize = head.Size
    local origHeadTransparency = head.Transparency
    local origHeadCanCollide = head.CanCollide
    
    pcall(function()
        head.Size = Vector3.new(CONFIG.HeadSize, CONFIG.HeadSize, CONFIG.HeadSize)
        head.Transparency = 0.3
        head.CanCollide = false
        head.Material = Enum.Material.Neon
        head.BrickColor = BrickColor.new("Bright red")
    end)

    -- Красный столб до неба
    local column = Instance.new("Part")
    column.Name = "R_Column_" .. p.Name
    column.Size = Vector3.new(CONFIG.ColumnWidth, CONFIG.ColumnHeight, CONFIG.ColumnWidth)
    column.Anchored = true
    column.CanCollide = false
    column.CanQuery = false
    column.CanTouch = false
    column.Material = CONFIG.ColumnMaterial
    column.Color = CONFIG.ColumnColor
    column.Transparency = CONFIG.ColumnTransparency
    column.Position = head.Position + Vector3.new(0, CONFIG.ColumnHeight / 2, 0)
    column.Parent = Workspace

    cache[p] = {
        char = char,
        head = head,
        root = root,
        column = column,
        origHeadSize = origHeadSize,
        origHeadTransparency = origHeadTransparency,
        origHeadCanCollide = origHeadCanCollide
    }
end

local function removeFor(p)
    local c = cache[p]
    if not c then return end
    
    -- Возвращаем голову
    if c.head and c.head.Parent then
        pcall(function()
            c.head.Size = c.origHeadSize
            c.head.Transparency = c.origHeadTransparency
            c.head.CanCollide = c.origHeadCanCollide
        end)
    end
    
    -- Убираем столб
    if c.column and c.column.Parent then
        c.column:Destroy()
    end
    
    cache[p] = nil
end

-- Постоянный цикл
RunService.Heartbeat:Connect(function()
    -- Строим для новых
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        if char and char.Parent == Workspace and char:FindFirstChild("Head") then
            if not cache[p] then
                buildFor(p)
            end
        end
    end
    
    -- Обновляем позицию столба и следим за головой
    for p, c in pairs(cache) do
        local char = p.Character
        if not char or char.Parent ~= Workspace then
            removeFor(p)
            continue
        end
        
        local head = char:FindFirstChild("Head")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not head or not root then
            removeFor(p)
            continue
        end
        
        -- Если умер — убираем
        if not isAlive(char) then
            removeFor(p)
            continue
        end
        
        -- Обновляем голову если сбросилась
        if head.Size ~= Vector3.new(CONFIG.HeadSize, CONFIG.HeadSize, CONFIG.HeadSize) then
            pcall(function()
                head.Size = Vector3.new(CONFIG.HeadSize, CONFIG.HeadSize, CONFIG.HeadSize)
                head.Transparency = 0.3
                head.CanCollide = false
                head.Material = Enum.Material.Neon
                head.BrickColor = BrickColor.new("Bright red")
            end)
        end
        
        -- Двигаем столб за головой
        if c.column and c.column.Parent then
            c.column.Position = head.Position + Vector3.new(0, CONFIG.ColumnHeight / 2, 0)
        else
            -- Столб удалился — пересоздаём
            local column = Instance.new("Part")
            column.Name = "R_Column_" .. p.Name
            column.Size = Vector3.new(CONFIG.ColumnWidth, CONFIG.ColumnHeight, CONFIG.ColumnWidth)
            column.Anchored = true
            column.CanCollide = false
            column.CanQuery = false
            column.CanTouch = false
            column.Material = CONFIG.ColumnMaterial
            column.Color = CONFIG.ColumnColor
            column.Transparency = CONFIG.ColumnTransparency
            column.Position = head.Position + Vector3.new(0, CONFIG.ColumnHeight / 2, 0)
            column.Parent = Workspace
            c.column = column
        end
    end
end)

-- Очистка при выходе игрока
Players.PlayerRemoving:Connect(function(p)
    removeFor(p)
end)

-- При респавне — перестроить
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        removeFor(p)
        buildFor(p)
    end)
end)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            removeFor(p)
            buildFor(p)
        end)
        buildFor(p)
    end
end

print("[R] Hitbox + Column loaded.")
