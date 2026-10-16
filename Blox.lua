-- BloxStrike Hitbox + Column | БЕЗ проверки Parent
-- Запускать в живом матче, когда ты сам живой

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    HeadSize = 8,
    ColumnHeight = 500,
    ColumnWidth = 6,
    ColumnColor = Color3.fromRGB(255, 40, 40)
}

local cache = {}

local function isValid(char)
    if not char then return false end
    -- УБРАЛ проверку char.Parent == Workspace
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
    return head ~= nil and root ~= nil
end

local function buildFor(p)
    if p == LocalPlayer or cache[p] then return end
    local char = p.Character
    if not isValid(char) then return end

    local head = char:FindFirstChild("Head")

    -- Увеличиваем голову
    pcall(function()
        head.Size = Vector3.new(CONFIG.HeadSize, CONFIG.HeadSize, CONFIG.HeadSize)
        head.Transparency = 0.3
        head.CanCollide = false
        head.Material = Enum.Material.Neon
        head.BrickColor = BrickColor.new("Bright red")
    end)

    -- Столб
    local column = Instance.new("Part")
    column.Name = "R_Column_" .. p.Name
    column.Size = Vector3.new(CONFIG.ColumnWidth, CONFIG.ColumnHeight, CONFIG.ColumnWidth)
    column.Anchored = true
    column.CanCollide = false
    column.CanQuery = false
    column.CanTouch = false
    column.Material = Enum.Material.Neon
    column.Color = CONFIG.ColumnColor
    column.Transparency = 0.3
    column.Position = head.Position + Vector3.new(0, CONFIG.ColumnHeight / 2, 0)
    column.Parent = Workspace

    cache[p] = {char = char, head = head, column = column}
end

local function removeFor(p)
    local c = cache[p]
    if not c then return end
    if c.head and c.head.Parent then
        pcall(function()
            c.head.Size = Vector3.new(2, 1, 1)
            c.head.Transparency = 0
            c.head.CanCollide = true
        end)
    end
    if c.column and c.column.Parent then c.column:Destroy() end
    cache[p] = nil
end

RunService.Heartbeat:Connect(function()
    -- Строим новых
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if not cache[p] and isValid(p.Character) then
            buildFor(p)
        end
    end

    -- Обновляем позицию столба
    for p, c in pairs(cache) do
        local char = p.Character
        if not isValid(char) then
            removeFor(p)
            continue
        end
        local head = char:FindFirstChild("Head")
        if not head then
            removeFor(p)
            continue
        end

        -- Держим голову большой
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
        end
    end
end)

Players.PlayerRemoving:Connect(removeFor)

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

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        buildFor(p)
    end)
end)

print("[R] Hitbox + Column loaded. БЕЗ проверки Parent.")
