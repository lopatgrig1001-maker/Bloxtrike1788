-- [[ ПОЛНЫЙ ОТКРЫТЫЙ ИСХОДНЫЙ КОД: AIMBOT + ESP SUITE (BLOXSTRIKE) ]] --

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ФУНКЦИЯ 1: ГЛОБАЛЬНЫЕ НАСТРОЙКИ (Конфиг чита)
local Config = {
    AimEnabled = true,
    AimKey = Enum.KeyCode.E,          -- Кнопка активации аима
    AimPart = "HumanoidRootPart",    -- Куда целиться
    AimRadius = 150,                 -- Радиус FOV круга
    AimSmooth = 0.12,                -- Плавность доводки мыши
    
    EspEnabled = true,
    EspBoxes = true,                 -- Отображение 2D Квадратов
    EspLines = true,                 -- Линии (Трейсеры) до врагов
    EspHealth = true,                -- Полоска здоровья врага
    EspDistance = true,              -- Расстояние в метрах
    TeamCheck = true                 -- Проверка на союзников
}

-- ФУНКЦИЯ 2: ОТРИСОВКА КРУГА ФОКУСА (FOV)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(0, 255, 255) -- Бирюзовый круг
FOVCircle.Radius = Config.AimRadius
FOVCircle.Filled = false
FOVCircle.Visible = Config.AimEnabled

-- ФУНКЦИЯ 3: СИНХРОНИЗАЦИЯ КРУГА С МЫШКОЙ
RunService.RenderStepped:Connect(function()
    if FOVCircle then
        local MousePos = UserInputService:GetMouseLocation()
        FOVCircle.Position = Vector2.new(MousePos.X, MousePos.Y)
    end
end)

-- ФУНКЦИЯ 4: УНИВЕРСАЛЬНЫЙ СКАНЕР ДЛЯ ПОИСКА БЛИЖАЙШЕЙ ЦЕЛИ
local function GetClosestEnemyInFOV()
    local MaxDist = Config.AimRadius
    local ClosestTarget = nil
    local MousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Config.AimPart) then
            -- Двойная проверка на команду (Team Check)
            if Config.TeamCheck and player.Team == LocalPlayer.Team then continue end
            
            -- Проверка здоровья цели
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health <= 0 then continue end

            local ScreenPos, OnScreen = Camera:WorldToViewportPoint(player.Character[Config.AimPart].Position)
            
            if OnScreen then
                local DistanceToMouse = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                -- Проверяем, входит ли цель в радиус нашего круга
                if DistanceToMouse < MaxDist then
                    MaxDist = DistanceToMouse
                    ClosestTarget = player.Character[Config.AimPart]
                end
            end
        end
    end
    return ClosestTarget
end

-- ФУНКЦИЯ 5: РАБОТА АИМБОТА ЧЕРЕЗ ЭМУЛЯЦИЮ МЫШИ (mousemoverel)
RunService.RenderStepped:Connect(function()
    if Config.AimEnabled and (UserInputService:IsKeyDown(Config.AimKey) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then
        local Target = GetClosestEnemyInFOV()
        if Target then
            local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Target.Position)
            if OnScreen then
                local MousePos = UserInputService:GetMouseLocation()
                -- Метод mousemoverel имитирует физический сдвиг мыши, обходя защиту Блок Страйка
                if mousemoverel then
                    mousemoverel((ScreenPos.X - MousePos.X) * Config.AimSmooth, (ScreenPos.Y - MousePos.Y) * Config.AimSmooth)
                else
                    -- Запасной вариант изменения CFrame камеры, если инжектор старый
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Target.Position), Config.AimSmooth)
                end
            end
        end
    end
end)

-- ФУНКЦИЯ 6: ПОЛНЫЙ ДИНАМИЧЕСКИЙ ESP ПАКЕТ
local function CreateFullESP(TargetPlayer)
    -- Инициализация элементов рисования
    local Box = Drawing.new("Square")
    Box.Thickness = 1.5
    Box.Color = Color3.fromRGB(255, 0, 100) -- Ярко-розовый бокс
    Box.Filled = false
    Box.Visible = false

    local HealthBar = Drawing.new("Line")
    HealthBar.Thickness = 2
    HealthBar.Color = Color3.fromRGB(0, 255, 0)
    HealthBar.Visible = false

    local Tracer = Drawing.new("Line")
    Tracer.Thickness = 1
    Tracer.Color = Color3.fromRGB(255, 255, 255)
    Tracer.Visible = false

    local TextDistance = Drawing.new("Text")
    TextDistance.Size = 14
    TextDistance.Center = true
    TextDistance.Outline = true
    TextDistance.Color = Color3.fromRGB(255, 255, 255)
    TextDistance.Visible = false

    -- Цикл обновления графики ESP на каждый кадр
    local RenderConnection
    RenderConnection = RunService.RenderStepped:Connect(function()
        if Config.EspEnabled and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            if Config.TeamCheck and TargetPlayer.Team == LocalPlayer.Team then
                Box.Visible = false; HealthBar.Visible = false; Tracer.Visible = false; TextDistance.Visible = false
                return
            end

            local Humanoid = TargetPlayer.Character:FindFirstChildOfClass("Humanoid")
            if Humanoid and Humanoid.Health > 0 then
                local RootPart = TargetPlayer.Character.HumanoidRootPart
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)

                if OnScreen then
                    local DistZ = ScreenPos.Z
                    local BoxSizeX = 2300 / DistZ
                    local BoxSizeY = 3300 / DistZ
                    local BoxPosX = ScreenPos.X - BoxSizeX / 2
                    local BoxPosY = ScreenPos.Y - BoxSizeY / 2

                    -- Отрисовка Квадрата (Box)
                    if Config.EspBoxes then
                        Box.Size = Vector2.new(BoxSizeX, BoxSizeY)
                        Box.Position = Vector2.new(BoxPosX, BoxPosY)
                        Box.Visible = true
                    else Box.Visible = false end

                    -- Отрисовка Здоровья (Dynamic HealthBar)
                    if Config.EspHealth then
                        local HealthPercent = Humanoid.Health / Humanoid.MaxHealth
                        HealthBar.From = Vector2.new(BoxPosX - 4, BoxPosY + BoxSizeY)
                        HealthBar.To = Vector2.new(BoxPosX - 4, BoxPosY + BoxSizeY - (BoxSizeY * HealthPercent))
                        -- Меняем цвет от зеленого к красному в зависимости от остатка HP
                        HealthBar.Color = Color3.fromHSV(HealthPercent * 0.3, 1, 1)
                        HealthBar.Visible = true
                    else HealthBar.Visible = false end

                    -- Отрисовка Линий (Tracers из нижней части экрана)
                    if Config.EspLines then
                        Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        Tracer.To = Vector2.new(ScreenPos.X, ScreenPos.Y)
                        Tracer.Visible = true
                    else Tracer.Visible = false end

                    -- Отрисовка Расстояния (Distance)
                    if Config.EspDistance then
                        local Meters = math.floor((RootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                        TextDistance.Text = tostring(Meters) .. "m"
                        TextDistance.Position = Vector2.new(ScreenPos.X, BoxPosY + BoxSizeY + 2)
                        TextDistance.Visible = true
                    else TextDistance.Visible = false end

                    return
                end
            end
        end

        -- Скрываем всё, если игрок мертв или за экраном
        Box.Visible = false
        HealthBar.Visible = false
        Tracer.Visible = false
        TextDistance.Visible = false

        -- Очистка памяти при выходе игрока
        if not TargetPlayer.Parent then
            Box:Remove()
            HealthBar:Remove()
            Tracer:Remove()
            TextDistance:Remove()
            RenderConnection:Disconnect()
        end
    end)
end

-- ФУНКЦИЯ 7: ИНИЦИАЛИЗАЦИЯ ПОТОКОВ ДЛЯ ВСЕХ ИГРОКОВ
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then CreateFullESP(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then CreateFullESP(p) end
end)
