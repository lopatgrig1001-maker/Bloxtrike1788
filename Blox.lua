local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

game:GetService("RunService").RenderStepped:Connect(function()
    local myChar = LP.Character
    if not myChar then return end
    local myHead = myChar:FindFirstChild("Head")
    if not myHead then return end
    
    local camPos = Camera.CFrame.Position
    local headPos = myHead.Position
    local dist = (camPos - headPos).Magnitude
    
    local sp, on = Camera:WorldToViewportPoint(headPos)
    
    print(string.format(
        "CamPos: (%.1f,%.1f,%.1f) | MyHead: (%.1f,%.1f,%.1f) | Dist: %.1f | ScreenZ: %.1f | OnScreen: %s",
        camPos.X, camPos.Y, camPos.Z,
        headPos.X, headPos.Y, headPos.Z,
        dist, sp.Z, tostring(on)
    ))
end)
