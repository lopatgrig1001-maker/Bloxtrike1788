-- Безопасный лог ремоутов через self.Name (не ломает стрельбу)
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local fired = {}

local mt = getrawmetatable(game)
if not mt then return end

local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    
    -- Ловим ТОЛЬКО FireServer/Fire — НЕ трогаем Raycast и ViewportPointToRay
    if method == "FireServer" or method == "Fire" or method == "InvokeServer" then
        local name = "?"
        -- Прямое обращение к свойствам — БЕЗ методов __namecall
        pcall(function()
            local n = rawget(self, "Name")
            local p = rawget(self, "Parent")
            if n then
                name = tostring(n)
                if p then
                    local pn = rawget(p, "Name")
                    if pn then name = tostring(pn) .. "." .. name end
                end
            end
        end)
        
        fired[name] = (fired[name] or 0) + 1
    end
    
    return old(self, ...)
end)

setreadonly(mt, true)

-- GUI
local sg = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.Parent = PG

local f = Instance.new("Frame")
f.Size = UDim2.new(0, 500, 0, 600)
f.Position = UDim2.new(0, 20, 0, 60)
f.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
f.BackgroundTransparency = 0.15
f.BorderSizePixel = 2
f.BorderColor3 = Color3.fromRGB(255, 100, 100)
f.Parent = sg

local s = Instance.new("ScrollingFrame")
s.Size = UDim2.new(1, -20, 1, -20)
s.Position = UDim2.new(0, 10, 0, 10)
s.BackgroundTransparency = 1
s.CanvasSize = UDim2.new(0, 0, 0, 3000)
s.ScrollBarThickness = 6
s.Parent = f

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(1, -10, 0, 3000)
lbl.BackgroundTransparency = 1
lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.TextYAlignment = Enum.TextYAlignment.Top
lbl.Font = Enum.Font.Code
lbl.TextSize = 14
lbl.TextWrapped = true
lbl.Parent = s

game:GetService("RunService").Heartbeat:Connect(function()
    local lines = {"=== Ремоуты (по количеству) ===", ""}
    local list = {}
    for name, count in pairs(fired) do
        table.insert(list, {name = name, count = count})
    end
    table.sort(list, function(a, b) return a.count > b.count end)
    for _, item in ipairs(list) do
        table.insert(lines, item.count .. "  " .. item.name)
    end
    lbl.Text = table.concat(lines, "\n")
end)

print("[R] safe remote logger loaded")
