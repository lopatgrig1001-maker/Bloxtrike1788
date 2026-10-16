-- BloxStrike ESP | ФИНАЛ
-- Использует attribute Dead, Head.Position, фильтр мусора

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local CONFIG = {
    ESP = true,
    Box = true,
    Name = true,
    Distance = true,
    MaxDist = 3000,
    BoxColor = Color3.fromRGB(255, 60, 60),
    NameColor = Color3.fromRGB(255, 255, 255),
}

local espCache = {}

-- Отсев мусорных координат (0,106,0) и улетевших в бесконечность
local function isValidPos(pos)
    if math.abs(pos.X) < 0.5 and math.abs(pos.Z) < 0.5 and math.abs(pos.Y - 106) < 5 then
        return false
    end
    if math.abs(pos.X) > 20000 or math.abs(pos.Y) > 20000 or math.abs(pos.Z) > 20000 then
        return false
    end
    return true
end

-- Проверка мёртв ли (использует attribute Dead)
local function isDead(char)
    local deadAttr = char:GetAttribute("Dead")
    if deadAttr ~= nil then return deadAttr end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health <= 0 end
    return false
end

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

    local dt = Drawing.new("Text")
    dt.Size = 12; dt.Center = true; dt.Outline = true
    dt.Color = Color3.fromRGB(220, 220, 220); dt.Visible = false

    espCache[p] = {box = box, outline = outline, name = nm, dist = dt}
end

local function hide(d)
    d.box.Visible = false
    d.outline.Visible = false
    d.name.Visible = false
    d.dist.Visible = false
end

RunService.RenderStepped:Connect(function()
    local vp = Camera.ViewportSize

    for p, d in pairs(espCache) do
        if not CONFIG.ESP then hide(d) continue end

        local char = p.Character
        if not char then hide(d) continue end

        local head = char:FindFirstChild("Head")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not head or not root then hide(d) continue end

        -- Мёртвых не рисуем
        if isDead(char) then hide(d) continue end

        -- Проверка координат
        if not isValidPos(head.Position) or not isValidPos(root.Position) then
            hide(d)
            continue
        end

        local dist = (Camera.CFrame.Position - root.Position).Magnitude
        if dist > CONFIG.MaxDist then hide(d) continue end

        -- WorldToViewportPoint от реальных позиций
        local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local feetPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))

        -- Мягкий фильтр (не строгий Z > 0)
        if not onScreen or headPos.Z <= 0 or headPos.Z > 10000 then
            hide(d)
            continue
        end

        -- Координаты за пределами экрана — не рисуем (без строгого отсева)
        if headPos.X < -500 or headPos.Y < -500 then
            hide(d)
            continue
        end
        if headPos.X > vp.X + 500 or headPos.Y > vp.Y + 500 then
            hide(d)
            continue
        end

        local h = math.abs(feetPos.Y - headPos.Y)
        if h < 8 then h = 8 end
        if h > 800 then hide(d) continue end  -- цель слишком растянута = баг
        local w = h * 0.55
        local boxX = headPos.X - w / 2
        local boxY = headPos.Y

        if CONFIG.Box then
            d.outline.Size = Vector2.new(w + 2, h + 2)
            d.outline.Position = Vector2.new(boxX - 1, boxY - 1)
            d.outline.Visible = true
            d.box.Size = Vector2.new(w, h)
            d.box.Position = Vector2.new(boxX, boxY)
            d.box.Visible = true
        end

        if CONFIG.Name then
            d.name.Position = Vector2.new(headPos.X, boxY - 20)
            d.name.Text = p.Name
            d.name.Visible = true
        end

        if CONFIG.Distance then
            d.dist.Position = Vector2.new(headPos.X, boxY + h + 4)
            d.dist.Text = string.format("[%d]", math.floor(dist))
            d.dist.Visible = true
        end
    end
end)

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
