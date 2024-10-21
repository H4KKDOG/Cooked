if game.PlaceId ~= 16732694052 then return end
print("Fisch (Executed)")

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

local LocalPlayer = Players.LocalPlayer
local playerName = LocalPlayer.Name
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildOfClass("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local playerBobberWorkspace = workspace:FindFirstChild(playerName)

local Progress, Reeling, WaitDelay, flying = false, false, false, false
local horizontalSpeed, verticalSpeed = 175, 75
local rodName, lastButtonInstance, bodyVelocity
local Enabled = true

local FarmKeybind, SellKeybind, FlyKeybind = Enum.KeyCode.T, Enum.KeyCode.F, Enum.KeyCode.X
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
        if nRod and nRod:FindFirstChild("events") then
            if rodName and rodName ~= "" then
                Character:FindFirstChild(rodName).events.reset:FireServer()
                Character:FindFirstChild(rodName).events.cast:FireServer(100)
            end
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

local function handleShakeUI()
    if LocalPlayer.PlayerGui:FindFirstChild("shakeui") and LocalPlayer.PlayerGui.shakeui.safezone.button then
        local shakeButton = LocalPlayer.PlayerGui.shakeui.safezone.button
        if shakeButton ~= lastButtonInstance then
            lastButtonInstance = shakeButton

            local ButtonPosition, ButtonSize = shakeButton.AbsolutePosition, shakeButton.AbsoluteSize
            local radius = ButtonSize.X / 2
            local ClickPositionX = ButtonPosition.X + ButtonSize.X - radius * 0.55
            local ClickPositionY = ButtonPosition.Y + ButtonSize.Y - radius * 0.55

            if ClickPositionX ~= 29 then
                VirtualInputManager:SendMouseButtonEvent(ClickPositionX, ClickPositionY, 0, true, game, 1)
                VirtualInputManager:SendMouseButtonEvent(ClickPositionX, ClickPositionY, 0, false, game, 1)
            end
        end
    end
end

local function Invi()
    if flying then
        local originalCFrame = HumanoidRootPart.CFrame
        local offsetCFrame = originalCFrame * CFrame.new(0, -1000, 0)
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
    end
end

LocalPlayer.Character.ChildAdded:Connect(function(Child)
    if Child:IsA('Tool') and Child.Name:lower():find('rod') then
        rodName = Child.Name
    end
end)

LocalPlayer.Character.ChildRemoved:Connect(function(Child)
    if Child.Name == rodName then
        rodName, WaitDelay, Reeling, Progress = nil, false, false, false
    end
end)

playerBobberWorkspace.DescendantRemoving:Connect(function(BobChild)
    if BobChild.Name == "bobber" then
        Progress = false
    end
end)

LocalPlayer.PlayerGui.DescendantAdded:Connect(function(Descendant)
    if Descendant.Name == 'playerbar' and Descendant.Parent.Name == 'bar' then
        handleReelUI(Descendant)
    end
end)

RunService.Heartbeat:Connect(function()
    handleShakeUI()
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

ContextActionService:BindAction('ToggleFarm', ToggleFarm, false, FarmKeybind)
ContextActionService:BindAction('toggleFly', toggleFly, false, FlyKeybind)
ContextActionService:BindAction('SellFish', SellFish, false, SellKeybind)

ShowNotification("Fisch Script Executed")
ShowNotification("Farm Status: " .. tostring(Enabled))
