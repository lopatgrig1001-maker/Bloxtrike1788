local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RunService = game:GetService("RunService")

local sg = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.DisplayOrder = 9999
sg.Parent = LP:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 800, 0, 900)
frame.Position = UDim2.new(0, 10, 0, 60)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 3
frame.BorderColor3 = Color3.fromRGB(255, 100, 100)
frame.Parent = sg

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 80, 0, 40)
close.Position = UDim2.new(1, -90, 0, 5)
close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Font = Enum.Font.GothamBold
close.Parent = frame
close.MouseButton1Click:Connect(function() sg:Destroy() end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -60)
scroll.Position = UDim2.new(0, 10, 0, 50)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 2000)
scroll.ScrollBarThickness = 6
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 2)
layout.Parent = scroll

local labels = {}
local function line(i, text, color)
    if not labels[i] then
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -10, 0, 18)
        l.BackgroundTransparency = 1
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Font = Enum.Font.Code
        l.TextSize = 14
        l.Parent = scroll
        labels[i] = l
    end
    labels[i].Text = text
    labels[i].TextColor3 = color or Color3.fromRGB(220, 220, 220)
    labels[i].Visible = true
end

RunService.RenderStepped:Connect(function()
    local i = 1
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local char = p.Character
        if not char then continue end
        local head = char:FindFirstChild("Head")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not head or not root then continue end

        line(i, "=== " .. p.Name .. " ===", Color3.fromRGB(255, 220, 100))
        i = i + 1

        -- Head.Position vs Root.Position
        line(i, string.format("  Head.Pos: (%.1f, %.1f, %.1f)", head.Position.X, head.Position.Y, head.Position.Z), Color3.fromRGB(180, 220, 255))
        i = i + 1
        line(i, string.format("  Root.Pos: (%.1f, %.1f, %.1f)", root.Position.X, root.Position.Y, root.Position.Z), Color3.fromRGB(180, 220, 255))
        i = i + 1
        line(i, string.format("  Head.CFrame.Pos: (%.1f, %.1f, %.1f)", head.CFrame.Position.X, head.CFrame.Position.Y, head.CFrame.Position.Z), Color3.fromRGB(180, 220, 255))
        i = i + 1

        -- Attributes на персонаже
        local attrs = char:GetAttributes()
        for name, val in pairs(attrs) do
            line(i, string.format("  [Attr] %s = %s", tostring(name), tostring(val)), Color3.fromRGB(255, 180, 255))
            i = i + 1
        end

        -- Attributes на head и root
        for _, part in ipairs({head, root}) do
            local a = part:GetAttributes()
            for name, val in pairs(a) do
                line(i, string.format("  [%s Attr] %s = %s", part.Name, tostring(name), tostring(val)), Color3.fromRGB(255, 180, 255))
                i = i + 1
            end
        end
    end
    for j = i, #labels do
        labels[j].Visible = false
    end
end)
