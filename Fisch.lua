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
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local playerBobberWorkspace = workspace:FindFirstChild(playerName)
local OnPc = not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled
local OnMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled

local Progress = false
local Reeling = false
local WaitDelay = false
local flyEnabled = false
local horizontalSpeed = 125
local verticalSpeed = 75
local bodyVelocity
local rodName
local MouseValue

local lastCheck = tick()

if OnPc then
    MouseValue = 0
elseif OnMobile then
    MouseValue = 1
end

getgenv().config = getgenv().config
local isFirstTime = false
local configTemplate = {
    Enabled = false,
    AutoSell = false,
    SellBind = "F",
    FlyBind = "X"
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
    if AFK and UserInputService.WindowFocused then
        task.wait(0.75)
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

function fly()
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Parent = Character:WaitForChild("HumanoidRootPart")

    while flyEnabled do
        local moveDirection = Character.Humanoid.MoveDirection

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

        wait()
    end

    bodyVelocity:Destroy()
end

function toggleFly()
    flyEnabled = not flyEnabled
    if flyEnabled then
        fly()
    end
end

--// Reel / Shake
LocalPlayer.PlayerGui.DescendantAdded:Connect(function(Descendant)
    if Descendant.Name == 'button' and Descendant.Parent.Name == 'safezone' then
        task.wait()
        local ButtonPosition, ButtonSize = Descendant.AbsolutePosition, Descendant.AbsoluteSize

        local radius = ButtonSize.X / 2

        local ClickPositionX = ButtonPosition.X + ButtonSize.X - radius * 0.55
        local ClickPositionY = ButtonPosition.Y + ButtonSize.Y - radius * 0.55

        if ClickPositionX ~= 29 and ClickPositionY ~= 29 then
            task.wait(0.75)
            VirtualInputManager:SendMouseButtonEvent(ClickPositionX, ClickPositionY, MouseValue, true, game, 1)
            VirtualInputManager:SendMouseButtonEvent(ClickPositionX, ClickPositionY, MouseValue, false, game, 1)
        end
    elseif Descendant.Name == 'playerbar' and Descendant.Parent.Name == 'bar' then
        local fish = Descendant.Parent:FindFirstChild("fish")
        local randomChance = math.random(1, 3)
        local Perfect = randomChance <= 1

        WaitDelay = true
        Reeling = true

        while Reeling do
            if fish and Descendant then
                if not Perfect and WaitDelay then
                    task.wait(3.0)
                    WaitDelay = false
                end

                Descendant.Position = UDim2.new(
                    fish.Position.X.Scale + math.random(0.75, 0.1) / 100,
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
        Progress = false
        WaitDelay = false
        Reeling = false
    end
end)

playerBobberWorkspace.DescendantRemoving:Connect(function(BobChild)
    if BobChild.Name == "bobber" then
        Progress = false
    end
end)

LocalPlayer.PlayerGui.DescendantRemoving:Connect(function(Descendant)
    if Descendant.Name == 'reel' then
        Progress = false
        WaitDelay = false
        Reeling = false
        if config.AutoSell then
            ReplicatedStorage.events.selleverything:InvokeServer()
        end
    end
end)

--// Cast
coroutine.wrap(function()
    while config.Enabled do
        task.wait(0.25)

        if not Progress then
            local nRod = updateRodInWorkspace()
            if nRod and not nRod:FindFirstChild("bobber") then
                Progress = true
                task.wait(3.0)

                VirtualInputManager:SendMouseButtonEvent(1, 1, MouseValue, true, game, 1)
                task.wait(0.3)
                VirtualInputManager:SendMouseButtonEvent(1, 1, MouseValue, false, game, 1)

                wait()

                if nRod and nRod:FindFirstChild("events") then
                    if rodName and rodName ~= "" then
                        Character:FindFirstChild(rodName).events.reset:FireServer()
                        Character:FindFirstChild(rodName).events.cast:FireServer(100)
                    end
                end
            end
        end
    end
end)()

coroutine.wrap(function()
    while config.Enabled do
        task.wait(0.25)

        if tick() - lastCheck >= 30 then
            local nRod = updateRodInWorkspace()
            if nRod and not nRod:FindFirstChild("bobber") then
                Progress = false
            end
            lastCheck = tick()
        end
    end
end)()

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
        local position = HumanoidRootPart.Position
        local clipboardContent = "{ \"LocationName\", Vector3.new(" .. position.X .. ", " .. position.Y .. ", " .. position.Z .. ") },"
        setclipboard(clipboardContent)
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
end)

local SellToggle = Tabs.Fishing:CreateToggle("MyToggle", {Title = "Auto Sell", Default = config.AutoSell })
SellToggle:OnChanged(function(value)
    config.AutoSell = value
    updateConfig()
end)

Tabs.Fishing:CreateParagraph("Paragraph", { Title = "", Content = "" })

local fishingSpots = {
    { "Sunstone (Common Crate)", Vector3.new(-1149.08508, 134.49998, -1055.80151) },
    { "Vertigo (Small Stone)", Vector3.new(-107.99476623535156, -731.946533203125, 1207.8134765625) },
    { "Moosewood (Small Island)", Vector3.new(229.60299682617188, 139.34976196289062, 43.50540542602539) },
    { "Snowcap (Cave)", Vector3.new(2805.062744140625, 131.85032653808594, 2712.624267578125) },
    { "Deep Ocean (Boat)", Vector3.new(1447.85071, 139.649994, -7649.64502) },
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
    { "Vertigo", Vector3.new(-95.83425903320312, -513.2993774414062, 1116.5545654296875) }
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
elseif UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    replaceAFKEvent()
    Library:Notify{ Title = "Fisch Notification", Content = "Loaded!", Duration = 5 }
end

Window:SelectTab(1)
