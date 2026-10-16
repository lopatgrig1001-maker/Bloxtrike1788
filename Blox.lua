local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local sg = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.DisplayOrder = 9999
sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

local f = Instance.new("Frame")
f.Size = UDim2.new(0, 600, 0, 600)
f.Position = UDim2.new(0, 30, 0, 80)
f.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
f.BackgroundTransparency = 0.1
f.BorderSizePixel = 3
f.BorderColor3 = Color3.fromRGB(255, 100, 100)
f.Parent = sg

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -20)
scroll.Position = UDim2.new(0, 10, 0, 10)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 3000)
scroll.ScrollBarThickness = 6
scroll.Parent = f

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 2)
layout.Parent = scroll

local labels = {}
local function line(i, text, color)
    if not labels[i] then
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -10, 0, 20)
        l.BackgroundTransparency = 1
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Font = Enum.Font.Code
        l.TextSize = 15
        l.Parent = scroll
        labels[i] = l
    end
    labels[i].Text = text
    labels[i].TextColor3 = color or Color3.fromRGB(220, 220, 220)
    labels[i].Visible = true
end

game:GetService("RunService").RenderStepped:Connect(function()
    local i = 1
    line(i, "=== SCAN ===", Color3.fromRGB(255, 220, 100)); i = i + 1
    line(i, "Всего игроков: " .. #Players:GetPlayers(), Color3.fromRGB(180, 220, 255)); i = i + 1
    line(i, "Мой персонаж: " .. tostring(LocalPlayer.Character), Color3.fromRGB(180, 220, 255)); i = i + 1
    line(i, "", Color3.fromRGB(0,0,0)); i = i + 1

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        local hasParent = char and "Workspace" or "nil"
        local hasHead = char and char:FindFirstChild("Head") and "ДА" or "нет"
        local hasRoot = char and char:FindFirstChild("HumanoidRootPart") and "ДА" or "нет"
        local isWS = char and char.Parent == Workspace and "ДА" or "нет"

        local col
        if char and char.Parent == Workspace and char:FindFirstChild("Head") then
            col = Color3.fromRGB(100, 255, 100)
        else
            col = Color3.fromRGB(255, 100, 100)
        end

        line(i, p.Name, Color3.fromRGB(255, 220, 100)); i = i + 1
        line(i, "  Char: " .. tostring(char ~= nil) .. " | Parent: " .. hasParent, col); i = i + 1
        line(i, "  Head: " .. hasHead .. " | Root: " .. hasRoot, col); i = i + 1
        line(i, "  В Workspace: " .. isWS, col); i = i + 1
        line(i, "--------", Color3.fromRGB(80, 80, 80)); i = i + 1
    end

    for j = i, #labels do
        labels[j].Visible = false
    end
end)
