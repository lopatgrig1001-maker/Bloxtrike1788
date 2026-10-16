-- SILENT AIM через hookfunction (менее агрессивно чем __namecall)
local function getTarget()
    local vp = Cam.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)
    local fovPx = (FOV / 90) * (math.sqrt(vp.X^2 + vp.Y^2) / 2)
    local best, bd = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local char = p.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then continue end
        if char:GetAttribute("Dead") then continue end
        local head = char:FindFirstChild("Head")
        if not head then continue end
        local sp, on = Cam:WorldToViewportPoint(head.Position)
        if not on or sp.Z <= 0 then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < fovPx and d < bd then bd = d; best = head end
    end
    return best
end

-- Пытаемся хукнуть через __namecall (если не крашит)
local success, err = pcall(function()
    local mt = getrawmetatable(game)
    if not mt then error("no mt") end
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Fire" or method == "FireServer" or method == "InvokeServer" then
            local args = {...}
            if typeof(args[1]) == "Vector3" or typeof(args[1]) == "CFrame" then
                local target = getTarget()
                if target then
                    if typeof(args[1]) == "Vector3" then
                        args[1] = target.Position
                    elseif typeof(args[1]) == "CFrame" then
                        args[1] = CFrame.new(target.Position)
                    end
                end
                return old(self, table.unpack(args))
            end
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end)

if success then
    print("[R] SILENT via __namecall OK")
else
    warn("[R] __namecall failed:", err)
end
