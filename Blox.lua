-- BloxStrike Aimbot + Silent Aim + ESP + Bunny Hop
-- Executor: Delta / Xeno / Wave

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--========== НАСТРОЙКИ ==========
local CONFIG = {
    AimEnabled = true,
    AimKey = Enum.UserInputType.MouseButton2,
    AimSmoothness = 0.15,
    AimFOV = 120,
    AimPart = "Head",
    WallCheck = true,
    TeamCheck = true,
    
    SilentAimEnabled = true,
    SilentAimHitChance = 100,
    
    ESPEnabled = true,
    ESPBox = true,
    ESPName = true,
    ESPHealth = true,
    ESPDistance = true,
    ESPMaxDistance = 500,
    
    BhopEnabled = true,
    BhopSpeed = 18
}

--========== ПЕРЕМЕННЫЕ ==========
local currentTarget = nil
local espCache = {}
local bhopConnection = nil

--========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========
local function isTeammate(player)
    if not CONFIG.TeamCheck then return false end
    return player.Team == LocalPlayer.Team
end

local function isVisible(player)
    if not CONFIG.WallCheck then return true end
    local char = player.Character
    if not char then return false end
    local part = char:FindFirstChild(CONFIG.AimPart) or char:FindFirstChild("HumanoidRootPart")
    if not part then return false end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * 1000
    local result = Workspace:Raycast(origin, direction, rayParams)
    
    if result then
        return result.Instance:IsDescendantOf(char)
    end
    return true
end

local function getClosestPlayer()
    local closest = nil
    local closestDist = math.huge
    local center = Camera.ViewportSize / 2
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if isTeammate(player) then continue end
        
        local char = player.Character
        if not char then continue end
        
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        
        local part = char:FindFirstChild(CONFIG.AimPart) or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        
        if not isVisible(player) then continue end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < CONFIG.AimFOV and dist < closestDist then
            closestDist = dist
            closest = player
        end
    end
    
    return closest
end

--========== AIMBOT ==========
local function updateAimbot()
    if not CONFIG.AimEnabled then
        currentTarget = nil
        return
    end
    
    if UserInputService:IsMouseButtonPressed(CONFIG.AimKey) then
        currentTarget = getClosestPlayer()
        
        if currentTarget then
            local char = currentTarget.Character
            local part = char and char:FindFirstChild(CONFIG.AimPart)
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if part and root then
                local predictedPos = part.Position + (part.Velocity * 0.05)
                local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, predictedPos)
                
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, CONFIG.AimSmoothness)
            end
        end
    else
        currentTarget = nil
    end
end

--========== ESP ==========
local function createESP(player)
    if player == LocalPlayer then return end
    if espCache[player] then return end
    
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Transparency = 1
    box.Color = Color3.fromRGB(255, 255, 255)
    box.Visible = false
    
    local name = Drawing.new("Text")
    name.Size = 14
    name.Center = true
    name.Outline = true
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Visible = false
    
    local healthBar = Drawing.new("Square")
    healthBar.Thickness = 1
    healthBar.Filled = true
    healthBar.Transparency = 1
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Visible = false
    
    local distText = Drawing.new("Text")
    distText.Size = 12
    distText.Center = true
    distText.Outline = true
    distText.Color = Color3.fromRGB(200, 200, 200)
    distText.Visible = false
    
    espCache[player] = {
        box = box,
        name = name,
        healthBar = healthBar,
        distText = distText
    }
end

local function updateESP()
    for player, data in pairs(espCache) do
        local char = player.Character
        
        if not CONFIG.ESPEnabled or not char then
            data.box.Visible = false
            data.name.Visible = false
            data.healthBar.Visible = false
            data.distText.Visible = false
            continue
        end
        
        local hum = char:FindFirstChild("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        
        if not hum or not root or not head or hum.Health <= 0 then
            data.box.Visible = false
            data.name.Visible = false
            data.healthBar.Visible = false
            data.distText.Visible = false
            continue
        end
        
        local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local rootPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2, 0))
        
        local distance = (Camera.CFrame.Position - root.Position).Magnitude
        
        if not headPos.Z or headPos.Z < 0 or distance > CONFIG.ESPMaxDistance then
            data.box.Visible = false
            data.name.Visible = false
            data.healthBar.Visible = false
            data.distText.Visible = false
            continue
        end
        
        local height = math.abs(headPos.Y - rootPos.Y)
        local width = height * 0.6
        
        data.box.Size = Vector2.new(width, height)
        data.box.Position = Vector2.new(headPos.X - width / 2, headPos.Y)
        data.box.Visible = true
        
        data.name.Position = Vector2.new(headPos.X, headPos.Y - 18)
        data.name.Text = player.Name
        data.name.Visible = true
        
        local healthPercent = hum.Health / hum.MaxHealth
        data.healthBar.Size = Vector2.new(3, height * healthPercent)
        data.healthBar.Position = Vector2.new(headPos.X - width / 2 - 6, headPos.Y + height * (1 - healthPercent))
        data.healthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
        data.healthBar.Visible = true
        
        data.distText.Position = Vector2.new(headPos.X, headPos.Y + height + 4)
        data.distText.Text = string.format("[%d studs]", math.floor(distance))
        data.distText.Visible = true
    end
end

--========== BUNNY HOP ==========
local function startBhop()
    if bhopConnection then
        bhopConnection:Disconnect()
    end
    
    bhopConnection = RunService.Heartbeat:Connect(function()
        if not CONFIG.BhopEnabled then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        
        if not root or not hum then return end
        
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {char}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            
            local groundCheck = Workspace:Raycast(root.Position, Vector3.new(0, -4, 0), rayParams)
            
            if groundCheck then
                hum.Jump = true
            end
        end
        
        local direction = Vector3.zero
        local look = Camera.CFrame.LookVector
        local right = Camera.CFrame.RightVector
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += look end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= look end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= right end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += right end
        
        if direction.Magnitude > 0 then
            direction = Vector3.new(direction.X, 0, direction.Z).Unit * CONFIG.BhopSpeed
            local vel = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(
                vel.X + (direction.X - vel.X) * 0.2,
                vel.Y,
                vel.Z + (direction.Z - vel.Z) * 0.2
            )
        end
    end)
end

--========== ИНИЦИАЛИЗАЦИЯ ==========
-- ESP для существующих игроков
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

-- ESP для новых игроков
Players.PlayerAdded:Connect(function(player)
    createESP(player)
end)

-- Обновление в цикле
RunService.RenderStepped:Connect(function()
    updateAimbot()
    updateESP()
end)

-- Запуск Bhop
startBhop()

--========== СИЛЕНТ АИМ (HOOK METAMETHOD) ==========
-- Перехват выстрелов через hookmetamethod
local oldNamecall
local mt = getrawmetatable(game)
if mt then
    setreadonly(mt, false)
    oldNamecall = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        
        if CONFIG.SilentAimEnabled and (method == "Fire" or method == "InvokeServer") then
            local args = {...}
            
            if typeof(args[1]) == "Vector3" or typeof(args[1]) == "CFrame" then
                local target = nil
                local closestDist = math.huge
                
                for _, player in ipairs(Players:GetPlayers()) do
                    if player == LocalPlayer then continue end
                    if isTeammate(player) then continue end
                    
                    local char = player.Character
                    if not char then continue end
                    
                    local hum = char:FindFirstChild("Humanoid")
                    if not hum or hum.Health <= 0 then continue end
                    
                    local part = char:FindFirstChild(CONFIG.AimPart) or char:FindFirstChild("HumanoidRootPart")
                    if not part then continue end
                    
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if not onScreen then continue end
                    
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Camera.ViewportSize/2).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        target = part
                    end
                end
                
                if target and math.random(1, 100) <= CONFIG.SilentAimHitChance then
                    if typeof(args[1]) == "Vector3" then
                        args[1] = target.Position
                    elseif typeof(args[1]) == "CFrame" then
                        args[1] = CFrame.new(target.Position)
                    end
                end
                
                return oldNamecall(self, table.unpack(args))
            end
        end
        
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end

print("[R] BloxStrike loaded. Aimbot: RMB, Silent Aim: ON, ESP: ON, Bhop: Hold Space")
