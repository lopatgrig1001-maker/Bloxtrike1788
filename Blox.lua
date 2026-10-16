local mt = getrawmetatable(game)
if not mt then print("no mt") return end

local old = mt.__namecall
setreadonly(mt, false)

local seen = {}

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if not seen[method] then
        seen[method] = 0
    end
    seen[method] = seen[method] + 1
    
    if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
        local name = self:GetFullName()
        if not seen["_name_" .. name] then
            seen["_name_" .. name] = true
            print("[REMOTE]", method, "->", name)
        end
    end
    
    return old(self, ...)
end)

setreadonly(mt, true)

-- Показываем лог
local sg = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local f = Instance.new("Frame")
f.Size = UDim2.new(0, 700, 0, 700)
f.Position = UDim2.new(0, 30, 0, 60)
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
    local lines = {"=== NAMEcall METHODS (выстрели пару раз) ===", ""}
    for k, v in pairs(seen) do
        if typeof(v) == "number" then
            table.insert(lines, k .. " : " .. v .. " вызовов")
        else
            table.insert(lines, k)
        end
    end
    lbl.Text = table.concat(lines, "\n")
end)
