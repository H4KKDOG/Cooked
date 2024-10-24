if game.PlaceId ~= 16732694052 then return end
if getgenv().Cooked then return end
getgenv().Cooked = true

repeat
    task.wait()
until game:IsLoaded()

local Players = game:GetService('Players')
local CoreGui = game:GetService('StarterGui')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local VirtualInputManager = game:GetService('VirtualInputManager')
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildOfClass("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Head = LocalPlayer.Character:FindFirstChild("Head")
local playerWorkspace = workspace:FindFirstChild(LocalPlayer.Name)

local Enabled = false
local Rod = false
local Casted = false
local Progress = false
local Flying = false
local IsTransparent = false
local visibleParts = {}

local horizontalSpeed = 150
local verticalSpeed = 75
local teleportState = 0

local bodyVelocity
local InvisCon
local lastshake
local castConnection
local shakeConnection

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
    Enabled = not Enabled

    if not Enabled then
        AutoCast(false)
        AutoShake(false)
        ShowNotification("Fishing", "OFF")
    else
        AutoCast(true)
        AutoShake(true)
        ShowNotification("Fishing", "ON")
    end
end

function ToggleFly()
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

function TPAltar()
    if Flying then return end
    if teleportState == 0 then
        HumanoidRootPart.CFrame = CFrame.new(Vector3.new(1296.32080078125, -805.292236328125, -298.93817138671875))
        teleportState = 1
    else
        HumanoidRootPart.CFrame = CFrame.new(383.060546875, 134.50001525878906, 267.64471435546875)
        teleportState = 0
    end
end

function TPWhirlpool()
    if Flying then return end
    local whirlpool = workspace.active:FindFirstChild("Safe Whirlpool")
    if whirlpool then
        teleportToPart(whirlpool)
    else
        ShowNotification("Whirlpool", "Invalid")
    end
end

function TPEvent()
    if Flying then return end
    local event = workspace.zones.fishing:FindFirstChild("FischFright24")
    if event and event:IsA("BasePart") then
        teleportToPart(event)
    else
        ShowNotification("Event", "Invalid")
    end
end

function TPAbundance()
    if Flying then return end
    local abundancePartFound = false
    local mediumStoneGrey = Color3.fromRGB(163, 162, 165)

    for _, part in ipairs(workspace.zones.fishing:GetChildren()) do
        if part:IsA("Part") and part.Name ~= "FischFright24" then
            if part.Material == Enum.Material.Plastic then
                if part.Color ~= mediumStoneGrey then
                    teleportToPart(part)
                    abundancePartFound = true
                    break
                end
            end
        end
    end

    if not abundancePartFound then
        ShowNotification("Abundance", "Invalid")
    end
end

function TPlayerToBoat()
    if Flying then return end
    local boatFolder = workspace.active.boats:FindFirstChild(LocalPlayer.Name)
    if not boatFolder then
        ShowNotification("Missing", "Boat")
        return
    end

    local boat = boatFolder:FindFirstChildOfClass("Model")
    if boat then
        local basePart = boat:FindFirstChild("Base")

        if basePart and basePart:IsA("Part") then
            HumanoidRootPart.CFrame = basePart.CFrame + Vector3.new(0, basePart.Size.Y / 2 + 3, 0)
        end
    end
end

function teleportToPart(part)
    local offset = Vector3.new(100, 75, 0)
    local newPosition = part.Position + offset
    local lookAtCFrame = CFrame.new(newPosition, part.Position)

    HumanoidRootPart.CFrame = lookAtCFrame
end

function updateRodInWorkspace()
    if playerWorkspace then
        for _, item in pairs(playerWorkspace:GetChildren()) do
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
        wait(0.5)
        local FakeAFK = Instance.new("RemoteEvent")
        FakeAFK.Name = "afk"
        FakeAFK.Parent = ReplicatedStorage:FindFirstChild("events")

        AFK:Destroy()
        LocalPlayer.PlayerGui.TopbarStandard.Holders.Left.Quest.Selectable = true
        playerWorkspace:FindFirstChild("client"):FindFirstChild("oxygen").Enabled = false
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
                if currentButton then
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
            if not Progress and not Flying then
                local workRod = updateRodInWorkspace()
                if workRod and not workRod:FindFirstChild("bobber") then
                    if Rod then
                        Progress = true
                        task.wait(2.25)

                        VirtualInputManager:SendMouseButtonEvent(1, 1, Enum.UserInputType.MouseButton1.Value, true, game, 1)

                        local humanoidRootPart = playerWorkspace:FindFirstChild("HumanoidRootPart")
                        local power = humanoidRootPart:WaitForChild("power", 5)
                        if not power then Progress = false return end
                        local powerbar = power:WaitForChild("powerbar", 5)
                        local bar = powerbar:WaitForChild("bar", 5)

                        local WaitForPerfect

                        if WaitForPerfect then
                            WaitForPerfect:Disconnect()
                        end

                        WaitForPerfect = RunService.Heartbeat:Connect(function()
                            if bar and bar:IsA("Frame") then
                                local barSizeY = bar.Size.Y

                                if barSizeY.Scale == 1 then
                                    VirtualInputManager:SendMouseButtonEvent(1, 1, Enum.UserInputType.MouseButton1.Value, false, game, 1)
                                    WaitForPerfect:Disconnect()
                                end
                            end
                        end)

                        task.wait(2.75)
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

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.T then
            ToggleFarm()
        elseif input.KeyCode == Enum.KeyCode.X then
            ToggleFly()
        elseif input.KeyCode == Enum.KeyCode.F then
            ReplicatedStorage.events.selleverything:InvokeServer()
        elseif input.KeyCode == Enum.KeyCode.KeypadThree then
            TPAltar()
        elseif input.KeyCode == Enum.KeyCode.KeypadMinus then
            TPAbundance()
        elseif input.KeyCode == Enum.KeyCode.KeypadMultiply then
            TPWhirlpool()
        elseif input.KeyCode == Enum.KeyCode.KeypadPlus then
            TPEvent()
        elseif input.KeyCode == Enum.KeyCode.B then
            TPlayerToBoat()
        end
    end
end)

CoreGui:SetCore('SendNotification', {
    Title = "Notification",
    Text = "Fisch Loaded!",
    Duration = math.huge,
    Button1 = "@zxc.shiro",
    Callback = ToggleFarm()
})
