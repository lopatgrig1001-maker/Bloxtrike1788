-- R DIAGNOSTIC — 4 проверки
-- Запусти и скажи что видишь

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer
local sg = Instance.new("ScreenGui")
sg.Name = "R_Diag"
sg.ResetOnSpawn = false
sg.DisplayOrder = 9999
sg.Parent = LP:WaitForChild("PlayerGui")

-- Окно с выводом
local f = Instance.new("Frame")
f.Size = UDim2.new(0, 700, 0, 700)
f.Position = UDim2.new(0, 20, 0, 60)
f.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
f.BackgroundTransparency = 0.1
f.BorderSizePixel = 3
f.BorderColor3 = Color3.fromRGB(255, 100, 100)
f.Parent = sg

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 80, 0, 36)
close.Position = UDim2.new(1, -90, 0, 8)
close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
close.Text = "CLOSE"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.Parent = f
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
close.MouseButton1Click:Connect(function() sg:Destroy() end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -60)
scroll.Position = UDim2.new(0, 10, 0, 52)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.new(0, 0, 0, 2000)
scroll.ScrollBarThickness = 6
scroll.Parent = f

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.Parent = scroll

local function log(text, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 0, 22)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(220, 220, 220)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Code
    l.TextSize = 15
    l.Parent = scroll
end

log("=== ПРОВЕРКА 1: ScreenGui ===", Color3.fromRGB(255, 220, 100))
log("Если видишь это окно → ScreenGui РАБОТАЕТ", Color3.fromRGB(100, 255, 100))

task.wait(1)

log("", Color3.fromRGB(0,0,0))
log("=== ПРОВЕРКА 2: Instance.new(Part) ===", Color3.fromRGB(255, 220, 100))
local ok, result = pcall(function()
    local part = Instance.new("Part")
    part.Size = Vector3.new(5, 5, 5)
    part.Anchored = true
    part.BrickColor = BrickColor.new("Bright red")
    part.Material = Enum.Material.Neon
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    part.Position = root and (root.Position + Vector3.new(0, 10, 0)) or Vector3.new(0, 50, 0)
    part.Parent = Workspace
    return part
end)

if ok then
    log("Part СОЗДАН. Красный куб над головой?", Color3.fromRGB(100, 255, 100))
else
    log("Part НЕ СОЗДАН: " .. tostring(result), Color3.fromRGB(255, 100, 100))
end

log("", Color3.fromRGB(0,0,0))
log("=== ПРОВЕРКА 3: Highlight на игроках ===", Color3.fromRGB(255, 220, 100))
local count = 0
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP and p.Character and p.Character.Parent == Workspace then
        local okHL = pcall(function()
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255, 0, 0)
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = p.Character
            hl.Parent = p.Character
        end)
        if okHL then
            count = count + 1
            log("  HL -> " .. p.Name, Color3.fromRGB(100, 255, 100))
        else
            log("  HL FAIL -> " .. p.Name, Color3.fromRGB(255, 100, 100))
        end
    end
end
log("Обведено игроков: " .. count, Color3.fromRGB(100, 255, 100))

log("", Color3.fromRGB(0,0,0))
log("=== ПРОВЕРКА 4: API Delta ===", Color3.fromRGB(255, 220, 100))
log("Executor: " .. tostring(identifyexecutor and identifyexecutor() or "unknown"), Color3.fromRGB(180, 220, 255))
log("Drawing: " .. tostring(pcall(function() return Drawing.new("Square") end)), Color3.fromRGB(180, 220, 255))
log("Highlight: " .. tostring(pcall(function() return Instance.new("Highlight") end)), Color3.fromRGB(180, 220, 255))
log("BillboardGui: " .. tostring(pcall(function() return Instance.new("BillboardGui") end)), Color3.fromRGB(180, 220, 255))
log("hookmetamethod: " .. tostring(hookmetamethod ~= nil), Color3.fromRGB(180, 220, 255))
log("getrawmetatable: " .. tostring(getrawmetatable ~= nil), Color3.fromRGB(180, 220, 255))
log("setreadonly: " .. tostring(setreadonly ~= nil), Color3.fromRGB(180, 220, 255))
log("newcclosure: " .. tostring(newcclosure ~= nil), Color3.fromRGB(180, 220, 255))
log("getnamecallmethod: " .. tostring(getnamecallmethod ~= nil), Color3.fromRGB(180, 220, 255))

log("", Color3.fromRGB(0,0,0))
log("=== END ===", Color3.fromRGB(255, 220, 100))
