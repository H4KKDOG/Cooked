if game.PlaceId ~= 16732694052 then
    return
end

if getgenv().Cooked then
    return
end

repeat
    task.wait()
until game:IsLoaded()
getgenv().Cooked = true

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

local Rod = false
local Casted = false
local Progress = false

local lastshake
local castConnection
local shakeConnection
local reelConnection

--// Notification
function ShowNotification(Title, Content, Time)
    CoreGui:SetCore('SendNotification', {
        Title = Title,
        Text = Content,
        Duration = Time or 2.5
    })
end

--// Teleport
function TPAltar()
    HumanoidRootPart.CFrame = CFrame.new(Vector3.new(1296.32080078125, -805.292236328125, -298.93817138671875))
end

function TPMoosewood()
    HumanoidRootPart.CFrame = CFrame.new(383.060546875, 134.50001525878906, 267.64471435546875)
end

function TPWhirlpool()
    local whirlpool = workspace.active:FindFirstChild("Safe Whirlpool")
    if whirlpool then
        teleportToPart(whirlpool)
    else
        ShowNotification("Whirlpool", "Not Found")
    end
end

function TPEvent()
    local event = workspace.zones.fishing:FindFirstChild("FischFright24")
    if event and event:IsA("BasePart") then
        teleportToPart(event)
    else
        ShowNotification("FischFright24", "Not Found")
    end
end

function TPAbundance()
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
        ShowNotification("Abundance", "Not Found")
    end
end

function TPToBoat()
    local boatFolder = workspace.active.boats:FindFirstChild(LocalPlayer.Name)
    if not boatFolder then
        ShowNotification("Boat", "Not Found")
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
    local offset
    if Humanoid.Sit then
        offset = Vector3.new(150, 0, 0)
    else
        offset = Vector3.new(100, 75, 0)
    end

    local newPosition = part.Position + offset
    local lookAtCFrame = CFrame.new(newPosition, part.Position)

    HumanoidRootPart.CFrame = lookAtCFrame
end


--// Other Function
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

function replaceAFKEvent()
    local AFK = ReplicatedStorage:FindFirstChild("events"):FindFirstChild("afk")
    if AFK then
        wait(0.5)
        local FakeAFK = Instance.new("RemoteEvent")
        FakeAFK.Name = "afk"
        FakeAFK.Parent = ReplicatedStorage:FindFirstChild("events")

        AFK:Destroy()
        LocalPlayer.PlayerGui.TopbarStandard.Holders.Left.Quest.Selectable = true
        ShowNotification("AntiAFK", "Enabled")
    end
end

function createUIButton(name, text, position, size, callback)
    local ScreenGui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("ScreenGui")

    if not ScreenGui then
        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "ScreenGui"
        ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        ScreenGui.ResetOnSpawn = false
    end

    local button = Instance.new("TextButton")
    button.Name = name
    button.Parent = ScreenGui
    button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    button.Position = position
    button.Size = size
    button.Font = Enum.Font.SourceSans
    button.Text = text
    button.TextColor3 = Color3.fromRGB(248, 248, 248)
    button.TextSize = 28
    button.Draggable = true

    local Corner = Instance.new("UICorner")
    Corner.Parent = button

    button.MouseButton1Click:Connect(callback)

    return button
end


--// LocalPlayer Loop
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

LocalPlayer.PlayerGui.DescendantRemoving:Connect(function(Descendant)
    if Descendant.Name == 'reel' then
        Progress = false
        Reeling = false
    end
end)

--// Fishing Loop
function AutoCast(Cast)
    if Cast then
        if castConnection then return end
        castConnection = RunService.Heartbeat:Connect(function()
            if not Progress then
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

function AutoReel(Reel)
    if Reel then
        if reelConnection then return end
        reelConnection = LocalPlayer.PlayerGui.DescendantAdded:Connect(function(Descendant)
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
    else
        if reelConnection then
            reelConnection:Disconnect()
            reelConnection = nil
            Reeling = false
        end
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

--// Gui Function
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/H4KKDOG/Cooked/refs/heads/main/Library/Kavo.lua"))()
local Window = Library.CreateLib("Fisch GUI", "BloodTheme")

local Fishing = Window:NewTab("Fishing")
local Teleport = Window:NewTab("Teleport")

local Main = Fishing:NewSection("Main")
local Event = Teleport:NewSection("Event")

--// Main
Main:NewToggle("Auto Cast", "ToggleInfo", function(value)
    AutoCast(value)
end)

Main:NewToggle("Auto Shake", "ToggleInfo", function(value)
    AutoShake(value)
end)

Main:NewToggle("Auto Reel", "ToggleInfo", function(value)
    AutoReel(value)
end)

Main:NewLabel("Extra")

Main:NewToggle("No Oxygen", "ToggleInfo", function(value)
    playerWorkspace:FindFirstChild("client"):FindFirstChild("oxygen").Disabled = value
end)

Main:NewButton("Sell All Fish", "ButtonInfo", function()
    ReplicatedStorage.events.selleverything:InvokeServer()
end)

Main:NewButton("AntiAFK (Label)", "ButtonInfo", function()
    ReplicatedStorage.events.selleverything:InvokeServer()
end)

--// Event
Event:NewButton("FischFright24", "ButtonInfo", function()
    TPEvent()
end)

Event:NewButton("Abundance", "ButtonInfo", function()
    TPAbundance()
end)

Event:NewButton("Whirlpool", "ButtonInfo", function()
    TPWhirlpool()
end)

Event:NewLabel("Island")

Event:NewButton("Moosewood", "ButtonInfo", function()
    TPMoosewood()
end)

Event:NewButton("Altar", "ButtonInfo", function()
    TPAltar()
end)


--// Useless Func
function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function isPC()
    return not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled
end

if isMobile() then
    createUIButton("ToggleUI", "UI", UDim2.new(0, 0, 0.454, 0), UDim2.new(0, 50, 0, 50), function()
        Library:ToggleUI()
    end)

    createUIButton("ToggleTP", "TP", UDim2.new(0, 0, 0.554, 0), UDim2.new(0, 50, 0, 50), function()
        TPToBoat()
    end)
elseif isPC() then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/H4KKDOG/Cooked/refs/heads/main/InviFly.lua", true))()
    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end

        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.LeftControl then
                Library:ToggleUI()
            elseif input.KeyCode == Enum.KeyCode.B then
                TPToBoat()
            end
        end
    end)
end
