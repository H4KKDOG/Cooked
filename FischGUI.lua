if game.PlaceId ~= 16732694052 then return end
if getgenv().Cooked then return end
repeat task.wait() until game:IsLoaded()
getgenv().Cooked = true

local Library = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/H4KKDOG/Cooked/refs/heads/main/Library/Fluent.lua"))()
local Window = Library:CreateWindow{
    Title = "Fisch GUI",
    SubTitle = "@zxc.shiro",
    TabWidth = 100,
    Size = UDim2.fromOffset(750, 650),
    Resize = true,
    MinSize = Vector2.new(650, 550),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
}

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

local horizontalSpeed = 150
local verticalSpeed = 75

local bodyVelocity
local InvisCon
local AutoReel
local lastshake
local castConnection
local shakeConnection
local visibleParts = {}

for _, part in pairs(Character:GetDescendants()) do
    if part:IsA("BasePart") and part.Transparency == 0 then
        table.insert(visibleParts, part)
    end
end

function TPWhirlpool()
    if Flying then return end
    local whirlpool = workspace.active:FindFirstChild("Safe Whirlpool")
    if whirlpool then
        teleportToPart(whirlpool)
    else
        Library:Notify{ Title = "Fisch", Content = "No Safe Whirlpool Found", Duration = 2.5 }
    end
end

function TPEvent()
    if Flying then return end
    local event = workspace.zones.fishing:FindFirstChild("FischFright24")
    if event and event:IsA("BasePart") then
        teleportToPart(event)
    else
        Library:Notify{ Title = "Fisch", Content = "No FischFright24 Found", Duration = 2.5 }
    end
end

function findAbundancePart()
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
        Library:Notify{ Title = "Fisch", Content = "No Abundance Found", Duration = 2.5 }
    end
end

function teleportToPart(part)
    if Humanoid and Humanoid.Sit then
        local offset = Vector3.new(100, 0, 0)
        local newPosition = part.Position + offset
        local lookAtCFrame = CFrame.new(newPosition, part.Position)

        HumanoidRootPart.CFrame = lookAtCFrame
    else
        Library:Notify{ Title = "Fisch", Content = "Need to be OnBoat", Duration = 2.5 }
    end
end

function TPlayerToBoat()
    if Flying then return end
    local boatFolder = workspace.active.boats:FindFirstChild(LocalPlayer.Name)
    if not boatFolder then
        Library:Notify{ Title = "Fisch", Content = "No Boat Found", Duration = 2.5 }
        return
    end

    local boat = boatFolder:FindFirstChildOfClass("Model")
    if boat then
        local basePart = boat.PrimaryPart or boat:FindFirstChild("BasePart")

        if basePart then
            if HumanoidRootPart then
                HumanoidRootPart.CFrame = basePart.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
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
        Library:Notify{ Title = "Fisch", Content = "AntiAFK", Duration = 2.5 }
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
                        task.wait(1.25)

                        VirtualInputManager:SendMouseButtonEvent(1, 1, Enum.UserInputType.MouseButton1.Value, true, game, 1)

                        local humanoidRootPart = playerWorkspace:FindFirstChild("HumanoidRootPart")
                        local power = humanoidRootPart:WaitForChild("power", 5)
                        local powerbar = power:FindFirstChild("powerbar")
                        local bar = powerbar:FindFirstChild("bar")

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

        while Reeling and AutoReel do
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

local Tabs = {
    Fishing = Window:CreateTab{
        Title = "Fishing",
        Icon = "fish"
    },
    Teleport = Window:CreateTab{
        Title = "Teleport",
        Icon = "tree-palm"
    },
    Extra = Window:CreateTab{
        Title = "Extra",
        Icon = "circle-ellipsis"
    }
}

local Cast = Tabs.Fishing:CreateToggle("MyToggle", {Title = "Auto Cast", Default = false })
Cast:OnChanged(function(toggle)
    AutoCast(toggle)
end)

local Shake = Tabs.Fishing:CreateToggle("MyToggle", {Title = "Auto Shake", Default = false })
Shake:OnChanged(function(toggle)
    AutoShake(toggle)
end)

local Reel = Tabs.Fishing:CreateToggle("MyToggle", {Title = "Auto Reel", Default = false })
Reel:OnChanged(function(toggle)
    AutoReel = toggle
end)

Tabs.Fishing:CreateButton{
    Title = "Sell All",
    Callback = function()
        ReplicatedStorage.events.selleverything:InvokeServer()
    end
}

local Event = Tabs.Teleport:CreateDropdown("Dropdown", {
    Title = "Ocean Event",
    Values = {"Abundance", "FischFright24", "Whirlpool"},
    Multi = false,
    Default = 1,
})

Event:OnChanged(function(AAA)
    Library:Notify{ Title = "Fisch", Content = "Event: "..AAA, Duration = 2.5}
    if AAA == "Abundance" then
        findAbundancePart()
    elseif AAA == "FischFright24" then
        TPEvent()
    elseif AAA == "Whirlpool" then
        TPWhirlpool()
    end
end)

local Island = Tabs.Teleport:CreateDropdown("Dropdown", {
    Title = "Island / Area",
    Values = {"Moosewood", "Altar"},
    Multi = false,
    Default = 1,
})

Island:OnChanged(function(AAA)
    Library:Notify{ Title = "Fisch", Content = "Island: "..AAA, Duration = 2.5}
    if AAA == "Moosewood" then
        HumanoidRootPart.CFrame = CFrame.new(383.060546875, 134.50001525878906, 267.64471435546875)
    elseif AAA == "Altar" then
        HumanoidRootPart.CFrame = CFrame.new(Vector3.new(1296.32080078125, -805.292236328125, -298.93817138671875))
    end
end)

Tabs.Fishing:CreateButton{
    Title = "AntiAFK (Label)",
    Callback = function()
        replaceAFKEvent()
    end
}

Tabs.Extra:CreateKeybind("Keybind", {
    Title = "InviFly",
    Mode = "Toggle",
    Default = "X",

    Callback = function()
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
    end,

    ChangedCallback = function(New)
        Library:Notify{ Title = "Fisch", Content = "Bind: "..New, Duration = 2.5 }
    end
})

Tabs.Extra:CreateKeybind("Keybind", {
    Title = "TP to Boat",
    Mode = "Toggle",
    Default = "B",

    Callback = function()
        TPlayerToBoat()
    end,

    ChangedCallback = function(New)
        Library:Notify{ Title = "Fisch", Content = "Bind: "..New, Duration = 2.5 }
    end
})

Window:SelectTab(1)
Library:Notify{ Title = "Fisch", Content = "Loaded.", Duration = 5 }
