-- [[ УНИВЕРСАЛЬНЫЙ AIMBOT И ESP ДЛЯ DELTA ]] --

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- НАСТРОЙКИ ЧИТА (Можно менять прямо тут)
local Settings = {
    AimbotEnabled = true,
    AimKey = Enum.UserInputType.MouseButton2, -- Правая кнопка мыши (или зажатие экрана на телефоне)
    AimPart = "Head", -- Куда целиться: "Head" (Голова) или "HumanoidRootPart" (Тело)
    AimSmoothness = 0.15, -- Плавность (чем меньше, тем быстрее наводка)
    
    EspEnabled = true,
    EspBoxes = true, -- Квадраты вокруг врагов
    EspTracer = true, -- Линии до врагов
    TeamCheck = true -- Не целиться и не подсвечивать своих
}

-- ГЕНЕРАЦИЯ ESP (Отрисовка линий и боксов)
local function CreateESP(Player)
    local Box = Drawing.new("Square")
    Box.Visible = false
    Box.Color = Color3.fromRGB(255, 0, 0)
    Box.Thickness = 1
    Box.Filled = false

    local Tracer = Drawing.new("Line")
    Tracer.Visible = false
    Tracer.Color = Color3.fromRGB(255, 255, 0)
    Tracer.Thickness = 1

    local function Update()
        local Connection
        Connection = RunService.RenderStepped:Connect(function()
            if Settings.EspEnabled and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChildOfClass("Humanoid") and Player.Character.Humanoid.Health > 0 and Player ~= LocalPlayer then
                
                if Settings.TeamCheck and Player.Team == LocalPlayer.Team then
                    Box.Visible = false
                    Tracer.Visible = false
                    return
                end

                local RootPart = Player.Character.HumanoidRootPart
                local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)

                if OnScreen then
                    -- Расчет размеров квадрата
                    local SizeX = 2000 / ScreenPosition.Z
                    local SizeY = 3000 / ScreenPosition.Z
                    
                    if Settings.EspBoxes then
                        Box.Size = Vector2.new(SizeX, SizeY)
                        Box.Position = Vector2.new(ScreenPosition.X - SizeX / 2, ScreenPosition.Y - SizeY / 2)
                        Box.Visible = true
                    else
                        Box.Visible = false
                    end

                    if Settings.EspTracer then
                        Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        Tracer.To = Vector2.new(ScreenPosition.X, ScreenPosition.Y)
                        Tracer.Visible = true
                    else
                        Tracer.Visible = false
                    end
                else
                    Box.Visible = false
                    Tracer.Visible = false
                end
            else
                Box.Visible = false
                Tracer.Visible = false
                if not Player.Parent then
                    Box:Remove()
                    Tracer:Remove()
                    Connection:Disconnect()
                end
            end
        end)
    end
    coroutine.wrap(Update)()
end

-- Включаем ESP для текущих и новых игроков
for _, player in pairs(Players:GetPlayers()) do
    CreateESP(player)
end
Players.PlayerAdded:Connect(CreateESP)

-- ЛОГИКА AIMBOT (Автонаведение)
local Holding = false

UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Settings.AimKey then
        Holding = true
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Settings.AimKey then
        Holding = false
    end
end)

local function GetClosestPlayer()
    local MaximumDistance = math.huge
    local Target = nil

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character footprints and player.Character:FindFirstChild(Settings.AimPart) and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
            if Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
            
            local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(player.Character[Settings.AimPart].Position)
            if OnScreen then
                local MousePosition = UserInputService:GetMouseLocation()
                local Distance = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - MousePosition).Magnitude
                
                if Distance < MaximumDistance then
                    MaximumDistance = Distance
                    Target = player
                end
            end
        end
    end
    return Target
end

RunService.RenderStepped:Connect(function()
    if Settings.AimbotEnabled and Holding then
        local Target = GetClosestPlayer()
        if Target and Target.Character and Target.Character:FindFirstChild(Settings.AimPart) then
            local TargetPosition = Camera:WorldToViewportPoint(Target.Character[Settings.AimPart].Position)
            local MousePosition = UserInputService:GetMouseLocation()
            
            -- Плавное перемещение камеры к цели
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Target.Character[Settings.AimPart].Position), Settings.AimSmoothness)
        end
    end
end)
