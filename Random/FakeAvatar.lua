-- Global Configuration
if not getgenv().Config then
    getgenv().Config = {
        Headless = true,
        FakeId = 1235931594,
    }
end

-- Services
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

-- Local Player
local lp = players.LocalPlayer

-- Cleans up the character by removing all old accessories and clothing
local function cleanCharacter(char)
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("BodyColors") then
            obj:Destroy()
        elseif obj:IsA("BasePart") and obj.Name == "Head" then
            local face = obj:FindFirstChildOfClass("Decal")
            if face then
                face:Destroy()
            end
        end
    end
end

-- Applies a new appearance to the player's character
local function disguiseCharacter(char, id)
    task.spawn(function()
        if not char then return end

        cleanCharacter(char)

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local desc
        repeat
            local success = pcall(function()
                desc = players:GetHumanoidDescriptionFromUserId(id)
            end)
            task.wait()
        until success

        humanoid:ApplyDescriptionClientServer(desc)
    end)
end

-- Makes the player's character headless
local function makeHeadless()
    task.spawn(function()
        local char = lp.Character or lp.CharacterAdded:Wait()
        local head = char:WaitForChild("Head")
        head.Transparency = 1

        local face = head:FindFirstChildOfClass("Decal")
        if face then face:Destroy() end

        head:GetPropertyChangedSignal("Transparency"):Connect(function()
            if head.Transparency ~= 1 then
                head.Transparency = 1
            end
        end)

        head.ChildAdded:Connect(function(child)
            if child:IsA("Decal") then
                child:Destroy()
            end
        end)
    end)
end

-- Initialization
lp.CharacterAppearanceId = Config.FakeId

lp.CharacterAdded:Connect(function(char)
    disguiseCharacter(char, Config.FakeId)
    if Config.Headless then
        makeHeadless()
    end
end)

if lp.Character then
    disguiseCharacter(lp.Character, Config.FakeId)
    if Config.Headless then
        makeHeadless()
    end
end
