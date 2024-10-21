if game.PlaceId ~= 16732694052 then return end
print("FischSimple (Executed)")

repeat task.wait() until game:IsLoaded()

if getgenv().Shiro then return end
getgenv().Shiro = true

local Players = game:GetService('Players')
local CoreGui = game:GetService('StarterGui')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ContextActionService = game:GetService('ContextActionService')
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService('VirtualInputManager')
local GuiService = game:GetService('GuiService')

local LocalPlayer = Players.LocalPlayer
local playerName = LocalPlayer.Name
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildOfClass("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local playerBobberWorkspace = workspace:FindFirstChild(playerName)

local Progress, Reeling, WaitDelay, flying = false, false, false, false
local horizontalSpeed, verticalSpeed = 175, 75
local rodName, lastButtonInstance, bodyVelocity, currentPlatform
local Enabled = true
local AShake = true

local FarmKeybind = Enum.KeyCode.T
local SellKeybind = Enum.KeyCode.F
local FlyKeybind = Enum.KeyCode.X
local ShakeKeybind = Enum.KeyCode.N
local platformKeybind = Enum.KeyCode.P
local teleportKeybind = Enum.KeyCode.KeypadMinus

local parts = {}

for _, part in pairs(Character:GetDescendants()) do
    if part:IsA("BasePart") and part.Transparency == 0 then
        table.insert(parts, part)
    end
end

local function ShowNotification(String)
    CoreGui:SetCore('SendNotification', {
        Title = 'Notification',
        Text = String,
        Duration = 5
    })
end

local function updateRodInWorkspace()
    local playerWorkspace = workspace:FindFirstChild(playerName)
    if playerWorkspace then
        for _, item in pairs(playerWorkspace:GetChildren()) do
            if item:IsA('Tool') and item.Name:lower():find('rod') then
                rodName = item.Name
                return item
            end
        end
    end
    return nil
end

local function createPlatform()
    if currentPlatform then
        currentPlatform:Destroy()
        currentPlatform = nil
    end

    currentPlatform = Instance.new("Part")
    currentPlatform.Size = Vector3.new(5, 1, 5)
    currentPlatform.Anchored = true
    currentPlatform.Transparency = 0.5
    currentPlatform.CanCollide = true
    currentPlatform.Color = Color3.fromRGB(255, 255, 255)
    currentPlatform.Position = HumanoidRootPart.Position - Vector3.new(0, HumanoidRootPart.Size.Y / 2 + 1, 0)
    currentPlatform.Parent = workspace
end

local function checkBobber()
    local nRod = updateRodInWorkspace()
    if nRod and not nRod:FindFirstChild("bobber") then
        return nRod
    end
    return nil
end

local function farmAction()
    local nRod = checkBobber()
    if nRod then
        Progress = true
        wait(1.75)

        VirtualInputManager:SendMouseButtonEvent(1, 1, 0, true, game, 1)
        task.wait(0.75)
        VirtualInputManager:SendMouseButtonEvent(1, 1, 0, false, game, 1)

        wait()
        if rodName and rodName ~= "" then
            Character:FindFirstChild(rodName).events.reset:FireServer()
            Character:FindFirstChild(rodName).events.cast:FireServer(100)
        end

        wait(1.75)
    end
end

local function ToggleFarm(_, State)
    if State == Enum.UserInputState.Begin then
        Enabled = not Enabled
        ShowNotification("Farm Status: " .. tostring(Enabled))
    end
end

local function togglePlatform(_, State)
    if State == Enum.UserInputState.Begin then
        createPlatform()
    end
end

local function AutoShake(_, State)
    if State == Enum.UserInputState.Begin then
        AShake = not AShake
        ShowNotification("Auto Shake: " .. tostring(AShake))
        if not AShake then
            GuiService.SelectedObject = nil
        end
    end
end

local function teleportToLocation(_, State)
    if State == Enum.UserInputState.Begin then
        if HumanoidRootPart then
            HumanoidRootPart.CFrame = CFrame.new(Vector3.new(1296.32080078125, -805.292236328125, -298.93817138671875))
        end
    end
end

local function SellFish(_, State)
    if State == Enum.UserInputState.Begin then
        ReplicatedStorage.events.selleverything:InvokeServer()
    end
end

local function fly()
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(5000, 5000, 5000)
    bodyVelocity.Parent = HumanoidRootPart

    while flying do
        local moveDirection = Character.Humanoid.MoveDirection
        moveDirection = moveDirection.Magnitude > 0 and moveDirection.Unit or Vector3.new()

        local verticalVelocity = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            verticalVelocity = verticalSpeed
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            verticalVelocity = -verticalSpeed
        end

        bodyVelocity.Velocity = Vector3.new(
            moveDirection.X * horizontalSpeed,
            verticalVelocity,
            moveDirection.Z * horizontalSpeed
        )
        RunService.RenderStepped:Wait()
    end

    bodyVelocity:Destroy()
end

local function toggleFly(_, State)
    if State == Enum.UserInputState.Begin then
        flying = not flying
        for _, part in pairs(parts) do
            part.Transparency = flying and 0.5 or 0
        end
        if flying then
            fly()
        else
            HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        end
    end
end

local function handleReelUI(Descendant)
    local fish = Descendant.Parent:FindFirstChild("fish")
    local randomChance = math.random(1, 3)
    local Perfect = randomChance <= 1

    WaitDelay = true
    Reeling = true
    GuiService.SelectedObject = nil

    while Reeling do
        if fish and Descendant then
            if not Perfect and WaitDelay then
                Descendant:GetPropertyChangedSignal("Position"):Wait()
                task.wait(0.75)
                WaitDelay = false
            end
            Descendant.Position = UDim2.new(
                fish.Position.X.Scale,
                fish.Position.X.Offset,
                Descendant.Position.Y.Scale,
                Descendant.Position.Y.Offset
            )
        end
        task.wait()
    end
end

local function handleShakeUI(Descendant)
    if AShake and Descendant then
        GuiService.SelectedObject = Descendant
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    end
end


local function Invi()
    if flying then
        local originalCFrame = HumanoidRootPart.CFrame
        local offsetCFrame = originalCFrame * CFrame.new(0, -500, 0)
        Humanoid.CameraOffset = offsetCFrame:ToObjectSpace(CFrame.new(originalCFrame.Position)).Position
        HumanoidRootPart.CFrame = offsetCFrame

        RunService.RenderStepped:Wait()

        Humanoid.CameraOffset = Vector3.new()
        HumanoidRootPart.CFrame = originalCFrame
    end
end

local function replaceAFKEvent()
    local AFK = ReplicatedStorage:FindFirstChild("events"):FindFirstChild("afk")
    if AFK then
        wait(0.75)
        local FakeAFK = Instance.new("RemoteEvent")
        FakeAFK.Name = "afk"
        FakeAFK.Parent = ReplicatedStorage:FindFirstChild("events")

        ShowNotification("AntiAFK")
        AFK:Destroy()
        LocalPlayer.PlayerGui.TopbarStandard.Holders.Left.Quest:Destroy()
    end
end

LocalPlayer.Character.ChildAdded:Connect(function(Child)
    if Child:IsA('Tool') and Child.Name:lower():find('rod') then
        rodName = Child.Name
    end
end)

LocalPlayer.Character.ChildRemoved:Connect(function(Child)
    if Child.Name == rodName then
        rodName = nil
        WaitDelay = false
        Reeling = false
        Progress = false
        GuiService.SelectedObject = nil
    end
end)

playerBobberWorkspace.DescendantRemoving:Connect(function(BobChild)
    if BobChild.Name == "bobber" then
        wait(0.75)
        Progress = false
        GuiService.SelectedObject = nil
    end
end)

LocalPlayer.PlayerGui.DescendantAdded:Connect(function(Descendant)
    if Descendant.Name == 'playerbar' and Descendant.Parent.Name == 'bar' then
        handleReelUI(Descendant)
    elseif Descendant.Name == 'button' and Descendant.Parent.Name == 'safezone' then
        handleShakeUI(Descendant)
    end
end)

RunService.Heartbeat:Connect(function()
    Invi()

    if Enabled and not Progress then
        farmAction()
    end
end)

if UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled then
    local WindowAFK
    WindowAFK = UserInputService.WindowFocused:Connect(function()
        replaceAFKEvent()
        WindowAFK:Disconnect()
    end)
elseif UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    replaceAFKEvent()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == FarmKeybind then
        ToggleFarm(nil, Enum.UserInputState.Begin)
    elseif input.KeyCode == ShakeKeybind then
        AutoShake(nil, Enum.UserInputState.Begin)
    elseif input.KeyCode == FlyKeybind then
        toggleFly(nil, Enum.UserInputState.Begin)
    elseif input.KeyCode == SellKeybind then
        SellFish(nil, Enum.UserInputState.Begin)
    elseif input.KeyCode == teleportKeybind then
        teleportToLocation(nil, Enum.UserInputState.Begin)
    elseif input.KeyCode == platformKeybind then
        togglePlatform(nil, Enum.UserInputState.Begin)
    end
end)

ShowNotification("Fisch Script Executed")
ShowNotification("Farm Status: " .. tostring(Enabled))
ShowNotification("Auto Shake: " .. tostring(AShake))
