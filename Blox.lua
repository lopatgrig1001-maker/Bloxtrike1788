-- HARD DEBUG: покажет в окне что видит ESP по каждому игроку
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local sg = Instance.new("ScreenGui")
sg.Name = "R_HardDebug"
sg.ResetOnSpawn = false
sg.DisplayOrder = 9999
sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 700, 0, 800)
frame.Position = UDim2.new(0, 20, 0, 60)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 3
frame.BorderColor3 = Color3.fromRGB(255, 100, 100)
frame.Parent = sg

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 100, 0, 40)
close.Position = UDim2.new(1, -110, 0, 10)
close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
close.Text = "CLOSE"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Font = Enum.Font.GothamBold
close.TextSize = 16
close.BorderSizePixel = 0
close.Parent = frame
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
close.MouseButton1Click:Connect(function() sg:Destroy() end)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -120, 0, 40)
title.Position = UDim2.new(0, 15, 0, 10)
title.BackgroundTransparency = 1
title.Text = "R HARD DEBUG — live"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = frame

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -70)
scroll.Position = UDim2.new(0, 10, 0, 60)
scroll.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 8
scroll.Parent = frame
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 3)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local labels = {}
local function ensureLabel(i)
    if labels[i] then return labels[i] end
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 0, 24)
    l.BackgroundTransparency = 1
    l.Text = ""
    l.TextColor3 = Color3.fromRGB(220, 220, 220)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Code
    l.TextSize = 14
    l.Parent = scroll
    labels[i] = l
    return l
end

local vp = Camera.ViewportSize

RunService.RenderStepped:Connect(function()
    vp = Camera.ViewportSize
    local i = 1

    local function line(text, color)
        local l = ensureLabel(i)
        l.Text = text
        l.TextColor3 = color or Color3.fromRGB(220, 220, 220)
        l.Visible = true
        i = i + 1
    end

    line("Viewport: " .. math.floor(vp.X) .. " x " .. math.floor(vp.Y), Color3.fromRGB(255, 255, 100))
    line("My Char: " .. tostring(LocalPlayer.Character), Color3.fromRGB(255, 200, 100))
    line("--------------------------------------------------")

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end

        local char = p.Character
        if not char then
            line(p.Name .. " | NO CHARACTER", Color3.fromRGB(255, 100, 100))
            continue
        end

        local head = char:FindFirstChild("Head")
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")

        local headPos = "nil"
        local rootPos = "nil"
        local hp = "nil"
        local dist = "nil"
        local onScreen = "nil"

        if head then headPos = string.format("(%.1f, %.1f, %.1f)", head.Position.X, head.Position.Y, head.Position.Z) end
        if root then
            rootPos = string.format("(%.1f, %.1f, %.1f)", root.Position.X, root.Position.Y, root.Position.Z)
            dist = string.format("%.0f", (Camera.CFrame.Position - root.Position).Magnitude)
        end
        if hum then hp = string.format("%.0f/%.0f", hum.Health, hum.MaxHealth) end

        local col = Color3.fromRGB(180, 255, 180)

        if head and root then
            local sp, on = Camera:WorldToViewportPoint(head.Position)
            onScreen = tostring(on) .. " | Z=" .. string.format("%.1f", sp.Z) .. " | X=" .. string.format("%.0f", sp.X) .. " Y=" .. string.format("%.0f", sp.Y)
            col = on and Color3.fromRGB(180, 255, 180) or Color3.fromRGB(255, 150, 150)
        else
            col = Color3.fromRGB(255, 100, 100)
        end

        line(p.Name .. " | Head: " .. tostring(head ~= nil) .. " | Root: " .. tostring(root ~= nil) .. " | Hum: " .. tostring(hum ~= nil), col)
        line("   HP: " .. hp .. " | Dist: " .. dist .. " | HeadPos: " .. headPos, col)
        line("   Screen: " .. onScreen, col)
        line("--------------------------------------------------")
    end

    for j = i, #labels do
        labels[j].Visible = false
    end
end)
