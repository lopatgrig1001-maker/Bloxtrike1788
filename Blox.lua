local VIM = game:GetService("VirtualInputManager")

print("VIM:", VIM)

-- Двигаем "курсор" и кликаем
VIM:SendMouseMoveEvent(200, 200, game)
task.wait(0.3)
VIM:SendMouseMoveEvent(400, 400, game)
task.wait(0.3)
VIM:SendMouseButtonEvent(400, 400, 0, true, game, 1)
task.wait(0.1)
VIM:SendMouseButtonEvent(400, 400, 0, false, game, 1)

print("VIM test sent")
