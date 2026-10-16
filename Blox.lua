-- Логгер БЕЗ GetFullName — не ломает стрельбу
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local hits = {}

local mt = getrawmetatable(game)
if not mt then return end

local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    
    -- БЕЗ GetFullName — только считаем вызовы
    if method == "Fire" or method == "FireServer" or method == "InvokeServer" 
        or method == "Raycast" or method == "FindPartOnRayWithIgnoreList" 
        or method == "ViewportPointToRay" then
        
        hits[method] = (hits[method] or 0) + 1
    end
    
    return old(self, ...)
end)

setreadonly(mt, true)

-- GUI
local sg = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.Parent = PG

local f = Instance.new("Frame")
f.Size = UDim2.new(0, 500, 0, 400)
f.Position = UDim2.new(0, 20, 0, 60)
f.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
f.BackgroundTransparency = 0.15
f.BorderSizePixel = 2
f.BorderColor3 = Color3.fromRGB(255, 100, 100)
f.Parent = sg

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(1, -20, 1, -20)
lbl.Position = UDim2.new(0, 10, 0, 10)
lbl.BackgroundTransparency = 1
lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.TextYAlignment = Enum.TextYAlignment.Top
lbl.Font = Enum.Font.Code
lbl.TextSize = 14
lbl.TextWrapped = true
lbl.Parent = f

game:GetService("RunService").Heartbeat:Connect(function()
    local lines = {"=== Выстрели 5 раз ===", ""}
    for method, count in pairs(hits) do
        table.insert(lines, method .. " : " .. count)
    end
    lbl.Text = table.concat(lines, "\n")
end)

print("[R] safe logger loaded")
