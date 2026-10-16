-- [[ ОТКРЫТЫЙ МОБИЛЬНЫЙ СКРИПТ: MENU + AIMBOT + ESP (NO KEY) ]] --

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Переменные функций управления
_G.AimbotEnabled = false
_G.EspEnabled = false
_G.AimRadius = 140
_G.AimSmooth = 0.12

-- 1. ОТРИСОВКА ИНТЕРФЕЙСА (МЕНЮ)
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ToggleAim = Instance.new("TextButton")
local ToggleEsp = Instance.new("TextButton")
local CloseBtn = Instance.new("TextButton")

ScreenGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

MainFrame.Name = "MobileMenu"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 220, 0, 180)
MainFrame.Active = true
MainFrame.Draggable = true -- Меню можно двигать пальцем по экрану

Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "BloxStrike Keyless Suite"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.TextSize = 16

ToggleAim.Parent = MainFrame
ToggleAim.Position = UDim2.new(0.05, 0, 0.25, 0)
ToggleAim.Size = UDim2.new(0.9, 0, 0, 35)
ToggleAim.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
ToggleAim.Text = "Aimbot: OFF"
ToggleAim.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleAim.TextSize = 14

ToggleEsp.Parent = MainFrame
ToggleEsp.Position = UDim2.new(0.05, 0, 0.50, 0)
ToggleEsp.Size = UDim2.new(0.9, 0, 0, 35)
ToggleEsp.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
ToggleEsp.Text = "ESP Boxes: OFF"
ToggleEsp.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleEsp.TextSize = 14

CloseBtn.Parent = MainFrame
CloseBtn.Position = UDim2.new(0.05, 0, 0.75, 0)
CloseBtn.Size = UDim2.new(0.9, 0, 0, 30)
CloseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
CloseBtn.Text = "СВЕРНУТЬ МЕНЮ"
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)

-- Включение кнопок меню
ToggleAim.MouseButton1Click:Connect(function()
    _G.AimbotEnabled = not _G.AimbotEnabled
    ToggleAim.Text = _G.AimbotEnabled and "Aimbot: ON" or "Aimbot: OFF"
    ToggleAim.BackgroundColor3 = _G.AimbotEnabled and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(150, 0, 0)
end)

ToggleEsp.MouseButton1Click:Connect(function()
    _G.EspEnabled = not _G.EspEnabled
    ToggleEsp.Text = _G.EspEnabled and "ESP Boxes: ON" or "ESP Boxes: OFF"
    ToggleEsp.BackgroundColor3 = _G.EspEnabled and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(150, 0, 0)
end)

local IsOpen = true
CloseBtn.MouseButton1Click:Connect(function()
    IsOpen = not IsOpen
    MainFrame.Size = IsOpen and UDim2.new(0, 220, 0, 180) or UDim2.new(0, 220, 0, 30)
    ToggleAim.Visible = IsOpen
    ToggleEsp.Visible = IsOpen
end)

-- 2. ЛОГИКА AIMBOT И МОБИЛЬНОЙ КАМЕРЫ
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(0, 255, 255)
FOVCircle.Radius = _G.AimRadius
FOVCircle.Filled = false
FOVCircle.Visible = true

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Visible = _G.AimbotEnabled
end)

local function GetClosestTarget()
    local CurrentTarget = nil
    local MaxDistance = _G.AimRadius
    local CenterScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if p.Team == LocalPlayer.Team then continue end
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then continue end

            local Pos, Visible = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if Visible then
                local Distance = (Vector2.new(Pos.X, Pos.Y) - CenterScreen).Magnitude
                if Distance < MaxDistance then
                    MaxDistance = Distance
                    CurrentTarget = p.Character.Head
                end
            end
        end
    end
    return CurrentTarget
end

RunService.RenderStepped:Connect(function()
    if _G.AimbotEnabled and (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then
        local Target = GetClosestTarget()
        if Target then
            local LookCFrame = CFrame.new(Camera.CFrame.Position, Target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(LookCFrame, _G.AimSmooth)
        end
    end
end)

-- 3. ЛОГИКА СТАБИЛЬНОГО МОБИЛЬНОГО ESP
local function AddEspToPlayer(Plr)
    local Box = Drawing.new("Square")
    Box.Thickness = 1.5
    Box.Color = Color3.fromRGB(255, 0, 100)
    Box.Filled = false
    Box.Visible = false

    local Connection
    Connection = RunService.RenderStepped:Connect(function()
        if _G.EspEnabled and Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") then
            if Plr.Team == LocalPlayer.Team then Box.Visible = false return end
            local Hum = Plr.Character:FindFirstChildOfClass("Humanoid")
            if Hum and Hum.Health > 0 then
                local Pos, OnScreen = Camera:WorldToViewportPoint(Plr.Character.HumanoidRootPart.Position)
                if OnScreen then
                    local SizeZ = Pos.Z
                    Box.Size = Vector2.new(2200 / SizeZ, 3200 / SizeZ)
                    Box.Position = Vector2.new(Pos.X - Box.Size.X / 2, Pos.Y - Box.Size.Y / 2)
                    Box.Visible = true
                    return
                end
            end
        end
        Box.Visible = false
        if not Plr.Parent then Box:Remove() Connection:Disconnect() end
    end)
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then AddEspToPlayer(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then AddEspToPlayer(p) end end)
