if Invi then 
    for _,b in pairs(Invi) do 
        b:Disconnect() 
    end 
    Invi = nil 
end

local player
repeat task.wait() until game.Players.LocalPlayer 
player = game.Players.LocalPlayer

local mouse, character, humanoid, humanoidRootPart = player:GetMouse(), player.Character or player.CharacterAdded:Wait(), nil, nil
repeat humanoid = character:FindFirstChildOfClass("Humanoid") until humanoid
repeat humanoidRootPart = character:FindFirstChild("HumanoidRootPart") until humanoidRootPart

local isActive = false
local visibleParts = {}

for _, part in pairs(character:GetDescendants()) do 
    if part:IsA("BasePart") and part.Transparency == 0 then 
        table.insert(visibleParts, part)
    end
end

local connections = {}

connections[1] = mouse.KeyDown:Connect(function(key)
    if key == "G" then
        isActive = not isActive
        for _, part in pairs(visibleParts) do 
            part.Transparency = part.Transparency == 0 and 0.5 or 0
        end
    end
end)

connections[2] = game:GetService("RunService").Heartbeat:Connect(function()
    if isActive then
        local currentCFrame, originalCameraOffset = humanoidRootPart.CFrame, humanoid.CameraOffset
        local newCFrame = currentCFrame * CFrame.new(0, -10000, 0)
      
        humanoid.CameraOffset, humanoidRootPart.CFrame = newCFrame:ToObjectSpace(CFrame.new(currentCFrame.Position)).Position, newCFrame
        game:GetService("RunService").RenderStepped:Wait()
        humanoid.CameraOffset, humanoidRootPart.CFrame = originalCameraOffset, currentCFrame
    end
end)

Invi = connections
