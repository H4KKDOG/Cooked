local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ESPLoop = true
local localPlayer = Players.LocalPlayer
local espThreshold = 125
local espUpdateInterval = 0.25
local lastUpdate = tick()
local Debounce = false

local function createSeeThroughOutline(character)
    if not character then return end

    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            local existingOutline = part:FindFirstChild("Outline")
            if existingOutline then
                existingOutline:Destroy()
            end

            local surfaceGui = Instance.new("SurfaceGui")
            surfaceGui.Name = "Outline"
            surfaceGui.AlwaysOnTop = true
            surfaceGui.Face = Enum.NormalId.Front
            surfaceGui.Adornee = part
            surfaceGui.Parent = part

            local outlineFrame = Instance.new("Frame")
            outlineFrame.Size = UDim2.new(1, 0, 1, 0)
            outlineFrame.BackgroundColor3 = Color3.new(1, 0, 0)
            outlineFrame.BorderSizePixel = 0
            outlineFrame.BackgroundTransparency = 0.75
            outlineFrame.Parent = surfaceGui

            for _, face in pairs(Enum.NormalId:GetEnumItems()) do
                if face ~= Enum.NormalId.Front then
                    local guiClone = surfaceGui:Clone()
                    guiClone.Face = face
                    guiClone.Parent = part
                end
            end
        end
    end
end

local function createESP(player)
    local character = player.Character
    if not character or not character:FindFirstChild("Humanoid") then return end

    local head = character:FindFirstChild("Head")
    if not head or head:FindFirstChild("ESP") then return end

    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP"
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 1, 0)
    billboardGui.Adornee = head
    billboardGui.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 15
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Text = player.DisplayName
    nameLabel.Parent = billboardGui

    createSeeThroughOutline(character)
end

local function shouldHideESP(player)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end

    local distance = (character.HumanoidRootPart.Position - localPlayer.Character.HumanoidRootPart.Position).magnitude
    return distance < espThreshold
end

local function cleanupESP(player)
    local character = player.Character
    if character then
        local head = character:FindFirstChild("Head")
        if head then
            local espGui = head:FindFirstChild("ESP")
            if espGui then
                espGui:Destroy()
            end
        end

        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                local surfaceGui = part:FindFirstChild("Outline")
                if surfaceGui then
                    surfaceGui:Destroy()
                end
            end
        end
    end
end

local function updateESPs()
    if tick() - lastUpdate < espUpdateInterval then return end
    lastUpdate = tick()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local character = player.Character
            if shouldHideESP(player) then
                cleanupESP(player)
            else
                if character and character:FindFirstChild("Head") then
                    if not character.Head:FindFirstChild("ESP") then
                        createESP(player)
                    end
                end
            end
        end
    end
end


local function addESPToPlayers()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            createESP(player)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        createESP(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    cleanupESP(player)
end)

addESPToPlayers()

task.spawn(function()
    while ESPLoop do
        if not Debounce then
            Debounce = true
            updateESPs()
            Debounce = false
        end

        task.wait()
    end
end)
