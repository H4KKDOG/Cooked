if game.PlaceId ~= 16732694052 then return end
if getgenv().Cooked then return end
getgenv().Cooked = true

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
local Head = LocalPlayer.Character:FindFirstChild("Head")
local playerBobberWorkspace = workspace:FindFirstChild(LocalPlayer.Name)

local Enabled = false
local Rod = false
local Casted = false
local Progress = false
local Flying = false
local IsTransparent = false

local horizontalSpeed = 150
local verticalSpeed = 75
local teleportState = 0
local antiAFK = 0

local bodyVelocity
local InvisCon
local statusLabel
local lastshake
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

function ToggleFarm()
    if Flying then return end
    Enabled = not Enabled

    if not Enabled then
        AutoCast(false)
        AutoShake(false)
        unfreezePlayer()
        GuiService.SelectedObject = nil
        ShowNotification("Fishing", "OFF")
        if statusLabel then
            statusLabel:Destroy()
            statusLabel = nil
        end
    else
        AutoCast(true)
        AutoShake(true)
        freezePlayer()
        ShowNotification("Fishing", "ON")
        createStatusLabel("FISHING")
    end
end

function ToggleFly()
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

function ToggleSell()
    ReplicatedStorage.events.selleverything:InvokeServer()
end

function TPAltar()
    if Enabled or Flying then return end
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

function TPWhirlpool()
    if Enabled or Flying then return end
    local whirlpool = workspace.zones:FindFirstChild("Safe Whirlpool")
    if whirlpool then
        teleportToPart(whirlpool)
    else
        ShowNotification("Whirlpool", "Invalid")
    end
end

function TPAbundance()
    if Enabled or Flying then return end
    findAbundancePart()
end

function TPEvent()
    if Enabled or Flying then return end
    local event = workspace.zones.fishing:FindFirstChild("FischFright24")
    if event and event:IsA("BasePart") then
        teleportToPart(event)
    else
        ShowNotification("Event", "Invalid")
    end
end

function teleportToPart(part)
    local offset = Vector3.new(100, 0, 0)
    local newPosition = part.Position + offset

    HumanoidRootPart.CFrame = CFrame.new(newPosition)
end

function findAbundancePart()
    local abundancePartFound = false
    local mediumStoneGrey = Color3.fromRGB(163, 162, 165)

    for _, part in ipairs(workspace.zones.fishing:GetChildren()) do
        if part:IsA("Part") then
            if part.Material == Enum.Material.Plastic then
                if part.Color ~= mediumStoneGrey then
                    teleportToPart(part)
                    abundancePartFound = true
                    print("Found Event Part (Plastic with Event):", part.Name, "Color:", part.Color)
                    break
                else
                    print("Normal Part (Plastic, Medium Stone Grey):", part.Name)
                end
            elseif part.Material == Enum.Material.Slate then
                print("Normal Part (Slate):", part.Name)
            else
                print("Other Material Part:", part.Name, "Material:", part.Material.Name)
            end
        end
    end

    if not abundancePartFound then
        ShowNotification("Abundance", "Invalid")
    end
end

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

function createStatusLabel(text)
    if statusLabel then
        statusLabel:Destroy()
    end
    
    statusLabel = Instance.new("BillboardGui")
    statusLabel.Adornee = HumanoidRootPart
    statusLabel.Size = UDim2.new(0, 100, 0, 50)
    statusLabel.StudsOffset = Vector3.new(0, 5, 0)
    statusLabel.AlwaysOnTop = true
    statusLabel.LightInfluence = 0
    statusLabel.Active = false

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(0, 0, 1)
    textLabel.TextStrokeTransparency = 0.5
    textLabel.TextSize = 50
    textLabel.Font = Enum.Font.SourceSans
    textLabel.Text = text
    textLabel.Parent = statusLabel

    statusLabel.Parent = HumanoidRootPart
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

function freezePlayer()
    if not HumanoidRootPart:FindFirstChild("FreezeBodyPosition") then
        local bodyPosition = Instance.new("BodyPosition")
        bodyPosition.Name = "FreezeBodyPosition"
        bodyPosition.MaxForce = Vector3.new(5000, 5000, 5000)
        bodyPosition.Position = HumanoidRootPart.Position
        bodyPosition.Parent = HumanoidRootPart
    end
end

function unfreezePlayer()
    local bodyPosition = HumanoidRootPart:FindFirstChild("FreezeBodyPosition")
    if bodyPosition then
        bodyPosition:Destroy()
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
        LocalPlayer.PlayerGui.TopbarStandard.Holders.Left.Quest.Selectable = true
        ShowNotification("AntiAFK", "Enabled")
    end
end

function AutoShake(Shake)
    if Shake then
        if shakeConnection then return end
        shakeConnection = RunService.Heartbeat:Connect(function()
            local shakeUI = LocalPlayer.PlayerGui:FindFirstChild("shakeui")
            if shakeUI and shakeUI:FindFirstChild("safezone") then
                local currentButton = shakeUI.safezone:FindFirstChild("button")
                if currentButton ~= lastshake then
                    lastshake = currentButton

                    local ButtonPosition, ButtonSize = currentButton.AbsolutePosition, currentButton.AbsoluteSize
                    local radius = ButtonSize.X / 2
                    local ClickPositionX = ButtonPosition.X + ButtonSize.X - radius * 0.55
                    local ClickPositionY = ButtonPosition.Y + ButtonSize.Y - radius * 0.55

                    if ClickPositionX ~= 29 then
                        VirtualInputManager:SendMouseButtonEvent(ClickPositionX, ClickPositionY, Enum.UserInputType.MouseButton1.Value, true, game, 1)
                        VirtualInputManager:SendMouseButtonEvent(ClickPositionX, ClickPositionY, Enum.UserInputType.MouseButton1.Value, false, game, 1)
                    end

                    task.wait()
                end
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
        castConnection = RunService.Heartbeat:Connect(function()
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
    WindowAFK:Disconnect()
end)

function onInputBegan(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.T then
            ToggleFarm()
        elseif input.KeyCode == Enum.KeyCode.X then
            ToggleFly()
        elseif input.KeyCode == Enum.KeyCode.F then
            ToggleSell()
        elseif input.KeyCode == Enum.KeyCode.Slash then
            TPAltar()
        elseif input.KeyCode == Enum.KeyCode.KeypadMinus then
            TPAbundance()
        elseif input.KeyCode == Enum.KeyCode.KeypadMultiply then
            TPWhirlpool()
        elseif input.KeyCode == Enum.KeyCode.KeypadPlus then
            TPEvent()
        end
    end
end

UserInputService.InputBegan:Connect(onInputBegan)

CoreGui:SetCore('SendNotification', {
    Title = "Notification",
    Text = "Fisch Loaded!",
    Duration = math.huge,
    Button1 = "@zxc.shiro",
})
