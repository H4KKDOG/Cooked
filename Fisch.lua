if game.PlaceId ~= 16732694052 then return end
print("Executed : "..game:GetService('Players').LocalPlayer.Name)

repeat
    task.wait()
until game:IsLoaded()

local Players = game:GetService('Players')
local CoreGui = game:GetService('StarterGui')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ContextActionService = game:GetService('ContextActionService')
local VirtualInputManager = game:GetService('VirtualInputManager')
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService('GuiService')

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildOfClass("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local playerBobberWorkspace = workspace:FindFirstChild(LocalPlayer.Name)

local Enabled = false
local Rod = false
local Casted = false
local Progress = false
local Flying = false
local IsTransparent = false

local horizontalSpeed = 200
local verticalSpeed = 75
local teleportState = 0
local antiAFK = 0

local bodyVelocity
local originalCFrame
local InvisCon
local castConnection
local shakeConnection
local visibleParts = {}

for _, part in pairs(Character:GetDescendants()) do
    if part:IsA("BasePart") and part.Transparency == 0 then
        table.insert(visibleParts, part)
    end
end

function ShowNotification(Title, Content, Time)
    CoreGui:SetCore('SendNotification', {
        Title = Title,
        Text = Content,
        Duration = Time or 2.5
    })
end

function ToggleFarm(Name, State, Input)
    if State == Enum.UserInputState.Begin then
        if Flying then return end
        Enabled = not Enabled

        if not Enabled then
            originalCFrame = nil
            AutoCast(false)
            AutoShake(false)
            ShowNotification("Fishing", "OFF")
        else
            originalCFrame = HumanoidRootPart.CFrame
            AutoCast(true)
            AutoShake(true)
            ShowNotification("Fishing", "ON")
        end
    end
end

function ToggleFly(Name, State, Input)
    if State == Enum.UserInputState.Begin then
        if Enabled then return end
        Flying = not Flying

        for _, part in pairs(visibleParts) do
            part.Transparency = part.Transparency == 0 and 0.5 or 0
        end

        if Flying then
            Invis()
            fly()
        else
            unInvis()
        end
    end
end

function ToggleSell(Name, State, Input)
    if State == Enum.UserInputState.Begin then
        ReplicatedStorage.events.selleverything:InvokeServer()
    end
end

function ToggleTP(Name, State, Input)
    if State == Enum.UserInputState.Begin then
        if Enabled then return end
        if HumanoidRootPart then
            if teleportState == 0 then
                HumanoidRootPart.CFrame = CFrame.new(Vector3.new(1296.32080078125, -805.292236328125, -298.93817138671875))
                teleportState = 1
            else
                HumanoidRootPart.CFrame = CFrame.new(383.060546875, 134.50001525878906, 267.64471435546875)
                teleportState = 0
            end
        end
    end
end

function onPlayerDied()
    IsTransparent = false
    for _, part in pairs(CharacterParts) do
        part.Transparency = 0
    end
end

Humanoid.Died:Connect(onPlayerDied)

function onCharacterAdded(newCharacter)
    Character = newCharacter
    Humanoid = newCharacter:WaitForChild("Humanoid")
    HumanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")

    visibleParts = {}

    for _, part in pairs(Character:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency == 0 then
            table.insert(visibleParts, part)
        end
    end

    Humanoid.Died:Connect(onPlayerDied)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

function updateRodInWorkspace()
    if playerBobberWorkspace then
        for _, item in pairs(playerBobberWorkspace:GetChildren()) do
            if item:IsA('Tool') and item.Name:lower():find('rod') then
                return item
            end
        end
    end
    return nil
end

function fly()
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(5000, 5000, 5000)
    bodyVelocity.Parent = Character:WaitForChild("HumanoidRootPart")

    while Flying do
        local moveDirection = Character.Humanoid.MoveDirection

        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
        end

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

    task.wait()
    bodyVelocity:Destroy()
end

function Invis()
    isInvisible = true

    InvisCon = RunService.Heartbeat:Connect(function()
        if isInvisible then
            local originalCFrame = HumanoidRootPart.CFrame
            local offsetCFrame = originalCFrame * CFrame.new(0, -100, 0)
            Humanoid.CameraOffset = offsetCFrame:ToObjectSpace(CFrame.new(originalCFrame.Position)).Position
            HumanoidRootPart.CFrame = offsetCFrame

            RunService.RenderStepped:Wait()

            Humanoid.CameraOffset = Vector3.new()
            HumanoidRootPart.CFrame = originalCFrame
        end
        
        task.wait()
    end)
end

function unInvis()
    isInvisible = false

    if InvisCon then
        InvisCon:Disconnect()
        InvisCon = nil
    end
end

function replaceAFKEvent()
    local AFK = ReplicatedStorage:FindFirstChild("events"):FindFirstChild("afk")
    if AFK then
        wait(0.75)
        local FakeAFK = Instance.new("RemoteEvent")
        FakeAFK.Name = "afk"
        FakeAFK.Parent = ReplicatedStorage:FindFirstChild("events")

        AFK:Destroy()
        ShowNotification("AntiAFK", "Enabled")
    end
end

function AutoShake(Shake)
    if Shake then
        if shakeConnection then return end
        shakeConnection = RunService.RenderStepped:Connect(function()
            if LocalPlayer.PlayerGui:FindFirstChild("shakeui") and LocalPlayer.PlayerGui.shakeui.safezone:WaitForChild("button") then
                local currentButton = LocalPlayer.PlayerGui.shakeui.safezone:WaitForChild("button")
                if currentButton ~= lastButtonInstance then
                    lastButtonInstance = currentButton
                    GuiService.SelectedObject = currentButton
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                end
            else
                lastButtonInstance = nil
                GuiService.SelectedObject = nil
            end
            task.wait()
        end)
    else
        if shakeConnection then
            shakeConnection:Disconnect()
            shakeConnection = nil
        end
    end
end

function AutoCast(Cast)
    if Cast then
        if castConnection then return end
        castConnection = RunService.RenderStepped:Connect(function()
            if not Progress then
                local workRod = updateRodInWorkspace()
                if workRod and not workRod:FindFirstChild("bobber") then
                    if Rod then
                        Progress = true
                        task.wait(1.25)
                        VirtualInputManager:SendMouseButtonEvent(1, 1, Enum.UserInputType.MouseButton1.Value, true, game, 1)
                        task.wait(0.5)
                        VirtualInputManager:SendMouseButtonEvent(1, 1, Enum.UserInputType.MouseButton1.Value, false, game, 1)
                        Rod.events.reset:FireServer()
                        Rod.events.cast:FireServer(100.5)
                        task.wait(1.75)
                        HumanoidRootPart.CFrame = originalCFrame
                        Progress = false
                    end
                end
            end
            task.wait()
        end)
    else
        if castConnection then
            castConnection:Disconnect()
            castConnection = nil
        end
    end
end

LocalPlayer.Character.ChildAdded:Connect(function(Child)
    if Child:IsA('Tool') and Child.Name:lower():find('rod') then
        Rod = Child
    end
end)

LocalPlayer.Character.ChildRemoved:Connect(function(Child)
    if Child == Rod then
        Progress = false
        Reeling = false
        Rod = nil
    end
end)

LocalPlayer.PlayerGui.DescendantAdded:Connect(function(Descendant)
    if Descendant.Name == 'playerbar' and Descendant.Parent.Name == 'bar' then
        Reeling = true
        WaitDelay = true

        local Random = math.random(1, 3)
        local isPerfect = Random <= 1
        local fish = Descendant.Parent:FindFirstChild("fish")

        while Reeling do
            if fish and Descendant then
                if not isPerfect and WaitDelay then
                    Descendant:GetPropertyChangedSignal("Position"):Wait()
                    task.wait(0.5)
                    WaitDelay = false
                end
                Descendant.Position = fish.Position
            end

            task.wait()
        end
    end
end)

LocalPlayer.PlayerGui.DescendantRemoving:Connect(function(Descendant)
    if Descendant.Name == 'reel' then
        Progress = false
        Reeling = false
    end
end)

local WindowAFK
WindowAFK = UserInputService.WindowFocused:Connect(function()
    replaceAFKEvent()
    AutoShake()
    WindowAFK:Disconnect()
end)
ContextActionService:BindAction('ToggleFarm', ToggleFarm, false, Enum.KeyCode.T)
ContextActionService:BindAction('ToggleFly', ToggleFly, false, Enum.KeyCode.X)
ContextActionService:BindAction('ToggleSell', ToggleSell, false, Enum.KeyCode.F)
ContextActionService:BindAction('ToggleTP', ToggleTP, false, Enum.KeyCode.KeypadPlus)

CoreGui:SetCore('SendNotification', {
    Title = "Notification",
    Text = "Fisch Loaded!",
    Duration = math.huge,
    Button1 = "@zxc.shiro",
})
