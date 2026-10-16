-- Упрощённый тест B — что ловит __namecall при стрельбе

local seen = {}

local mt = getrawmetatable(game)
if not mt then return end

local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method then
        seen[method] = (seen[method] or 0) + 1
    end
    return old(self, ...)
end)

setreadonly(mt, true)

-- Окно
local sg = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local f = Instance.new("Frame")
f.Size = UDim2.new(0, 500, 0, 600)
f.Position = UDim2.new(0, 40, 0, 100)
f.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
f.BackgroundTransparency = 0.15
f.BorderSizePixel = 2
f.BorderColor3 = Color3.fromRGB(255, 100, 100)
f.Parent = sg

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(1, -20, 1, -20)
lbl.Position = UDim2.new(0, 10, 0, 10)
lbl.BackgroundTransparency = 1
lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.TextYAlignment = Enum.TextYAlignment.Top
lbl.Font = Enum.Font.Code
lbl.TextSize = 15
lbl.TextWrapped = true
lbl.Parent = f

game:GetService("RunService").Heartbeat:Connect(function()
    local lines = {"=== METHODS (постреляй) ===", ""}
    for k, v in pairs(seen) do
        table.insert(lines, k .. " : " .. v)
    end
    lbl.Text = table.concat(lines, "\n")
end)
