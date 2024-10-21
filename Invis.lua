if _G.connections then 
    for _, connection in pairs(_G.connections) do 
        connection:Disconnect() 
    end 
    _G.connections = nil 
end

local Player
repeat task.wait() until game.Players.LocalPlayer 
Player = game.Players.LocalPlayer

local Mouse
local Character
local Humanoid
local HumanoidRootPart

Mouse = Player:GetMouse()
Character = Player.Character or Player.CharacterAdded:Wait()

repeat 
    Humanoid = Character:FindFirstChildOfClass("Humanoid") 
until Humanoid

repeat 
    HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart") 
until HumanoidRootPart

local IsTransparent = false
local CharacterParts = {}

for _, part in pairs(Character:GetDescendants()) do 
    if part:IsA("BasePart") and part.Transparency == 0 then 
        CharacterParts[#CharacterParts + 1] = part 
    end 
end

local function onPlayerDied()
    IsTransparent = false 
    for _, part in pairs(CharacterParts) do 
        part.Transparency = 0 
    end
end

Humanoid.Died:Connect(onPlayerDied)

local KeyConnections = {nil, nil}

KeyConnections[1] = Mouse.KeyDown:Connect(function(key)
    if key == "g" then
        IsTransparent = not IsTransparent
        for _, part in pairs(CharacterParts) do 
            part.Transparency = part.Transparency == 0 and 0.5 or 0 
        end
    end
end)

KeyConnections[2] = game:GetService("RunService").Heartbeat:Connect(function()
    if IsTransparent then
        local originalCFrame = HumanoidRootPart.CFrame
        local originalCameraOffset = Humanoid.CameraOffset
        local newCFrame = originalCFrame * CFrame.new(0, -2000000, 0)
        Humanoid.CameraOffset = newCFrame:ToObjectSpace(CFrame.new(originalCFrame.Position)).Position
        HumanoidRootPart.CFrame = newCFrame
        game:GetService("RunService").RenderStepped:Wait()
        Humanoid.CameraOffset = originalCameraOffset
        HumanoidRootPart.CFrame = originalCFrame
    end
end)

_G.connections = KeyConnections

local function onCharacterAdded(newCharacter)
    Character = newCharacter
    Humanoid = newCharacter:WaitForChild("Humanoid")
    HumanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
    
    CharacterParts = {}
    for _, part in pairs(newCharacter:GetDescendants()) do 
        if part:IsA("BasePart") and part.Transparency == 0 then 
            CharacterParts[#CharacterParts + 1] = part 
        end 
    end

    Humanoid.Died:Connect(onPlayerDied)
end

Player.CharacterAdded:Connect(onCharacterAdded)
