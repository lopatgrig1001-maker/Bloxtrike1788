-- ТЕСТ: возвращаем Ray ВСЕГДА В НЕБО
local Workspace = game:GetService("Workspace")
local Cam = Workspace.CurrentCamera

pcall(function()
    local oldFunc = Cam.ViewportPointToRay
    local newFunc = newcclosure(function(self, ...)
        return Ray.new(Cam.CFrame.Position, Vector3.new(0, 1, 0) * 1000)
    end)
    hookfunction(oldFunc, newFunc)
end)

print("TEST: Ray → небо")
