if game.PlaceId ~= 16732694052 then return end
print("Fisch (Executed)")

repeat
    task.wait()
until game:IsLoaded()

if getgenv().Shiro then return end
getgenv().Shiro = true

local Library = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/H4KKDOG/Cooked/refs/heads/main/Library/Fluent.lua"))()
local Window = Library:CreateWindow{
    Title = "Fisch GUI (PublicVer)",
    SubTitle = "@zxc.shiro",
    TabWidth = 135,
    Size = UDim2.fromOffset(650, 575),
    Resize = true,
    MinSize = Vector2.new(450, 375),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
}

local Players = game:GetService('Players')
local CoreGui = game:GetService('StarterGui')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ContextActionService = game:GetService('ContextActionService')
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService('VirtualInputManager')
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local playerName = LocalPlayer.Name
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildOfClass("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local playerBobberWorkspace = workspace:FindFirstChild(playerName)

local Progress = false
local Reeling = false
local WaitDelay = false
local isActive = false
local flying = false
local horizontalSpeed = 250
local verticalSpeed = 75
local bodyVelocity
local rodName
local lastButtonInstance
local MouseValue

getgenv().config = getgenv().config
local isFirstTime = false
local configTemplate = {
    Enabled = false,
    AutoSell = false,
    AutoShake = false,
    FastShake = false,
    AutoReel = false,
    SellBind = "F",
    FlyBind = "X",
}

if not isfolder("FischConfig") then
    isFirstTime = true
    makefolder("FischConfig")
end

if not isfile("FischConfig/Cooked.txt") then
    isFirstTime = true
    writefile("FischConfig/Cooked.txt", "")
end

if isFirstTime then
    local encodedConfig = HttpService:JSONEncode(configTemplate)
    writefile("FischConfig/Cooked.txt", encodedConfig)
end

function loadConfig()
    local decodedConfig = HttpService:JSONDecode(readfile("FischConfig/Cooked.txt"))
    getgenv().config = decodedConfig
end

function updateConfig()
    local encodedConfig = HttpService:JSONEncode(getgenv().config)
    writefile("FischConfig/Cooked.txt", encodedConfig)
end

loadConfig()

function replaceAFKEvent()
    local AFK = ReplicatedStorage:FindFirstChild("events"):FindFirstChild("afk")
    if AFK then
        wait(0.75)
        local FakeAFK = Instance.new("RemoteEvent")
        FakeAFK.Name = "afk"
        FakeAFK.Parent = ReplicatedStorage:FindFirstChild("events")

        Library:Notify{ Title = "Fisch Notification", Content = "AntiAFK Enabled.", Duration = 5 }
        AFK:Destroy()
    end
end

function updateRodInWorkspace()
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

if _G.con then
    for _, conn in pairs(_G.con) do
        conn:Disconnect()
    end
    _G.con = nil
end

local parts = {}
for _, part in pairs(Character:GetDescendants()) do
    if part:IsA("BasePart") and part.Transparency == 0 then
        table.insert(parts, part)
    end
end

function fly()
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(5000, 5000, 5000)
    bodyVelocity.Parent = Character:WaitForChild("HumanoidRootPart")

    while flying do
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

    bodyVelocity:Destroy()
end

local connections = {}

connections[1] = RunService.Heartbeat:Connect(function()
    if flying then
        local originalCFrame = HumanoidRootPart.CFrame
        local offsetCFrame = originalCFrame * CFrame.new(0, -1000, 0)
        Humanoid.CameraOffset = offsetCFrame:ToObjectSpace(CFrame.new(originalCFrame.Position)).Position
        HumanoidRootPart.CFrame = offsetCFrame

        RunService.RenderStepped:Wait()

        Humanoid.CameraOffset = Vector3.new()
        HumanoidRootPart.CFrame = originalCFrame
    end
end)

connections[2] = RunService.Heartbeat:Connect(function()
    if LocalPlayer.PlayerGui:FindFirstChild("shakeui") and LocalPlayer.PlayerGui.shakeui.safezone.button then
        local shakeButton = LocalPlayer.PlayerGui.shakeui.safezone.button
        if shakeButton ~= lastButtonInstance then
			lastButtonInstance = shakeButton
            local ButtonPosition, ButtonSize = shakeButton.AbsolutePosition, shakeButton.AbsoluteSize
            local radius = ButtonSize.X / 2
            local ClickPositionX = ButtonPosition.X + ButtonSize.X - radius * 0.55
            local ClickPositionY = ButtonPosition.Y + ButtonSize.Y - radius * 0.55
                
            if ClickPositionX ~= 29 and config.AutoShake then
                if not config.FastShake then
                    task.wait(0.69)
                end
        
                VirtualInputManager:SendMouseButtonEvent(ClickPositionX, ClickPositionY, MouseValue, true, game, 1)
                VirtualInputManager:SendMouseButtonEvent(ClickPositionX, ClickPositionY, MouseValue, false, game, 1)
            end
        end
    end
end)

_G.con = connections

function toggleFly()
    flying = not flying

    for _, part in pairs(parts) do
        part.Transparency = flying and 0.5 or 0
    end

    if flying then
        fly()
        Invis()
    else
        HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
    end
end

--// Reel / Shake
LocalPlayer.PlayerGui.DescendantAdded:Connect(function(Descendant)
    if Descendant.Name == 'playerbar' and Descendant.Parent.Name == 'bar' then
        local fish = Descendant.Parent:FindFirstChild("fish")
        local randomChance = math.random(1, 3)
        local Perfect = randomChance <= 1

        WaitDelay = true
        Reeling = true

        while Reeling and config.AutoReel do
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
end)


LocalPlayer.Character.ChildAdded:Connect(function(Child)
    if Child:IsA('Tool') and Child.Name:lower():find('rod') then
        rodName = Child.Name
        Rod = Child
    end
end)

LocalPlayer.Character.ChildRemoved:Connect(function(Child)
    if Child.Name == rodName then
        rodName = nil
        WaitDelay = false
        Reeling = false
        wait(0.75)
        Progress = false
    end
end)

playerBobberWorkspace.DescendantRemoving:Connect(function(BobChild)
    if BobChild.Name == "bobber" then
        wait(0.75)
        Progress = false
    end
end)

LocalPlayer.PlayerGui.DescendantRemoving:Connect(function(Descendant)
    if Descendant.Name == 'reel' then
        WaitDelay = false
        Reeling = false
        if config.AutoSell then
            ReplicatedStorage.events.selleverything:InvokeServer()
        end
        wait(0.75)
        Progress = false
    end
end)

--// GUI
local Tabs = {
    Fishing = Window:CreateTab{
        Title = "Fishing",
        Icon = "fish"
    },
    Island = Window:CreateTab{
        Title = "Island",
        Icon = "tree-palm"
    },
    Debug = Window:CreateTab{
        Title = "MiscDev",
        Icon = "bug"
    }
}

--// MiscDev
Tabs.Debug:CreateButton{
    Title = "Get Current Pos",
    Callback = function()
        Window:Dialog{
            Title = "Clipboard Pos",
            Content = "Select One",
            Buttons = {
                {
                    Title = "OnFoot",
                    Callback = function()
                        local position = HumanoidRootPart.Position
                        local clipboardContent = "{ \"LocationName\", Vector3.new(" .. position.X .. ", " .. position.Y .. ", " .. position.Z .. ") },"
                        setclipboard(clipboardContent)
                    end
                },
                {
                    Title = "OnBoat",
                    Callback = function()
                        local position = HumanoidRootPart.Position
                        local newPositionY = position.Y + 5
                        local clipboardContent = "{ \"LocationName\", Vector3.new(" .. position.X .. ", " .. newPositionY .. ", " .. position.Z .. ") },"
                        setclipboard(clipboardContent)
                    end
                }
            }
        }
    end
}

local Fly = Tabs.Debug:CreateKeybind("Keybind", {
    Title = "Flight",
    Mode = "Toggle",
    Default = config.FlyBind,

    Callback = function(click)
        toggleFly()
    end,

    ChangedCallback = function(Key)
        config.FlyBind = tostring(Key.Name)
        updateConfig()
        Library:Notify{ Title = "Fisch Notification", Content = "Set Keybind : "..tostring(Key.Name), Duration = 5 }
    end
})

Tabs.Debug:CreateParagraph("Paragraph", { Title = "", Content = "" })

Tabs.Debug:CreateButton{
    Title = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end
}

Tabs.Debug:CreateButton{
    Title = "Server Hop",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/H4KKDOG/MiscScripts/refs/heads/main/ServerHop"))()
    end
}


--// Fishing
local SellInv = Tabs.Fishing:CreateKeybind("Keybind", {
    Title = "Sell Inventory",
    Mode = "Toggle",
    Default = config.SellBind,

    Callback = function(click)
        ReplicatedStorage.events.selleverything:InvokeServer()
    end,

    ChangedCallback = function(Key)
        config.SellBind = tostring(Key.Name)
        updateConfig()
        Library:Notify{ Title = "Fisch Notification", Content = "Set Keybind : "..tostring(Key.Name), Duration = 5 }
    end
})

local CastToggle = Tabs.Fishing:CreateToggle("MyToggle", {Title = "Auto Cast", Default = config.Enabled })
CastToggle:OnChanged(function(value)
    config.Enabled = value
    updateConfig()

    if not config.Enabled then
        Progress = false
    else
        coroutine.wrap(function()
            local lastCheck = tick()
            while config.Enabled do
                task.wait(0.25)

                if not Progress then
                    local nRod = updateRodInWorkspace()
                    if nRod and not nRod:FindFirstChild("bobber") then
                        Progress = true
                        wait(1.75)

                        VirtualInputManager:SendMouseButtonEvent(1, 1, MouseValue, true, game, 1)
                        task.wait(0.75)
                        VirtualInputManager:SendMouseButtonEvent(1, 1, MouseValue, false, game, 1)

                        task.wait()
                        if nRod and nRod:FindFirstChild("events") then
                            if rodName and rodName ~= "" then
                                Character:FindFirstChild(rodName).events.reset:FireServer()
                                Character:FindFirstChild(rodName).events.cast:FireServer(100)
                            end
                        end
                        wait(0.75)
                    end
                end

                if tick() - lastCheck >= 30 then
                    local nRod = updateRodInWorkspace()
                    if nRod and not nRod:FindFirstChild("bobber") then
                        Progress = false
                    end
                    lastCheck = tick()
                end
            end
        end)()
    end
end)


local ShakeToggle = Tabs.Fishing:CreateToggle("MyToggle", {Title = "Auto Shake", Default = config.AutoShake })
ShakeToggle:OnChanged(function(value)
    config.AutoShake = value
    updateConfig()
end)

local FastShakeToggle = Tabs.Fishing:CreateToggle("MyToggle", {Title = "Fast Shake (Settings)", Default = config.FastShake })
FastShakeToggle:OnChanged(function(value)
    config.FastShake = value
    updateConfig()
end)

local ReelToggle = Tabs.Fishing:CreateToggle("MyToggle", {Title = "Auto Reel", Default = config.AutoReel })
ReelToggle:OnChanged(function(value)
    config.AutoReel = value
    updateConfig()
end)

local SellToggle = Tabs.Fishing:CreateToggle("MyToggle", {Title = "Auto Sell", Default = config.AutoSell })
SellToggle:OnChanged(function(value)
    config.AutoSell = value
    updateConfig()
end)

Tabs.Fishing:CreateParagraph("Paragraph", { Title = "", Content = "" })

local fishingSpots = {
    { "Deep Ocean", Vector3.new(1307.6851806640625, 139.40093994140625, -7598.64208984375) },
}

for _, location in ipairs(fishingSpots) do
    Tabs.Fishing:CreateButton{
        Title = location[1],
        Callback = function()
            HumanoidRootPart.CFrame = CFrame.new(location[2])
        end
    }
end

--// Island
local locations = {
    { "Moosewood", Vector3.new(383.060546875, 134.50001525878906, 267.64471435546875) },
    { "Roslit Hamlet", Vector3.new(-1442.3291015625, 133, 726.9091796875) },
    { "Terrapin Island", Vector3.new(-192.4793243408203, 135.2742919921875, 1953.1597900390625) },
    { "Statue Of Sovereignty", Vector3.new(31.58206558227539, 144.49334716796875, -1021.61083984375) },
    { "Sunstone", Vector3.new(-917.5526733398438, 135.08364868164062, -1122.1175537109375) },
    { "Snowcap Island", Vector3.new(2620.824951171875, 139.7838592529297, 2423.62890625) },
    { "The Arc", Vector3.new(998.9711303710938, 131.3202362060547, -1237.1431884765625) },
    { "Keepers Altar", Vector3.new(1296.32080078125, -805.292236328125, -298.93817138671875) },
    { "Harvester Spike", Vector3.new(-1254.696044921875, 137.56063842773438, 1554.47119140625) },
    { "Mushgrove Swamp", Vector3.new(2441.1611328125, 130.904052734375, -683.6802368164062) },
    { "Vertigo", Vector3.new(-95.83425903320312, -513.2993774414062, 1116.5545654296875) },
}

for _, location in ipairs(locations) do
    Tabs.Island:CreateButton{
        Title = location[1],
        Callback = function()
            HumanoidRootPart.CFrame = CFrame.new(location[2])
        end
    }
end

-- // Extra Func
if UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled then

    local WindowAFK
    WindowAFK = UserInputService.WindowFocused:Connect(function()
        replaceAFKEvent()
        WindowAFK:Disconnect()
    end)
    Library:Notify{ Title = "Fisch Notification", Content = "Loaded!", Duration = 5 }
    MouseValue = 0
elseif UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    replaceAFKEvent()
    Library:Notify{ Title = "Fisch Notification", Content = "Loaded!", Duration = 5 }
    MouseValue = 1
end

Window:SelectTab(1)
