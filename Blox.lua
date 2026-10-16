-- Лог методов при выстреле | Безопасный
local seen = {}
local fired = {}

local mt = getrawmetatable(game)
if not mt then
    return
end

local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    
    -- Считаем частоту методов
    if method then
        seen[method] = (seen[method] or 0) + 1
    end
    
    -- Логируем ВСЁ что вызывается через namecall при стрельбе (кроме спама Roblox)
    if method and method ~= "IsA" and method ~= "FindFirstChild" and method ~= "GetPropertyChangedSignal" 
        and method ~= "WaitForChild" and method ~= "GetChildren" and method ~= "GetDescendants"
        and method ~= "GetFullName" and method ~= "GetAttribute" and method ~= "SetAttribute"
        and method ~= "GetService" and method ~= "Destroy" and method ~= "Clone" then
        
        local key = method
        if not fired[key] then
            fired[key] = { count = 0, lastSelf = self }
        end
        fired[key].count = fired[key].count + 1
        fired[key].lastSelf = self
    end
    
    return old(self, ...)
end)

setreadonly(mt, true)

-- GUI
local sg = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local f = Instance.new("Frame")
f.Size = UDim2.new(0, 700, 0, 600)
f.Position = UDim2.new(0, 20, 0, 60)
f.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
f.BackgroundTransparency = 0.15
f.BorderSizePixel = 2
f.BorderColor3 = Color3.fromRGB(255, 100, 100)
f.Parent = sg

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -20)
scroll.Position = UDim2.new(0, 10, 0, 10)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 3000)
scroll.ScrollBarThickness = 6
scroll.Parent = f

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(1, -10, 0, 3000)
lbl.BackgroundTransparency = 1
lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.TextYAlignment = Enum.TextYAlignment.Top
lbl.Font = Enum.Font.Code
lbl.TextSize = 14
lbl.TextWrapped = true
lbl.Parent = scroll

game:GetService("RunService").Heartbeat:Connect(function()
    local lines = {"=== Выстрели пару раз ===", ""}
    for method, data in pairs(fired) do
        local selfName = "?"
        pcall(function() selfName = data.lastSelf:GetFullName() end)
        table.insert(lines, method .. " (" .. data.count .. ")")
        table.insert(lines, "    -> " .. selfName)
        table.insert(lines, "")
    end
    lbl.Text = table.concat(lines, "\n")
end)

print("[R] Method logger started")
